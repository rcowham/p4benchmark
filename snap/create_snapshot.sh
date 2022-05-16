#!/bin/bash
# Create a snapshot of Backup group

source=PGp4checkpoint
backup=p4backup

echo "Listing snapshots on $backup"
python flash_array.py --list --backup=p4backup | tail -3

echo "Creating snapshot of $source"
python flash_array.py --snapshot --source PGp4checkpoint

echo "Listing snapshots on $backup"
python flash_array.py --list --backup=p4backup | tail -3

