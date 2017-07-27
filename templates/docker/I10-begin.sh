#!/bin/sh

# This pause is needed otherwise the init scripts are run before the DB is ready.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
echo "BEGIN $script"
sleep ${PG_PAUSE}
echo "END $script"
