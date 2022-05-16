#!/usr/bin/bash

# Setup root dir for all scripts etc
script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
P4BENCH_UTILS="$P4BENCH_HOME/utils"

cd $P4BENCH_HOME

tpid=$(pgrep run_top)
[[ $tpid -eq 0 ]] || kill $tpid

NETWORK_LOG=network.out
[[ -e ps.out ]] && sudo rm ps.out
[[ -e $NETWORK_LOG ]] && sudo rm $NETWORK_LOG

num_workers=$(grep "num_workers" hosts | awk '{print $2}')

nohup $P4BENCH_UTILS/run_top.sh > ps.out 2>&1 & 

# Define NIC(s) to record traffic for (space seperated list of values)
# nics="bond0 enp66s0 enp66s0d1"
nics="eth0"
echo "Start of benchmark" >> $NETWORK_LOG
date +"%Y-%m-%dT%H-%M-%SZ" >> $NETWORK_LOG
for nic in $nics
do
    ifconfig $nic >> $NETWORK_LOG
done

# Record average CPU load on 10 second basis
loadavg() {
    date +"%Y-%m-%dT%H-%M-%S" >> loadavg.out
    cat /proc/loadavg >> loadavg.out
}

loadavg
sleep 10

config_file=$(ls -tr config_p4_* | tail -1)
p4port=`grep 666 $config_file | head -1 | sed -e 's/\s*port:\s*//' | sed -e 's/ \- //'`
p4user=`grep user $config_file | sed -e 's/\s*user:\s*//'`
p4="p4 -p $p4port -u $p4user "

# Save current change counter - for use with multiple runs
$p4 changes -s submitted -m 1 | cut -d" " -f 2 > change_counter.out

while true
do
    loadavg
    count=$($p4 monitor show | grep -v monitor | grep -v rmt-Journal | wc -l)
    [[ $count -eq 0 ]] && echo -e "\n\nBenchmark has finished!!\n\n" && break
    sleep 10
done

echo "End of benchmark" >> $NETWORK_LOG
date +"%Y-%m-%dT%H-%M-%SZ" >> $NETWORK_LOG
for nic in $nics
do
    ifconfig $nic >> $NETWORK_LOG
done

kill $(pgrep run_top)
