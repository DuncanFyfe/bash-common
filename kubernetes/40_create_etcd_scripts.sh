#!/bin/bash
#
# Create per-node scripts to initialize 'outside of kubernetes' etcd
#
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname ${SCRIPT})
export SCRIPT_NAME=$(basename ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"
. ${SCRIPT_DIR}/project.sh
assert_directory ${BUILD_ROOT}

load 'etcd' 'etcd.sh'

NODES=$(echo "${ETCD_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')
debugenv ${SCRIPT_NAME} NODES
nsmg="Create etcd boot script."
for node_name in ${NODES}; do
  debug "${SCRIPT_NAME}//BEGIN NODE ${node_name}//${nmsg}"
  ${SCRIPT_DIR}/create_initial_etcd_script.sh ${node_name}
  debug "${SCRIPT_NAME}//END NODE ${node_name}//${nmsg}"
done
debug_end
