# Common default configuration variables.
# These can be overridden by the order of sourcing.
# The following variables ust point to directories that exsist.

# These three have to exist for us to make use of common libraries and
# configurations
assert_directory $PROJECT_ROOT

PROJECT_LIB=${PROJECT_LIB:-"$PROJECT_ROOT/lib"}
assert_directory $PROJECT_LIB
PROJECT_CONFIG=${PROJECT_CONFIG:-"$PROJECT_ROOT/config"}
assert_directory $PROJECT_CONFIG

PROJECT_PATH=${PROJECT_PATH:-"$PROJECT_ROOT/bin"}
if [ "X$PROJECT_PATH" != "X" -a -d $PROJECT_PATH ]; then
  PATH=${PROJECT_PATH}:$PATH
fi
PROJECT_TEMPLATES=${PROJECT_TEMPLATES:-"$PROJECT_ROOT/templates"}

# Where we put files for distribution.
DIST_ROOT=${BUILD_ROOT:-"$PROJECT_ROOT/dist"}
# Where we put work in progress
BUILD_ROOT=${BUILD_ROOT:-"$PROJECT_ROOT/build"}
# Executables downloaded by scripts.
BUILD_PATH="${BUILD_ROOT}/bin"
if [ "X$BUILD_PATH" != "X" -a -d $BUILD_PATH ]; then
  PATH=${BUILD_PATH}:$PATH
fi
BUILD_LOG="${BUILD_ROOT}/log"
BUILD_RUN="${BUILD_ROOT}/run"
BUILD_TMP="${BUILD_ROOT}/tmp"
BUILD_LIB="${BUILD_ROOT}/lib"
BUILD_CONFIG="${BUILD_ROOT}/etc"

SUDO_PATH=${SUDO_PATH:-'/usr/bin/sudo'}

###
### Default SSL Certificate and CA values.
###
# Used in the CA templates.
CERT_COUNTRY=""
CERT_LOCATION=""
CERT_STATE=""
CERT_ORGANIZATION=""
CERT_ORGANIZATION_UNIT=""
# ROOT CA NAME is used for filenames so COMMON_NAME can be more meaningful.
ROOT_CA_NAME=""
ROOT_CA_COMMON_NAME=""
# INTERMEDIATE CA NAME is used for filenames so COMMON_NAME can be more meaningful.
INTER_CA_NAME=""
INTER_CA_COMMON_NAME=""

###
### Default non-root user to use for sudo based installation.
###
ADMINUSER="ubuntu"
