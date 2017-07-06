function debugcfsslca {
  debugenv "debugcfsslca" CFSSL_VERSION CFSSL_DOWNLOAD CFSSLJSON_DOWNLOAD CFSSL CFSSLJSON CFSSL_CA_DIR
}

function get_ca_config_json {
  # Try to find a CA json configuration files for cfssl.
  local _var=$1
  local _name=$2
  debugenv 'get_ca_config_json' _var _name
  assert_var _var
  assert_var _name
  local _config_json="${_var}_config_json"
  local _csr_json="${_var}_csr_json"
  eval "export ${_config_json}=${CFSSL_CA_DIR}/${_name}-ca-config.json"
  eval "export ${_csr_json}=${CFSSL_CA_DIR}/${_name}-ca-csr.json"
}

function get_certificate_file_names {
  # Get the names of certificate files to make it easy to find them.
  # Naming convention:
  # Certificate authority files using the certificate authority name.
  # Service certificates are given filenames of the form:
  # ${hostname}-${service}-${ca_profile}
  # because a service like etcd can have server, client and/or peer certificates
  # on the same host for the same service.
  # For service as a client certificates (eg. flannel as an etcd client) names # are of the from:
  # ${client service name}-${server service name}-${ca_profile}
  # eg. flanneld-etcd-client
  # For user client certificates (eg. for authentication) we construct the name
  # from: ${userid}-${service}-${ca_profile}
  #
  # This function just blindly builds a name from the input arguments.
  #
  #
  local _var=$1
  local _name=$2
  assert_var _var
  assert_var _name
  local _dir=$3
  _dir=${_dir:-$CFSSL_CA_DIR}
  join_by _fullname '-' $_name ${@:4}
  local _key_pem="${_var}_key_pem"
  local _pem="${_var}_pem"
  local _csr="${_var}_csr"
  eval "export ${_key_pem}=${_dir}/${_fullname}-key.pem"
  eval "export ${_pem}=${_dir}/${_fullname}.pem"
  eval "export ${_csr}=${_dir}/${_fullname}.csr"
}

function assert_ca {
  # Check that the necessary CA files are present.
  # This is a precursor to generating new certificates rather than
  # certificating a new CA.
  local _test_ca_name=$1
  debugenv _test_ca_name
  assert_var _test_ca_name
  local _parent_ca_name=$2
  if [ "X$_parent_ca_name" = "X" ]; then
    _parent_ca_name=$_test_ca_name
  fi
  debugenv 'assert_ca' _test_ca_name _parent_ca_name
  assert_directory "${CFSSL_CA_DIR}"
  get_certificate_file_names _parent ${_parent_ca_name}
  get_certificate_file_names _test ${_test_ca_name}

  assert_file "$_parent_pem"
  assert_file "$_test_key_pem"
  assert_file "$_test_pem"

  # Check the public keys are the same.
  local _x509=$(openssl x509 -pubkey -in $_test_pem -noout  | openssl md5)
  local _pkey=$(openssl pkey -in $_test_key_pem -pubout | openssl md5)
  if [ "X$_x509" != "X$_pkey" ]; then
    debug "Public key in pem does not match that in the key.pem."
    debug "Failed assert ca: ${_test_ca_name}."
    exit $ERR_VERIFY_CA
  fi
  # Check the test pem was signed by the parent pem.
  local _expected="${_test_pem}: OK"
  local _verify=$(openssl verify -CAfile $_parent_pem -verbose $_test_pem)
  if [ "X$_verify" != "X$_expected" ]; then
    debug "Failed to verify $_test_pem was signed by $_parent_pem"
    debug "Failed assert ca: ${_test_ca_name}."
    exit $ERR_VERIFY_CA
  fi
  debugenv "assert_ca" CFSSL_CA_DIR _test_key_pem _test_pem
}

function assert_certificate {
  # Arguments: certificate_name ca_name
  # Test if the certificates found suing the certificate_name were signed
  # by the named CA.
  local _cert_name=$1
  assert_var _cert_name
  local _ca_name=$2
  assert_var _ca_name
  debugenv 'assert_certificate' _cert_name _ca_name
  assert_directory "${CFSSL_CA_DIR}"
  get_certificate_file_names _cert ${_cert_name}
  debugenv 'assert_certificate' _cert_pem _cert_key_pem
  assert_file "$_cert_key_pem"
  assert_file "$_cert_pem"
  # Check the public keys are the same.

  local _x509=$(openssl x509 -pubkey -in $_cert_pem -noout  | openssl md5)
  local _pkey=$(openssl pkey -in $_cert_key_pem -pubout | openssl md5)
  if [ "X$_x509" != "X$_pkey" ]; then
    error $ERR_VERIFY_CA "Public key in pem does not match that in the key.pem. Failed assert certificate: ${_cert_name}."
  fi

  # Check the test pem was signed by the CA pem.
  # Look for a full chain pem first.
  # If that doesn't exist, use the CA pem directly.
  get_certificate_file_names _ca "${_ca_name}-chain"

  if [ ! -f "$_ca_pem" ]; then
    get_certificate_file_names _ca ${_ca_name}
  fi

  local _expected="${_cert_pem}: OK"
  debug "openssl verify -CAfile $_ca_pem -verbose $_cert_pem"
  local _verify=$(openssl verify -CAfile $_ca_pem -verbose $_cert_pem)
  if [ "X$_verify" != "X$_expected" ]; then
    debug "expected=$_expected"
    debug "actual  =$_verify"
    error $ERR_VERIFY_CA "Failed to verify $_cert_pem was signed by $_ca_pem. Failed assert certificate: ${_cert_name}."
  fi
}
