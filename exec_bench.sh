#!/bin/bash
# Run benchmark for specified server yaml file
# Allows the user to update the number of workspaces and submit runs

# ============================================================

function msg () { echo -e "$*"; }
function bail () { msg "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

function usage
{
   declare style=${1:--h}
   declare errorMessage=${2:-Unset}

   if [[ "$errorMessage" != Unset ]]; then
      echo -e "\\n\\nUsage Error:\\n\\n$errorMessage\\n\\n" >&2
   fi

   echo "USAGE for exec_bench.sh:

exec_bench.sh <benchmark-config.yaml> [-w <workspace-count>] [-s <submit-count>] [-b <benchmark>] [-d <description>]

   or

exec_bench.sh -h

    <benchmark-config.yaml> Specify the benchmark config yaml file (REQUIRED), e.g. server1.yaml
    <workspace-count>       How many workspaces to use (updates the config file) - default as per config
    <submit-count>          How many loops of submit to use (updates the config file) - default as per config
    <benchmark>             The locust benchmark to run, eg. default is basic, alternative is sync
    <description>           A textual description of this test run - saved with results for reports

Examples:

exec_bench.sh server1.yaml
exec_bench.sh server1-small.yaml -w 5 -s 5 -b sync -d \"Large server\"

"
}

: Command Line Processing

declare -i shiftArgs=0
declare -i workspaces=0
declare -i submits=0
declare configfile=""
declare benchmark="basic"
declare description="Not set"

set +u
while [[ $# -gt 0 ]]; do
    case $1 in
        (-h) usage -h && exit 0;;
        # (-man) usage -man;;
        (-w) workspaces=$2; shiftArgs=1;;
        (-s) submits=$2; shiftArgs=1;;
        (-b) benchmark=$2; shiftArgs=1;;
        (-d) description=$2; shiftArgs=1;;
        (-*) usage -h "Unknown command line option ($1)." && exit 1;;
        (*) export configfile=$1;;
    esac

    # Shift (modify $#) the appropriate number of times.
    shift; while [[ "$shiftArgs" -gt 0 ]]; do
        [[ $# -eq 0 ]] && usage -h "Incorrect number of arguments."
        shiftArgs=$shiftArgs-1
        shift
    done
done
set -u

# Check for dependencies
command -v yq >/dev/null 2>&1 || bail "Please install yq command (via yum/apt)"

[[ -f "$configfile" ]] || bail "Please specify config file as parameter!"

export ANSIBLE_HOSTS="$configfile"
P4PORT=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.port[0]')
instance=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.sdp_instance')
workspace_common_dir=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.workspace_common_dir')
p4bench_client_user=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.p4bench_client_user')
remove_workspaces_per_client=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.remove_workspaces_per_client')

# Perform updates
if [[ $workspaces -gt 0 ]]; then
    yq -yi ".all.vars.num_workers = $workspaces" "$configfile" || bail "Failed to set num_workers=$workspaces"
fi
if [[ $submits -gt 0 ]]; then
    yq -yi ".all.vars.perforce.repeat = $submits"  "$configfile" || bail "Failed to set repeat=$submits"
fi

count_workspaces=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.num_workers')
count_repeats=$(cat $ANSIBLE_HOSTS | yq -r '.all.vars.perforce.repeat')
echo "Running with $ANSIBLE_HOSTS, P4PORT $P4PORT, workspaces $count_workspaces, submit repeats $count_repeats"

# Remove workspaces from common dir
function rm_ws() {
    [[ $remove_workspaces_per_client = "true" ]] && return
    pushd "$workspace_common_dir" || bail "Failed to pushd to $workspace_common_dir"
    ls | grep "^$p4bench_client_user" > dirs.txt
    count=$(wc -l dirs.txt)
    echo "Removing ${count} '$p4bench_client_user' workspaces from ${PWD}"
    parallel -a dirs.txt rm -rf {} > rm.out
    popd
}

function set_server() {
    # [[ -z $instance ]] || source /p4/common/bin/p4_vars $instance
    p4 set | grep P4PORT
    p4 set | grep P4USER
    echo $ANSIBLE_HOSTS
}

# Activate pythen venv if it exists (can be easier way to install Python packages)
if [[ -f bin/activate ]]; then
    source bin/activate || bail "Failed to activate virtual env"
fi

# Remove old workspaces from shared location
rm_ws

# Select system to test
set_server

# Reset previous run
utils/obliterate_changes.sh $instance || bail "Failed to obliterate changes"
sleep 5

utils/run_bench.sh "$benchmark" || bail "Failed run_bench.sh"
sleep 5

utils/wait_end_bench.sh
sleep 5

utils/analyse.sh "$description"
