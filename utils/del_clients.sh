#!/bin/bash

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

instance=${1:-Unset}
[[ $instance == "Unset" ]] && bail "Specify instance as parameter"

function del_clients() {
    P4PORT=${1}
    p4 -p $P4PORT -u bruno clients -e bruno* | cut -d" " -f2 | while read f; do p4 -p $P4PORT -u bruno client -d -f $f; done
}

p4port=$(ps ax | grep "p4d_${instance}" | grep -v grep | head -1 |perl -ne 'print "$1" if /\-p\s*([0-9.:]+)/')
# Run for edge servers:
# del_clients sn1-r720-a02-13:${instance}666
# del_clients sn1-r720-a02-15:${instance}666
# del_clients sn1-r720-a02-17:${instance}666
# del_clients sn1-r720-a02-19:${instance}666
del_clients $p4port
