#!/bin/bash
# Restore snapshot to /p4checkpoint_fa

source_name=PGp4checkpoint
source=p4backup
target=p4checkpoint

df -h | grep $source_dir
echo "Removing data"
rm -rf /$source_dir/p4/1
echo "Data is gone"
df -h | grep $source_dir

echo "Copy from snapshot"
# python flash_array.py --restore --backup=p4backup --source=sn1-x70-d08-21:PGp4checkpoint.329.p4checkpoint

# python flash_array.py --restore --backup=$source --source $source --target $target --overwrite

echo "Checking data"
df -h | grep $source_dir

