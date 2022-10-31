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
export AWS_REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)

export P4D_AUTH_ID="commit"

export DEPOT_DEVICE="/dev/sdf"
export LOG_DEVICE="/dev/sdg"
export METADATA_DEVICE="/dev/sdh"


# if [[ "${s3_checkpoint_bucket}" != '' ]] ;
# then
#     echo "Extracting depot data archive and restoring from checkpoint"

#     export RESTORED_FROM_SNAPSHOT=true
#     aws s3 cp s3://${s3_checkpoint_bucket}/${checkpoint_filename} /p4/1/checkpoints/

#     aws s3 cp s3://${s3_checkpoint_bucket}/${archive_filename} /hxdepots/

#     # tar zxvf -C /p4/1/depots/ fileNameHere.tgz

# fi




run-parts /home/perforce/.userdata/custom-pre/

run-parts /home/perforce/.userdata/default/

run-parts /home/perforce/.userdata/custom-post/
