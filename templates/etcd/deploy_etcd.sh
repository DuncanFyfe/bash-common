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
# The host etcd data directory.
mkdir -p ${ETCD_DATA_DIR}
rm -rf ${ETCD_DATA_DIR}/*
chown -R etcd:etcd ${ETCD_DATA_DIR}

mkdir -p ${ETCD_SSL_DIR}
# Set ownership of etcd certificates.
# The etcd keys must belong to the user used to run the etcd container (root ir
# root, etcd if etcd etc)
# locksmithd runs as root so those certis can be left alone

cp ${server_pem} '${ETCD_SSL_DIR}/etcd-server.pem'
cp ${server_key_pem} '${ETCD_SSL_DIR}/etcd-server-key.pem'
cp ${peer_pem} '${ETCD_SSL_DIR}/etcd-peer.pem'
cp ${peer_key_pem} '${ETCD_SSL_DIR}/etcd-peer-key.pem'

chown etcd:etcd '${ETCD_SSL_DIR}/etcd-server.pem' '${ETCD_SSL_DIR}/etcd-server-key.pem' '${ETCD_SSL_DIR}/etcd-peer.pem' '${ETCD_SSL_DIR}/etcd-peer-key.pem'

# #Needed so locksmithd can take etcd locks oce TLS/SSL is enabled.
cp ${locksmithd_pem} '${ETCD_SSL_DIR}/locksmithd-etcd-client.pem'
cp ${locksmithd_key_pem} '${ETCD_SSL_DIR}/locksmithd-etcd-client-key.pem'

etcdca='${ETCD_SSL_DIR}/${ETCD_CA}-chain.pem'
if [ ! -f ${etcdca} ]; then
  cp ${node_ca_pem} ${etcdca}
  chmod a+r ${etcdca}
  update-ca-certificates
fi

# This is needed by locksmithd on coreos
if [ $(grep -c REBOOT_STRATEGY /etc/coreos/update.conf ) -eq 0 ]; then
  echo "REBOOT_STRATEGY=etcd-lock" >> /etc/coreos/update.conf
fi

if [ -f ${etcd_options} ]; then
  mkdir -p /etc/etcd /run/etcd
  chown etcd:etcd /etc/etcd /run/etcd
  cp ${etcd_options} /etc/etcd/options.env
  rm -f /run/etcd/options.env
  ln -s /etc/etcd/options.env /run/etcd/options.env
fi

if [ -f ${locksmithd_options} ]; then
  mkdir -p /etc/locksmithd /run/locksmithd
  cp ${locksmithd_options} /etc/locksmithd/options.env
  rm -f /run/locksmithd/options.env
  ln -s /etc/locksmithd/options.env /run/locksmithd/options.env
fi
# systemd dropin folders
mkdir -p /etc/systemd/system/locksmithd.service.d
cp ${locksmithd_override} /etc/systemd/system/locksmithd.service.d/override.conf
mkdir -p /etc/systemd/system/etcd-member.service.d
cp ${etcd_override} /etc/systemd/system/etcd-member.service.d/override.conf

systemctl daemon-reload
systemctl enable locksmithd.service
systemctl restart locksmithd.service
systemctl enable etcd-member.service
systemctl start etcd-member.service
