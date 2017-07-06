export POSTGRES_NAME='postgres'
export POSTGRES_VERSION="9"
export POSTGRES_ROOT="${HOST_ROOT}/${POSTGRES_NAME}/${POSTGRES_VERSION}"
# This is where we put/look for scripts to initialize the database.
# The source of those script templates, where we put them on the host and where
# we find them in the container.
export POSTGRES_SRC_INITDB="$SCRIPT_DIR/docker-entrypoint-initdb.d"
export POSTGRES_HOST_INITDB="$POSTGRES_ROOT/docker-entrypoint-initdb.d"
export POSTGRES_CONT_INITDB="/docker-entrypoint-initdb.d"
export POSTGRES_PASSWORD='ABIGLONGSECRET'
