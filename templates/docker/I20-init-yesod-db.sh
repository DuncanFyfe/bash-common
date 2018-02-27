#!/bin/sh
# This init script initializes a database and user for use with the
# yesod-postgres scaffolding.  Start the postgres container with the
# environment variables:
# YESOD_PGUSER = The Postgres user configured for the yesod-postgres
# application.
# YESOD_PGPASS = The password for the above user.
# YESOD_PGDATABASE = The name of the database to which the yesod-postgres is
# configured to connect
# These mirror the environment variables in the yesod-postgres settings file.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export SCRIPT="${BASH_SOURCE[0]}"
else
  export SCRIPT=$(readlink -f "$0")
fi
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
echo "BEGIN $SCRIPT"

echo "CREATE USER ${YESOD_PGUSER}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM   pg_catalog.pg_user WHERE  usename = '${YESOD_PGUSER}';" | grep -q 1 || psql -v ON_ERROR_STOP=1 --username "postgres" -c "CREATE USER ${YESOD_PGUSER} WITH UNENCRYPTED PASSWORD '${YESOD_PGPASS}';"
echo "CREATE DATABASE ${YESOD_PGDATABASE}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '${YESOD_PGDATABASE}';" | grep -q 1 || psql -U postgres -c "CREATE DATABASE ${YESOD_PGDATABASE} WITH TEMPLATE = 'template1';"
echo "GRANT ALL PRIVILEGES"
psql -v ON_ERROR_STOP=1 --username "postgres" -c "GRANT ALL PRIVILEGES ON DATABASE ${YESOD_PGDATABASE} TO ${YESOD_PGUSER};"
#
# Database extensions
echo "POSTGRES EXTENSION pg_trgm"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${YESOD_PGDATABASE} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
echo "POSTGRES EXTENSION unaccent"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${YESOD_PGDATABASE}  -c "CREATE EXTENSION IF NOT EXISTS unaccent;"

echo "END $SCRIPT"
