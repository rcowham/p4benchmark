#!/bin/bash

function bail () { echo "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

script_dir="${0%/*}"
parent_dir="$(cd "$script_dir/.."; pwd -P)"
P4BENCH_HOME=${P4BENCH_HOME:-$parent_dir}
cd $P4BENCH_HOME

# Runs SQL report for specified run
rundir=${1:-Unset}
[[ $rundir == "Unset" ]] && bail "Specify rundir as parameter"

[[ -d "run/$rundir" ]] && rundir="run/$rundir"

cd $rundir || bail "Rundir $rundir doesn't exist"

config=config.out
instance=$(grep P4PORT $config | perl -ne 'print $1 if /([0-9])666/')

sqlreport=sql.txt

cat > sql.in <<EOF
.output $sqlreport

.mode column

select cmd, count(cmd), 
round(cast(avg(completedLapse) AS DECIMAL(9, 3)), 3) as "Avg Time", 
round(cast(max(completedLapse) AS DECIMAL(9, 3)), 3) as "Max Time",
round(cast(sum(completedLapse) AS DECIMAL(9, 3)), 3) as "Sum Time"
from process
group by cmd;

.print "\n"

.width 9 5 50

/*
.print "Submits per 10 seconds\n"
select substr(endtime, 12, 7) as time, count(cmd) as cmds,
replace(substr(quote(zeroblob(COUNT(cmd) / 2)), 3, COUNT(cmd)), '0', '*') AS bar
from process
where cmd = "dm-CommitSubmit"
group by time;
*/

/*
.width 12 9 5 120

.print "\n"
.print "Submits by IP per second\n"
select IP, substr(endtime, 12, 8) as time, count(cmd) as cmds,
replace(substr(quote(zeroblob(COUNT(cmd) / 2)), 3, COUNT(cmd)), '0', '*') AS bar
from process
where cmd = "dm-CommitSubmit"
group by IP, time;
*/

.print "\n"
.width 0 0 0 0

.print "Syncs\n"
select substr(workspace, 7, 12) as svr, cmd, count(cmd),  round(cast(avg(completedLapse) AS DECIMAL(9,2)), 2) as "Avg Time", 
round(cast(max(completedLapse) AS DECIMAL(9, 2)), 2) as "Max Time",
cast(sum(completedLapse) as decimal(9,2)) as "Sum Time",
round(cast(avg(rpcsizeout) AS DECIMAL(9,2)), 2) as "Avg Sent(MB)",
cast(sum(rpcsizeout) AS DECIMAL(9,2)) as "Sum Sent(MB)",
round(cast(sum(rpcsizeout) as decimal(9,2)) / cast(sum(completedLapse) as decimal(9,2)), 2) as "Rate MB/s"
FROM process where (cmd = "user-sync" or cmd = "user-transmit") and completedLapse > 1
GROUP by svr, cmd;

.print "\n"

/*
.print "By IP"\n
select ip, cmd, count(cmd),  round(cast(avg(completedLapse) AS DECIMAL(9,2)), 2) as "Avg Time", 
round(cast(max(completedLapse) AS DECIMAL(9, 2)), 2) as "Max Time",
cast(sum(completedLapse) as decimal(9,2)) as "Sum Time",
round(cast(avg(rpcsizeout) AS DECIMAL(9,2)), 2) as "Avg Sent(MB)",
cast(sum(rpcsizeout) AS DECIMAL(9,2)) as "Sum Sent(MB)",
round(cast(sum(rpcsizeout) as decimal(9,2)) / cast(sum(completedLapse) as decimal(9,2)), 2) as "Rate MB/s"
FROM process where (cmd = "user-sync") and completedLapse > 1
group by ip;
*/

.print "\n"
.print "Submit  times\n"
select substr(workspace, 7, 12) as svr, min(substr(starttime, 12, 8)) as 'start', 
  max(substr(endtime, 12, 8)) as 'end', count(completedlapse) as 'count' 
from process where cmd = "user-submit" 
group by svr;

.print "\n"
.print "Sync times\n"
select substr(workspace, 7, 12) as svr, min(substr(starttime, 12, 8)) as 'start', 
  max(substr(endtime, 12, 8)) as 'end', count(completedlapse) as 'count'
from process where cmd = "user-sync" or cmd = "cmd-transmit" and completedlapse > 1
group by svr;

PRAGMA temp_store = 2;      -- store temp table in memory, not on disk
CREATE TEMP TABLE _Variables(Start DATE, SubmitStart DATE, SubmitEnd DATE);

.print "\n"
insert into _variables
values((select min(starttime) from process where cmd = "user-sync" or cmd = "user-transmit"),
    (select min(starttime) from process where cmd = "user-submit"),
    (select max(endtime) from process where cmd = "user-submit"));

select CAST ((julianday(SubmitStart) - julianday(start)) * 24 * 60 * 60 as INTEGER) as Phase1Duration,
    CAST ((julianday(SubmitEnd) - julianday(SubmitStart)) * 24 * 60 * 60 as INTEGER) as Phase2Duration
from _variables;

.print "\n"

select CAST ((julianday(max(endtime)) - julianday(min(starttime))) * 24 * 60 * 60 as INTEGER) as TotalSecondsDuration 
from process where cmd = 'user-sync' or cmd = 'user-transmit';

.print "\n"

EOF
sqlite3 -header run.db < sql.in

echo "" >> $sqlreport
echo "Report for instance: $instance" >> $sqlreport
echo "$rundir" >> $sqlreport
echo "" >> $sqlreport
cat $sqlreport

grep parallel config.out
grep workspace_root config_p4_*.yml | grep -v "#"

echo ""
echo "Workspace sizes on commit (for cross check)"
echo "Client:"
echo "Files Size"
cat client_sizes*.txt | awk '{f += $2; s += $4+0} END { printf "%d %.2fG\n", f, s;}'

cat changes.out

echo ""
