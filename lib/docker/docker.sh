#
# Library functions useful when handling docker images, containers, volumes and
# systemd controlled docker services
#
function has_docker_container {
  # has_docker_container name var
  # Check whether a container by a given name exists.
  # If var is given set a variable by that name with the result.
  # Otherwise echo it.
  local _var=$1
  local _n="$2"
  assert_var _var
  assert_var _n
  local _val=$(docker ps -a --filter "name=$_n" --format "{{.ID}}")
  eval "export ${_var}=${_val}"
}

function assert_docker_container {
  # Test if a named container exists.
  # Exit with status $ERR_NO_CONTAINER if it is not.
  local _n="$1"
  has_docker_container _has_docker_container $_n
  if [ "X$_has_docker_container" = "X" ]; then
    error $ERR_NO_CONTAINER "Failed assert container: ${_n}"
  fi
}

function rm_container {
  # Arguments: container_name
  # Test if a named container exists and delete it.
  local _n
  for _n in $@; do
    has_docker_container _has_docker_container $_n
    if [ "X$_has_docker_container" != "X" ]; then
      docker stop $_n
      docker rm $_n
      local _check
      has_docker_container _has_docker_container $_n
      if [ "X$_check" != "X" ]; then
        error $ERR_BAD_CONTAINER "Removing container $_n failed."
      fi
    fi
  done
}

function has_docker_image {
  # Arguments: var name
  # Check whether a docker image by a given name exists.
  # And write the result into the given envirnment variable.
  local _var=$1
  local _n="$2"
  debugenv "has_docker_image" _n
  assert_var _var
  assert_var _n
  local _val=$(docker images --filter="reference=$_n" --format "{{.ID}}")
  eval "export ${_var}=${_val}"
}


function get_docker_image {
  # Arguments: variable image_name
  # Check whether a container by a given name exists.  If it does
  # return the underlying image id, an empty string otherwise.
  local _var=$1
  local _n="$2"
  debugenv "has_doget_docker_imagecker_image" _n
  assert_var _var
  assert_var _n
  has_docker_container _has_docker_container $_n
  if [ "X$_has_docker_container" != "X" ]; then
    local _val=$(docker ps -a --filter "name=$_n" --format "{{.Image}}")
    eval "export ${_var}=${_val}"
  else
    eval "export ${_var}=\"\""
  fi
}

function rm_docker_image {
  # Arguments image_name
  # Check whether a container by a given name exists.
  # If var is given set a variable by that name with the result.
  # Otherwise echo it.
  local _n
  for _n in $@; do
    has_docker_image _has_docker_image $_n
    if [ "X$_has_docker_image" != "X" ]; then
      docker rmi $_n
      local _check
      has_docker_image $_check $_n
      if [ "X$_check" != "X" ]; then
        error $ERR_BAD_CONTAINER "Removing docker image $_n failed."
      fi
    fi
  done
}


function has_docker_volume {
  # Arguments: var name
  # Check whether a docker image by a given name exists.
  # And write the result into the given envirnment variable.
  local _var=$1
  local _n="$2"
  assert_var _var
  assert_var _n
  local _val=$(docker volume ls --filter="name=$_n" --format "{{.Name}}")
  eval "export ${_var}=${_val}"
}

function assert_docker_volume {
  # Test if a named volume exists.
  # Exit with status $ERR_NO_VOLUME if it is not.
  local _n="$1"
  has_docker_container _has_docker_container $_n
  if [ "X$_has_docker_container" = "X" ]; then
    error $ERR_NO_CONTAINER "Failed assert container: ${_n}"
  fi
}

function get_docker_volume {
  # Arguments: variable volume_name
  # Check whether a container by a given name exists.  If it does
  # return the underlying image id, an empty string otherwise.
  local _var=$1
  local _n="$2"
  assert_var _var
  assert_var _n
  local _val=$(docker volume ls --filter="name=$_n" --format "{{.Name}}")
  eval "export ${_var}=${_val}"
}

function rm_docker_volume {
  local _n
  for _n in $@; do
    has_docker_volume _has_docker_volume $_n
    if [ "X$_has_docker_volume" != "X" ]; then
      docker volume rm $_n
      local _check
      has_docker_volume $_check $_n
      if [ "X$_check" != "X" ]; then
        error $ERR_BAD_VOLUME "Removing docker volume $_n failed."
      fi
    fi
  done
}

function configure_systemd {
  # Arguments: service_name requires after
  # Use the template systemd.service to configre the running of a docker
  # service via systemd.  This function only setup the systemd script it
  # does not enable it or run it - sometimes they need manual tweaking.
  if [ "X$USE_SYSTEMD" != "X" ]; then
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
  fi
}

function enable_systemd {
  # Arguments: service_name
  # Enable a docker service via systemd.
  if [ "X$USE_SYSTEMD" != "X" ]; then
    local _s=$1
    local _f="docker-container@${_s}.service"
    systemctl enable ${_f}
  fi
}
