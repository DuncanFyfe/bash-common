#!/bin/bash
# Setup a swapfile
# Setup a non-root admin user (passwordless sudo access)
# Enable the firewall with an OpenSSH hole.
#
# This script must only be run on a target host and execute as root.
# This script is deliberately stand alone.

export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME $(hostname) ${@:1}"
cd $SCRIPT_DIR

dist='Ubunut'
distver='16.04'
distcheck=$(uname -a | grep -c $dist)
distvercheck=$(uname -a | grep -c $distver)
if [ "X$distcheck" != "X1" -a "X$distvercheck" != "X1" ]; then
  echo "[ERROR] $SCRIPT is for $dist version $distver.  Exiting."
  exit 99
fi

# The ADMINUSER must be the same as in the script config.sh file.
export ADMINUSER="ubuntu"
export DEBIAN_FRONTEND=noninteractive;
apt-get update
apt-get --assume-yes upgrade
apt-get install --assume-yes --no-install-recommends unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades
apt-get clean


# Add a swap file
SWAPFILE="/swapfile1"
SWAPSIZE="2G"
if [ ! -f $SWAPFILE ]; then
  fallocate -l $SWAPSIZE $SWAPFILE
  err_status=$?
  if [ -f $SWAPFILE ]; then
    chmod 600 $SWAPFILE
    sudo mkswap $SWAPFILE
    swapon $SWAPFILE
    cp /etc/fstab /etc/fstab.bak
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
  else
    echo "#ERROR[$err_status]: Failed to fallocate a swapfile $SWAPFILE of size $SWAPSIZE."
  fi
else
  echo "File $SWAPFILE already exists."
fi

# Create a non-root admin user.
check=$(getent passwd $ADMINUSER)
if [ "X$check" = "X" ]; then
  echo "Creating user $ADMINUSER"
  adduser --quiet --disabled-password $ADMINUSER
else
  echo "$ADMINUSER already exsists."
fi

sshdir="/home/$ADMINUSER/.ssh"
sshauth="$sshdir/authorized_keys"
if [ ! -d $sshdir ]; then
  echo "Creating ssh directory."
  mkdir $sshdir
  chown $ADMINUSER:$ADMINUSER $sshdir
  chmod 700 $sshdir
fi

if [ ! -f $sshauth ]; then
  echo "Adding authorized_keys file."
  cp /root/.ssh/authorized_keys $sshauth
  chown $ADMINUSER:$ADMINUSER $sshauth
else
  echo "Authorized_keys file exists, leaving unmodified."
fi

sudoersfile=/etc/sudoers.d/90-admin-users
if [ ! -f $sudoersfile ]; then
  echo "Giving $ADMINUSER access via sudo"
  echo "$ADMINUSER ALL=(ALL) NOPASSWD:ALL" > $sudoersfile
  chmod 0440 $sudoersfile
else
  if [ $(grep -c "\b$ADMINUSER\b" $sudoersfile) -gt 0 ]; then
    echo "$ADMINUSER already has sudo access."
  else
    echo "Giving $ADMINUSER access via sudo"
    echo "$ADMINUSER ALL=(ALL) NOPASSWD:ALL" >> $sudoersfile
    chmod 0440 $sudoersfile
  fi
fi

# Ensure firewall is open for ssh.
if [ $(ufw status | grep -c OpenSSH) -eq 0 ]; then
  echo "Allowing OpenSSH through firewall."
  ufw allow OpenSSH
  # Enable firewall but only if ssh hole exists.
  if [ $(ufw status | grep -c 'Status: inactive') ]; then
    echo "Enabling firewall."
    ufw enable
  fi
fi
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT END $SCRIPT_NAME $(hostname) ${@:1}"
