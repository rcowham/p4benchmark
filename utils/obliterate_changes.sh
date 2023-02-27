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

# All commit and edge servers to poll
declare -a p4hosts
mapfile -t p4hosts < <(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[]')

function obliterate_changes() {
    P4PORT=${1}
    last_change=$(p4 -p "$P4PORT" -u "${P4BENCH_CLIENT_USER}" changes | grep "@${P4BENCH_CLIENT_USER}" | tail -1 | cut -d' ' -f 2)
    [[ -z $last_change ]] && return
    start=$((last_change))
    cmd="p4 -p "$P4PORT" -u "$P4BENCH_SETUP_USER" obliterate -y -h //...@$start,now"
    echo $cmd
    $cmd | tail -5
    p4 -p $P4PORT -u "$P4BENCH_SETUP_USER" admin journal
}

function delete_changes() {
    P4PORT=${1}
    count=0
    p4="p4 -p $P4PORT -u $P4BENCH_SETUP_USER"
    chgcount=$($p4  changes -u "${P4BENCH_CLIENT_USER}" | wc -l)
    echo "Deleting $chgcount changes"
    $p4 changes -u "${P4BENCH_CLIENT_USER}" | cut -d' ' -f 2 | while read c
    do
        $p4 change -df $c > /dev/null 2>&1
        count=$((count+1))
    done
    echo "Deleted $count changes"
    opened=$($p4 opened -a | wc -l)
    if [[ $opened -gt 0 ]]; then
         $p4 -F "%change% %client%" opened -a | sort | uniq | while read a c w
         do
             if [[ $a == "default" ]]; then
                c="$a"
             fi
             $p4 revert -c $c -C $w //... | tail -1
         done
    fi
    $p4 admin journal
}

obliterate_changes $p4port
for h in "${p4hosts[@]}"
do
    delete_changes $h
done
