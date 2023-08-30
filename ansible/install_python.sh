#!/bin/bash
# Install Python 3.8 plus all requirements for running locust
# Valid for Rocky Linux 8/RHEL 8.*

# Compilers and related tools:
yum install yum-utils

yum groupinstall -y "development tools"

cd /tmp
dnf install --assumeyes python38 python38-devel python3-pip

# Now install python modules
pip3 install pyaml numpy pyzmq locust==2.14.2 mimesis yq


