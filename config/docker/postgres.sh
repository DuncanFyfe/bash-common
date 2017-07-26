export POSTGRES_VERSION="9"
export POSTGRES_DOCKER_IMAGE="postgres:${POSTGRES_VERSION}-alpine"
export POSTGRES_NAME="postgres_${POSTGRES_VERSION}"
export POSTGRES_ROOT="${HOST_ROOT}/${POSTGRES_NAME}"
export POSTGRES_DATA="${POSTGRES_ROOT}/data"
# This is where we put/look for scripts to initialize the database.
# The source of those script templates, where we put them on the host and where
# we find them in the container.
export POSTGRES_SRC_INITDB="$SCRIPT_DIR/docker-entrypoint-initdb.d"
export POSTGRES_HOST_INITDB="$POSTGRES_ROOT/docker-entrypoint-initdb.d"
export POSTGRES_CONT_INITDB="/docker-entrypoint-initdb.d"
export POSTGRES_PASSWORD='ABIGLONGSECRET'
export POSTGRES_INITDB_ARGS="--data-checksums"
# initdb scripts to copy to the INIOTDB folder.
export POSTGRES_INITDB_SCRIPTS="I10-begin.sh"
# Additional docker run arguments.
export POSTGRES_TEMPLATE_VARS=""
export POSTGRES_DOCKER_RUN=""
