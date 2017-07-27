#!/bin/bash
# Install docker on an ubuntu node.
# TBD:
# Add instllation of fail2ban
# Add instllation and configuration of dnsmasq as cache.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_NAME=$(basename ${SCRIPT})
export SCRIPT_DIR=$(dirname ${SCRIPT})
_sudo=${SUDO_PATH:-'/usr/bin/sudo'}

dist='Ubunut'
distver='16.04'
distcheck=$(uname -a | grep -c $dist)
distvercheck=$(uname -a | grep -c $distver)
if [ "X$distcheck" != "X1" -a "X$distvercheck" != "X1" ]; then
  echo "[ERROR] $SCRIPT is for $dist version $distver.  Exiting."
  exit 99
fi

if [ "$(id -u)" != "0" ]; then
    [ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "RESTARTING SCRIPT WITH SUDO: $_sudo $0 $@"
    exec $_sudo $0 $@
fi

export DEBIAN_FRONTEND=noninteractive
apt-get --assume-yes remove docker docker-engine
apt-get --assume-yes update
apt-get install \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual

apt-get --assume-yes  install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "Verify that the key fingerprint is 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88."
apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get --assume-yes install docker-ce

# Enable overlay storage driver
servicefile=$(systemctl show --property=FragmentPath docker | cut -d= -f2)
if [ "X$servicefile" != "X" -a -f $servicefile -a $(grep -c -- --storage-driver=overlay $servicefile) -eq 0 ]; then
  echo "Editing $servicefile"
  sed -i 's!ExecStart=/usr/bin/dockerd!ExecStart=/usr/bin/dockerd --storage-driver=overlay!' $servicefile
  echo "Trying to enable the docker overlay filesystem. Please confirm this has worked. Steps are:"
  echo "Identify systemd service file: systemctl show --property=FragmentPath docker."
  echo "Change   \"ExecStart=/usr/bin/dockerd (.+)\""
  echo "To       \"ExecStart=/usr/bin/dockerd --storage-driver=overlay \\1\""

  c=$(grep -c -- --storage-driver=overlay $servicefile)
  if [ $c -eq 1 ]; then
    systemctl daemon-reload
    systemctl restart $(basename $servicefile)
  fi
fi

adminuser="${ADMINUSER}"
if [ "X$adminuser" != "X" ]; then
  if [ $(groups ${adminuser} | grep -c '\bdocker\b' ) -eq 0 ]; then
    echo "Adding ${adminuser} to docker group."
    usermod -aG docker ${adminuser}
  else
    echo "${adminuser} is already in docker group."
  fi
fi
