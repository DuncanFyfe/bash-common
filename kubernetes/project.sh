# Minimal variables that allow the rest to be found.
_default_project_root=$(dirname $SCRIPT_DIR)
export PROJECT_ROOT=${PROJECT_ROOT:-${_default_project_root}}
export PROJECT_PATH=${PROJECT_PATH:-"${PROJECT_ROOT}/bin"}
export PROJECT_LIB=${PROJECT_LIB:-"${PROJECT_ROOT}/lib"}
export PROJECT_CONFIG=${PROJECT_CONFIG:-"${PROJECT_ROOT}/config"}

. $PROJECT_LIB/common.sh
. $PROJECT_CONFIG/common.sh
