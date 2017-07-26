#!/bin/bash
etcdctl --peers "https://etcd1.example.com:2379,https://etcd2.example.com:2379,https://etcd3.example.com:2379" --cert-file my-client.pem --key-file my-client-key.pem --ca-file my_intermediate_ca.pem

curl --cert $PWD/my-client.pem --key my-client-key.pem  --cacert $PWD/my_intermediate_ca.pem -X PUT https://etcd1.example.com:2379/v2/keys/message2 -d value="Hello, World!"
