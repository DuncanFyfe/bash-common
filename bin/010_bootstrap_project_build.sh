#!/bin/bash
# First thing to do after checking out the project is to initilize build and
# distribution directories

export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'nodes' 'nodes.sh'
assert_var BUILD_ROOT

###
### Prepare the directory and space for other init scripts.
###
for d in $BUILD_ROOT $BUILD_PATH $BUILD_LOG $BUILD_RUN $BUILD_TMP $BUILD_LIB $BUILD_CONFIG $DIST_ROOT; do
  makedir $d
done

nodes=${nodes:-$ALL_NODES}
if [ -z "$nodes" ]; then
  nodes=$(echo "$@" | tr ',' '\n' | sort -u | tr '\n' ' ')
fi
# Make node specific directories
for n in $nodes; do
  get_pernode_build _build $n
  makedir $_build
  get_pernode_dist _dist $n
  makedir $_dist
done
# Put a common date/time into a file for other scripts to use
make_timestamp

debug_end
