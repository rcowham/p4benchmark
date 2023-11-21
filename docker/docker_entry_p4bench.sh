#!/bin/bash
# Docker entry point - intended to be run on the p4 benchmark driver machine only
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

echo "Waiting for master server ssh"
until nc -zw 1 master 22; do sleep 1; done && sleep 1

echo "Starting up master server p4d"
ssh master /p4/benchmark/docker_entry_master.sh

# Wait for p4d to be running
echo "Waiting for master server to be running"
until nc -zw 1 master 1666; do sleep 1; done && sleep 1

echo "Master server now running"

export P4BENCH_HOME=/p4/benchmark
cd $P4BENCH_HOME

# Use the default hosts file for docker
export ANSIBLE_HOSTS=hosts.docker.yaml

# Turn off host checking for ansible
cat <<"EOF" > ansible.cfg
[defaults]
host_key_checking = False
EOF

# Now run the benchmark - waiting for it to terminate and then analysing

mkdir run logs
echo "Starting benchmark (including initialisation)"
./utils/run_bench.sh basic 
echo "Waiting for benchmark to complete"
sleep 10
./utils/wait_end_bench.sh
echo "Waiting to analyse results"
sleep 10
export PATH=/home/perforce/bin:$PATH
./utils/analyse.sh

echo "Waiting for 10 minutes (in case you want to have a look at the machine config etc)"
echo "If so, run:"
echo "    docker exec -ti p4benchmark_master_1 /bin/bash"
echo "Otherwise Ctrl+C to finish"
sleep 6000
