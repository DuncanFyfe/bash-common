#!/bin/bash
#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname ${SCRIPT})
export SCRIPT_NAME=$(basename ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"
. ${SCRIPT_DIR}/project.sh
assert_directory ${BUILD_ROOT}

load 'nodes' 'nodes.sh'
get_timestamp 'current_timestamp'
assert_var current_timestamp

node_name=$1
assert_var node_name

# Get just the host name if we were given a FQDN
target_nodename=$(echo ${node_name} | sed -e 's/\([^.]\+\)\..\+/\1/')
assert_var target_nodename
get_pernode_config_path cfgfile ${target_nodename} 'config.sh'
if [ -f ${cfgfile} ]; then
  . ${cfgfile}
fi

debugenv 'copy_to_node' node_name target_nodename current_timestamp cfgfile  SYNC_HOST
# Export to the host
if [ "X${SYNC_HOST}" = "XTRUE" ]; then
  get_pernode_export_path 'node_root' ${target_nodename}
  assert_directory ${node_root}

  default_target_directory="${NODE_BUILD_ROOT}/${target_nodename}/${current_timestamp}"
  target_directory=${target_directory:-${default_target_directory}}
  debugenv 'copy_to_node' node_root target_directory NODE_USER NODE_HOSTNAME NODE_BUILD_ROOT

  assert_var NODE_USER
  assert_var NODE_HOSTNAME
  assert_var NODE_BUILD_ROOT
  assert_var node_root
  assert_var target_directory
  ssh ${NODE_USER}@${NODE_HOSTNAME} "mkdir -p \"${target_directory}\""
  rsync -a --delete "${node_root}/"  "${NODE_USER}@${NODE_HOSTNAME}:${target_directory}/"
fi

debug_end
