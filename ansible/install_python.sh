#!/bin/bash
# Install Python 3.6 plus all requirements for running locust
# Valid for CentOS/RHEL 7.*

# Compilers and related tools:
yum install yum-utils

yum groupinstall -y "development tools"

cd /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y epel-release-latest-7.noarch.rpm

yum install -y https://centos7.iuscommunity.org/ius-release.rpm
yum install -y python36u
yum install -y python36u-pip
yum install -y python36u-devel

# Now install python modules
pip3.6 install p4python
pip3.6 install pyaml
pip3.6 install numpy
pip3.6 install pyzmq
pip3.6 install locustio==0.8


