#!/bin/bash
# Manually create some certificates
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh
#
# Pstgres server ceritifacte
create_certificate.sh 'serverboxen.example.com' $INTER_CA_NAME 'server' \
  'postgres.example.com' "$SERVER_IP_ADDRESS"

# gitlab server ceritifcate
# Hosted on serverboxen.example.com acting as proxy for gitlab.example.com
create_certificate.sh 'serverboxen.example.com' $INTER_CA_NAME 'server' \
  'gitlab.example.com' "$SERVER_IP_ADDRESS"

# Postgres account SSL client certificate
# Intended for distribution to laptop.example.com the postgres username
# is required to be placed in the common name field.
create_certificate.sh 'laptop.example.com' $INTER_CA_NAME 'client' \
  $GITLAB_PG_USER
