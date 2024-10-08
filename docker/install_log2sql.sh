#!/bin/bash
# Install appropriate log2sql version for architecture
set -e

arch="amd64"
[[ $(uname -m) == "aarch64" ]] && arch="arm64"

mkdir /home/perforce/bin
cd /home/perforce/bin
wget -q https://github.com/rcowham/go-libp4dlog/releases/latest/download/log2sql-linux-${arch}.gz
gunzip log2sql-linux-${arch}.gz
mv log2sql-linux-${arch} log2sql
chmod +x log2sql
