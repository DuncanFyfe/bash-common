export GITLAB_VERSION="9.1.7-ce.0"
export GITLAB_DOCKER_IMAGE="gitlab/gitlab-ce:${GITLAB_VERSION}"
export GITLAB_NAME='gitlab_9'
export GITLAB_ROOT="$HOST_ROOT/$GITLAB_NAME"
export GITLAB_DATA="${GITLAB_ROOT}/data"
export GITLAB_CONF="${GITLAB_ROOT}/config"
export GITLAB_LOGS="${GITLAB_ROOT}/logs"
export GITLAB_REGISTRY="${GITLAB_ROOT}/registry"

export GITLAB_REDIS_HOST="${REDIS_NAME}"
export GITLAB_REDIS_DB=2
export GITLAB_PG_HOST="${POSTGRES_NAME}"
export GITLAB_PG_USER='gitlab'
export GITLAB_PG_DB='gitlab_production'
export GITLAB_PG_PASSWORD='ABIGLONGSECRET'

export GITLAB_HOST="gitlab.example.com"
export GITLAB_LETSENCRYPT_HOST=$GITLAB_HOST
export GITLAB_LETSENCRYPT_EMAIL=${NGINX_LETSENCRYPT_EMAIL:-"admin@$GITLAB_LETSENCRYPT_HOST"}
