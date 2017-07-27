#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
load 'docker' 'docker.sh'

nodes=$(echo "$UBUNTU_NODES" | tr ',' '\n' | sort -u | tr '\n' ' ')
template_name='install_docker.sh'
for node in $nodes; do
  echo "BEGIN NODE $node"
  load_pernode $node 'node.sh'
  load_pernode $node 'docker.sh'
  INSTALL_DOCKER=${INSTALL_DOCKER}
  if [ "X$INSTALL_DOCKER" = "XY" ]; then
    # Node specific template
    find_template srcscript $node 'ubuntu' $template_name
    if [ "X$srcscript" != "X" ]; then
      get_pernode_dist destscript $node $template_name
      copy_template $srcscript $destscript 'ADMINUSER'
    fi
  fi
  echo "END NODE $node"
done
debug_end
