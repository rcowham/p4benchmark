#!/bin/bash

function bail () { echo "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

# Analyse using next available directory
#runid=${1:-Unset}
#[[ $runid == "Unset" ]] && bail "Specify runid as parameter"

# Get common root dir
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
P4BENCH_UTILS="$P4BENCH_HOME/utils"

mkdir -p $P4BENCH_HOME/run
last_run=$(ls $P4BENCH_HOME/run/ | sort -n | tail -1)
runid=$((last_run+1))  
rundir=$P4BENCH_HOME/run/$runid

echo "Creating $rundir"

# copy client logs just in case useful
echo "Copying logs..."
ansible-playbook -i hosts ansible/copy_logs.yml > /dev/null

# For edge servers this might be useful
# ansible-playbook -i hosts ansible/copy_monitor_logs.yml
# ansible-playbook -i hosts ansible/stop_monitoring.yml

mkdir $rundir
config_file=$(ls -tr $P4BENCH_HOME/config_p4_* | tail -1)
pushd $rundir
cp $config_file .

p4port=`grep 666 $config_file | head -1 | sed -e 's/\s*port:\s*//' | sed -e 's/ \- //'`
p4user=`grep user $config_file | sed -e 's/\s*user:\s*//'`
p4="p4 -p $p4port -u $p4user "

port=`echo "$p4port" | cut -d: -f2`
instance=${port:0:1}

[[ $instance -gt 0 && $instance -lt 10 ]] || bail "can't find instance"

# Set to a list of edge servers to poll for logs
# edges="sn1-r720-a02-15 sn1-r720-a02-17 sn1-r720-a02-19"
edges=""

cp $P4BENCH_HOME/nethogs.out .
[[ -e $P4BENCH_HOME/ps.out ]] && mv $P4BENCH_HOME/ps.out .
[[ -e $P4BENCH_HOME/change_counter.out ]] && mv $P4BENCH_HOME/change_counter.out .
[[ -e $P4BENCH_HOME/network.out ]] && mv $P4BENCH_HOME/network.out .
[[ -e $P4BENCH_HOME/loadavg.out ]] && mv $P4BENCH_HOME/loadavg.out .
kill $(pgrep run_top)
cp $P4BENCH_HOME/logs/*worker* .
gzip *worker*.out &

# Record sizes of clients
$p4 clients -e bruno* |cut -d " " -f 2| while read c; do $p4 -c $c sizes -sh //$c/... >> client_sizes.txt; done
for h in $edges
do
  ep4="p4 -p $h:${instance}666 -u $p4user"
  $ep4 clients -e bruno* |cut -d " " -f 2| while read c; do $ep4 -c $c sizes -sh //$c/... >> client_sizes-$h.txt; done
done

echo $p4 configure show > config.out
$p4 configure show > config.out
sudo ls -l /p4/$instance/ >> config.out
grep numActions $P4BENCH_HOME/locust_files/p4benchutils.py >> config.out

# record number of submitted changes
start_chg=$(cat change_counter.out)
end_chg=$($p4 changes -ssubmitted -m1 | cut -d" " -f2)
chgs=$($p4 changes "@>$start_chg" | wc -l)
echo "Submitted change start $start_chg end $end_chg" > changes.out
echo "Count: $chgs" >> changes.out

# Get logs from master server instance(s)
sudo mv /p4/$instance/logs/log .
for h in $edges
do
  scp $h:/p4/$instance/logs/log $h-edge.log
  ssh $h mv /p4/$instance/logs/log /p4/$instance/logs/log.old
done

# Analyse logs into sql db
~/bin/log2sql.py -d run log
for h in $edges
do
  [[ -e $h-edge.log ]] && ~/bin/log2sql.py -d run $h-edge.log
done

$P4BENCH_UTILS/sqlreport.sh $rundir
