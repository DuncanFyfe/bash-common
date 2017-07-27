#!/bin/bash
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

# Auto generate a postgres user password.
if [ "X$POSTGRES_PASSWORD" = 'XAUTOMATICFORTHEPEOPLE' ]; then
  LENGTH=32
  export POSTGRES_PASSWORD=$(openssl rand -base64 $LENGTH | tr -d '[:space:]' | head -c${1:-${LENGTH}})
  echo "Set POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
fi

# On first start the database goes into the background and then is too slow to
# start causing problems with the init scripts.  PG_PAUSE is a configurable
# pause (sleep) between database start and firing the init scripts.
# sleep time to wait before firing off DB init scripts.
export PG_PAUSE=${PG_PAUSE:-5}

# GITHUB_* are used in the create-gitlab-db.sh script.
for dir in $POSTGRES_ROOT $POSTGRES_DATA $POSTGRES_HOST_INITDB; do
  makedir $dir
done

# Copy initdb scripts.
if [ "X$POSTGRES_INITDB_SCRIPTS" != "X" ]; then
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
  --env "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" $POSTGRES_DOCKER_RUN \
  -v ${POSTGRES_DATA}:/var/lib/postgresql/data \
  -v ${POSTGRES_HOST_INITDB}:${POSTGRES_CONT_INITDB}:ro \
  -d ${POSTGRES_DOCKER_IMAGE}"
docker run --name ${POSTGRES_NAME} --log-driver=journald $PUBLISH_PORTS \
  --env "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" $POSTGRES_DOCKER_RUN \
  -v ${POSTGRES_DATA}:/var/lib/postgresql/data \
  -v ${POSTGRES_HOST_INITDB}:${POSTGRES_CONT_INITDB}:ro \
  -d ${POSTGRES_DOCKER_IMAGE}

open_ufw_ports=$(echo "$OPEN_UFW_PORTS" | tr ',' '\n' | sort -u | tr '\n' ' ')
for p in $open_ufw_ports; do
  echo "ufw allow $p"
  ufw allow $p
done

echo "Pause for DB to come up..."
sleep $PG_PAUSE
# Get postgres client
echo "#"
echo "# To get a psql client connection to the new container:"
echo "docker run -it --rm --link $POSTGRES_NAME:postgres ${POSTGRES_DOCKER_IMAGE} psql -h postgres -U postgres"
echo "# To get shell access for debugging try (alpine does not include bash!):"
echo "docker exec -it $POSTGRES_NAME /bin/sh"
echo "To execute commands on the database after init:"
echo "docker exec -it $POSTGRES_NAME /bin/sh -c 'echo \"SELECT datname FROM pg_database WHERE datistemplate = false;\" | psql -U postgres'"
echo "#"

assert_container ${POSTGRES_NAME}
configure_systemd $POSTGRES_NAME "docker.service" "docker.service"

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
enable_systemd ${POSTGRES_NAME}

# Sleep twice the PG_PAUSE time to give the DB time to come up.
docker logs $POSTGRES_NAME
