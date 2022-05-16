#!/bin/bash
# Example utility script to do direct comparisons of scp vs other comamnds
# Not directly used in benchmarking

d=/p4depot_fa/ws/long_directory_name_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_1234567890_/00
 
pushd $d
nohup sudo nethogs -c 30 -t -d 1 > nethogs.out 2>&1 &
time ls | parallel scp -r {} sn1-r720-a01-03:/ram/disk/00/{}
sudo pkill nethogs

grep ssh nethogs.out | awk '{s += $2; r += $3} END{ printf("sent/rcvd MB tot %.2f,%.2f\n", s/1024, r/1024);}'
