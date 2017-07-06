function has_container {
  # has_container name var
  # Check whether a container by a given name exists.
  # If var is given set a variable by that name with the result.
  # Otherwise echo it.
  local _n="$1"
  local _var=$2
  debugenv "has_container" _n
  assert_var _n
  local _val=$(docker ps -a --filter "name=$_n" --format "{{.ID}}")
  if [ "X$_var" != "X" ]; then
    eval "export ${_var}=${_val}"
  else
    echo ${_val}
  fi
}
function has_docker_image {
  # has_container name var
  # Check whether a container by a given name exists.
  # If var is given set a variable by that name with the result.
  # Otherwise echo it.
  local _n="$1"
  local _var=$2
  debugenv "has_docker_image" _n
  assert_var _n
  local _val=$(docker images --filter="reference=$_n" --format "{{.ID}}")
  if [ "X$_var" != "X" ]; then
    eval "export ${_var}=${_val}"
  else
    echo ${_val}
  fi
}

function assert_container {
  # Test if a named container exists.
  # Exit with status $ERR_NO_CONTAINER if it is not.
  local _n="$1"
  has_container $_n _has_container
  if [ "X$_has_container" = "X" ]; then
    error $ERR_NO_CONTAINER "Failed assert container: ${_n}"
  fi
}

function rm_container {
  # Test if a named container exists and delete it.
  local _n="$1"
  has_container $_n _has_container
  if [ "X$_has_container" != "X" ]; then
    docker stop $_n
    docker rm $_n
    local _check
    has_container $_n $_check
    if [ "X$_check" != "X" ]; then
      error $ERR_BAD_CONTAINER "Removing container $_n failed."
    fi
  fi
}

function rm_docker_image {
  # has_container name var
  # Check whether a container by a given name exists.
  # If var is given set a variable by that name with the result.
  # Otherwise echo it.
  local _n="$1"
  has_docker_image $_n _has_docker_image
  if [ "X$_has_docker_image" != "X" ]; then
    docker rmi $_n
    local _check
    has_docker_image $_n $_check
    if [ "X$_check" != "X" ]; then
      error $ERR_BAD_CONTAINER "Removing docker image $_n failed."
    fi
  fi
}


function configure_systemd {
  # Arguments: service_name requires after
  # Use the template systemd.service to configre the running of a docker
  # service via systemd.  This function only setup the systemd script it
  # does not enable it or run it - sometimes they need manual tweaking.
  assert_directory $SYSYEMD_DIR
  local _s=$1
  local _r=$2
  local _a=$3
  local _force=$4
  get_template _f 'docker' 'systemd.service'
  local _f="$SYSYEMD_DIR/docker-container@${_s}.service"
  if [ ! -f $_f -o "X${_force}" != "X" ]; then
    cp $SCRIPT_DIR/systemd.service $_f
    sed -i -e"s/\${REQUIRES}/${_r}/g" $_f
    sed -i -e"s/\${AFTER}/${_a}/g" $_f
  fi
}

function enable_systemd {
  # Arguments: service_name
  # Enable a docker service via systemd.
  local _s=$1
  local _f="docker-container@${_s}.service"
  systemctl enable ${_f}
}
