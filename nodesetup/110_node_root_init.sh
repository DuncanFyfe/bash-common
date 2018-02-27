#!/bin/bash
# This script copies a script to a node and runs that script as root.
# I use this to prepare Ubuntu 16.04 nodes with a swapfile, non-root user
# with sudo access and a firewall.
# All other initialization and configuration is performed as the non-root user.

export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
assert_directory $BUID_ROOT
template_name='root_bootstrap.sh'

_destdir=$(basename $PROJECT_ROOT)
destdir='/root/'${destdir:-$_destdir}

nodes=$(echo "${@:-$ALL_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')
for node in $nodes; do
  echo "BEGIN NODE $h"
  load_pernode $node 'node.sh'
  node_dist=${NODE_DIST}
  get_pernode_template srcscript_t $node $template_name
  get_template srcscript_n "$node_dist" $template_name
  first_of srcscript $srcscript_t $srcscript_n
  destscript="$destdir/$(basename $srcscript)"
  ssh root@${node} mkdir -p $destdir
  scp $srcscript root@${node}:$destscript
  ssh root@${node} chmod u+x $destscript
  ssh root@${node} $destscript
  echo "END NODE $h"
done
