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
cd $SCRIPT_DIR

hosttemplate=$NGINX_GEN_ROOT/templates/nginx.tmpl

for dir in $NGINX_GEN_ROOT $NGINX_GEN_ROOT/templates; do
  makedir $dir
done

if [ ! -f "/srv/docker-gen/templates/nginx.tmpl" ]; then
  curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > $hosttemplate
  assert_file $hosttemplate
fi

assert_container $NGINX_PROXY_NAME
systemctl stop "docker-container@${NGINX_GEN_NAME}.service"
rm_container $NGINX_GEN_NAME

docker run -d --name $NGINX_GEN_NAME --log-driver=journald \
  --volumes-from $NGINX_PROXY_NAME \
  -v $hosttemplate:/etc/docker-gen/templates/nginx.tmpl:ro \
  -v /var/run/docker.sock:/tmp/docker.sock:ro \
  jwilder/docker-gen -notify-sighup $NGINX_PROXY_NAME \
  -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

configure_systemd ${NGINX_GEN_NAME} "docker-container@${NGINX_PROXY_NAME}.service" "docker-container@${NGINX_PROXY_NAME}.service"
enable_systemd ${NGINX_GEN_NAME}
