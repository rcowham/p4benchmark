#!/bin/bash
# Restore snapshot to p4checkpoint_fa

source=sn1-x70-d08-21:p4checkpoint.restore-of.sn1-x70-d08-21-PGp4checkpoint-329-p4checkpoint
target=p4checkpoint
target_dir=p4checkpoint_fa

echo "Checking filesystem"
mount -l|grep $target_dir
df -h | grep $target_dir
echo "Removing data"
rm -rf /$target_dir/p4/1
echo "Data is gone"
df -h | grep $target_dir

sudo umount /$target_dir
echo "/$target_dir should be gone"
df -h | grep $target
mount -l|grep $target_dir

echo "Copy $source to $target"
python flash_array.py --copy --source $source --target $target --overwrite


echo "Remounting"
sudo mount -a -v -t ext4 | grep $target

echo "Checking data"
df -h | grep $target_dir


