#!/bin/bash

script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
cd $P4BENCH_HOME

num_workers=$(grep "num_workers" hosts | awk '{print $2}')
num_hosts=$(grep -A 99999 bench_clients: hosts | grep -E "^\s+\S+:$" | wc -l)
# Format of file:
# bench_clients:
#   hosts:
#     client1:
#     client2:

num_lines=$((($num_hosts - 2) * $num_workers + 10))
tmpfile=$(mktemp)

while true
do
    echo "%CPU %MEM ARGS $(date +%Y/%M/%d_%H:%m:%S)"
    ps -e -o pcpu,pmem,args --sort=pcpu | cut -d" " -f1-5 | grep -v " 0.0  0.0 " > $tmpfile
    cat $tmpfile
    cat $tmpfile | grep p4d_ | awk '{s += $1} END {print s}'
    sleep 5
done
