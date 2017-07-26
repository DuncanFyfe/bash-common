#!/bin/bash
# Stop and Remove nginx-proxy containers.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh
load 'docker' 'docker.sh'
load 'nginx-proxy' 'nginx-proxy.sh'
cd $SCRIPT_DIR

# Try systemctl. If dependencies have been set up correctly the first one
# will stop everything.
systemctl stop docker-container@$NGINX_PROXY_NAME.service
systemctl stop docker-container@$NGINX_GEN_NAME.service
systemctl stop docker-container@$NGINX_LENTENCRYPT_NAME.service

# Then docker: When we bootstrap systemctl isn't running the containers.
rm_container $NGINX_LENTENCRYPT_NAME $NGINX_GEN_NAME $NGINX_PROXY_NAME
