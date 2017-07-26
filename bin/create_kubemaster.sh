#!/bin/bash
# Install this on your machine and all kubernetes nodes.  It is mandatory on
# a master node and useful on a worker node.

kubeadm init --pod-network-cidr=10.244.0.0/16 --allocate-node-cidrs=true

# You need to run this after running kubeadm otherwise you will get this error:
#The connection to the server localhost:8080 was refused - did you specify the
# right host or port?
kubeconfig="${KUBECONFIG}"
kubeconfig=${kubeconfig:-"$HOME/${ADMINUSER}/.kube/config"}
_kubeconfig_d=$(dirname $kubeconfig)
if [ ! -d ${_kubeconfig_d} ]; then
  mkdir -p ${_kubeconfig_d}
fi

if [ ! -f $kubeconfig ]; then
  cp /etc/kubernetes/admin.conf $kubeconfig
  chown ${ADMINUSER}:${ADMINUSER} $kubeconfig
fi

kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.6/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.6/canal.yaml

#
# For calico do:
# kubectl apply -f http://docs.projectcalico.org/v2.3/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

# For canal (calico + flannel) do:
# setup the pod network before adding nodes
# On other nodes (output by kubeadm init above)
# eg.
#kubeadm join --token 920611.079ba0f29af6f012 178.62.117.231:6443
