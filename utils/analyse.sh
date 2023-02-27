#!/bin/bash
# Default usage:
#   ./analyse.sh

function bail () { echo "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Get common root dir
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
P4BENCH_UTILS="$P4BENCH_HOME/utils"

mkdir -p $P4BENCH_HOME/run
last_run=$(ls $P4BENCH_HOME/run/ | sort -n | tail -1)
runid=$((last_run+1))  
rundir=$P4BENCH_HOME/run/$runid

[[ -z $ANSIBLE_HOSTS ]] && bail "Environment variable ANSIBLE_HOSTS not set"
[[ -e $ANSIBLE_HOSTS ]] || bail "ANSIBLE_HOSTS file not found: $ANSIBLE_HOSTS"

echo "Creating $rundir"

# copy logs - server logs for analysis and clients just in case
avoid_ssh_executions=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.avoid_ssh_connection')
echo "Avoid ssh executions: ${avoid_ssh_executions}"

echo "Copying logs..."
[[ $avoid_ssh_executions != "true" ]] && ansible-playbook -i $ANSIBLE_HOSTS ansible/copy_server_logs.yml > /dev/null
ansible-playbook -i $ANSIBLE_HOSTS ansible/copy_client_logs.yml > /dev/null
[[ $avoid_ssh_executions != "true" ]] && ansible-playbook -i $ANSIBLE_HOSTS ansible/rm_server_logs.yml > /dev/null

mkdir $rundir
pushd $rundir
cp "$P4BENCH_HOME/$ANSIBLE_HOSTS" .

p4port=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')
p4user=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.user')
p4="p4 -p $p4port -u $p4user "

instance=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.sdp_instance')

[[ $instance -gt 0 && $instance -lt 10 ]] || bail "can't find instance"

# All commit and edge servers to poll
declare -a p4hosts
mapfile -t p4hosts < <(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[]')

[[ -e $P4BENCH_HOME/change_counter.txt ]] && mv $P4BENCH_HOME/change_counter.txt .
cp $P4BENCH_HOME/logs/*worker* .
gzip *worker*.out &

# Master/edge logs
cp $P4BENCH_HOME/logs/*-log .

# Record sizes of clients
for h in "${p4hosts[@]}"
do
  ep4="p4 -p $h -u $p4user"
  $ep4 clients -e bruno* |cut -d " " -f 2| while read c
  do
    $ep4 -c $c sizes -sh //$c/... >> client_sizes.txt
  done
done

echo $p4 configure show > config.out
$p4 configure show > config.out
grep numActions $P4BENCH_HOME/locust_files/p4benchutils.py >> config.out

# record number of submitted changes
start_chg=$(cat change_counter.txt)
end_chg=$($p4 changes -ssubmitted -m1 | cut -d" " -f2)
chgs=$($p4 changes "@>$start_chg" | wc -l)
echo "Submitted change start $start_chg end $end_chg" > changes.out
echo "Count: $chgs" >> changes.out

# Analyse logs into sql db - uses log2sql from https://github.com/rcowham/go-libp4dlog/releases
~/bin/log2sql -d run *-log

$P4BENCH_UTILS/sqlreport.sh $rundir
