#!/bin/bash
if [ "$(id -u)" != "0" ]; then
    /usr/bin/sudo $0 $*
    exit 0
fi
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)

# Run this to create a named container that will be picked up by name by systemd.

NGINX_PROXY_NAME="nginx-proxy"
NGINX_GEN_NAME="nginx-gen"
NGINX_LENTENCRYPT_NAME="nginx-letsencrypt"

# Try systemctl. If dependencies have been set up correctly the first one
# will stop everything.
systemctl stop docker-container@$NGINX_PROXY_NAME.service
systemctl stop docker-container@$NGINX_GEN_NAME.service
systemctl stop docker-container@$NGINX_LENTENCRYPT_NAME.service

# Then docker: When we bootstrap systemctl isn't running the containers.
docker stop $NGINX_LENTENCRYPT_NAME $NGINX_GEN_NAME $NGINX_PROXY_NAME
