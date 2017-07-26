export ETCD_SSL_DIR='/etc/ssl/certs'
export ETCD_NODES="etcd1.example.com,etcd2.example.com,etcd3.example.com,etcdadmin.example.com"
export ETCD_ENDPOINTS="https://etcd3.example.com:2379,https://etcd2.example.com:2379,https://etcd1.example.com:2379"
# Regenerate ETCD_DISCOVERY with
# curl -w "\n" "https://discovery.etcd.io/new?size=3"
export ETCD_DISCOVERY="https://discovery.etcd.io/c85fe61ff93dbe67444a7891838a4b3b"
# Default Node certificate authority
ETCD_CA="$INTER_CA_NAME"

ETCD_ADVERTISE_CLIENT_URLS="https://${ETCD_NODENAME}:2379"
ETCD_AUTO_COMPACTION_RETENTION='1'
ETCD_DATA_DIR="${HOST_ROOT}/etcd/${ETCD_INITIAL_CLUSTER_TOKEN}"
ETCD_DEBUG='false'
ETCD_DISCOVERY_SRV='discovery.example.com'
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://${ETCD_NODENAME}:2380"
ETCD_PROXY='off'
