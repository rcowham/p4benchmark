#!/bin/bash
# Copy /p4d to /p4checkpoint_fa

echo "Checking filesystem"
mount -l|grep p4checkpoint_fa
df -h | grep p4checkpoint_fa
echo "Removing data"
rm -rf /p4checkpoint_fa/p4/1
echo "Data is gone"
df -h | grep p4checkpoint_fa

sudo umount /p4checkpoint_fa
echo "/p4checkpoint_fa should be gone"
df -h | grep p4checkpoint
mount -l|grep p4checkpoint_fa

echo "Copy flasharray"
python flash_array.py --copy --source p4d --target p4checkpoint --overwrite

echo "Remounting"
sudo mount -a -v -t ext4 | grep p4checkpoint

echo "Checking data"
df -h | grep p4checkpoint_fa
