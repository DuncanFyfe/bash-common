#!/bin/bash
# Rerun self with sudo if not called from account with admin priviliges.
#
# Setup to use the existing coreos systemd service and flanneld.wrapper
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

mkdir -p ${FLANNELD_SSL_DIR}

cp ${client_key_pem} '${FLANNELD_SSL_DIR}/flanneld-etcd-client-key.pem'
cp ${client_pem} '${FLANNELD_SSL_DIR}/flanneld-etcd-client.pem'
cp ${flanneld_pem} '${FLANNELD_SSL_DIR}/flanneld-peer.pem'
cp ${flanneld_key_pem} '${FLANNELD_SSL_DIR}/flanneld-peer-key.pem'

# The combined root+intermediate CA certificates.
flanneldca='${FLANNELD_SSL_DIR}/${FLANNELD_CA}-chain.pem'
if [ ! -f ${flanneldca} ]; then
  cp ${node_ca_pem} ${flanneldca}
  chmod a+r ${flanneldca}
  update-ca-certificates
fi

# Container options
if [ -f ${flanneld_options} ]; then
  mkdir -p /etc/flannel /run/flannel
  cp ${flanneld_options} /etc/flannel/options.env
  rm -f /run/flannel/options.env
  ln -s /etc/flannel/options.env /run/flannel/options.env
fi

# systemd dropin
mkdir -p /etc/systemd/system/flanneld.service.d
cp ${flanneld_override} /etc/systemd/system/flanneld.service.d/override.conf

# Container options
if [ -f ${flanneld_docker_opts_options} ]; then
  mkdir -p /etc/flannel /run/flannel
  cp ${flanneld_docker_opts_options} /etc/flannel/flannel_docker_opts.env
  rm -f /run/flannel/flannel_docker_opts.env
  ln -s /etc/flannel/flannel_docker_opts.env /run/flannel/flannel_docker_opts.env
fi

# systemd dropin
mkdir -p /etc/systemd/system/flanneld-docker-opts.service.d
cp ${flanneld_docker_opts_override} /etc/systemd/system/flanneld-docker-opts.service.d/override.conf

# Container options
if [ -f ${flanneld_docker_options} ]; then
  mkdir -p /etc/flannel /run/flannel
  cp ${flanneld_docker_options} /etc/flannel/flannel_docker_options.env
  rm -f /run/flannel/flannel_docker_options.env
  ln -s /etc/flannel/flannel_docker_options.env /run/flannel/flannel_docker_options.env
fi

# The current wrapper mounts /usr/share/ca-certificates twice.
# We need /usr/share/ca-certificates and /etc/ssl/certs
sed -i -e's!coreos-etc-ssl-certs,kind=host,source=/usr/share/ca-certificates,readOnly=true!coreos-etc-ssl-certs,kind=host,source=/etc/ssl/certs,readOnly=true!g'  /usr/lib64/coreos/flannel-wrapper

#systemctl daemon-reload
#systemctl restart flanneld.service
#systemctl enable etcd-member.service
#systemctl start etcd-member.service
