#!/bin/bash
# Copy the per-node distribution folders to the nodes.
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
remote_root="${project_name}/dist"
nodes=$(echo "${@:-$ALL_NODES}" | tr ',' '\n' | sort -u | tr '\n' ' ')
for node in $nodes; do
  debug "BEGIN NODE $node"
  load_pernode $node 'node.sh'
  get_pernode_dist dist_dir $node
  remote_dir="$remote_root/$node"
  ssh ${ADMINUSER}@${node} mkdir -p ${remote_dir}
  #rsync -a --delete $PROJECT_ROOT/ ${ADMINUSER}@${node}:${project_name}/
  rsync -a --delete $dist_dir/ ${ADMINUSER}@${node}:${remote_dir}/

  debug "END NODE $node"
done
debug_end
