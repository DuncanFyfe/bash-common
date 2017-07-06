# Host location for systemd files.
export SYSYEMD_DIR='/etc/systemd/system'
export HOST_ROOT='/srv/production'

export NGINX_PROXY_NAME="nginx_proxy"
export NGINX_PROXY_VERSION="1"
export NGINX_PROXY_ROOT=$HOST_ROOT/$NGINX_PROXY_NAME/${NGINX_PROXY_VERSION}

export NGINX_GEN_NAME="nginx_gen"
export NGINX_GEN_VERSION="0"
export NGINX_GEN_ROOT=$HOST_ROOT/$NGINX_GEN_NAME/${NGINX_GEN_VERSION}

export NGINX_LENTENCRYPT_NAME="nginx_letsencrypt"
export NGINX_LENTENCRYPT_VERSION="1"

export REDIS_NAME='redis'
export REDIS_VERSION="3"
export REDIS_ROOT="$HOST_ROOT/$REDIS_NAME/${REDIS_VERSION}"

export REGISTRY_NAME='docker_registry'
export REGISTRY_VERSION=2
export REGISTRY_REDIS_DB=1
export REGISTRY_ROOT="${HOST_ROOT}/${REGISTRY_NAME}/${REGISTRY_VERSION}"
export REGISTRY_REDIS_HOST="${REDIS_NAME}"
export REGISTRY_REDIS_DB=1

export GITLAB_NAME='gitlab'
export GITLAB_VERSION="9.1.7-ce.0"
export GITLAB_ROOT="$HOST_ROOT/$GITLAB_NAME/${GITLAB_VERSION}"
export GITLAB_REDIS_HOST="${REDIS_NAME}"
export GITLAB_REDIS_DB=2
export GITLAB_PG_HOST="${POSTGRES_NAME}"
export GITLAB_PG_USER='gitlab'
export GITLAB_PG_DB='gitlab_production'
export GITLAB_PG_PASSWORD='ABIGLONGSECRET'
