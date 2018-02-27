#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'docker' 'docker.sh'
load 'postgres' 'postgres.sh'
load 'gitlab' 'postgres.sh'
load 'docker' 'redis.sh'
load 'docker' 'registry.sh'
load 'gitlab' 'gitlab.sh'
cd $SCRIPT_DIR

assert_docker_container $REDIS_NAME
assert_docker_container $POSTGRES_NAME
export GITLAB_DATA="${GITLAB_ROOT}/data"
export GITLAB_CONF="${GITLAB_ROOT}/config"
export GITLAB_LOGS="${GITLAB_ROOT}/logs"
export GITLAB_REGISTRY="${GITLAB_ROOT}/registry"
# Local Configuration
srcconffile="$SCRIPT_DIR/gitlab.rb"
hostconffile="$GITLAB_CONF/gitlab.rb"

for dir in $GITLAB_ROOT $GITLAB_DATA $GITLAB_CONF $GITLAB_LOGS $GITLAB_REGISTRY; do
  makedir $dir
done

# Copy gitlab configuration.
if [ -f $srcconffile -a ! -f "$hostconffile" ]; then
  cp $srcconffile $hostconffile
  template_substitution $hostconffile 'GITLAB_PG_USER' 'GITLAB_PG_DB' 'GITLAB_PG_PASSWORD' 'GITLAB_PG_HOST' 'GITLAB_REDIS_HOST' 'GITLAB_REDIS_DB'
fi

# Copy DB initialization script and run it.
# This assumes postgres is already running.
postgres_add_initdb "I20-init-gitlab-db.sh" 'GITLAB_PG_USER' 'GITLAB_PG_DB' 'GITLAB_PG_PASSWORD'
postgres_exec_initdb "I20-init-gitlab-db.sh"

systemctl stop "docker-container@${GITLAB_NAME}.service"
rm_container $GITLAB_NAME

docker run --name $GITLAB_NAME --log-driver=journald \
  -e "VIRTUAL_HOST=$GITLAB_HOST" \
  -e "LETSENCRYPT_HOST=$GITLAB_LETSENCRYPT_HOST" \
  -e "LETSENCRYPT_EMAIL=$GITLAB_LETSENCRYPT_EMAIL" \
  --link $POSTGRES_NAME:$GITLAB_PG_HOST \
  --link $REDIS_NAME:$GITLAB_REDIS_HOST \
  -p 10022:22 \
  --volume $NGINX_PROXY_ROOT/certs:/etc/gitlab/ssl:ro \
  --volume $GITLAB_CONF:/etc/gitlab \
  --volume $GITLAB_LOGS:/var/log/gitlab \
  --volume $GITLAB_DATA:/var/opt/gitlab \
  --volume $GITLAB_REGISTRY:/var/opt/registry \
  -d ${GITLAB_DOCKER_IMAGE}

assert_docker_container $GITLAB_NAME
configure_systemd $GITLAB_NAME "docker-container@${REGISTRY_NAME}.service" "docker-container@${REGISTRY_NAME}.service"
#enable_systemd $GITLAB_NAME
