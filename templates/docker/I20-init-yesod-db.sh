#!/bin/sh
# This init script initializes a database and user for use with the
# yesod-postgres scaffolding.  Start the postgres container with the
# environment variables:
# PGUSER = The Postgres user configured for the yesod-postgres
# application.
# PGPASS = The password for the above user.
# PGDATABASE = The name of the database to which the yesod-postgres is
# configured to connect
# These mirror the environment variables in the yesod-postgres settings file.

echo "CREATE USER ${PGUSER}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM   pg_catalog.pg_user WHERE  usename = '${PGUSER}';" | grep -q 1 || psql -v ON_ERROR_STOP=1 --username "postgres" -c "CREATE USER ${PGUSER} WITH UNENCRYPTED PASSWORD '${PGPASS}';"
echo "CREATE DATABASE ${PGUSER}"
psql -v ON_ERROR_STOP=1 --username "postgres" -tc "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '${PGDATABASE}';" | grep -q 1 || psql -U postgres -c "CREATE DATABASE ${PGDATABASE} WITH TEMPLATE = 'template1';"
echo "GRANT ALL PRIVILEGES"
psql -v ON_ERROR_STOP=1 --username "postgres" -c "GRANT ALL PRIVILEGES ON DATABASE ${PGDATABASE} TO ${PGUSER};"

# Database extensions
echo "EXTENSION pg_trgm"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${PGDATABASE} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
echo "EXTENSION unaccent"
psql -v ON_ERROR_STOP=1 --username "postgres" -d ${PGDATABASE}  -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
