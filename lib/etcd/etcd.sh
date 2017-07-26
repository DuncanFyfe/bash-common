function make_cluster_token {
  local _filename="${BUILD_RUN}/etcd_cluster_token.sh"
  local _t=$(uuid)
  echo "export ETCD_CLUSTER_TOKEN=${_t}" > $_filename
}

function get_cluster_token {
  local _var=$1
  assert_var _var
  local _filename="${BUILD_RUN}/etcd_cluster_token.sh"
  if [ ! -f ${_filename} ]; then
      make_cluster_token
      assert_file ${_filename}
  fi
  _val=$(head -n 1 ${_filename} | cut -d= -f2)
  eval "export ${_var}=${_val}"
}

function etcd_template_substitution {
  local _filename=$1
  assert_var _filename
  local _val
  local _var

  # NODE_IP_ADDR comes straight from the sourced configuration file.
 local _keys='ETCD_ADVERTISE_CLIENT_URLS ETCD_AUTO_COMPACTION_RETENTION  ETCD_DATA_DIR ETCD_DEBUG ETCD_LISTEN_CLIENT_URLS ETCD_LISTEN_PEER_URLS ETCD_NAME ETCD_PEER_CLIENT_CERT_AUTH ETCD_PROXY ETCD_DISCOVERY_SRV ETCD_INITIAL_ADVERTISE_PEER_URLS ETCD_INITIAL_CLUSTER_STATE ETCD_INITIAL_CLUSTER_TOKEN RKT_ETCD_IMAGE ETCD_SSL_DIR ETCD_CA INTER_CA_NAME server_pem server_key_pem peer_pem peer_key_pem node_ca_pem locksmithd_pem locksmithd_key_pem etcd_systemd locksmithd_systemd etcd_override etcd_options locksmithd_override locksmithd_options deploy_etcd'

 template_substitution $_filename $_keys
}

function copy_etcd_template {
  local _var=$1
  assert_var _var
  local _basename=$2
  assert_var _basename
  local _nodename=$3
  assert_var _nodename
  local _template
  local _dest
  get_template _template 'etcd' "$_basename"
  assert_file $_template
  get_pernode_export_path _dest $_nodename "$_basename"
  debugenv 'copy_etcd_config' _f _template _dest
  cp $_template $_dest
  assert_file $_dest
  etcd_template_substitution $_dest
  debug "Wrote etcd template $_template to $_dest."
  eval "export ${_var}=${_dest}"
}
