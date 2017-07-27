#!/bin/sh
# This init script initializes a database and user for gitlab.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
echo "BEGIN $script"
echo "CREATE USER ${GITLAB_PG_USER}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM   pg_catalog.pg_user WHERE  usename = '${GITLAB_PG_USER}';" | grep -q 1 || psql -v ON_ERROR_STOP=1 --username "postgres" -c "CREATE USER ${GITLAB_PG_USER} WITH UNENCRYPTED PASSWORD '${GITLAB_PG_PASSWORD}';"
echo "CREATE DATABASE ${GITLAB_PG_USER}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '${GITLAB_PG_DB}';" | grep -q 1 || psql -U postgres -c "CREATE DATABASE ${GITLAB_PG_DB} WITH TEMPLATE = 'template1';"
echo "GRANT ALL PRIVILEGES"
psql -v ON_ERROR_STOP=1 --username "postgres" -c "GRANT ALL PRIVILEGES ON DATABASE ${GITLAB_PG_DB} TO ${GITLAB_PG_USER};"

# Database extensions
echo "EXTENSION pg_trgm"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${GITLAB_PG_DB} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
echo "EXTENSION unaccent"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${GITLAB_PG_DB}  -c "CREATE EXTENSION IF NOT EXISTS unaccent;"

echo "END $script"
