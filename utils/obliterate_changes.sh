#!/bin/bash
# Obliterates all changes by user bruno - make sure you have submitted changes
# you want to keep under different user id, e.g. perforce!!

function bail () { echo "Error: ${1:-Unknown Error}\n"; exit ${2:-1}; }

instance=${1:-Unset}
[[ $instance == "Unset" ]] && bail "Specify instance as parameter"

P4USER=perforce

function obliterate_changes() {
    P4PORT=${1}
    last_change=$(p4 -p $P4PORT -u bruno changes | grep "@bruno" | tail -1 | cut -d' ' -f 2) 
    start=$((last_change))
    cmd="p4 -p $P4PORT -u $P4USER obliterate -y -h //...@$start,now"
    echo $cmd
    $cmd | tail -5
    p4 -p $P4PORT -u $P4USER admin journal 
}

p4port=$(ps ax | grep "p4d_${instance}" | grep -v grep | head -1 | perl -ne 'print "$1" if /\-p\s*([0-9.:]+)/')

obliterate_changes $p4port

