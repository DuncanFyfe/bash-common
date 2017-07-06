#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
assert_directory $BUID_ROOT
#nodes=$(echo "$UBUNTU_NODES" | tr ',' '\n' | sort -u | tr '\n' ' ')
nodes="do-1gb-fra1-01.domenlas.com"
template_name='root_bootstrap.sh'

_destdir=$(basename $PROJECT_ROOT)
destdir='/root/'${destdir:-$_destdir}

for node in $nodes; do
  echo "BEGIN NODE $h"
  get_pernode_template srcscript_t $node $template_name
  get_template srcscript_n 'ubuntu' $template_name
  first_of srcscript $srcscript_t $srcscript_n
  destscript="$destdir/$(basename $srcscript)"
  ssh root@${node} mkdir -p $destdir
  scp $srcscript root@${node}:$destscript
  ssh root@${node} chmod u+x $destscript
  ssh root@${node} $destscript
  echo "END NODE $h"
done
