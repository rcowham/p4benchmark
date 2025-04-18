FROM rockylinux/rockylinux:9-ubi-init as p4bench
MAINTAINER Robert Cowham "rcowham@perforce.com"

# ubi-init base containers support systemd

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

# Common machine configuration (p4bench) - is all that is required for client machines and is
# basis for master machine.

RUN yum update -y; \
    yum install -y net-tools; \
    yum install -y perl; \
    yum install -y sudo; \
    yum install -y wget; \
    yum install -y procps; \
    echo /usr/local/lib>> /etc/ld.so.conf; \
    echo /usr/lib64>> /etc/ld.so.conf; \
    sed -ie "s/^Defaults[ \t]*requiretty/#Defaults  requiretty/g" /etc/sudoers

RUN yum install -y openssh-server openssh-clients passwd; \
    yum install -y rpm dnf-plugins-core; \
    yum clean all; \
    ssh-keygen -A

# Create perforce user with UID to 1000 before p4d installation
RUN useradd --home-dir /home/perforce --create-home --uid 1000 perforce; \
    mkdir /p4; \
    chown perforce:perforce /p4
RUN echo perforce:perforce | /usr/sbin/chpasswd
ADD docker/install_p4.sh /tmp
RUN /tmp/install_p4.sh
RUN echo "[[ -e /p4/common/bin/p4_vars ]] && source /p4/common/bin/p4_vars 1" >> /home/perforce/.bashrc

RUN echo 'perforce ALL=(ALL) NOPASSWD:ALL'> /tmp/perforce; \
    chmod 0440 /tmp/perforce; \
    chown root:root /tmp/perforce; \
    mv /tmp/perforce /etc/sudoers.d

# Python plus tools to install requirements for numpy etc.
RUN dnf install --assumeyes python3-devel python3-pip; \
    dnf group install --assumeyes "Development Tools"

ADD docker/insecure_ssh_key.pub /tmp
ADD docker/insecure_ssh_key /tmp
ADD docker/setup_ssh.sh /tmp

RUN /bin/bash -x /tmp/setup_ssh.sh && rm /tmp/*ssh*
EXPOSE 22

RUN mkdir -p /p4/benchmark; \
    chown -R perforce:perforce /p4/benchmark

# jq/yq for yaml in bash
RUN dnf install --assumeyes jq

ADD locust_files/requirements.txt /p4/benchmark/
RUN pip3 install -r /p4/benchmark/requirements.txt

RUN dnf clean all

# ==================================================================
# Dockerfile for master/commit target - builds on the above
FROM p4bench as p4benchmaster

USER root

RUN dnf install --assumeyes cronie nc; \
    dnf clean all

RUN mkdir /hxdepots /hxmetadata /hxlogs; \
    chown -R perforce:perforce /hx*; \
    mkdir -p /hxdepots/reset; \
    cd /hxdepots/reset; \
    curl -k -s -O https://swarm.workshop.perforce.com/downloads/guest/perforce_software/helix-installer/main/src/reset_sdp.sh; \
    chmod +x reset_sdp.sh; \
    ./reset_sdp.sh -fast -no_ssl -no_sd -no_tweaks

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
    dnf install --assumeyes sqlite nc iproute; \
    dnf clean all


# Log analyzer required
ADD docker/install_log2sql.sh /tmp/
RUN /tmp/install_log2sql.sh

USER perforce

RUN echo "export PATH=/home/perforce/bin:$PATH" >> /home/perforce/.bashrc

RUN mkdir -p /p4/benchmark/locust_files; \
    mkdir -p /p4/benchmark/ansible; \
    mkdir -p /p4/benchmark/utils

ADD locust_files/* /p4/benchmark/locust_files/
ADD ansible/* /p4/benchmark/ansible/
ADD utils/* /p4/benchmark/utils/
COPY hosts.docker.yaml exec_bench.sh docker/docker_entry_p4bench.sh /p4/benchmark/
