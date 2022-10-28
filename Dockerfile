FROM rockylinux:8 as p4bench
MAINTAINER Robert Cowham "rcowham@perforce.com"

# Common machine configuration (p4bench) - is all that is required for client machines and is
# basis for master machine.

RUN yum update -y; \
    yum install -y net-tools; \
    yum install -y perl; \
    yum install -y sudo; \
    yum install -y wget; \
    echo /usr/local/lib>> /etc/ld.so.conf; \
    echo /usr/lib64>> /etc/ld.so.conf; \
    sed -ie "s/^Defaults[ \t]*requiretty/#Defaults  requiretty/g" /etc/sudoers

RUN yum install -y openssh-server openssh-clients passwd; \
    yum install -y rpm dnf-plugins-core; \
    yum clean all; \
    ssh-keygen -A

# Python plus p4python
RUN dnf install --assumeyes python38 python38-devel python3-pip; \
    dnf group install --assumeyes "Development Tools"; \
    rpm --import https://package.perforce.com/perforce.pubkey; \
    echo -e "[perforce]\\nname=Perforce\\nbaseurl=https://package.perforce.com/yum/rhel/8/x86_64\\nenabled=1\\ngpgcheck=1\\n" >  /etc/yum.repos.d/perforce.repo; \
    yum install -y perforce-p4python3

# Create perforce user with UID to 1000 before p4d installation
RUN useradd --home-dir /home/perforce --create-home --uid 1000 perforce; \
    mkdir /p4; \
    chown perforce:perforce /p4
RUN echo perforce:perforce | /usr/sbin/chpasswd
RUN cd /usr/local/bin && curl -k -s -O http://ftp.perforce.com/perforce/r22.1/bin.linux26x86_64/p4 && \
    chmod +x /usr/local/bin/p4

RUN echo 'perforce ALL=(ALL) NOPASSWD:ALL'> /tmp/perforce; \
    chmod 0440 /tmp/perforce; \
    chown root:root /tmp/perforce; \
    mv /tmp/perforce /etc/sudoers.d

ADD utils/insecure_ssh_key.pub /tmp
ADD utils/insecure_ssh_key /tmp
ADD utils/setup_ssh.sh /tmp

RUN /bin/bash -x /tmp/setup_ssh.sh && rm /tmp/*ssh*
EXPOSE 22

RUN mkdir -p /p4/benchmark; \
    chown -R perforce:perforce /p4/benchmark

ADD locust_files/requirements.txt /p4/benchmark/

RUN dnf remove --assumeyes python36 python39
RUN pip3 install -r /p4/benchmark/requirements.txt

# ==================================================================
# Dockerfile for master target - builds on the above
FROM p4bench as p4benchmaster

USER root

RUN dnf install --assumeyes epel-release; \
    dnf install --assumeyes ansible

RUN mkdir /hxdepots /hxmetadata /hxlogs; \
    chown -R perforce:perforce /hx*; \
    mkdir -p /hxdepots/reset; \
    cd /hxdepots/reset; \
    curl -k -s -O https://swarm.workshop.perforce.com/downloads/guest/perforce_software/helix-installer/main/src/reset_sdp.sh; \
    chmod +x reset_sdp.sh; \
    ./reset_sdp.sh -fast -no_ssl -no_sd

USER perforce
RUN mkdir -p /p4/benchmark/locust_files; \
    mkdir -p /p4/benchmark/ansible; \
    mkdir -p /p4/benchmark/utils

# Log analyzer required
RUN mkdir /p4/bin; \
    cd /p4/bin; \
    curl -k -s -O https://github.com/rcowham/go-libp4dlog/releases/download/v0.10.1/log2sql-linux-amd64.gz; \
    gunzip log2sql-linux-amd64.gz; \
    mv log2sql-linux-amd64 log2sql; \
    chmod +x log2sql

ADD locust_files/* /p4/benchmark/locust_files/
ADD ansible/* /p4/benchmark/ansible/
ADD utils/* /p4/benchmark/utils/
ADD hosts /p4/benchmark/
ADD docker_entry_master.sh /p4/benchmark/

# # Optional - this installs node_exporter which is part of Prometheus
# USER root
