#!/bin/bash
# Install this on your machine and all kubernetes nodes.  It is mandatory on
# a master node and useful on a worker node.
# The target is Ubuntu 16.04 nodes.
_sudo=${SUDO_PATH:-'/usr/bin/sudo'}
if [ "$(id -u)" != "0" ]; then
    $_sudo $0 $@
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive;
apt-get update
apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
fi
apt-get update
# Install docker if you don't have it already.
apt-get install -y kubelet kubeadm kubernetes-cni
