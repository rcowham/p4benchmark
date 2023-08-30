#!/bin/bash
# Main script for running a benchmark.
# Usage:
#   Ensure the env variable ANSIBLE_HOSTS is set to name of appropriate YAML file
#   ./run_bench.sh basic
#   ./run_bench.sh syncbench
# Specify the name of the benchmark script:
#   basic/syncbench - corresponds to 2 files - locust_files/p4_basic.py or p4_syncbench.py

function bail () { echo -e "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Setup root dir for all scripts etc
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
export P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
export P4BENCH_UTILS="$P4BENCH_HOME/utils"

cd $P4BENCH_HOME

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

# Check for dependencies
command -v yq >/dev/null 2>&1 || bail "Please install yq command (via yum/apt)"
command -v ip >/dev/null 2>&1 || bail "Please install ip command (via yum/apt)"

P4BENCH_SCRIPT=${1:-Unset}
[[ $P4BENCH_SCRIPT == "Unset" ]] && bail "Specify P4BENCH_SCRIPT as parameter"
[[ ! -f locust_files/p4_$P4BENCH_SCRIPT.py ]] && bail "Benchmark script $P4BENCH_SCRIPT not found: locust_files/p4_$P4BENCH_SCRIPT.py"

avoid_ssh_executions=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.avoid_ssh_connection')
echo "Avoid ssh executions: ${avoid_ssh_executions}"

# Used in post_previous_client_bench.yml - in some circumstances we want to remove them differently
# e.g. with shared filesystems
remove_workspaces_per_client=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.remove_workspaces_per_client')
if [[ -z $remove_workspaces_per_client || $remove_workspaces_per_client = "null" ]]; then
    export REMOVE_WORKSPACES_PER_CLIENT=true
else
    export REMOVE_WORKSPACES_PER_CLIENT=$remove_workspaces_per_client
fi

export DEFAULT_ROUTE_INTERFACE=$(ip route | grep default | awk '{print $5}')
export P4BENCH_HOST=$(ifconfig $DEFAULT_ROUTE_INTERFACE | grep "inet " | awk '{print $2}')
export P4BENCH_SCRIPT

instance=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.sdp_instance')
p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')
p4user=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.user')
p4="p4 -p $p4port -u $p4user "

# Calculate env vars to be picked up by run_master.sh
export P4BENCH_NUM_WORKERS_PER_HOST=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.num_workers')
export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')
export P4BENCH_NUM_HOSTS=$(cat $ANSIBLE_HOSTS | yq '.all.children.bench_clients.hosts | length')

echo "Running p4_${P4BENCH_SCRIPT} with ANSIBLE_HOSTS ${ANSIBLE_HOSTS} on instance ${instance}"

echo "Removing $P4BENCH_CLIENT_USER clients"
$P4BENCH_UTILS/del_clients.sh

rm -f logs/*worker*.out logs/*log
echo "Removing remote logs..."
ansible-playbook -i $ANSIBLE_HOSTS ansible/rm_client_logs.yml > /dev/null
[[ $avoid_ssh_executions != "true" ]] && ansible-playbook -i $ANSIBLE_HOSTS ansible/rm_server_logs.yml > /dev/null
echo "Setting up client machines..."
ansible-playbook -i $ANSIBLE_HOSTS ansible/post_previous_client_bench.yml
ansible-playbook -i $ANSIBLE_HOSTS ansible/pre_client_bench.yml

# Flush filesystem caches on server
[[ $avoid_ssh_executions != "true" ]] && ansible-playbook -i $ANSIBLE_HOSTS ansible/flush_server_cache.yml

# Save starting change counter - picked up by analyse.sh
$p4 counter change > change_counter.txt

# Run the locust master - waiting for clients to connect and then spawn client worker jobs
$P4BENCH_UTILS/run_locust_master.sh
ansible-playbook -i $ANSIBLE_HOSTS ansible/client_bench.yml

echo ""
echo "Run utils/wait_end_bench.sh to wait for client worker jobs to finish"
echo "Then run utils/analyse.sh to analyse the results"
echo ""
