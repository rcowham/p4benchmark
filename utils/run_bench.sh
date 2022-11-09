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

P4BENCH_SCRIPT=${2:-Unset}
[[ $P4BENCH_SCRIPT == "Unset" ]] && bail "Specify P4BENCH_SCRIPT as second parameter"
[[ ! -f locust_files/p4_$P4BENCH_SCRIPT.py ]] && bail "Benchmark script $P4BENCH_SCRIPT not found: locust_files/p4_$P4BENCH_SCRIPT.py"

export P4BENCH_HOST=`hostname`
export P4BENCH_SCRIPT
# Calculate env vars to be picked up by run_master.sh
export P4BENCH_NUM_WORKERS_PER_HOST=$(grep "num_workers" hosts | awk '{print $2}')
export P4BENCH_CLIENT_USER=$(grep "p4bench_client_user" hosts | awk '{print $2}')

hosts=$(grep -A 99999 bench_clients: hosts | grep -E "^\s+\S+:$" | wc -l)
export P4BENCH_NUM_HOSTS=$(($hosts - 2))

echo "Running p4_${P4BENCH_SCRIPT} on instance ${instance}"

echo "Removing $P4BENCH_CLIENT_USER clients"
$P4BENCH_UTILS/del_clients.sh $instance

# Remove existing logs to make sure they don't clutter up the measurements
[[ -f /p4/$instance/logs/log ]] && sudo rm /p4/$instance/logs/log
# Remove shared logs on other (replica) servers if appropriate
# E.g. via ssh or directly from shared storage
#sudo rm /remote/p4/rep/h02_$instance/logs/log

config_file="config_p4_${P4BENCH_SCRIPT}.yml"
sed -e "s/:1666/:${instance}666/" < locust_files/$config_file > $config_file

rm logs/*worker*.out
echo "Removing remote logs..."
ansible-playbook -i hosts ansible/rm_client_logs.yml > /dev/null
ansible-playbook -i hosts ansible/rm_server_logs.yml > /dev/null
ansible-playbook -i hosts ansible/post_previous_client_bench.yml
ansible-playbook -i hosts ansible/pre_client_bench.yml

# Flush filesystem caches on server
sudo sync
sudo bash -c 'echo 3 > /proc/sys/vm/drop_caches'

# Run the locust master - waiting for clients to connect
$P4BENCH_UTILS/run_locust_master.sh
ansible-playbook -i hosts ansible/client_bench.yml

# echo "Running monitor jobs in background"
# $P4BENCH_UTILS/run_monitor.sh &
echo ""
