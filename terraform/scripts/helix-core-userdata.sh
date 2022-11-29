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

export DEPOT_DEVICE="/dev/sdf"
export LOG_DEVICE="/dev/sdg"
export METADATA_DEVICE="/dev/sdh"


run-parts /home/perforce/.userdata/custom-pre/

run-parts /home/perforce/.userdata/default/

run-parts /home/perforce/.userdata/custom-post/

if [[ "${license_filename}" != '' ]] ;
then
    echo "Pulling down license file from S3..."

    aws s3 cp s3://${s3_checkpoint_bucket}/${license_filename} /p4/1/root/license
    service p4d_1 restart
    sleep 10  
    echo "Finished applying the license"
fi
