export NODE_USER='core'
export NODE_BUILD_ROOT="/home/${NODE_USER}/kubernetes"
export NODE_HOSTNAME='host2.example.com'
export NODE_IP_ADDR='192.168.10.22'
export SYNC_HOST='TRUE'

export ETCD_PROFILE='server'
export ETCD_NODENAME='etcd2.example.com'
export ETCD_NODENAMES="etcd2.example.com,${NODE_IP_ADDR},etcd2.local,etcd2"
export KUBE_PROFILE='worker'
export KUBE_NODENAME='kube2.example.com'
export KUBE_NODENAMES="kube2.example.com,${NODE_IP_ADDR},kube2.local,kube2"
