#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
assert_var DIST_ROOT
assert_directory $DIST_ROOT

#remote_root=${destdir:-$(basename $PROJECT_ROOT)}
project_name=$(basename $PROJECT_ROOT)
remote_root="dist"
nodes=$(echo "$UBUNTU_NODES" | tr ',' '\n' | sort -u | tr '\n' ' ')
for node in $nodes; do
  debug "BEGIN NODE $node"
  get_pernode_dist dist_dir $node
  remote_dir="$remote_root/$node"
  echo "rsync -a --delete $dist_dir/ ${ADMINUSER}@${node}:${remote_dir}/"
  ssh ${ADMINUSER}@${node} mkdir -p ${remote_dir}
  rsync -a --delete $PROJECT_ROOT/ ${ADMINUSER}@${node}:${project_name}/
  rsync -a --delete $dist_dir/ ${ADMINUSER}@${node}:${remote_dir}/

  debug "END NODE $node"
done
debug_end
