#!/bin/bash
# Create a new Certificate Authority (CA) if one does not exist.
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)

$SCRIPT_DIR/10_bootstrap.sh
$SCRIPT_DIR/20_install_cfssl.sh
$SCRIPT_DIR/21_create_root_ca.sh
$SCRIPT_DIR/22_create_intermediate_ca.sh
$SCRIPT_DIR/40_create_etcd_scripts.sh
$SCRIPT_DIR/50_create_flanneld_scripts.sh
$SCRIPT_DIR/60_create_kube_scripts.sh
$SCRIPT_DIR/90_create_deploy_scripts.sh
$SCRIPT_DIR/99_sync.sh
