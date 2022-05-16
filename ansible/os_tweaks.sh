#!/bin/bash
set -u

# Usage (bash syntax):
# ./os_tweaks.sh 2>&1 | tee /tmp/os_tweaks.log

# This script checks, and if need be sets, certain OS parameters per
# Perforce recommendations: http://answers.perforce.com/articles/KB/3005#LINUX

# Following is a sample manual session:
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
# [yes] no
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/defrag
# [always] madvise never
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/enabled
# [always] madvise never
# ROOT@perforce1:/root echo no > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
# ROOT@perforce1:/root echo never > /sys/kernel/mm/transparent_hugepage/defrag
# ROOT@perforce1:/root echo never > /sys/kernel/mm/transparent_hugepage/enabled
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
# yes [no]
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/defrag
# always madvise [never]
# ROOT@perforce1:/root cat /sys/kernel/mm/transparent_hugepage/enabled
# always madvise [never]

function bail () { echo -e "\nError: ${1:-Unknown Error}\n"; exit ${2:-1}; }

declare -i i=0
declare -a Files
declare -i ChangesNeeded=0
declare -a CurrentValues
declare -a CorrectValues
declare CurrentValue
declare Version=1.0.1

# Static Data
Files[0]=/sys/kernel/mm/transparent_hugepage/khugepaged/defrag
Files[1]=/sys/kernel/mm/transparent_hugepage/defrag
Files[2]=/sys/kernel/mm/transparent_hugepage/enabled

# Usage Verification.

[[ -r /etc/redhat-release ]] || bail "This is only tested on RHEL/CentOS."
if [[ -n "$(grep 'CentOS release 6' /etc/redhat-release)" ]]; then
   echo -e "Verified: Running on supported OS (CentOS 6)."
   CorrectValues[0]="no"
elif [[ -n "$(grep '(Core)' /etc/redhat-release)" ]]; then
   echo -e "Verified: Running on supported OS (CentOS 7)."
   CorrectValues[0]="0"
else
   bail "This is only tested on RHEL/CentOS 6 and 7."
fi

[[ $(whoami) == root ]] || bail "This must be run as root."

CorrectValues[1]="never"
CorrectValues[2]="never"

echo -e "\nStarted ${0##*/} v$Version at $(date) on $(hostname --fqdn).\n"

while [[ $i -lt ${#Files[*]} ]]; do
   if [[ -r ${Files[$i]} ]]; then
      CurrentValue=$(cat ${Files[$i]})
      CurrentValue=${CurrentValue#*\[}
      CurrentValue=${CurrentValue%\]*}
      CurrentValues[$i]=$CurrentValue
   else
      bail "Expected file does not exist: ${Files[$i]}"
   fi

   echo -n -e "File:        : ${Files[$i]}\nCurrent Value: ${CurrentValues[$i]}\nCorrect Value: ${CorrectValues[$i]}"

   if [[ "$CurrentValue" == "${CorrectValues[$i]}" ]]; then
      echo -e " (OK)\n"
   else
      echo -e " (Needs to be adjusted)\n"
      ChangesNeeded=$((ChangesNeeded+1))
   fi

   i=$((i+1))
done

if [[ $ChangesNeeded -eq 0 ]]; then
   echo -e "Verified: No changes to the OS parameters checked by this script are needed.\n"
   exit 0
else
   echo -e "Detected $ChangesNeeded of ${#Files[*]} OS parameters needing to be updated.\n"
fi

echo -e "Making updates.\n"
i=0
while [[ $i -lt ${#Files[*]} ]]; do
   CurrentValue=$(cat ${Files[$i]})
   CurrentValue=${CurrentValue#*\[}
   CurrentValue=${CurrentValue%\]*}

   [[ "$CurrentValue" == "${CorrectValues[$i]}" ]] && continue

   echo -e "Setting value to ${CorrectValues[$i]} in ${Files[$i]}"
   echo ${CorrectValues[$i]} > ${Files[$i]} || bail  "Failed to set value in ${Files[$i]}."

   i=$((i+1))
done

echo -e "\nRechecking files after making updates.\n"
i=0
ChangesNeeded=0

while [[ $i -lt ${#Files[*]} ]]; do
   CurrentValue=$(cat ${Files[$i]})
   CurrentValue=${CurrentValue#*\[}
   CurrentValue=${CurrentValue%\]*}

   echo -n -e "File:        : ${Files[$i]}\nCurrent Value: $CurrentValue\nCorrect Value: ${CorrectValues[$i]}"

   if [[ "$CurrentValue" == "${CorrectValues[$i]}" ]]; then
      echo -e " (OK)\n"
   else
      echo -e " (Still needs to be adjusted)\n"
      ChangesNeeded=$((ChangesNeeded+1))
   fi

   i=$((i+1))
done

if [[ $ChangesNeeded -eq 0 ]]; then
   echo -e "Done. All OS parameters needing updates have been made.\n"
else
   bail "Some OS parameter updates failed.  See output above.\n"
fi

