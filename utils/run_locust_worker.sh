#!/bin/bash
# Run locust workers on relevant client machines

function bail () { echo -e "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

export P4BENCH_NUM_WORKERS=${P4BENCH_NUM_WORKERS:-Undefined}
export P4BENCH_NUM_WORKERS=${1:-$P4BENCH_NUM_WORKERS}
[[ $P4BENCH_NUM_WORKERS == Undefined ]] && \
   bail "Num_workers parameter not supplied."

export P4BENCH_SCRIPT=${P4BENCH_SCRIPT:-Undefined}
export P4BENCH_SCRIPT=${2:-$P4BENCH_SCRIPT}
[[ $P4BENCH_SCRIPT == Undefined ]] && \
   bail "Benchmark script parameter not supplied."

export P4BENCH_HOST=${P4BENCH_HOST:-Undefined}
[[ $P4BENCH_HOST == Undefined ]] && \
   bail "Benchmark host not defined."

for i in $(seq 1 $P4BENCH_NUM_WORKERS); do
    nohup locust -f p4_${P4BENCH_SCRIPT}.py --worker --master-host=${P4BENCH_HOST} > worker$i.out 2>&1 &
done

