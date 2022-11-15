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

yum group install -y "Development Tools"  --nogpgcheck
yum install -y helix-p4d epel-release sqlite wget jq vim net-tools perl nmap-ncat python38 python38-devel python3-pip perforce-p4python3-python3.8
yum remove -y python36 python39

echo /usr/local/lib>> /etc/ld.so.conf
echo /usr/lib64>> /etc/ld.so.conf

# copy down the project from github just so we can get the requirments.txt file
# laster the driver VM will use ansible to copy over the required files
cd /tmp
git clone https://github.com/${git_owner}/${git_project}.git
cd ${git_project}/
git checkout ${git_branch}

cd locust_files
pip3 install -r requirements.txt

rm -rf /tmp/${git_project}

mkdir -p /${p4benchmark_dir}
chown -R ${p4benchmark_os_user}:${p4benchmark_os_user} ${p4benchmark_dir}

mkdir -p /${locust_workspace_dir}
chown -R ${p4benchmark_os_user}:${p4benchmark_os_user} ${locust_workspace_dir}


cat << EOF >> /etc/security/limits.conf

perforce        hard nofile 10000
perforce        soft nofile 10000
EOF


# the python code does a login but not a trust
# the user data cant do a login at this point because the p4benchmark_os_user is created by the driver
# vm which is created after the client VMs
export P4TRUST="/home/${p4benchmark_os_user}/.p4trust"
export P4PORT="ssl:${helix_core_private_ip}:1666"
p4 trust -y
chown ${p4benchmark_os_user}:${p4benchmark_os_user} /home/${p4benchmark_os_user}/.p4*
