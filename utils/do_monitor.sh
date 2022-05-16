#!/bin/bash

commit_edges="sn1-r720-a02-11 sn1-r720-a02-13"
for h in $commit_edges
do
    cnt=$(p4 -p $h:1666 -u perforce monitor show | wc -l)
    echo $h $cnt
done
