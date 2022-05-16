#!/bin/bash
# Waits for the end of the benchmark
# Work out which instance we are talking to and then polls master server and any
# replicas for running jobs (excluding various replication specific ones)

script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
cd $P4BENCH_HOME

config_file=$(ls -tr config_p4_* | tail -1)
p4port=`grep 666 $config_file | head -1 | sed -e 's/\s*port:\s*//' | sed -e 's/ \- //'`
p4user=`grep user $config_file | sed -e 's/\s*user:\s*//'`
p4="p4 -p $p4port -u $p4user "

# List of commit and edge servers to poll for - space seperated list
# hosts="master edge1 edge2"
hosts="master"

while true
do
    count=0
    for h in $hosts
    do
        cnt=$(p4 -p $h:1666 -u perforce monitor show | grep -v monitor | grep -v rmt-Journal | grep -v pull | wc -l)
        echo $h $cnt
        count=$(($count + $cnt))
    done
    [[ $count -eq 0 ]] && echo -e "\n\nBenchmark has finished!!\n\n" && break
    sleep 10
done
