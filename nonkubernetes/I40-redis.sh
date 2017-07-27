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
load 'nginx-proxy' 'nginx-proxy.sh'
load 'docker' 'redis.sh'
#load 'gitlab' 'gitlab.sh'
#load 'gitlab' 'redis.sh'

cd $SCRIPT_DIR

assert_container $NGINX_LENTENCRYPT_NAME

for dir in $REDIS_ROOT $REDIS_DATA $REDIS_CONFD; do
  makedir $dir
done

# Local Configuration
srcconf="$SCRIPT_DIR/redis.conf"
hostconf="$REDIS_CONFD/redis.conf"

systemctl stop "docker-container@${REDIS_NAME}.service"
rm_container $REDIS_NAME

if [ -f $srcconf -a ! -f $hostconf ]; then
  cp $srcconf $hostconf
  chmod a+r $hostconf
fi

docker run --name $REDIS_NAME --log-driver=journald \
  -v $REDIS_DATA:/data \
  -v $hostconf:/usr/local/etc/redis/redis.conf:ro \
  -d ${REDIS_DOCKER_IMAGE} /usr/local/etc/redis/redis.conf

assert_container ${REDIS_NAME}
configure_systemd ${REDIS_NAME} "docker-container@${NGINX_LENTENCRYPT_NAME}.service" "docker-container@${NGINX_LENTENCRYPT_NAME}.service"
enable_systemd ${REDIS_NAME}
