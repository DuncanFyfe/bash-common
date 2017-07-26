function postgres_add_initdb {
  # Arguments: template_file additional_template_variables ...
  # Requires:
  #   POSTGRES_SRC_INITDB = Directory of source template
  #   POSTGRES_HOST_INITDB = Host directory which will be mounted in container
  #     at /docker-entrypoint-initdb.d
  #
  # The dockerized postgresql runs the scripts in /docker-entrypoint-initdb.d
  # to initialize itself.  Copy a source template into the host folder,
  # apply template substitution and make the script executable (it is assumed
  # to be a shell script but this should not cause problems with sql
  # statement files).
  #
  # PG_PAUSE is a pause inserted to allow the database to come up before
  # running a script.
  #
    local _template=$1
    assert_var _template
    local _init=$(basename $_template)
    local _src=$POSTGRES_SRC_INITDB/$_init
    local _dest=$POSTGRES_HOST_INITDB/$_init
    echo "\$_src=$_src"
    echo "\$_dest=$_dest"
    if [ -f $_src -a ! -f $_dest ]; then
      echo "cp $_src $_dest"
      cp $_src $_dest
      assert_file $_dest
      template_substitution $_dest 'POSTGRES_PASSWORD' 'POSTGRES_VERSION' 'PG_PAUSE' ${@:2}
      chmod u+rx $_dest
    fi
}

function postgres_exec_initdb {
    # Arguments: script_filename
    # Requires:
    #   POSTGRES_HOST_INITDB = Host directory which will be mounted on container
    #     at /docker-entrypoint-initdb.d
    #   POSTGRES_NAME = Name of the postgresql container to exec this script on.
    # POSTGRES_CONT_INITDB is the directory of the script in the container.
    # Notice there are no checks here to see if a script has already been run
    # or not.
    # This function allows scripts placed in the container
    # /docker-entrypoint-initdb.d folder to be executed after the container
    # has been run.
    local _filename=$1
    assert_var _filename
    # Check the script is on the host
    local _init=$(basename $_filename)
    local _hostinit="$POSTGRES_HOST_INITDB/$_init"
    # Where in the container we can find the initdb.d directory.
    POSTGRES_CONT_INITDB=${POSTGRES_CONT_INITDB:-'/docker-entrypoint-initdb.d'}
    assert_file $_hostinit
    docker exec -it $POSTGRES_NAME $POSTGRES_CONT_INITDB/$_init
}
