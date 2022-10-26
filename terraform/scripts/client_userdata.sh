#!/bin/bash

set -eux -o pipefail

trap 'catch $? $LINENO' ERR

catch() {
    echo ""
    echo "ERROR CAUGHT!"
    echo ""
    echo "Error code $1 occurred on line $2"
    echo ""
    
    exit $1
}

useradd perforce

mkdir -p /home/${p4benchmark_os_user}/.ssh/
touch /home/${p4benchmark_os_user}/.ssh/authorized_keys
chown -R ${p4benchmark_os_user}:${p4benchmark_os_user} /home/${p4benchmark_os_user}

echo 'perforce ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/perforce

echo "${ssh_public_key}" > /ssh_public_key
echo "${ssh_public_key}" >> /home/${p4benchmark_os_user}/.ssh/authorized_keys
echo "${ssh_private_key}" > /ssh_private_key

cat << EOF > /etc/yum.repos.d/perforce.repo
[Perforce]
name=Perforce
baseurl=https://package.perforce.com/yum/rhel/8/x86_64
enabled=1
gpgcheck=1
EOF

rpm --import https://package.perforce.com/perforce.pubkey

yum install -y helix-p4d perforce-p4python3

yum group install -y "Development Tools"
yum install -y nmap-ncat python3 python3-devel python3-numpy python3-pip python3-setuptools python3-wheel openssl-devel

cd /
git clone https://github.com/${git_owner}/${git_project}.git
cd ${git_project}/
git checkout ${git_branch}

cd locust_files
pip3 install -r requirements.txt
