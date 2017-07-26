#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh
load 'docker' 'docker.sh'
load 'nginx-proxy' 'nginx-proxy.sh'
cd $SCRIPT_DIR

for dir in $NGINX_PROXY_ROOT $NGINX_PROXY_ROOT/certs $NGINX_PROXY_ROOT/conf.d  $NGINX_PROXY_ROOT/html $NGINX_PROXY_ROOT/vhost.d $NGINX_PROXY_ROOT/htpasswd; do
  makedir $dir
done

systemctl stop "docker-container@${NGINX_PROXY_NAME}.service"
rm_container $NGINX_PROXY_NAME

docker run -d -p 80:80 -p 443:443 --name $NGINX_PROXY_NAME \
  --log-driver=journald \
  -v $NGINX_PROXY_ROOT/conf.d:/etc/nginx/conf.d \
  -v $NGINX_PROXY_ROOT/vhost.d:/etc/nginx/vhost.d \
  -v $NGINX_PROXY_ROOT/html:/usr/share/nginx/html \
  -v $NGINX_PROXY_ROOT/certs:/etc/nginx/certs:ro \
  -v $NGINX_PROXY_ROOT/htpasswd:/etc/nginx/htpasswd:ro \
  --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true nginx:${NGINX_PROXY_VERSION}-alpine

configure_systemd ${NGINX_PROXY_NAME} "docker.service" "docker.service"
enable_systemd ${NGINX_PROXY_NAME}
