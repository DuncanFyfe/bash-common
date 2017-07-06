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

# Create the certificate authority
debug "$SCRIPT_NAME//BEGIN Create Intermediate Certificate Authorities."
echo "$SCRIPT_DIR/create_root_ca.sh $root_ca_name"
$SCRIPT_DIR/create_root_ca.sh $root_ca_name
echo "get_certificate_file_names root_ca $root_ca_name"
get_certificate_file_names root_ca $root_ca_name

debug "$SCRIPT_NAME//END Create Intermediate Certificate Authorities."

get_dist cfssl_dir 'cfssl'
makedir $cfssl_dir

get_certificate_file_names top ${root_ca_name} $cfssl_dir

cp ${root_ca_key_pem} ${top_key_pem}
cp ${root_ca_csr} ${top_csr}
cp ${root_ca_pem} ${top_pem}

nodes=$(echo "$ALL_NODES" | tr ',' '\n' | sort -u | tr '\n' ' ')
for node in $nodes; do
  debug "BEGIN NODE $node"
  get_pernode_dist dist_dir $node 'ssl'
  makedir $dist_dir

  get_certificate_file_names dist ${root_ca_name} $dist_dir

  cp ${root_ca_pem} ${dist_pem}
  debug "END NODE $node"
done

debug_end
