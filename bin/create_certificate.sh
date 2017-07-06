#!/bin/bash
### Use an existing certificate authority to create server, client or peer
### certificates.
###
### By default the common name (CN) is set to ${cert_node_name}-${srv_profile}.
### For server and peer certificates a comma separated list of hostnames is
### required.  
#
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
# *node_name* identifes the node onto which this certificate will be deployed or
# a user identifier for user authentication certificates
# *service_name* is the hostname for servers, the client service name from client
# certificates or a user identifier for user authentication certificates.
# *service* is the name of the service the certificate is for (eg. etcd)
# *ca_name* is the name of the certificate authority to sign this certificate.
# *ca_profile*  is the certificate authority profile to be used (eg. peer or
# client or server).
#
# The *node_name* and *service_name* may be different, especially when deploying
# to machines with public and private network multiple interfaces.
#
# Examples:
#   user01 etcdctl etcd client
#   node01 etcdproxy etcd peer
#   public.example.com private.example.com nginx server
#
# Additional arguments are taken as additional certificate hostnames.

# The target node for distribution (not necessarily the same as "common name")
# For user certificates put the user name (identifier) here.
node_name=$1
node_name=${node_name:-$NODE_NAME}

# The CA to use to issue this certificate.
ca_name=$2
ca_name=${ca_name:-INTER_CA_NAME}
assert_var ca_name

# The certificate authority profile the certificate should be created with
# eg. client|server|peer
ca_profile=$3
ca_profile=${ca_profile:-$CA_PROFILE}
assert_var ca_profile

# The same common name can have multiple certificates for different services
# eg. example.com (etcd server), example.com (web server)
# service_name does not affect the created certificates but is used to avoid
# filename conflicts.
service_name=$4
service_name=${service_name:SERVICE_NAME}

common_name=$5
common_name=${common_name:-$COMMON_NAME}
assert_var common_name

# Alternative certificate host names - must be concatenated with ',' as
# separator.
join_by cert_hostnames ',' ${@:6}
cert_hostnames=${cert_hostnames:$CERT_HOSTNAMES}

# Create a form of the common name which can be used to help make
# filenames unique.
_name=$(echo -n $common_name | tr -c '[[:alnum:]]._-' '_')
cert_name="${_name}-${service_name}-${ca_profile}"
get_certificate_file_names cert ${cert_name}

if [ ! -f "$cert_key_pem" -a ! -f "$cert_pem" -a ! -f "$cert_csr" ]; then
  debug "Creating new certificate for $node_name CN=${common_name}."
  cd $CFSSL_CA_DIR

  # Empty hostnames is normal for clients.
  # Default servername is the same as the common name.
  hostnames=""
  if [ "X$cert_hostnames" != "X" ]; then
    _hostnames=$(echo "$cert_hostnames" | tr ' ' ',' | sort -u | tr '\n' ' ')
    hostnames="-hostname=$cert_hostnames"
  fi

  get_pernode_build cert_csr $node_name 'cfssl' "${cert_name}-csr.json"
  # Possible locations for csr.json files.
  # Take the first that exists.
  if [ ! -f $cert_csr ]; then
    # Possible configurations... yes, I could add more but
    # I don't need to.
    get_pernode_config ncfg1 $node_name "${cert_name}-csr.json"
    get_pernode_config ncfg2 $node_name "certificate-csr.json"
    get_config ccfg1 'cfssl' "${cert_name}-csr.json"
    get_config ccfg2 'cfssl' "certificate-csr.json"
    # Possible templates.
    get_pernode_template ntp1 $node_name "${cert_name}-csr.json"
    get_pernode_template ntp2 $node_name "certificate-csr.json"
    get_template ctp1 'cfssl' "${cert_name}-csr.json"
    get_template ctp2 'cfssl' "certificate-csr.json"

    first_of default_csr_t $ncfg1 $ncfg2 $ccfg1 $ccfg2  $ntp1 $ntp2 $ctp1 $ctp2

    # If we found one copy it with template substitution of CSR fields.
    if [ "X$default_csr_t" != "X" ]; then
      makedir $(dirname $cert_csr)
      copy_template $default_csr_t $cert_csr CERT_COUNTRY CERT_LOCATION CERT_STATE CERT_ORGANIZATION CERT_ORGANIZATION_UNIT COMMON_NAME
    fi

  fi
  assert_file $cert_csr

  # Certificate authority files.
  get_ca_config_json the_ca $ca_name
  get_certificate_file_names the_ca $ca_name

  # Generate the certificates
  echo "cfssl gencert -ca=$the_ca_pem -ca-key=$the_ca_key_pem -config=$the_ca_config_json -profile=$ca_profile $hostnames $cert_csr | cfssljson -bare $cert_name"

  cfssl gencert -ca=$the_ca_pem -ca-key=$the_ca_key_pem -config=$the_ca_config_json -profile=$ca_profile $hostnames $cert_csr | cfssljson -bare $cert_name

  # Checking the certificate needs the combined root and intermediate pem files.
  assert_certificate ${cert_name} $ca_name
  chmod 0600 ${cert_key_pem}

elif [ -f "${cert_key_pem}" -a -f "${cert_pem}" -a -f "${cert_csr}" ]; then
  echo "Certificate for ${cert_name} already exists."
  assert_certificate ${cert_name} $ca_name
else
  echo "Partial certificate setup already exists for ${common_name}.  Cannot continue."
  [ -f "${cert_key_pem}" ] && echo "${cert_key_pem} already exists."
  [ -f "${cert_pem}" ] && echo "${cert_pem} already exists."
  [ -f "${cert_csr}" ] && echo "${cert_csr} already exists."
  exit $ERR_CA_UNCLEAN
fi

# Create full chain pem
get_certificate_file_names chain "${cert_name}-chain"
if [ ! -f "$chain_pem" ]; then
  get_certificate_file_names ca_chain "${ca_name}-chain"
  if [ ! -f "$ca_chain_pem" ]; then
    ca_chain_pem=$the_ca_pem
  fi
  debug "cat $ca_chain_pem $cert_pem > $chain_pem"
  cat $ca_chain_pem $cert_pem > $chain_pem
fi
# Copy the certificate to the distribution folders

get_pernode_dist dist_dir $node_name 'ssl'
makedir $dist_dir
cp ${cert_key_pem} ${dist_dir}/$(basename $cert_key_pem)
cp ${cert_pem} ${dist_dir}/$(basename $cert_pem)
cp ${cert_csr} ${dist_dir}/$(basename $cert_csr)
cp $chain_pem ${dist_dir}/$(basename $chain_pem)

debug_end
