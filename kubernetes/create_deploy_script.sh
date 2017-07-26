#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_NAME=$(basename ${SCRIPT})
export SCRIPT_DIR=$(dirname ${SCRIPT})
[ "X${DEBUG}" = "XALL" -o "X${DEBUG#*${SCRIPT_NAME}}" != "X${DEBUG}" ] && echo "SCRIPT BEGIN ${SCRIPT_NAME} ${@:1}"

# Create node deployment scripts.

. ${SCRIPT_DIR}/common.sh
. ${SCRIPT_DIR}/config.sh
assert_directory ${BUILD_ROOT}

. ${SCRIPT_DIR}/config_create_certificate_authority.sh
. ${SCRIPT_DIR}/config_create_certificate.sh
. ${SCRIPT_DIR}/config_etcd.sh
. ${PROJECT_PERNODE_LIB}/commons.sh
. ${PROJECT_PERNODE_LIB}/config.sh

NODENAME=${1}
assert_var NODENAME

# So we can make copy directories timestamped for ease of management.
get_timestamp current_timestamp
get_cluster_token cluster_token

# Get just the host name if we were given a FQDN
target_nodename=$(echo ${NODENAME} | sed -e 's/\([^.]\+\)\..\+/\1/')
get_node_root node_root ${target_nodename}
makedir ${node_root}
get_pernode_config_path cfgfile ${target_nodename} config.sh
debugenv "create_deploy_script" cfgfile
if [ -f ${cfgfile} ]; then
  . ${cfgfile}
  debugenv "create_deploy_script" PROFILES
fi

get_pernode_work_path deploy_script ${target_nodename} "deploy.sh"

echo "#!/bin/bash" > ${deploy_script}
echo "# Deploy script generated ${current_timestamp}" >> ${deploy_script}
echo "# Deploy script generated for etcd cluster ${cluster_token}" >> ${deploy_script}
echo "if [ \"\$(id -u)\" != \"0\" ]; then" >> ${deploy_script}
echo "    /usr/bin/sudo \${0} \$*" >> ${deploy_script}
echo "    exit 0" >> ${deploy_script}
echo "fi" >> ${deploy_script}

chmod u+x ${deploy_script}

debug_end
