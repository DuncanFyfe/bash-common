#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"

if [ "$(id -u)" != "0" ]; then
    [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "RESTARTING SCRIPT WITH SUDO: $_sudo $0 $@"
    exec $_sudo $0 $@
fi

. $SCRIPT_DIR/project.sh
load 'docker' 'docker.sh'
load 'nginx-proxy' 'nginx-proxy.sh'
cd $SCRIPT_DIR

assert_directory $NGINX_PROXY_ROOT/certs
assert_container $NGINX_PROXY_NAME
assert_container $NGINX_GEN_NAME
systemctl stop "docker-container@${NGINX_LENTENCRYPT_NAME}.service"
rm_container $NGINX_LENTENCRYPT_NAME

docker run -d --name $NGINX_LENTENCRYPT_NAME --log-driver=journald \
  -e "NGINX_DOCKER_GEN_CONTAINER=$NGINX_GEN_NAME" \
  --volumes-from $NGINX_PROXY_NAME \
  -v $NGINX_PROXY_ROOT/certs:/etc/nginx/certs:rw \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  jrcs/letsencrypt-nginx-proxy-companion

configure_systemd $NGINX_LENTENCRYPT_NAME "docker-container@${NGINX_GEN_NAME}.service" "docker-container@${NGINX_GEN_NAME}.service"
enable_systemd ${NGINX_LENTENCRYPT_NAME}
