export NODE_USER='core'
export NODE_BUILD_ROOT="/home/${NODE_USER}/kubernetes"
export NODE_HOSTNAME='host2.example.com'
export NODE_IP_ADDR='192.168.10.21'
export SYNC_HOST='TRUE'

export ETCD_PROFILE='server'
export ETCD_NODENAME='etcd1.example.com'
export ETCD_NODENAMES="etcd1.example.com,${NODE_IP_ADDR},etcd1.local,etcd1"
export KUBE_PROFILE='worker'
export KUBE_NODENAME='kube1.example.com'
export KUBE_NODENAMES="kube1.example.com,${NODE_IP_ADDR},kube1.local,kube2"
