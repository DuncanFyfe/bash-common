#!/bin/bash
# Create a new Certificate Authority (CA) if one does not exist.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh
load 'cfssl' 'cfssl.sh'
assert_directory $BUILD_ROOT
assert_file $CFSSL
assert_file $CFSSLJSON
makedir $CFSSL_CA_DIR

root_ca_name=$1
root_ca_name=${root_ca_name:-$ROOT_CA_NAME}

common_name=$2
common_name=${common_name:-$ROOT_CA_COMMON_NAME}

get_certificate_file_names root_ca $root_ca_name
debugenv 'create_certificate_authority' root_ca_key_pem root_ca_pem root_ca_csr

if [ ! -f "$root_ca_key_pem" -a ! -f "$root_ca_pem" -a ! -f "$root_ca_csr" ]; then
  debug 'Creating new ROOT CA.'

  # Where to copy the templates to.
  get_template root_ca_config_t cfssl 'root-ca-config.json'
  get_build root_ca_config cfssl "$root_ca_name-ca-config.json"
  copy_template $root_ca_config_t $root_ca_config

  get_template root_ca_csr_t cfssl 'root-ca-csr.json'
  get_build root_ca_csr cfssl "$root_ca_name-ca-csr.json"
  COMMON_NAME=$common_name
  copy_template $root_ca_csr_t $root_ca_csr CERT_COUNTRY CERT_LOCATION CERT_STATE CERT_ORGANIZATION CERT_ORGANIZATION_UNIT COMMON_NAME

  debugenv 'create_root_ca' root_ca_config root_ca_csr

  cd $CFSSL_CA_DIR
  root_ca_csr=$(basename $root_ca_csr)
  root_ca_config=$(basename $root_ca_config)

  debug "CMD: cfssl gencert -initca $root_ca_csr | cfssljson -bare ${root_ca_name} -"
  cfssl gencert -initca $root_ca_csr | cfssljson -bare ${root_ca_name} -
  assert_ca $root_ca_name
  chmod 0600 $root_ca_key_pem

elif [ -f "$root_ca_key_pem" -a -f "$root_ca_pem" -a -f "$root_ca_csr" ]; then
  debug "CA $root_ca_name already exists.  Checking."
  assert_ca $root_ca_name
else
  echo "Partial CA $root_ca_name already exists.  Cannot continue."
  [ -f "$root_ca_key_pem" ] && echo "$root_ca_key_pem already exists."
  [ -f "$root_ca_pem" ] && echo "$root_ca_pem already exists."
  [ -f "$root_ca_csr" ] && echo "$root_ca_csr already exists."
  exit $ERR_CA_UNCLEAN
fi

debug_end
