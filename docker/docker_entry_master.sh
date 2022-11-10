#!/bin/bash
# Docker entry point - intended to be run on the p4 benchmark master machine only
# Installs a p4d installation
# Generates some test data
# Runs the benchmar scripts

function bail () { echo -e "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Ensure this script runs as perforce
OSUSER=perforce
if [[ $(id -u) -eq 0 ]]; then
   exec su - $OSUSER -c "$0 $*"
elif [[ $(id -u -n) != $OSUSER ]]; then
   echo "$0 can only be run by root or $OSUSER"
   exit 1
fi

# Change default port as installed by reset_sdp.sh
sdpinstance=1
cd /p4/common/config
mv "p4_$sdpinstance.vars" "p4_$sdpinstance.vars.old"
cat "p4_$sdpinstance.vars.old" | sed -e 's/1999/1666/' > "p4_$sdpinstance.vars"

# Start the server - some issues with doing sysctl in docker so we do it old way
sudo systemctl start "p4d_$sdpinstance"

echo "Waiting for master server to be running"
until nc -zw 1 localhost 1666; do sleep 1; done && sleep 1

# Set configurables - but without restarting server
source /p4/common/bin/p4_vars "$sdpinstance"
p4 configure set server.depot.root="/p4/$sdpinstance/depots"
p4 configure set journalPrefix="/p4/$sdpinstance/checkpoints/p4_$sdpinstance"
p4 configure set track=1
p4 configure set monitor=2
p4 configure show

# Create some dummy files and submit them

export P4CLIENT=test_ws
ws_root=/p4/test_ws
mkdir $ws_root
cd $ws_root
p4 --field "View=//depot/... //test_ws/..." client -o | p4 client -i
python3 /p4/benchmark/locust_files/createfiles.py -d $ws_root -l 10 10 -m 400 -c > /dev/null
p4 rec > /dev/null
p4 submit -d "Initial files" > /dev/null
p4 changes -t
p4 sizes -sh //depot/...
