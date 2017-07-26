function flanneld_template_substitution {
  local _filename=$1
  assert_var _filename
  local _val
  local _var
  # NODE_IP_ADDR comes straight from the sourced configuration file.
 local _keys='ADVERTISE_IP ETCD_ENDPOINTS ETCD_SSL_DIR FLANNELD_SSL_DIR FLANNEL_CA INTER_CA_NAME flanneld_pem flanneld_key_pem client_pem client_key_pem node_ca_pem flanneld_override flanneld_options flanneld_docker_options flanneld_docker_opts_override flanneld_docker_opts_options'

  template_substitution $_filename $_keys
}

function copy_flanneld_template {
  local _var=$1
  assert_var _var
  local _basename=$2
  assert_var _basename
  local _template
  local _dest
  get_template _template 'flanneld' "$_basename"
  assert_file $_template
  get_pernode_export_path _dest $primary_nodename "$_basename"
  debugenv 'copy_flanneld_template' _f _template _dest
  cp $_template $_dest
  assert_file $_dest

  flanneld_template_substitution $_dest
  eval "export ${_var}=${_dest}"
  debug "Wrote flanneld template $_template to $_dest."
}


function kube_template_substitution {
  local _filename=$1
  assert_var _filename
  local _var
  local _val
  # NODE_IP_ADDR comes straight from the sourced configuration file.
  local _keys='ETCD_SSL_DIR KUBE_SSL_DIR CONTROLLER_ENDPOINT ETCD_ENDPOINTS NODE_IP_ADDR ETCD_CA INTER_CA_NAME apiserver_pem apiserver_key_pem node_ca_pem kube_mode etcdclient_pem etcdclient_key_pem worker_pem worker_key_pem'

  template_substitution $_filename $_keys

}

function copy_kubernetes_template {
  local _var=$1
  assert_var _var
  local _basename=$2
  assert_var _basename
  local _template
  local _dest
  get_template _template 'kubernetes' "$_basename"
  assert_file $_template
  get_pernode_export_path _dest $primary_nodename "$_basename"
  debugenv 'copy_kubernetes_template' _f _template _dest
  cp $_template $_dest
  assert_file $_dest

  kube_template_substitution $_dest
  eval "export ${_var}=${_dest}"
  debug "Wrote kubernetes template $_template to $_dest."
}
