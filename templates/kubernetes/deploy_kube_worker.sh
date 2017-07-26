#!/bin/bash
# Rerun self with sudo if not called from account with admin priviliges.
#
# The kube-etcd service assumes etcd has already been bootstrapped.
#
export SCRIPT=$(readlink -f "$0")
export SCRIPT_NAME=$(basename ${SCRIPT})
export SCRIPT_DIR=$(dirname ${SCRIPT})
_sudo=${SUDO_PATH:-'/usr/bin/sudo'}
if [ "$(id -u)" != "0" ]; then
    [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "RESTARTING SCRIPT WITH SUDO: $_sudo $0 $@"
    exec $_sudo $0 $@
fi

cd ${SCRIPT_DIR}

mkdir -p ${ETCD_SSL_DIR}
# Set ownership of etcd certificates.
# The etcd keys must belong to the user used to run the etcd container (root ir
# root, etcd if etcd etc)
# locksmithd runs as root so those certis can be left alone

cp ${apiserver_key_pem} '${KUBE_SSL_DIR}/apiserver-key.pem'
cp ${apiserver_pem} '${KUBE_SSL_DIR}/apiserver.pem'
cp ${etcdclient_key_pem} '${KUBE_SSL_DIR}/kube-etcd-client-key.pem'
cp ${etcdclient_pem} '${KUBE_SSL_DIR}/kube-etcd-client.pem'

# The combined root+intermediate CA certificates.
kubeca='${KUBE_SSL_DIR}/digitalocean-ca.pem'
if [ ! -f ${kubeca} ]; then
  cp ${node_ca_pem} ${kubeca}
  chmod a+r ${kubeca}
  update-ca-certificates
fi


if [ -f ${kube_options} ]; then
  mkdir -p /etc/kubernetes /run/kubernetes
  cp ${kube_options} /etc/kubernetes/options.env
  ln -s /etc/kubernetes/options.env /run/kubernetes/options.env
fi
# systemd dropin folders
mkdir -p /etc/systemd/system/kubernetes.service.d
cp ${kube_override} /etc/systemd/system/kubernetes.service.d/override.conf
