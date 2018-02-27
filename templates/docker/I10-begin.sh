#!/bin/sh

# This pause is needed otherwise the init scripts are run before the DB is ready.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export SCRIPT="${BASH_SOURCE[0]}"
else
  export SCRIPT=$(readlink -f "$0")
fi
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
echo "BEGIN $SCRIPT ${PG_PAUSE}"
echo "sleep ${PG_PAUSE} to give DB time to finish initializing."
#sleep ${PG_PAUSE}
echo "END $SCRIPT"
