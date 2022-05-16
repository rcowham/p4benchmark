#!/bin/bash
# Docker entry point - intended to be run on the master only
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
cd /p4/common/config
mv p4_1.vars p4_1.vars.old
cat p4_1.vars.old | sed -e 's/1999/1666/' > p4_1.vars

# Start the server - some issues with doing sysctl in docker so we do it old way
/p4/1/bin/p4d_1_init start

# Set configurables - but without restarting server
. /p4/common/bin/p4_vars 1
p4 configure set server.depot.root=/p4/1/depots
p4 configure set journalPrefix=/p4/1/checkpoints/p4_1
p4 configure set track=1
p4 configure set monitor=2
p4 configure show

# Create some dummy files and submit them

export P4CLIENT=test_ws
ws_root=/p4/test_ws
mkdir $ws_root
cd $ws_root
p4 --field "View=//depot/... //test_ws/..." client -o | p4 client -i
python3.6 /p4/benchmark/locust_files/createfiles.py -d $ws_root -l 5 5 -c
p4 rec 
p4 submit -d "Initial files"
p4 changes -t

export P4BENCH_HOME=/p4/benchmark
cd $P4BENCH_HOME

# Turn off host checking for ansible
cat <<"EOF" > ansible.cfg
[defaults]
host_key_checking = False
EOF

# Now run the benchmark - waiting for it to terminate and then analysing

mkdir run
echo "Starting benchmark (including initialisation)"
./utils/run_bench.sh 1 basic 
echo "Waiting for benchmark to complete"
sleep 10
./utils/wait_end_bench.sh
echo "Waiting to analyse results"
sleep 10
./utils/analyse.sh

echo "Waiting for 10 minutes (in case you want to have a look at the machine config etc)"
echo "If so, run:"
echo "    docker exec -ti benchmark_pb_master_1 /bin/bash"
echo "Otherwise Ctrl+C to finish"
sleep 600
