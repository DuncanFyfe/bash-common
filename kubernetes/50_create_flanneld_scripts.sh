#!/bin/bash
#
# Create per-node scripts to initialize flannel overlay network
#
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname ${SCRIPT})
export SCRIPT_NAME=$(basename ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"
. ${SCRIPT_DIR}/project.sh

load 'etcd' 'etcd.sh'
load 'kubernetes' 'kubernetes.sh'

NODES=$(echo "${ETCD_NODES} ${KUBE_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')

nsmg="Create flanneld boot script."
for node in ${NODES}; do
  debug "${SCRIPT_NAME}//BEGIN NODE ${node_name}//${nmsg}"
  ${SCRIPT_DIR}/create_initial_flanneld_script.sh ${node}
  debug "${SCRIPT_NAME}//END NODE ${node_name}//${nmsg}"
done
debug_end
