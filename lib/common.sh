# This is a bash library of useful functions.
# Index:
#      debug
#      debugenv
#      debug_begin
#      debug_end
#      error
#      assert_var
#      assert_file
#      assert_directory
#      assert_exists
#      assert_user
#      assert_group
#      makedir
#      make_password
#      add_password
#      join_by
#      first_of
#      getipaddr4
#      get_dist
#      get_pernode_dist
#      get_build
#      get_pernode_build
#      get_lib
#      get_pernode_lib
#      get_config
#      get_pernode_config
#      load
#      load_pernode
#      get_template
#      get_pernode_template
#      find_template
#      template_substitution
#      copy_template
#      make_timestamp
#      get_timestamp
#      withsudo
#      distcheck
#      forceddelete

#
function debug {
  # Arguments: debug message strings
  # If LOG_LEVEL contains the substring "DEBUG" _AND_
  # (DEBUG==ALL _OR_ DEBUG contains the scriptname as a substring)
  # then echo the debug message.
  if [ "X${LOG_LEVEL#*DEBUG}" != "X$LOG_LEVEL" ]; then
    if [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ]; then
      local _tag=$SCRIPT_NAME
      echo "#DEBUG[$_tag] $@" 1>&2
    fi
  fi
}

function debugenv {
  # Arguments: variable_name(s)
  # If debugging is active echo the variable names and their
  # environment variable values.
  if [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ]; then
    for _e in $@; do
      eval _v=\$${_e}
      echo "#DEBUG[$SCRIPT_NAME] ${_e}=${_v}" 1>&2
    done
  fi
}

function debug_begin {
  # Arguments: sero or more supplimentary messages
  # Issue a debug identifier at the beginning of a script.
  # This should be used as a copy and paste template as you
  # probably want it to run before this library is loaded.
  [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "#DEBUG[$SCRIPT_NAME] BEGIN SCRIPT ${@:1}" 1>&2
}

function debug_end {
  # Arguments: Zero or more supplimentary messages
  # Convenience function to issue a debug identifier at the end of a script.
  # The begining of a script is identified before this library is loaded.
  debug "#DEBUG[$SCRIPT_NAME] END SCRIPT ${@:1}"
}

function error {
  # Arguments: status error [zero or more message strings]
  # Echo any given given error message and exit with the given status.
  # A default error status and message are used where either is not given.
  local _status=$1
  _status=${_status:-$ERR_UNKNOWN}
  local _errmsg="${@:2}"
  _errmsg=${_errmsg:="Exist Status $_status"}
  echo "#ERROR[$SCRIPT_NAME] $_errmsg" 1>&2
  exit $_status
}

function assert_var {
  # Arguments: one environment variable name
  # Test if the given environment variable is defined and of non-zero length
  # Exit with status $ERR_ASSERT_VAR if it is not.
  local _var="$1"
  eval _val=\$${_var}
  debugenv 'assert_var' $_var
  if [ "X${_val}" == "X" ]; then
    error $ERR_ASSERT_VAR "Failed assert var: ${_var}"
  fi
}

function assert_file {
  # Arguments: one filename with path relative to $CWD.
  # Test if the given path is a filename and exists
  # Exit with status $ERR_ASSERT_FILE if it is not.
  local _f="$1"
  debugenv 'assert_file' _f
  if [ "X${_f}" = "X" -o ! -f "${_f}" ]; then
    error $ERR_ASSERT_FILE "Failed assert file: ${_f}"
  fi
}

function assert_directory {
  # Arguments: one directory with path relative to $CWD.
  # Test if the given path is a directory and exists
  # Exit with status $ERR_ASSERT_DIRECTORY if it is not.
  local _f="$1"
  debugenv 'assert_directory' _f
  if [ "X${_f}" != "X" -a ! -d "${_f}" ]; then
    error $ERR_ASSERT_DIRECTORY "Failed assert directory: ${_f}"
  fi
}

function assert_exists {
  # Arguments: one filesystem path relative to $CWD.
  # Test if the given path exists (but we don't care what it is)
  # Exit with status $ERR_ASSERT_VAR if it is not.
  local _f="$1"
  debugenv 'assert_exists' _f
  if [ "X${_f}" != "X" -a ! -e "${_f}" ]; then
    error $ERR_ASSERT_DIRECTORY "Failed assert exists: ${_f}"
  fi
}

function assert_user {
  # Arguments: one system user name.
  # Test if the given group exists (but we don't care what it is)
  # Exit with status $ERR_ASSERT_USER  if it is not.
  local _u="$1"
  debugenv 'assert_user' _u
  assert_var _u
  local _e=$(getent passwd $_u)
  if [ "X${_e}" = "X" ]; then
    error $ERR_ASSERT_USER "Failed assert user: ${_u}"
  fi
}

function assert_group {
  # Arguments: one system group name.
  # Test if the given user exists (but we don't care what it is)
  # Exit with status $ERR_ASSERT_GROUP if it is not.
  local _g="$1"
  debugenv 'assert_user' _g
  assert_var _g
  local _e=$(getent group $_g)
  if [ "X${_e}" = "X" ]; then
    error $ERR_ASSERT_GROUP "Failed assert group: ${_g}"
  fi
}

function makedir {
  # Arguments: one directory with path relative to $CWD.
  # Create a directory path then verify that is was created.
  local _d="$1"
  debugenv "makedir" _d
  if [ "X${_d}" != "X" ];then
    if [ ! -d ${_d} ]; then
      mkdir -p ${_d}
      assert_directory "${_d}"
    fi
  fi
}

function make_password {
  # Arguments: one variable_name and zero or one integer
  # Use openssl to generate a password of base64 characters.
  local _var=$1
  assert_var _var
  local _len=${2:-32}
  local _val=$(openssl rand -base64 $_len | tr -d '[:space:]' | head -c$_len)
  eval "export ${_var}=${_val}"
}

function add_password {
  # Arguments: hostname username password
  # Services behind nginx-proxy can be given basic authentication at the
  # proxy.  This is useful for protecting services which start with a default
  # account or admin password entry.
  # The proxy-side basic authentication can be removed by deleting the htpasswd
  # file for the appropriate host.
  local _hostname=$1
  assert_var _hostname
  local _username=$2
  assert_var _username
  local _password=$3
  assert_var _password

  passwdfile="$NGINX_PROXY_ROOT/htpasswd/${_hostname}"
  docker run --rm --entrypoint htpasswd registry:2 -Bbn $_username $_password >> $passwdfile
  assert_file $passwdfile
}

function join_by {
  # Arguments: variable_name join_string string(s)
  # Join the ${@:3} into a single string using $2 as the separator.
  # Assign the result to the variable name given by $1.
  # This uses bash IFS concatenation using IFS
  local _var="$1"
  assert_var _var
  local IFS="$2"
  shift;shift
  # Yes, this has to be $* and not $@.
  local _val=$(echo "$*")
  eval "export ${_var}=${_val}"
  debugenv "join_by" _var IFS _val
}

function first_of {
  # Arguments: variable_name path(s)
  # Loop over the paths and assign the first one which exists to the
  # variable_name of the given name.
  local _var=$1
  for _e in ${@:2}; do
    echo "_e=$_e"
    if [ -e $_e ]; then
      eval "export ${_var}=${_e}"
      break
    fi
  done
}

function getipaddr4 {
  # Arguments: variable_name hostname
  # Get the (an ?) IP address for the given hostname in a way which uses
  # /etc/hosts (such as private IP address hostnames).
  # Assign the IP address to the given variable name.
  local _var=$1
  assert_var _var
  local _h=$2
  assert_var _h
  local _ip=$(getent ahostsv4 "$_h" | awk '{ print $1 }' | sort | uniq)
  join_by _val "," ${_ip}
  eval "export ${_var}=${_val}"
  debugenv "getipaddr4" _var _val _h _ip
}

function get_dist {
  # Arguments: variable_name section extras
  # Get an distribution path to the given section item.
  # The distribution path is a directory or file for common output
  # we expect to be able to export (copy) to more than one machine
  # It MUST not be node specific.
  assert_var DIST_ROOT
  local _var=$1
  assert_var _var
  local _sectname=$2
  assert_var _sectname
  join_by _path '/' ${DIST_ROOT} $_sectname ${@:3}
  eval "export ${_var}=${_path}"
  debugenv "get_dist" _var _sectname _path
}

function get_pernode_dist {
  # Arguments: variable_name nodename extras
  # Get an distribution path for the given node.
  # The distribution path is a directory or file for
  # node-specific output we expect to be able to export (copy)
  # to the given node.
  # The content MUST be node specific.
  get_dist $1 'nodes' ${@:2}
}

function get_build {
  # Arguments: variable_name section extras
  # Get a build path to the given section item.
  # The build path is a directory or file for output being
  # created by the build process.
  # It MUST not be node specific.
  #  This build path should conta


  assert_var BUILD_ROOT
  local _var=$1
  assert_var _var
  local _sectname=$2
  assert_var _sectname
  join_by _path '/' ${BUILD_ROOT} $_sectname ${@:3}
  eval "export ${_var}=${_path}"
  debugenv "get_build" _var _sectname _path
}

function get_pernode_build {
  # Arguments: variable_name nodename extras
  # Get an export path to the given node.
  # The export path is a directory or file for node-specific output we expect
  # to be able to export (copy) to the given node.
  # It MUST be node specific.
  get_build $1 'nodes' ${@:2}
}

function get_lib {
  # Arguments: variable_name section extras
  # Get a config path to the given section item.
  # The config path is a directory or file for common configurations on the
  # admin node (rather than a target node) which is not node specific.
  local _var=$1
  assert_var _var
  local _sectname=$2
  assert_var _sectname
  join_by _path '/' ${PROJECT_LIB} $_sectname ${@:3}
  eval "export ${_var}=${_path}"
  debugenv "get_lib" _var _sectname _path
}

function get_pernode_lib {
  # Arguments: variable_name nodename extras
  # Get a node specific config path.
  # The config path is a directory or file for node-specific configurations on
  # the admin node (rather than a target node) which is not node specific.
  _var=$1
  assert_var _var
  get_lib _path "nodes" ${@:2}
  eval "export ${_var}=${_path}"
  debugenv "get_pernode_lib" _var _path
}

function get_config {
  # Arguments: variable_name section extras
  # Get a config path to the given section item.
  # The config path is a directory or file for common configurations on the
  # admin node (rather than a target node) which is not node specific.
  local _var=$1
  assert_var _var
  local _sectname=$2
  assert_var _sectname
  _project_config=${PROJECT_CONFIG}
  _project_config=${_project_config:-"${PROJECT_ROOT}/config"}
  join_by _path '/' ${_project_config}  $_sectname ${@:3}
  eval "export ${_var}=${_path}"
  debugenv "get_config" _var _sectname _path
}

function get_pernode_config {
  # Arguments: variable_name nodename extras
  # Get a node specific config path.
  # The config path is a directory or file for node-specific configurations on
  # the admin node (rather than a target node) which is not node specific.
  _var=$1
  assert_var _var
  get_config _path "nodes" ${@:2}
  eval "export ${_var}=${_path}"
  debugenv "get_pernode_config" _var _path
}

function load {
  # Arguments: library_section zero or molre additional sub-levels
  # Source a shell common library and library configuration file.
  local _load_lib
  local _load_config
  get_lib _load_lib $@
  if [ -f "$_load_lib" ]; then
    debug "Found _load_lib=$_load_lib"
    . $_load_lib
  fi
  get_config _load_config $@
  if [ -f "$_load_config" ]; then
    debug "Found _load_config=$_load_config"
    . $_load_config
  fi
}

function load_pernode {
  # Arguments: node_name library_section zero or molre additional sub-levels
  # Source a per-node shell common library and library configuration file.
  local _load_lib
  local _load_config
  get_pernode_lib _load_lib $@
  if [ -f "$_load_lib" ]; then
    . $_load_lib
  fi
  get_pernode_config _load_config $@
  if [ -f "$_load_config" ]; then
    . $_load_config
  fi
}

function get_template {
  # Arguments: variable_name section extras
  # Get a config path to the given section item.
  # The config path is a directory or file for common configurations on the
  # admin node (rather than a target node) which is not node specific.
  local _var=$1
  assert_var _var
  local _sectname=$2
  assert_var _sectname
  _project_templates=${PROJECT_TEMPLATES}
  _project_templates=${_project_templates:-"${PROJECT_ROOT}/templates"}
  join_by _path '/' ${_project_templates} $_sectname ${@:3}
  eval "export ${_var}=${_path}"

  debugenv "get_config" _var _sectname _path
}

function get_pernode_template {
  # Arguments: variable_name nodename extras
  # Get a node specific config path.
  # The config path is a directory or file for node-specific configurations on
  # the admin node (rather than a target node) which is not node specific.
  get_template $1 'nodes' ${@:2}
}

function find_template {
  # Arguments: variable_name node section filename
  # Convenience function.
  # Look for the filename in:
  # node/section, node , section
  # and take the first one whic exists.
  # The point is to take the "most specialized" template for a task.
  local _var=$1
  assert_var _var
  local _node=$2
  assert_var _node
  local _section=$3
  assert_var _section
  local _filename=$4
  assert_var _filename
  get_pernode_template _first $_node $_section $_filename
  get_pernode_template _second $_node $_filename
  get_template _third $_section $_filename
  first_of $_var $_first $_second $_third
}

function template_substitution {
  # Arguments: filename ariable names...
  # For each variable name replace instances of "${VAR_NAME}" with the
  # value of the environment variable of that name in the given file.
  local _filename=$1
  assert_var _filename
  local _val
  local _var

  local _keys="${@:2}"
  for _var in $_keys; do
    eval _val=\$${_var}
    debug "$_var=$_val"
    sed -i -e"s!\${$_var}!$_val!g" $_filename
  done
}

function copy_template {
  # Copy a template and apply substitution.
  local _src=$1
  assert_var _src
  local _dest=$2
  assert_var _dest
  _tmpfile=${BUILD_TMP}/$(basename $_dest)
  rm -f $_tmpfile
  cp $_src $_tmpfile
  assert_file $_tmpfile
  template_substitution $_tmpfile ${@:3}
  cp $_tmpfile $_dest
  assert_file $_dest
}

function make_timestamp {
  # Write a timestamp to file.
  local _var=$1
  local _filename=$2
  _filename=${_filename:-"${BUILD_RUN}/current_timestamp.sh"}
  local _val=$(date --iso-8601="date")
  echo "export CURRENT_TIMESTAMP=${_val}" > $_filename
  assert_file ${_filename}
  if [ "X$_var" != "X" ]; then
    eval "export ${_var}=${_val}"
  fi
}

function get_timestamp {
  # Get the timestamp creating one if needed.
  local _var=$1
  assert_var _var
  local _filename=$2
  _filename=${_filename:-"${BUILD_RUN}/current_timestamp.sh"}
  if [ ! -f ${_filename} ]; then
    make_timestamp $_var ${_filename}
  else
    _val=$(head -n 1 ${_filename} | cut -d= -f2)
    eval "export ${_var}=${_val}"
  fi
}

function withsudo {
  # If you want to use this function feel free but I recommend you use it as
  # a cut and paste template (remove the "local" if it is going to be used
  # outside of a function).  To use this version directly you just wasted
  # time loading this shell library before relaunching and reloading it.
  #
  # To use as a template cut and paste the outer if/fi block near the
  # top of your script and remove the "local" since they cannot be used outside
  # of functions.
  #
  local _sudo=${SUDO_PATH:-'/usr/bin/sudo'}
  if [ "$(id -u)" != "0" ]; then
    [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "RESTARTING SCRIPT WITH SUDO: $_sudo $0 $@"
    exec $_sudo $0 $@
  fi
}

function distcheck {
  # Arguments: None
  # Get a Linux distribution identification string.
  local _var=$1
  assert_var _var
  local _dist=$2
  local _val=$(uname -a | grep -c $_dist)
  eval "export ${_var}=${_val}"
}

function forceddelete {
  # Arguments: One or more filesystem paths.
  # Force the deletion of a directory or files
  # with some sanity checks.
  local _loc
  for _loc in $@; do
    debug "Testing $_loc"
    if [ "X$_loc" != "X" -a -e $_loc ]; then
      _rloc=$(realpath $_loc)
      local _ok="TRUE"
      # Do not delete if $_loc is on this list.
      # No this isn't a complete sanity check but it helps.
      for chk in "X" "X/" "X$HOME"; do
        if [ "X$_rloc" = $chk ]; then
          _ok="FALSE"
          break
        fi
      done
      if [ $ok = "TRUE"  ]; then
        debug "Deleting $_loc"
        rm -rf $_loc
      fi
    fi
  done
}
# ERROR EXIT STATUSES
ERR_CA_UNCLEAN=1
ERR_CA_NAME=2
ERR_ASSERT_FILE=10
ERR_ASSERT_DIRECTORY=11
ERR_ASSERT_EXISTS=12
ERR_ASSERT_VAR=13
ERR_ASSERT_USER=14
ERR_ASSERT_GROUP=15
ERR_CERT_PROFILE=20
ERR_COMMON_NAME=21
ERR_VERIFY_CA=22
ERR_NO_CONTAINER=23
ERR_BAD_CONTAINER=24
ERR_NO_VOLUME=25
ERR_BAD_VOLUME=26
ERR_UNKNOWN=99
