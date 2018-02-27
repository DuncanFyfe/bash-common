#!/bin/bash
_sudo=${SUDO_PATH:-'/usr/bin/sudo'}
if [ "$(id -u)" != "0" ]; then
    $_sudo $0 $@
    exit 0
fi

adminuser="${ADMINUSER}"
adminuser=${adminuser:-$USER}
install_path=${INSTALL_PATH}
install_path=${install_path:-"$HOME/bin"}
if [ ! -d ${install_path} ]; then
  mkdir -p ${install_path}
fi

curl -LO -o "$install_path/kubctl" https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chown ${ADMINUSER}:${ADMINUSER} $install_path/kubctl
chmod +x $install_path/kubctl
