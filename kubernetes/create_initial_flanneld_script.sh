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

# The CA certificate is copied elsewhere because it may be a combination
# of multiple certificates.  BUT we need to set node_ca_pem so the deployment
# script will have the correct one.
assert_var FLANNELD_CA
get_certificate_file_names node_ca ${FLANNELD_CA}
debugenv 'create_initial_flanneld_script' FLANNELD_CA
node_ca_pem=$(basename ${node_ca_pem})

if [ "X${ETCD_NODENAME}" = 'X' ]; then
  ETCD_NODENAME=${primary_nodename}
fi
ETCD_NAME=$(echo ${ETCD_NODENAME} | sed -e 's/\([^.]\+\)\..\+/\1/')

# The directory where we need to copy the end results
get_pernode_export_path 'export_dir' ${primary_nodename}
debugenv 'create_initial_flanneld_script' export_dir
makedir ${export_dir}

# SSL certificates
debugenv 'create_initial_flanneld_script' ETCD_PROFILE
profiles=$(echo "${ETCD_PROFILE}" | tr ',' '\n' | sort -u | tr '\n' ' ')

# We always need a client certificate.  If the machine is an etcd server
# then locksmithd needs the client certificate.

get_common_name 'client_common_name' ${primary_nodename} 'flanneld-etcd-client'
get_certificate_file_names client "${client_common_name}"
if [ ! -f ${client_pem} -o ! -f ${client_key_pem} ]; then
  # Create the certificates
  ${SCRIPT_DIR}/create_certificate.sh 'flanneld-etcd-client' 'client' ${primary_nodename}
  # Copy the necessclientary certificates to the export directory.
  cp ${client_pem} ${client_key_pem} ${export_dir}
fi
client_pem=$(basename ${client_pem})
client_key_pem=$(basename ${client_key_pem})

get_common_name 'flanneld_common_name' ${primary_nodename} 'flanneld-peer'
get_certificate_file_names flanneld "${flanneld_common_name}"
if [ ! -f ${flanneld_pem} -o ! -f ${flanneld_key_pem} ]; then
  # Create the certificates
  ${SCRIPT_DIR}/create_certificate.sh 'flanneld-peer' 'peer' ${primary_nodename}
  # Copy the necessclientary certificates to the export directory.
  cp ${flanneld_pem} ${flanneld_key_pem} ${export_dir}
fi
flanneld_pem=$(basename ${flanneld_pem})
flanneld_key_pem=$(basename ${flanneld_key_pem})

FLANNELD_SSL_DIR=${FLANNELD_SSL_DIR:-${ETCD_SSL_DIR}}
###
### Create drop-in file for flanneld.service
### This creates CoreOs specific files/setup
### TBD Adapt this for other Linux variants
###
### systemd drop-in for flanneld.service
copy_flanneld_template flanneld_override 'flanneld-override.conf'
### EnvironmentFile for flanneld.service
copy_flanneld_template flanneld_options 'flanneld-options.env'
### systemd drop-in for flanneld-docker-opts.service
copy_flanneld_template flanneld_docker_options 'flanneld-docker-options.conf'
### systemd drop-in for flanneld-docker-opts.service
copy_flanneld_template flanneld_docker_opts_override 'flanneld-docker-opts-override.conf'
### systemd drop-in for flanneld-docker-opts.service
copy_flanneld_template flanneld_docker_opts_options 'flanneld-docker-opts-options.env'

flanneld_override=$(basename ${flanneld_override})
flanneld_options=$(basename ${flanneld_options})
flanneld_docker_options=$(basename ${flanneld_docker_options})
flanneld_docker_opts_override=$(basename ${flanneld_docker_opts_override})
flanneld_docker_opts_options=$(basename ${flanneld_docker_opts_options})

copy_flanneld_template deploy_flanneld 'deploy_flanneld.sh'
chmod u+x ${deploy_flanneld}

debug_end
