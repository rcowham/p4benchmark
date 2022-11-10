#!/bin/bash

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')

[[ -z $p4port ]] && bail "Can't get data out of hosts: $ANSIBLE_HOSTS"

export P4BENCH_CLIENT_USER=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')

function del_clients() {
    P4PORT=${1}
    p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" clients -e "${P4BENCH_CLIENT_USER}*" | cut -d" " -f2 | while read f; do p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" client -d -f $f; done
}

p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')

# Run for edge servers:
# del_clients sn1-r720-a02-13:${instance}666
# del_clients sn1-r720-a02-15:${instance}666
# del_clients sn1-r720-a02-17:${instance}666
# del_clients sn1-r720-a02-19:${instance}666

del_clients $p4port
