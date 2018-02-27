#!/bin/bash
# Postgres docker instance for use by yesod.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"

if [ "$(id -u)" != "0" ]; then
    _sudo=${SUDO_PATH:-'/usr/bin/sudo'}
    [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "RESTARTING SCRIPT WITH SUDO: $_sudo $0 $@"
    exec $_sudo $0 $@
fi

. $SCRIPT_DIR/project.sh

load 'docker' 'docker.sh'
load 'docker' 'postgres.sh'
load 'yesod' 'postgres.sh'

#load 'gitlab' 'postgresql.sh'
#
assert_var POSTGRES_NAME
assert_var POSTGRES_ROOT
assert_var POSTGRES_DATA
assert_var POSTGRES_HOST_INITDB
assert_var POSTGRES_DOCKER_IMAGE
assert_var POSTGRES_CONT_INITDB

cd $SCRIPT_DIR

systemctl stop "docker-container@${POSTGRES_NAME}.service"
rm_container $POSTGRES_NAME
FORCE_REMOVE_EXISTING="False"
#FORCE_REMOVE_EXISTING="True"
echo "FORCE_REMOVE_EXISTING=$FORCE_REMOVE_EXISTING"
if [ "X$FORCE_REMOVE_EXISTING" = "XTrue" ]; then
    echo "Forced removal of existing postgres data."
    forceddelete "$POSTGRES_DATA" "$POSTGRES_HOST_INITDB"
fi

# Auto generate a postgres user password.
if [ "X$POSTGRES_PASSWORD" = 'X' ]; then
  make_password POSTGRES_PASSWORD 32
fi
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"

# Auto generate a postgres yesod user password.
if [ "X$YESOD_PGPASS" = 'X' ]; then
  make_password YESOD_PGPASS 32
fi
echo "YESOD_PGDATABASE=$YESOD_PGDATABASE"
echo "YESOD_PGUSER=$YESOD_PGUSER"
echo "YESOD_PGPASS=$YESOD_PGPASS"

# On first start the database goes into the background and then is too slow to
# start.  This causes problems because other parts of th init are run before
# the DB is ready.  PG_PAUSE is a configurable pause (sleep) between database
# start and firing the init scripts.
# sleep time to wait before firing off DB init scripts.
# For some values this sleep can cause the container to timeout and die.
# A value of 2 seems to work but 10 is too long.
export PG_PAUSE=${PG_PAUSE:-5}


for dir in $POSTGRES_ROOT $POSTGRES_DATA $POSTGRES_HOST_INITDB; do
  makedir $dir
done

# Copy initdb scripts.
if [ "X$POSTGRES_INITDB_SCRIPTS" != "X" ]; then
  echo "POSTGRES_TEMPLATE_VARS=$POSTGRES_TEMPLATE_VARS"
  for s in ${POSTGRES_INITDB_SCRIPTS}; do
    postgres_add_initdb $s $POSTGRES_TEMPLATE_VARS
  done
fi

#PUBLISH_DOCKER_PORTS
publish_ports=$(echo "$PUBLISH_DOCKER_PORTS" | tr ',' '\n' | sort -u | tr '\n' ' ')
for p in $publish_ports; do
  PUBLISH_PORTS="-p $p ${PUBLISH_PORTS}"
done

echo "docker run --name ${POSTGRES_NAME} --log-driver=journald $PUBLISH_PORTS \
  --env "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" \
  -v ${POSTGRES_DATA}:/var/lib/postgresql/data \
  -v ${POSTGRES_HOST_INITDB}:${POSTGRES_CONT_INITDB}:ro \
  -d ${POSTGRES_DOCKER_IMAGE}"
docker run --name ${POSTGRES_NAME} --log-driver=journald $PUBLISH_PORTS \
  --env "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" \
  -v ${POSTGRES_DATA}:/var/lib/postgresql/data \
  -v ${POSTGRES_HOST_INITDB}:${POSTGRES_CONT_INITDB}:ro \
  -d ${POSTGRES_DOCKER_IMAGE}

# Get postgres client
echo "#"
echo "# To get a psql client connection to the new container:"
echo "docker run -it --rm --link $POSTGRES_NAME:postgres ${POSTGRES_DOCKER_IMAGE} psql -h postgres -U postgres"
echo "# To get shell access for debugging try (alpine does not include bash!):"
echo "docker exec -it $POSTGRES_NAME /bin/sh"
echo "To execute commands on the database after init:"
echo "docker exec -it $POSTGRES_NAME /bin/sh -c 'echo \"SELECT datname FROM pg_database WHERE datistemplate = false;\" | psql -U postgres'"
echo "#"

if [ $(uname -a | grep -c Ubuntu) -gt 0 ]; then
  open_ufw_ports=$(echo "$OPEN_UFW_PORTS" | tr ',' '\n' | sort -u | tr '\n' ' ')
  for p in $open_ufw_ports; do
    echo "ufw allow $p"
    ufw allow $p
  done
fi

assert_docker_container ${POSTGRES_NAME}
if [ "X$CONFIGURE_SYSTEMD" = "XTrue" ]; then
  configure_systemd $POSTGRES_NAME "docker.service" "docker.service"
fi

# Postgres runs as the postgres user inside the container.
# Add a user to the host system for the docker postgres pid.
# This is better for files created on the host.
if [ "X${ADD_HOST_USER}" = "XTrue" ]; then
  postgresgid=$(ps -eo gid,args | awk '$2 == "postgres" { print $1 }')
  echo "postgresgid=$postgresgid"
  if [ "X$postgresgid" != "X" ]; then
    groupexists=$(getent group $postgresgid | cut -d: -f1 )
    if [ "X$groupexists" = "X" ]; then
      addgroup --gid $postgresgid postgres
    else
      echo "[WARN] Group $groupexists with docker-postgres GID ${postgresgid} already exists."
    fi
    assert_group 'postgres'
  fi

  postgresuid=$(ps -eo uid,args | awk '$2 == "postgres" { print $1 }')
  echo "postgresuid=$postgresuid"
  if [ "X$postgresuid" != "X" ]; then
    userexists=$(getent passwd $postgresuid | cut -d: -f1)
    if [ "X$userexists" = "X" ]; then
      POSTGRES_HOME=${POSTGRES_HOME:-"$POSTGRES_ROOT/home"}
      makedir $POSTGRES_HOME
      chown "$postgresuid:$postgresgid" $POSTGRES_HOME
      adduser --system --uid=$postgresuid --gid $postgresgid \
    --home $POSTGRES_HOME --disabled-login --disabled-password postgres
    else
        echo "[WARN] USER $userexists with docker-postgres UID ${postgresuid} already exists."
    fi
    assert_user 'postgres'
    # Fix ownership and permissions on the init scripts from the host perspective
    chown postgres:postgres $POSTGRES_HOST_INITDB/*
    chmod go-x $POSTGRES_HOST_INITDB/*
  fi
fi
echo ""
if [ "X$CONFIGURE_SYSTEMD" = "XTrue" ]; then
  enable_systemd ${POSTGRES_NAME}
fi

# Sleep twice the PG_PAUSE time to give the DB time to come up.
echo "Pause ($PG_PAUSE) for DB to come up..."
sleep $PG_PAUSE
sleep $PG_PAUSE
docker logs $POSTGRES_NAME
