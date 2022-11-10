#!/bin/bash
# Run the locust master on current host, waiting for specified number of 
# workers to connect.

function bail () { echo -e "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Setup root dir for all scripts etc
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}

cd $P4BENCH_HOME

export P4BENCH_NUM_HOSTS=${P4BENCH_NUM_HOSTS:-Undefined}
export P4BENCH_NUM_HOSTS=${1:-$P4BENCH_NUM_HOSTS}
[[ $P4BENCH_NUM_HOSTS == Undefined ]] && \
   bail "Num_hosts parameter not supplied."

export P4BENCH_NUM_WORKERS_PER_HOST=${P4BENCH_NUM_WORKERS_PER_HOST:-Undefined}
export P4BENCH_NUM_WORKERS_PER_HOST=${2:-$P4BENCH_NUM_WORKERS_PER_HOST}
[[ $P4BENCH_NUM_WORKERS_PER_HOST == Undefined ]] && \
   bail "Num_workers parameter not supplied."

export P4BENCH_SCRIPT=${P4BENCH_SCRIPT:-Undefined}
export P4BENCH_SCRIPT=${3:-$P4BENCH_SCRIPT}
[[ $P4BENCH_SCRIPT == Undefined ]] && \
   bail "Benchmark script parameter not supplied."

total_workers=$(($P4BENCH_NUM_HOSTS * $P4BENCH_NUM_WORKERS_PER_HOST))

# This will commit suicide!
pkill -9 "^locust$"

nohup locust -f locust_files/p4_${P4BENCH_SCRIPT}.py --master --headless --expect-workers=$total_workers --users $total_workers -r $total_workers > master.out 2>&1 &
