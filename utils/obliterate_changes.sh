#!/bin/bash
# Obliterates all changes by user bruno - make sure you have submitted changes
# you want to keep under different user id, e.g. perforce!!

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

instance=${1:-Unset}
[[ $instance == "Unset" ]] && bail "Specify instance as parameter"

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')
export P4BENCH_SETUP_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_setup_user')
p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')

function obliterate_changes() {
    P4PORT=${1}
    last_change=$(p4 -p "$P4PORT" -u "${P4BENCH_CLIENT_USER}" changes | grep "@${P4BENCH_CLIENT_USER}" | tail -1 | cut -d' ' -f 2)
    start=$((last_change))
    cmd="p4 -p "$P4PORT" -u "$P4BENCH_SETUP_USER" obliterate -y -h //...@$start,now"
    echo $cmd
    $cmd | tail -5
    p4 -p $P4PORT -u "$P4BENCH_SETUP_USER" admin journal 
}

obliterate_changes $p4port
