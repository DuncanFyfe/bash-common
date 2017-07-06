#!/bin/bash
# Example script documenting use of bash-common
# TBD: Documentation
#
# The script with path
export SCRIPT=$(readlink -f "$0")
# The directory of the script
export SCRIPT_DIR=$(dirname $SCRIPT)
# The script name as called.
export SCRIPT_NAME=$(basename $SCRIPT)
# Issue a "BEGIN" statement if DEBUG=ALL OR DEBUG is a string containing
# the name ofd the script eg. DEBUG=example.sh,another.sh
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"

# Bootstrap the bash-common libraries and configurations like this.
. $SCRIPT_DIR/project.sh

# Load a library and configuration which follow the naming convention.
# In this case the library is looked for in lib/docker/docker.sh and
# the configuration in config/docker/docker/sh
load 'docker' 'docker.sh'
# Test if the variable BUILD_ROOT has been defined. Exit if it has not.
assert_var BUILD_ROOT
