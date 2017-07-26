#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_NAME=$(basename ${SCRIPT})
export SCRIPT_DIR=$(dirname ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"

. ${SCRIPT_DIR}/project.sh
assert_directory ${BUILD_ROOT}

load 'docker' 'docker.sh'
load 'etcd' 'etcd.sh'
load 'kubernetes' 'kubernetes.sh'

primary_nodename=$1
# Keep just the host name if we were given a FQDN
export short_nodename=$(echo ${primary_nodename} | sed -e 's/\([^.]\+\)\..\+/\1/')
debugenv 'create_initial_etcd_script' primary_nodename
assert_var primary_nodename

# Look for a node specific configuration file and load it.
load_pernode  ${primary_nodename} 'kubernetes' "kubernetes.sh"

#
# The CA certificate is copied elsewhere because it may be a combination
# of multiple certificates.  BUT we need to set node_ca_pem so the deployment
# script will have the correct one.
get_certificate_file_names node_ca ${KUBE_CA}
node_ca_pem=$(basename ${node_ca_pem})

assert_var KUBE_CA
if [ "X${KUBE_NODENAME}" = 'X' ]; then
  KUBE_NODENAME=${primary_nodename}
fi

KUBE_NAME=$(echo ${KUBE_NODENAME} | sed -e 's/\([^.]\+\)\..\+/\1/')

get_pernode_export_path 'export_dir' ${primary_nodename}
makedir ${export_dir}

# SSL certificates
profiles=$(echo "${KUBE_PROFILE}" | tr ',' '\n' | sort -u | tr '\n' ' ')
debugenv 'create_initial_kube_script' profiles

#
# Copy etc client certificates.
get_common_name 'etcdclient_common_name' ${primary_nodename} 'etcdclient'
get_certificate_file_names etcdclient "${etcdclient_common_name}"
if [ ! -f ${etcdclient_pem} -o ! -f ${etcdclient_key_pem} ]; then
  ${SCRIPT_DIR}/create_certificate.sh 'etcdclient' 'client' ${primary_nodename}
  debugenv 'create_initial_kube_script' etcdclient_pem etcdclient_key_pem export_dir
  assert_file ${etcdclient_pem}
  assert_file ${etcdclient_key_pem}
  cp ${etcdclient_pem} ${etcdclient_key_pem} ${export_dir}
fi
etcdclient_pem=$(basename ${etcdclient_pem})
etcdclient_key_pem=$(basename ${etcdclient_key_pem})

if [ $(echo ${profiles} | grep -c 'master') -gt 0 ]; then
  kube_mode='master'
  # Copy apiserver certificates.
  get_common_name 'apiserver_common_name' ${primary_nodename} 'apiserver'
  get_certificate_file_names apiserver "${apiserver_common_name}"
  if [ ! -f ${apiserver_pem} -o ! -f ${apiserver_key_pem} ]; then
    ${SCRIPT_DIR}/create_certificate.sh 'apiserver' 'server' ${primary_nodename} ${KUBE_NODENAMES}
    debugenv 'create_initial_kube_script' apiserver_pem apiserver_key_pem export_dir
    assert_file ${apiserver_pem}
    assert_file ${apiserver_key_pem}
    cp ${apiserver_pem} ${apiserver_key_pem} ${export_dir}
  fi
  apiserver_pem=$(basename ${apiserver_pem})
  apiserver_key_pem=$(basename ${apiserver_key_pem})

  # Copy and substitute deployment script.
  copy_kubernetes_template kube_override 'kube-master-override.conf'
  copy_kubernetes_template kube_options 'kube-master-options.env'
  kube_override=$(basename ${kube_override})
  kube_options=$(basename ${kube_options})
  copy_kubernetes_template deploy_kube 'deploy_kube_master.sh'
  chmod u+x ${deploy_kube}

elif [ $(echo ${profiles} | grep -c 'worker') -gt 0 ]; then
  #  Copy the necessclientary certificates to the export directory.
  # Copy the CA certificates.
  kube_mode='worker'

  # Create worker (client) certificates
  get_common_name 'worker_common_name' ${primary_nodename} 'worker'
  get_certificate_file_names worker "${worker_common_name}"
  if [ ! -f ${worker_pem} -o ! -f ${worker_key_pem} ]; then
    ${SCRIPT_DIR}/create_certificate.sh 'worker' 'client' ${primary_nodename}
    debugenv 'create_initial_kube_script' worker_pem worker_key_pem export_dir
    assert_file ${worker_pem}
    assert_file ${worker_key_pem}
    cp ${worker_pem} ${worker_key_pem} ${export_dir}
  fi
  worker_pem=$(basename ${worker_pem})
  worker_key_pem=$(basename ${worker_key_pem})

  # Copy and substitute deployment script.
  copy_kubernetes_template kube_override 'kube-worker-override.conf'
  copy_kubernetes_template kube_options 'kube-worker-options.env'
  kube_override=$(basename ${kube_override})
  kube_options=$(basename ${kube_options})
  copy_kubernetes_template deploy_kube 'deploy_kube_worker.sh'
  chmod u+x ${deploy_kube}
fi

debug_end
