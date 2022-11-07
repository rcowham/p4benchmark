#!/bin/bash

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

instance=${1:-Unset}
[[ $instance == "Unset" ]] && bail "Specify instance as parameter"

export P4BENCH_CLIENT_USER=$(grep "p4bench_client_user" hosts | awk '{print $2}')

function del_clients() {
    P4PORT=${1}
    p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" clients -e "${P4BENCH_CLIENT_USER}*" | cut -d" " -f2 | while read f; do p4 -p $P4PORT -u "${P4BENCH_CLIENT_USER}" client -d -f $f; done
}

# Handl SSL prefix if required
p4port=$(ps ax | grep "p4d_${instance}" | grep -v grep | grep " \-r " | head -1 |perl -ne 'print "$1" if /\-p\s*((ssl:)*[0-9.:]+)/')

# Run for edge servers:
# del_clients sn1-r720-a02-13:${instance}666
# del_clients sn1-r720-a02-15:${instance}666
# del_clients sn1-r720-a02-17:${instance}666
# del_clients sn1-r720-a02-19:${instance}666

del_clients $p4port
