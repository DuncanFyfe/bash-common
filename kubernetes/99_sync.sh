#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_NAME=$(basename ${SCRIPT})
export SCRIPT_DIR=$(dirname ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"

. ${SCRIPT_DIR}/common.sh
. ${SCRIPT_DIR}/config.sh
assert_directory ${BUILD_ROOT}

get_lib_config node_config 'nodes' 'config.sh'
if [ -f ${node_config} ]; then
  . ${node_config}
fi
NODES=$(echo "${ETCD_NODES} ${KUBE_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')
debugenv '99_sync' NODES

nsmg="Sync to nodes."
for node_name in ${NODES}; do
  debug "${SCRIPT_NAME}//BEGIN NODE ${node_name}//${nmsg}"
  ${SCRIPT_DIR}/copy_to_node.sh  ${node_name}
  debug "${SCRIPT_NAME}//END NODE ${node_name}//${nmsg}"
done

debug_end
