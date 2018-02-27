#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

install_path=${INSTALL_PATH:-"$HOME/bin"}
if [ ! -d ${install_path} ]; then
  mkdir -p ${install_path}
fi

curl -L `curl -s -o "$install_path/docker-compose" https://api.github.com/repos/docker/compose/releases/latest | jq -r '.assets[].browser_download_url | select(contains("Linux") and contains("x86_64"))'`
if [ -f "$install_path/docker-compose" ]; then
  chmod +x $install_path/docker-compose
else
  echo "Failed to install docker-compose to $install_path/docker-compose."
  exit 1
fi
