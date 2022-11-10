#!/bin/bash
# Waits for the end of the benchmark
# Work out which instance we are talking to and then polls master server and any
# replicas for running jobs (excluding various replication specific ones)

function bail () { echo -e "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
cd $P4BENCH_HOME

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')
export P4BENCH_SETUP_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_setup_user')
p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4ports[0]')
p4user=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4user')
p4="p4 -p $p4port -u $p4user "

# All commit and edge servers to poll
declare -a p4hosts

mapfile -t p4hosts < <(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port | values[]')

while true
do
    count=0
    for h in "${p4hosts[@]}"
    do
        cnt=$(p4 -p "$h" -u "$P4BENCH_SETUP_USER" monitor show | grep -v monitor | grep -v rmt-Journal | grep -v pull | wc -l)
        echo "$h $cnt"
        count=$(($count + $cnt))
    done
    [[ $count -eq 0 ]] && echo -e "\\n\\nBenchmark has finished!!\\n\\n" && break
    sleep 10
done
