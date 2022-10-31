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

echo "${ssh_public_key}" > /ssh_public_key
echo "${ssh_private_key}" > /ssh_private_key
chmod 600 /ssh_private_key

eval `ssh-agent -s`
ssh-add /ssh_private_key


cat << EOF > /etc/yum.repos.d/perforce.repo
[Perforce]
name=Perforce
baseurl=https://package.perforce.com/yum/rhel/8/x86_64
enabled=1
gpgcheck=1
EOF

rpm --import https://package.perforce.com/perforce.pubkey

yum install -y helix-p4d perforce-p4python3



#yum update -y
yum group install -y "Development Tools"
yum install -y nmap-ncat python3 python3-devel python3-numpy python3-pip python3-setuptools python3-wheel openssl-devel

python3 -m pip install ansible

cd /
git clone https://github.com/${git_owner}/${git_project}.git
cd ${git_project}/
git checkout ${git_branch}

cd locust_files
pip3 install -r requirements.txt

export P4PORT="ssl:${helix_core_private_ip}:1666"
export P4TRUST=/root/.p4trust
export P4TICKETS=/root/.p4tickets
export P4USER="${helix_core_commit_username}"

p4 trust -y
echo ${helix_core_password} | p4 login

cat <<EOT > /tmp/${helix_core_commit_benchmark_username}.cfg
User:  ${helix_core_commit_benchmark_username}

Email:${helix_core_commit_benchmark_username}@perforce.com

FullName:   ${helix_core_commit_benchmark_username}
EOT
cat /tmp/${helix_core_commit_benchmark_username}.cfg | p4 user -i -f 

cat <<EOT > /tmp/password_reset
${helix_core_password}
${helix_core_password}
EOT

cat /tmp/password_reset | p4 passwd ${helix_core_commit_benchmark_username}


p4 logout
export P4CLIENT=test_ws
export P4USER=${helix_core_commit_benchmark_username}
echo ${helix_core_password} | p4 login



# Create a test workspace root dir
ws_root=${createfile_directory}
mkdir -p $ws_root
cd $ws_root

# Create a client workspace with correct view - will default Root: to current directory
p4 --field "View=//depot/... //test_ws/..." client -o | p4 client -i
p4 --field "Host=" client -o | p4 client -i

python3 /p4benchmark/locust_files/createfiles.py -l ${createfile_levels} -s ${createfile_size} -m ${createfile_number} -d ${createfile_directory} --create

p4 rec 
p4 submit -d "Initial files"
p4 changes -t




cd /p4benchmark
rm hosts

cat << EOF > /p4benchmark/hosts.all.yml
all:
    vars:
        remote_user: ${p4benchmark_os_user}
        bench_dir: /hxdepots/p4benchmark
        # Number of workers per bench_client
        num_workers: ${number_locust_workers}

    children:
        replicas:
            hosts:
                ${helix_core_private_ip}:
        bench_clients:
            hosts:
%{ for ip in locust_client_ips ~}
                ${ip}:
%{ endfor ~}


EOF

cp /p4benchmark/hosts.all.yml /p4benchmark/hosts


cat << EOF > /p4benchmark/locust_files/config_p4_basic.yml

general:
    min_wait: 100
    max_wait: 100
    workspace_root:  /hxdepots/work

# Perforce benchmark testing parameters
# Specify password if required
perforce:
    # Array of ports - can include ssl prefix. Allows for random selection of edge servers
    port:
    - ssl:${helix_core_private_ip}:1666
    user:       ${helix_core_commit_benchmark_username}
    charset:
    password:   ${helix_core_password}
    options:  noallwrite noclobber nocompress unlocked nomodtime rmdir
    sync_progress_size_interval: 100 * 1000 * 1000
    # repoPath: should not include trailing /...
    #   If it includes "*" will be used as base for selection after running "p4 dirs" on it
    repoPath:   //depot/01
    # repoDirNum: (numeric) Number of entries to randomly select from the above "p4 dirs" output if relevant
    repoDirNum: 5
    # How many times to repeat the loop
    repeat: 5
    # sync_args: any extra sync arguments. This will result in the spawning of a "p4" command
    # Example to avoid actually writing files to filesystem on client side:
    #sync_args: -vfilesys.client.nullsync=1
    # Any other -v or similar options possible.
    # Note that the following commands will be passed automatically: -p/-u/-c


EOF

