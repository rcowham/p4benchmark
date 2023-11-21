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
    rpm --import https://package.perforce.com/perforce.pubkey

RUN yum update; \
    echo -e "[perforce]\\nname=Perforce\\nbaseurl=https://package.perforce.com/yum/rhel/8/x86_64\\nenabled=1\\ngpgcheck=1\\n" >  /etc/yum.repos.d/perforce.repo; \
    yum install -y perforce-p4python3-python3.8

# Create perforce user with UID to 1000 before p4d installation
RUN useradd --home-dir /home/perforce --create-home --uid 1000 perforce; \
    mkdir /p4; \
    chown perforce:perforce /p4
RUN echo perforce:perforce | /usr/sbin/chpasswd
RUN cd /usr/local/bin && curl -k -s -O https://ftp.perforce.com/perforce/r23.1/bin.linux26x86_64/p4 && \
    chmod +x /usr/local/bin/p4
RUN echo "[[ -e /p4/common/bin/p4_vars ]] && source /p4/common/bin/p4_vars 1" >> /home/perforce/.bashrc

RUN echo 'perforce ALL=(ALL) NOPASSWD:ALL'> /tmp/perforce; \
    chmod 0440 /tmp/perforce; \
    chown root:root /tmp/perforce; \
    mv /tmp/perforce /etc/sudoers.d

ADD docker/insecure_ssh_key.pub /tmp
ADD docker/insecure_ssh_key /tmp
ADD docker/setup_ssh.sh /tmp

RUN /bin/bash -x /tmp/setup_ssh.sh && rm /tmp/*ssh*
EXPOSE 22

RUN mkdir -p /p4/benchmark; \
    chown -R perforce:perforce /p4/benchmark

ADD locust_files/requirements.txt /p4/benchmark/

RUN dnf remove --assumeyes python36 python39
RUN pip3 install -r /p4/benchmark/requirements.txt
# Useful for parsing YAML in bash
RUN dnf install --assumeyes jq
RUN pip3 install yq

# Allow ssh from user perforce
RUN rm /run/nologin

# ==================================================================
# Dockerfile for master/commit target - builds on the above
FROM p4bench as p4benchmaster

USER root

RUN dnf install --assumeyes cronie nc

RUN mkdir /hxdepots /hxmetadata /hxlogs; \
    chown -R perforce:perforce /hx*; \
    mkdir -p /hxdepots/reset; \
    cd /hxdepots/reset; \
    curl -k -s -O https://swarm.workshop.perforce.com/downloads/guest/perforce_software/helix-installer/main/src/reset_sdp.sh; \
    chmod +x reset_sdp.sh; \
    ./reset_sdp.sh -fast -no_ssl -no_sd -no_tweaks

# Replace systemctl for use within docker
RUN cd /usr/local/bin; \
    wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py; \
    chmod 755 systemctl3.py; \
    cd /usr/local/bin; \
    mv systemctl systemctl.old; \
    ln -s /usr/local/bin/systemctl3.py systemctl; \
    cd /usr/bin; \
    mv systemctl systemctl.old; \
    ln -s /usr/local/bin/systemctl3.py systemctl

USER perforce

RUN mkdir -p /p4/benchmark/locust_files

ADD locust_files/* /p4/benchmark/locust_files/

ADD docker/docker_entry_master.sh /p4/benchmark

# Make sure that sshd can run
USER root

# ==================================================================
# Dockerfile for benchmark driver target - builds on the base
FROM p4bench as p4benchdriver

USER root

RUN dnf install --assumeyes epel-release; \
    dnf install --assumeyes ansible; \
    dnf install --assumeyes cronie; \
    dnf install --assumeyes sqlite nc iproute

# Log analyzer required
RUN mkdir /home/perforce/bin; \
    cd /home/perforce/bin; \
    wget -q https://github.com/rcowham/go-libp4dlog/releases/download/v0.12.2/log2sql-linux-amd64.gz; \
    gunzip log2sql-linux-amd64.gz; \
    mv log2sql-linux-amd64 log2sql; \
    chmod +x log2sql

USER perforce

RUN echo "export PATH=/home/perforce/bin:$PATH" >> /home/perforce/.bashrc

RUN mkdir -p /p4/benchmark/locust_files; \
    mkdir -p /p4/benchmark/ansible; \
    mkdir -p /p4/benchmark/utils

ADD locust_files/* /p4/benchmark/locust_files/
ADD ansible/* /p4/benchmark/ansible/
ADD utils/* /p4/benchmark/utils/
ADD hosts.docker.yaml /p4/benchmark/
ADD docker/docker_entry_p4bench.sh /p4/benchmark/
