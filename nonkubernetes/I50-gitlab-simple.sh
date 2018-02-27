#!/bin/bash
if [ "$(id -u)" != "0" ]; then
    /usr/bin/sudo $0 $*
    exit 0
fi
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)

. $SCRIPT_DIR/common.sh
. $SCRIPT_DIR/config.sh
cd $SCRIPT_DIR

#assert_docker_container $REDIS_NAME
#assert_docker_container $POSTGRES_NAME

# Local Configuration
hostdata="$GITLAB_ROOT/data"
hostconf="$GITLAB_ROOT/config"
hostlogs="$GITLAB_ROOT/logs"
registry="$GITLAB_ROOT/registry"
srcconffile="$SCRIPT_DIR/gitlab-simple.rb"
hostconffile="$hostconf/gitlab.rb"

for dir in $GITLAB_ROOT $hostdata $hostconf $hostlogs $registry; do
  makedir $dir
done

# Copy gitlab configuration.
if [ -f $srcconffile -a ! -f "$hostconffile" ]; then
  cp $srcconffile $hostconffile
  template_substitution $hostconffile 'GITLAB_PG_USER' 'GITLAB_PG_DB' 'GITLAB_PG_PASSWORD' 'GITLAB_PG_HOST' 'GITLAB_REDIS_HOST' 'GITLAB_REDIS_DB'
fi

systemctl stop "docker-container@${GITLAB_NAME}.service"
rm_container $GITLAB_NAME

docker run --name $GITLAB_NAME --log-driver=journald \
  -e 'VIRTUAL_HOST=gitlab.example.com' \
  -e 'LETSENCRYPT_HOST=gitlab.example.com' \
  -e 'LETSENCRYPT_EMAIL=accounts@example.com' \
  -p 10022:22 \
  -p 5000:5000 \
  --volume $NGINX_PROXY_ROOT/certs:/etc/gitlab/ssl:ro \
  --volume $hostconf:/etc/gitlab \
  --volume $hostlogs:/var/log/gitlab \
  --volume $hostdata:/var/opt/gitlab \
  --volume $registry:/var/opt/registry \
  -d ${GITLAB_DOCKER_IMAGE}

assert_docker_container $GITLAB_NAME
#configure_systemd $GITLAB_NAME "docker.service" "docker.service"
#enable_systemd $GITLAB_NAME
