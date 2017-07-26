# The postgres:9-alpine docker image uses locale en_US.UTF8. This is suitable
# for yesod-postgres.
# The environment variables below override those given in the
# postgres/postgres.sh config file.
export PGUSER="yesod"
export PGPASS="NOTHEPASSWORDYOUARELOOKINGFOR"
export PGDATABASE="www_example_com"

export POSTGRES_NAME="yesod-postgres-${POSTGRES_VERSION}"
export POSTGRES_ROOT="${HOST_ROOT}/${POSTGRES_NAME}"
export POSTGRES_DATA="${POSTGRES_ROOT}/data"
# This is where we put/look for scripts to initialize the database.
# The source of those script templates, where we put them on the host and where
# we find them in the container.
export POSTGRES_SRC_INITDB="$SCRIPT_DIR/docker-entrypoint-initdb.d"
export POSTGRES_HOST_INITDB="$POSTGRES_ROOT/docker-entrypoint-initdb.d"
export POSTGRES_CONT_INITDB="/docker-entrypoint-initdb.d"
export POSTGRES_INITDB_ARGS="--data-checksums"
# initdb scripts to copy to the INIOTDB folder.
export POSTGRES_INITDB_SCRIPTS="I10-begin.sh I20-init-yesod-db.sh"
# Additional docker run arguments.
export POSTGRES_TEMPLATE_VARS="PGUSER PGPASS PGDATABASE"
export POSTGRES_DOCKER_RUN="-e \"PGUSER=$PGUSER\" -e \"PGPASS=$PGPASS\" -e \"PGDATABASE=$PGDATABASE\""
