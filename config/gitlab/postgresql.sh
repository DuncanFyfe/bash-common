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

# Additional docker run arguments.

export POSTGRES_NAME="gitlab-postgres-${POSTGRES_VERSION}"
export POSTGRES_ROOT="${HOST_ROOT}/${POSTGRES_NAME}"
export POSTGRES_DATA="${POSTGRES_ROOT}/data"
# This is where we put/look for scripts to initialize the database.
# The source of those script templates, where we put them on the host and where
# we find them in the container.
export POSTGRES_HOST_INITDB="$POSTGRES_ROOT/docker-entrypoint-initdb.d"
# initdb scripts to copy to the INIOTDB folder.
export POSTGRES_INITDB_SCRIPTS="I10-begin.sh I20-init-gitlab-db.sh"
export POSTGRES_TEMPLATE_VARS="GITLAB_PG_USER GITLAB_PG_PASSWORD GITLAB_PG_DB"
# Additional docker run arguments.
export POSTGRES_DOCKER_RUN="-e \"GITLAB_PG_USER=$GITLAB_PG_USER\" -e \"GITLAB_PG_PASSWORD=$GITLAB_PG_PASSWORD\" -e \"GITLAB_PG_DB=$GITLAB_PG_DB\""
