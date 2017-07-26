#!/bin/bash
# Install this on your machine and all kubernetes nodes.  It is mandatory on
# a master node and useful on a worker node.

kube_token=$1
_kube_token="${KUBE_TOKEN}"
kube_token="${kube_token:-$_kube_token}"

master_node=$2
_master_node="${MASTER_NODE}"
master_node="${master_node:-$_master_node}"

kubeadm join --token $kube_token ${master_node}:6443
#
# For calico do:
# kubectl apply -f http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

# For canal (calico + flannel) do:
# setup the pod network before adding nodes
# On other nodes (output by kubeadm init above)
#kubeadm join --token 920611.079ba0f29af6f012 178.62.117.231:6443
