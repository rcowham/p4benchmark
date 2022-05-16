FROM centos:centos7 as p4bench
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
    yum clean all; \
    ssh-keygen -A

# Python 3.6 plus p4python
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm; \
    yum update; \
    yum install -y python36u python36u-libs python36u-devel python36u-pip; \
    ln -s /usr/bin/python3.6 /usr/bin/python3; \
    ln -s /usr/bin/pip3.6 /usr/bin/pip3;

# Create perforce user with UID to 1000 before p4d installation
RUN useradd --home-dir /p4 --create-home --uid 1000 perforce
RUN echo perforce:perforce | /usr/sbin/chpasswd
RUN cd /usr/local/bin && wget http://ftp.perforce.com/perforce/r18.2/bin.linux26x86_64/p4 && \
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

RUN pip3.6 install -r /p4/benchmark/requirements.txt

# ==================================================================
# Dockerfile for master target - builds on the above
FROM p4bench as p4benchmaster

USER root
RUN pip3.6 install ansible 

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
    curl -k -s -O https://swarm.workshop.perforce.com/downloads/guest/perforce_software/log-analyzer/psla/psla/log2sql.py; \
    chmod +x log2sql.py

ADD locust_files/* /p4/benchmark/locust_files/
ADD ansible/* /p4/benchmark/ansible/
ADD utils/* /p4/benchmark/utils/
ADD hosts /p4/benchmark/
ADD docker_entry_master.sh /p4/benchmark/

# Optional - this installs node_exporter which is part of Prometheus
USER root


