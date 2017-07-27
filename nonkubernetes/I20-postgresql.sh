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
assert_var POSTGRES_NAME
assert_var POSTGRES_ROOT
assert_var POSTGRES_DATA
assert_var POSTGRES_HOST_INITDB
assert_var POSTGRES_DOCKER_IMAGE
cd $SCRIPT_DIR

systemctl stop "docker-container@${POSTGRES_NAME}.service"
rm_container $POSTGRES_NAME

# Auto generate a postgres user password.
if [ "X$POSTGRES_PASSWORD" = 'XAUTOMATICFORTHEPEOPLE' ]; then
  LENGTH=32
  export POSTGRES_PASSWORD=$(openssl rand -base64 $LENGTH | tr -d '[:space:]' | head -c${1:-${LENGTH}})
fi
echo "Set POSTGRES_PASSWORD=$POSTGRES_PASSWORD"

# On first start the database goes into the background and then is too slow to
# start causing problems with the init scripts.  PG_PAUSE is a configurable
# pause (sleep) between database start and firing the init scripts.
# sleep time to wait before firing off DB init scripts.
export PG_PAUSE="${PG_PAUSE}:-5"

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

docker run --name ${POSTGRES_NAME} --log-driver=journald \
  --env "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" $POSTGRES_DOCKER_RUN \
  -v ${POSTGRES_DATA}:/var/lib/postgresql/data \
  -v ${POSTGRES_HOST_INITDB}:${POSTGRES_CONT_INITDB}:ro \
  -d ${POSTGRES_DOCKER_IMAGE}

echo "Pause for DB to come up..."
sleep $PG_PAUSE
# Get postgres client
echo "# To get a psql client connection to the new container:"
echo "docker run -it --rm --link $POSTGRES_NAME:postgres postgres psql -h postgres -U postgres"
echo "# To get shell access for debugging try (alpine does not include bash!):"
echo "docker exec -it $POSTGRES_NAME /bin/sh"
echo "To execute commands on the database after init:"
echo "docker exec -it postgresql /bin/sh -c 'echo \"SELECT datname FROM pg_database WHERE datistemplate = false;\" | psql -U postgres'"

assert_container ${POSTGRES_NAME}
configure_systemd $POSTGRES_NAME "docker.service" "docker.service"

# Postgres runs as the postgres user inside the container.
# Add a user to the system for the docker postgres pid.
# This is better for files created on the host.
ADD_USER="False"
if [ "X${ADD_USER}" != "XFalse" ]; then
  postgresuid=$(ps -eo uid,args | awk '$2 == "postgres" { print $1 }')
  echo "postgresuid=$postgresuid"
  if [ "X$postgresuid" != "X" ]; then
    postgresgid=$(ps -eo gid,args | awk '$2 == "postgres" { print $1 }')
    userexists=$(getent passwd $postgresuid)
    if [ "X$userexists" = "X" ]; then
      addgroup --gid $postgresgid postgres
      adduser --system --uid=$postgresuid --gid $postgresgid \
      --home $POSTGRES_ROOT --disabled-login --disable-password postgres
    fi
  fi
fi
enable_systemd "docker-container@${POSTGRES_NAME}.service"

# Sleep twice the PG_PAUSE time to give the DB time to come up.
docker logs $POSTGRES_NAME
