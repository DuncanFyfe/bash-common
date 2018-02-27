# The postgres:9-alpine docker image uses locale en_US.UTF8. This is suitable
# for yesod-postgres.
# The environment variables below override those given in the
# postgres/postgres.sh config file.
export YESOD_PGUSER="domenlas_yesod"
export YESOD_PGPASS="O8GHQOQG0baTE+MDL7tcLARwoVl0a+Vc"
export YESOD_PGDATABASE="domenlas_yesod"

export POSTGRES_NAME="yesod-postgres-${POSTGRES_VERSION}"
# This is safer than $A/$B because empty string A and B will not result in "/".
join_by POSTGRES_ROOT '/' "${HOST_ROOT}" "${POSTGRES_NAME}"

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
#export POSTGRES_INITDB_SCRIPTS="I10-begin.sh"
# Additional docker run arguments.
export POSTGRES_TEMPLATE_VARS="YESOD_PGUSER YESOD_PGPASS YESOD_PGDATABASE"
export ADD_HOST_USER="False"
# Format as docker -p external_port:container_port
export PUBLISH_DOCKER_PORTS="5432:5432"
export OPEN_UFW_PORTS="5432"
export CONFIGURE_SYSTEMD="False"
