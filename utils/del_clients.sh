#!/bin/bash

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

[[ -z $p4port ]] && bail "Can't get data out of hosts: $ANSIBLE_HOSTS"

export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')

# All commit and edge servers to poll
declare -a p4hosts
mapfile -t p4hosts < <(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[]')

function del_clients() {
    P4PORT=${1}
    p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" clients -e "${P4BENCH_CLIENT_USER}*" | cut -d" " -f2 | while read f
    do
        p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" client -d -f $f
    done
}

for h in "${p4hosts[@]}"
do
    del_clients $p4port
done
