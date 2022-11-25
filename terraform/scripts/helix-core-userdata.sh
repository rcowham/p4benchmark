#!/bin/bash

set -eux -o pipefail

trap 'catch $? $LINENO' ERR

catch() {
    echo ""
    echo "ERROR CAUGHT!"
    echo ""
    echo "Error code $1 occurred on line $2"
    echo ""
    
    exit $1
}

echo "${ssh_public_key}" > /ssh_public_key
echo "${ssh_public_key}" >> /home/${p4benchmark_os_user}/.ssh/authorized_keys
echo "${ssh_private_key}" > /ssh_private_key

echo 'perforce ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/perforce

## Set default values for environment variables here.
## Either PreUserdata or custom-pre will be able to overwrite these defaults
export HOSTNAME="commit"
export RESTORED_FROM_SNAPSHOT=false
export SWARM_IP=""
export DEPOT_CONTENT_SNAPSHOT=""
# TODO: make this work for both AWS and Azure.  need to test if cloud-init query cloud_name works across all our clouds
export AWS_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

export P4D_AUTH_ID="commit"
# TODO: make this work for both AWS and Azure. Azure does not allow to configure the desired path for the devices
export DEPOT_DEVICE="/dev/sde"
export LOG_DEVICE="/dev/sdc"
export METADATA_DEVICE="/dev/sdd"


run-parts /home/perforce/.userdata/custom-pre/

# run-parts /home/perforce/.userdata/default/
# This steps were copied from the image given that we need to increase the sleep on line 142
hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

counter=0
while [ ! -e "$DEPOT_DEVICE" ]; do
    echo "Waiting for $DEPOT_DEVICE to be attached..."
    sleep 10
    counter=$((counter + 1))
    if [ $counter -ge 50 ]; then
        echo "Counter expired waiting for $DEPOT_DEVICE to be attached"
        exit 1
    fi
done

start_p4d() {
    systemctl start p4d_1
    iterations=0
    max_iterations=30
    STATUS=1
    while [ $STATUS -ne 0 ]; do
        sleep 1
        ((iterations=iterations+1))
        systemctl is-active --quiet p4d_1
        STATUS=$?
        if [ "$iterations" -ge "$max_iterations" ]; then
            echo "Startup loop Timeout waiting for p4d_1 service"
            exit 1
        fi
    done
}

# The AMI is baked with /hx* on the EC2 root volume.  
# Now that we are starting from CloudFormation we can utilize seperate volumes
systemctl stop p4d_1
mkdir -p /_hxdata
mv /hxdepots /_hxdata
mv /hxmetadata /_hxdata
mv /hxlogs /_hxdata

mkdir -p /hxdepots
mkdir -p /hxlogs
mkdir -p /hxmetadata

mkfs -t xfs "$LOG_DEVICE"
mkfs -t xfs "$METADATA_DEVICE"

blkid "$LOG_DEVICE" | awk -v OFS="   " '{print $2,"/hxlogs","xfs","defaults,nofail","0","2"}' >> /etc/fstab
blkid "$METADATA_DEVICE" | awk -v OFS="   " '{print $2,"/hxmetadata","xfs","defaults,nofail","0","2"}' >> /etc/fstab

# If this commit server will be restored from backup we need to mount and not format the disk
# Unfortunely CloudFormation does not support the use of Conditionals inside Fn::Sub so I am having to check the Parameter instead
if [[ "$DEPOT_CONTENT_SNAPSHOT" == '' ]] ;
then
    echo "Creating Depot volume from scratch"
    mkfs -t xfs "$DEPOT_DEVICE"
    blkid "$DEPOT_DEVICE" | awk -v OFS="   " '{print $2,"/hxdepots","xfs","defaults,nofail","0","2"}' >> /etc/fstab

    # since we are not restoring from snapshot move over the p4d data from the AMI
    mount -a
    mv /_hxdata/hxlogs/* /hxlogs/
    mv /_hxdata/hxmetadata/* /hxmetadata/
    mv /_hxdata/hxdepots/* /hxdepots/

elif [[ "$DEPOT_CONTENT_SNAPSHOT" == snap* ]] ;
then

    echo "Creating Depot volume from snapshot"
    export RESTORED_FROM_SNAPSHOT=true
    blkid "$DEPOT_DEVICE" | awk -v OFS="   " '{print $2,"/hxdepots","xfs","defaults,nofail","0","2"}' >> /etc/fstab
    mount -a

    mv /_hxdata/hxlogs/* /hxlogs/
    mv /_hxdata/hxmetadata/* /hxmetadata/

else
    echo "Unsupported case...exiting."
    exit 1
fi

rm -rf /_hxdata

chown -R perforce:perforce /hx*

if [[ "$RESTORED_FROM_SNAPSHOT" == 'true' ]] ;
then
    echo "Instance was restored from snapshot, replay checkpoint"
    # shellcheck disable=SC2010
    CHECKPOINT_FILE="/p4/1/checkpoints/$(ls -r /p4/1/checkpoints/ | grep ckp | grep -v md5 | head -1)" 

    systemctl stop p4d_1
    sudo -i -u perforce /p4/common/bin/p4d -r /p4/1/root -z -jrF "$CHECKPOINT_FILE"
else
    echo "Fresh install, no need to replay checkpoint"
fi

start_p4d

# THIS SLEEP WAS INCREASED FROM 10 TO 40 SECONDS
echo "Sleeping for P4D start"
sleep 40

# do a login so that the rest of the scripts can run p4 commands
sudo -i -u perforce p4login -v 1

# this is for creating a swarm token, this will happen even if swarm does not get enabled
mkdir -p /tmp/depots/esp-config
chown -R perforce:perforce /tmp/depots
cd /tmp/depots/esp-config/

cat <<EOF > /tmp/esp-config.cfg
Depot:  esp-config
Owner:  perforce
Date:   2021/05/07 20:14:18
Description:
    Created by perforce.
Type:   local
Address:        local
Suffix: .p4s
StreamDepth:    //esp-config/1
Map:    esp-config/...
EOF

cat /tmp/esp-config.cfg | sudo -i -u perforce p4 depot -i

cat <<EOF > /tmp/helix-core-client.cfg
Client: helix-core
Owner:  perforce
Description:
        Created by perforce.
Root:   /tmp/depots/esp-config
Options:        noallwrite noclobber nocompress unlocked nomodtime normdir
SubmitOptions:  submitunchanged
LineEnd:        local
View:
        //esp-config/... //helix-core/...
EOF
cat /tmp/helix-core-client.cfg | sudo -i -u perforce p4 client -i

# If this is a restore the swarm.token file may already exist
sudo P4CLIENT="helix-core" -i -u perforce p4 sync -f

# swarm.token allows trigger on p4d to authenticate to swarm
export SWARM_TOKEN_FILE="/tmp/depots/esp-config/swarm.token"
# swarm.password is the password for the swarm user in p4d
export SWARM_USER_PASSWORD_FILE="/tmp/depots/esp-config/swarm.password"
if [[ -f "$SWARM_TOKEN_FILE" ]]; then
    echo "Swarm token file does exist"
    SWARM_TOKEN=$(cat $SWARM_TOKEN_FILE)
    export SWARM_TOKEN
else
    echo "Swarm token file does not exist, creating one now..."
	SWARM_TOKEN=$(uuid)
    export SWARM_TOKEN
	echo "$SWARM_TOKEN" > $SWARM_TOKEN_FILE

    # Pre create a password for the swarm user
    # We do this so that if we ever restore from a backup the new swarm instance can come up and find the original password
    uuid > $SWARM_USER_PASSWORD_FILE

	sudo P4CLIENT="helix-core" -i -u perforce p4 add /tmp/depots/esp-config/*
	chown -R perforce:perforce /tmp/depots/
	sudo P4CLIENT="helix-core" -i -u perforce p4 submit -d "Adding swarm token and password"
fi

if [[ -v SNS_ALERT_TOPIC_ARN && -v AWS_REGION ]]; then
# SNS_ALERT_TOPIC_ARN will always be set but if user did not provide a subscriber email address then SNS_ALERT_TOPIC will be an empty string
    cat <<-EOF >> /p4/common/site/config/p4_1.vars.local

# This file is for custom settings that are specific to a specific instance of the SDP

# SNS Alert Configurations
# Two methods of authentication are supported: key pair (on prem, azure, etc) and IAM role (AWS deployment)
# In the case of IAM role the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must not be set, not even empty strings

# To test SNS delivery use the following command: aws sns publish --topic-arn $SNS_ALERT_TOPIC_ARN --subject test --message "this is a test"

# export AWS_ACCESS_KEY_ID=""
# export AWS_SECRET_ACCESS_KEY=""

export AWS_DEFAULT_REGION="$AWS_REGION"
export SNS_ALERT_TOPIC_ARN="$SNS_ALERT_TOPIC_ARN"

EOF
else
    echo "Either SNS_ALERT_TOPIC_ARN or AWS_REGION are not set, skipping creation of p4_1.vars.local with notification environment variables."
fi

touch /p4/common/site/config/p4_1.vars.local
chown perforce:perforce /p4/common/site/config/p4_1.vars.local

sudo -i -u perforce p4 counter CLOUD_ESP TRUE
sudo -i -u perforce p4 counter CLOUD_ESP_DEPLOYMENT_DATE "$(date)"

# this script must be run once after restoring from checkpoint so that daily_checkpoint can run
sudo -i -u perforce /p4/common/bin/live_checkpoint.sh 1


run-parts /home/perforce/.userdata/custom-post/

if [[ "${license_filename}" != '' ]] ;
then
    echo "Pulling down license file from S3..."

    aws s3 cp s3://${s3_checkpoint_bucket}/${license_filename} /p4/1/root/license
    service p4d_1 restart
    sleep 10  
    echo "Finished applying the license"
fi
