#!/bin/bash
# This script sets up ssh for use within container as user perforce

home_dir=/home/perforce
mkdir /$home_dir/.ssh

mv /tmp/insecure_ssh_key.pub /$home_dir/.ssh/authorized_keys
mv /tmp/insecure_ssh_key /$home_dir/.ssh/id_rsa

cat << EOF > /$home_dir/.ssh/config
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User perforce
  LogLevel QUIET
EOF

chown -R perforce:perforce /$home_dir/.ssh

chmod 700 /$home_dir/.ssh
chmod 644 /$home_dir/.ssh/authorized_keys
chmod 400 /$home_dir/.ssh/id_rsa
chmod 400 /$home_dir/.ssh/config
