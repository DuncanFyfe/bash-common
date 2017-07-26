export NODE_USER='core'
export NODE_BUILD_ROOT="/home/${NODE_USER}/kubernetes"
export NODE_HOSTNAME='host2.example.com'
export NODE_IP_ADDR='192.168.10.23'
export SYNC_HOST='TRUE'

export ETCD_PROFILE='server'
export ETCD_NODENAME='etcd3.example.com'
export ETCD_NODENAMES="etcd3.example.com,${NODE_IP_ADDR},etcd3.local,etcd3"
export KUBE_PROFILE='worker'
export KUBE_NODENAME='kube3.example.com'
export KUBE_NODENAMES="kube3.example.com,${NODE_IP_ADDR},kube3.local,kube2"
