#!/bin/bash

set -eu -o pipefail

# sleep for a little bit to let cloud-init get started
logger -i -t cloud-init-signal "Sleeping before starting loop to check cloud-init status"
sleep 30

# wait a max of 60 minutes. 60 mins * 60 seconds / 5 second sleep

logger -i -t cloud-init-signal "starting loop to wait for cloud-init to finish"

iterations=0
max_iterations=720
STATUS="status: running"
while [[ $STATUS == "status: running" ]]
do
    logger -i -t cloud-init-signal "$(date) - cloud-init is still running...sleep."
    sleep 5
    ((iterations=iterations+1))
    STATUS=$(sudo cloud-init status)
    if [ "$iterations" -ge "$max_iterations" ]; then
        logger -i -t cloud-init-signal  "Timed out waiting for cloud-init to finish."
        exit 1
    fi
done

logger -i -t cloud-init-signal "cloud-init finished"

exit 0
