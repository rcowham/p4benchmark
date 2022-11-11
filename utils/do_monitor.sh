#!/bin/bash
# Monitor the commit (and any edges)

function bail () { echo -e "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

export P4BENCH_SETUP_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_setup_user')

declare -a p4hosts
mapfile -t p4hosts < <(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port | values[]')

for h in "${p4hosts[@]}"
do
    cnt=$(p4 -p $h -u "$P4BENCH_SETUP_USER" monitor show | wc -l)
    echo $h $cnt
done
