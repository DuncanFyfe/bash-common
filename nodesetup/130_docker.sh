#!/bin/bash
# Target: Ubuntu 16.04 node
# Copy an installer script to a node.  This script, when run will install
# docker on a node.
#
# Per node environment variables:
# INSTALL_DOCKER: Y to install docker on this node.
# NODE_DIST: eg. ubuntu16.04 to used to find the install template specific
# to the node distribution.
#

export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
load 'docker' 'docker.sh'

template_name='install_docker.sh'
nodes=$(echo "${@:-$ALL_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')

for node in $nodes; do
  echo "BEGIN NODE $node"
  load_pernode $node 'node.sh'
  load_pernode $node 'docker.sh'
  # A per-node variable which may be set in the above loaded configurations.
  install_docker=${INSTALL_DOCKER}
  node_dist=${NODE_DIST}
  if [ "X$install_docker" = "XY" ]; then
    # Node specific template
    find_template srcscript $node "$node_dist" $template_name
    if [ "X$srcscript" != "X" ]; then
      get_pernode_dist destscript $node $template_name
      copy_template $srcscript $destscript 'ADMINUSER'
    fi
  fi
  echo "END NODE $node"
done
debug_end
