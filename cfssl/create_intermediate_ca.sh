#!/bin/bash
# Create a new Certificate Authority (CA) if one does not exist.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'cfssl' 'cfssl.sh'
load 'nodes' 'nodes.sh'
assert_directory $BUILD_ROOT
assert_file $CFSSL
assert_file $CFSSLJSON

root_ca_name=$1
root_ca_name=${root_ca_name:-$ROOT_CA_NAME}

inter_ca_name=$2
inter_ca_name=${inter_ca_name:-$INTER_CA_NAME}

common_name=$3
common_name=${common_name:-$INTER_CA_COMMON_NAME}


assert_var root_ca_name
assert_var inter_ca_name
if [ "X$root_ca_name" = "X$inter_ca_name" ]; then
  error $ERR_CA_NAME "ROOT_CA_NAME=INTER_CA_NAME=$inter_ca_name"
fi

get_certificate_file_names root_ca $root_ca_name
debugenv 'create_intermediate_ca' root_ca_key_pem root_ca_pem root_ca_csr
echo "root_ca_pem=$root_ca_pem"

get_certificate_file_names inter_ca $inter_ca_name
debugenv 'create_intermediate_ca' inter_ca_key_pem inter_ca_pem inter_ca_csr

if [ ! -f "$inter_ca_key_pem" -a ! -f "$inter_ca_pem" -a ! -f "$inter_ca_csr" ]; then
  echo "Creating new intermediate authority ${inter_ca_name}"
  cd $CFSSL_CA_DIR

  # Root CA configs
  get_ca_config_json root_ca $root_ca_name
  debugenv 'create_intermediate_ca' root_ca_config_json root_ca_csr_json

  # Where to copy the templates to.
  get_ca_config_json inter_ca ${inter_ca_name}
  debugenv 'create_intermediate_ca' inter_ca_config_json inter_ca_csr_json

  # Where to copy the templates to.
  get_template inter_ca_config_t cfssl 'inter-ca-config.json'
  get_build inter_ca_config cfssl "${inter_ca_name}-ca-config.json"
  copy_template $inter_ca_config_t $inter_ca_config

  get_template inter_ca_csr_t cfssl 'inter-ca-csr.json'
  get_build inter_ca_csr cfssl "${inter_ca_name}-ca-csr.json"
  COMMON_NAME=$common_name
  copy_template $inter_ca_csr_t $inter_ca_csr CERT_COUNTRY CERT_LOCATION CERT_STATE CERT_ORGANIZATION CERT_ORGANIZATION_UNIT COMMON_NAME

  debugenv 'create_intermediate_ca' inter_ca_config inter_ca_csr

  # Root CA generates Intermediate CA certificates
  debug "cfssl gencert -ca=$root_ca_pem -ca-key=$root_ca_key_pem -config=$root_ca_config_json -profile=\"intermediate\" $inter_ca_csr_json | cfssljson -bare ${inter_ca_name}"
  cfssl gencert -ca=$root_ca_pem -ca-key=$root_ca_key_pem -config=$root_ca_config_json -profile="intermediate" $inter_ca_csr_json | cfssljson -bare ${inter_ca_name}
  assert_ca ${inter_ca_name} ${root_ca_name}
  chmod 0600 $inter_ca_key_pem

elif [ -f "$inter_ca_key_pem" -a -f "$inter_ca_pem" -a -f "$inter_ca_csr" ]; then
  echo "CA ${inter_ca_name} already exists."
  assert_ca ${inter_ca_name} ${root_ca_name}
else
  echo "Partial CA ${inter_ca_name} already exists.  Cannot continue."
  [ -f "$inter_ca_key_pem" ] && echo "$inter_ca_key_pem already exists."
  [ -f "$inter_ca_pem" ] && echo "$inter_ca_pem already exists."
  [ -f "$inter_ca_csr" ] && echo "$inter_ca_csr already exists."
  exit $ERR_CA_UNCLEAN
fi
#Create combined certificate authority pem.
get_certificate_file_names chain "${inter_ca_name}-chain"
if [ ! -f $chain_pem ]; then
  cat $root_ca_pem $inter_ca_pem > $chain_pem
fi

debug_end
