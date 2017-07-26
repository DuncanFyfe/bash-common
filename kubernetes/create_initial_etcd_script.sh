#!/bin/bash
#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname ${SCRIPT})
export SCRIPT_NAME=$(basename ${SCRIPT})
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

# The CA certificate is copied elsewhere because it may be a combination
# of multiple certificates -- BUT we need to set node_ca_pem so the deployment
# script will have the correct one.
assert_var ETCD_CA
get_certificate_file_names node_ca ${ETCD_CA}
debugenv 'create_initial_etcd_script' ETCD_CA
node_ca_pem=$(basename ${node_ca_pem})

if [ "X${ETCD_NODENAME}" = 'X' ]; then
  ETCD_NODENAME=${primary_nodename}
fi
ETCD_NAME=$(echo ${ETCD_NODENAME} | sed -e 's/\([^.]\+\)\..\+/\1/')

get_cluster_token ETCD_INITIAL_CLUSTER_TOKEN
assert_var ETCD_INITIAL_CLUSTER_TOKEN

# The directory where we need to copy the end results
get_pernode_export_path 'export_dir' ${primary_nodename}
debugenv 'create_initial_etcd_script' export_dir
makedir ${export_dir}

# SSL certificates
debugenv 'create_run_etcd_script' ETCD_PROFILE
profiles=$(echo "${ETCD_PROFILE}" | tr ',' '\n' | sort -u | tr '\n' ' ')

# On CoreOS we always need a client certificate.  If the machine is an etcd
# server then locksmithd needs the client certificate.
if [ $(echo ${profiles} | grep -c 'client' ) -gt 0 ]; then
  get_common_name 'client_common_name' ${primary_nodename} 'etcdclient'
  get_certificate_file_names client "${client_common_name}"
  if [ ! -f ${client_pem} -o ! -f ${client_key_pem} ]; then
    # Create the certificates
    ${SCRIPT_DIR}/create_certificate.sh 'etcdclient' 'client' ${primary_nodename}
    # Copy the necessclientary certificates to the export directory.
    cp ${client_pem} ${client_key_pem} ${export_dir}
  fi
  client_pem=$(basename ${client_pem})
  client_key_pem=$(basename ${client_key_pem})
fi

if [ $(echo ${profiles} | grep -c 'server' ) -gt 0 ]; then
  get_common_name 'locksmithd_common_name' ${primary_nodename} 'locksmithd'
  get_certificate_file_names locksmithd "${locksmithd_common_name}"
  if [ ! -f ${locksmithd_pem} -o ! -f ${locksmithd_key_pem} ]; then
    # Create the certificates
    ${SCRIPT_DIR}/create_certificate.sh 'locksmithd' 'client' ${primary_nodename}
    # Copy the necessclientary certificates to the export directory.
    cp ${locksmithd_pem} ${locksmithd_key_pem} ${export_dir}
  fi
  locksmithd_pem=$(basename ${locksmithd_pem})
  locksmithd_key_pem=$(basename ${locksmithd_key_pem})

  # Create the server certificates
  get_common_name 'server_common_name' ${primary_nodename} 'etcdserver'
  get_certificate_file_names server "${server_common_name}"
  if [ ! -f ${server_pem} -o ! -f ${server_key_pem} ]; then
    ${SCRIPT_DIR}/create_certificate.sh 'etcdserver' 'server' ${primary_nodename} ${ETCD_NODENAMES}
    assert_file ${server_pem}
    assert_file ${server_key_pem}
    cp ${server_pem} ${server_key_pem} ${export_dir}
  fi
  server_pem=$(basename ${server_pem})
  server_key_pem=$(basename ${server_key_pem})

  # Create the peer certificates
  get_common_name 'peer_common_name' ${primary_nodename} 'etcdpeer'
  get_certificate_file_names peer "${peer_common_name}"
  if [ ! -f ${peer_pem} -o ! -f ${peer_key_pem} ]; then
    ${SCRIPT_DIR}/create_certificate.sh 'etcdpeer' 'peer' ${primary_nodename} ${ETCD_NODENAMES}
    assert_file ${peer_pem}
    assert_file ${peer_key_pem}
    cp ${peer_pem} ${peer_key_pem} ${export_dir}
  fi
  peer_pem=$(basename ${peer_pem})
  peer_key_pem=$(basename ${peer_key_pem})

  ###
  ### Create drop-in file for etcd-member.service
  ### This is CoreOS Specific.
  ### TBD Adapt this to work on Ubuntu and other Linux variants.
  ###
  ### systemd drop-in for etcd-memeber.service
  copy_etcd_template etcd_override 'etcd-override.conf' ${primary_nodename}
  ### EnvironmentFile for etcd-memeber.service
  copy_etcd_template etcd_options 'etcd-options.env' ${primary_nodename}
  ### systemd drop-in for locksmithd.service
  copy_etcd_template locksmithd_override 'locksmithd-override.conf' ${primary_nodename}
    ### EnvironmentFile for locksmithd-memeber.service
  copy_etcd_template locksmithd_options 'locksmithd-options.env' ${primary_nodename}

  etcd_override=$(basename ${etcd_override})
  etcd_options=$(basename ${etcd_options})
  locksmithd_override=$(basename ${locksmithd_override})
  locksmithd_options=$(basename ${locksmithd_options})
  ###
  ### Create script to bootstrap an etcd cluster member
  ###

  copy_etcd_template deploy_etcd 'deploy_etcd.sh' ${primary_nodename}
  chmod u+x ${deploy_etcd}
  debug "Wrote etcd ${etcd_mode} template ${deploy_etcd}."
fi

debug_end
