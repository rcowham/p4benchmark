#!/bin/bash

set -eux -o pipefail

trap 'catch $? $LINENO' ERR

catch() {
    rm -rf "/tmp/$CREATE_FILES_DIRECTORY"
    echo ""
    echo "ERROR CAUGHT!"
    echo ""
    echo "Error code $1 occurred on line $2"
    echo ""
    
    exit $1
}

export P4CLIENT=$CREATE_FILES_DIRECTORY
export P4USER=${helix_core_commit_benchmark_username}
export P4PORT="ssl:${helix_core_private_ip}:${helix_core_port}"
export P4TRUST=/home/rocky/.p4trust
export P4TICKETS=/home/rocky/.p4tickets

p4 trust -y

echo ${helix_core_password} | p4 login

# Create a test workspace root dir
mkdir -p "/tmp/$CREATE_FILES_DIRECTORY"
cd "/tmp/$CREATE_FILES_DIRECTORY"

# Create a client workspace with correct view - will default Root: to current directory
p4 --field "View=//depot/... //$CREATE_FILES_DIRECTORY/..." client -o | p4 client -i
p4 --field "Host=" client -o | p4 client -i

export CREATE_FILES_ARGUMENTS="-l $CREATE_FILES_LEVELS -s $CREATE_FILES_SIZE -m $CREATE_FILES_NUMBER -d . --create"

python3 /p4benchmark/locust_files/createfiles.py $CREATE_FILES_ARGUMENTS



# TODO: rec and submit in parallel when running createfiles.py
# for i in {00..39}; do echo $i >> list.txt ; done

# nohup cat list.txt | parallel 'echo -n {}" "; ./do_rec.sh {} >> {}.out 2>&1 ' &

# #!/bin/bash
# # Reconcile a tree created by createfiles.py
# # Parameter: <2 digit directory>
# root=`pwd`
# dir="$root/$1"
# p4 rec -a $dir/...
# p4 submit -d "Initial import" "$dir/..."



p4 rec -a
p4 submit --parallel=threads=5 -d "Adding files created from createfiles.py - workspace: $P4CLIENT - arguments: $CREATE_FILES_ARGUMENTS"
p4 changes -t

cd /
rm -rf "/tmp/$CREATE_FILES_DIRECTORY"

echo "Done submitting files to Helix Core via createfiles.py"
