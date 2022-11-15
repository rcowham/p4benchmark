#!/bin/bash
# Main script for running a benchmark.
# Usage:
#   ./run_bench.sh 1 basic
#   ./run_bench.sh 1 syncbench
# Specify the p4d instance (SDP installed port) and the name of the benchmark script:
#   basic/syncbench - corresponds to 2 files - locust_files/p4_basic.py or p4_syncbench.py and
# their config_p4_basic.py etc.

function bail () { echo -e "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Setup root dir for all scripts etc
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
export P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
export P4BENCH_UTILS="$P4BENCH_HOME/utils"

cd $P4BENCH_HOME

instance=${1:-Unset}
[[ $instance == "Unset" ]] && bail "Specify instance as parameter"

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

P4BENCH_SCRIPT=${2:-Unset}
[[ $P4BENCH_SCRIPT == "Unset" ]] && bail "Specify P4BENCH_SCRIPT as second parameter"
[[ ! -f locust_files/p4_$P4BENCH_SCRIPT.py ]] && bail "Benchmark script $P4BENCH_SCRIPT not found: locust_files/p4_$P4BENCH_SCRIPT.py"

export DEFAULT_ROUTE_INTERFACE=$(ip route  | grep default | awk '{print $5}')
export P4BENCH_HOST=$(ifconfig $DEFAULT_ROUTE_INTERFACE | grep "inet " | awk '{print $2}')
export P4BENCH_SCRIPT
# Calculate env vars to be picked up by run_master.sh

export P4BENCH_NUM_WORKERS_PER_HOST=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.num_workers')
export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')
export P4BENCH_NUM_HOSTS=$(cat $ANSIBLE_HOSTS | yq '.all.children.bench_clients.hosts | length')

echo "Running p4_${P4BENCH_SCRIPT} on instance ${instance}"

echo "Removing $P4BENCH_CLIENT_USER clients"
$P4BENCH_UTILS/del_clients.sh $instance

rm -f logs/*worker*.out logs/*log
echo "Removing remote logs..."
ansible-playbook -i $ANSIBLE_HOSTS ansible/rm_client_logs.yml > /dev/null
ansible-playbook -i $ANSIBLE_HOSTS ansible/rm_server_logs.yml > /dev/null
ansible-playbook -i $ANSIBLE_HOSTS ansible/post_previous_client_bench.yml
ansible-playbook -i $ANSIBLE_HOSTS ansible/pre_client_bench.yml

# Flush filesystem caches on server
ansible-playbook -i $ANSIBLE_HOSTS ansible/flush_server_cache.yml

# Run the locust master - waiting for clients to connect and then spawn client worker jobs
$P4BENCH_UTILS/run_locust_master.sh
ansible-playbook -i $ANSIBLE_HOSTS ansible/client_bench.yml

# echo "Running monitor jobs in background"
# $P4BENCH_UTILS/run_monitor.sh &
echo ""
