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

# Create the certificate authority
debug "$SCRIPT_NAME//BEGIN Create Intermediate Certificate Authorities."
$SCRIPT_DIR/create_intermediate_ca.sh $root_ca_name $inter_ca_name $common_name
debug "$SCRIPT_NAME//END Create Intermediate Certificate Authorities."

get_dist cfssl_dir 'cfssl'
makedir $cfssl_dir

get_certificate_file_names inter_ca ${inter_ca_name}
get_certificate_file_names top ${inter_ca_name} $cfssl_dir
get_certificate_file_names chain "${inter_ca_name}-chain"
get_certificate_file_names top_chain "${inter_ca_name}-chain" $cfssl_dir

cp ${inter_ca_key_pem} ${top_key_pem}
cp ${inter_ca_csr} ${top_csr}
cp ${inter_ca_pem} ${top_pem}
cp ${chain_pem} ${top_chain_pem}

nodes=$(echo "$ALL_NODES" | tr ',' '\n' | sort -u | tr '\n' ' ')
for node in $nodes; do
  debug "BEGIN NODE $node"
  get_pernode_dist dist_dir $node 'ssl'
  makedir $dist_dir

  get_certificate_file_names dist ${inter_ca_name} $dist_dir

  get_certificate_file_names chain_dist "${inter_ca_name}-chain" $dist_dir

  cp ${inter_ca_pem} ${dist_pem}
  cp ${chain_pem} ${chain_dist_pem}
  debug "END NODE $node"
done
debug_end
