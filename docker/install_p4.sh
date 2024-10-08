#!/bin/bash
# Install appropriate p4 version for architecture

arch="x86_64"
[[ $(uname -m) == "aarch64" ]] && arch="aarch64"

cd /usr/local/bin
curl -k -s -O https://ftp.perforce.com/perforce/r24.1/bin.linux26${arch}/p4
chmod +x /usr/local/bin/p4
