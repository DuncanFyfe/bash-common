#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'docker' 'docker.sh'
load 'docker' 'redis.sh'
load 'docker' 'registry.sh'

cd $SCRIPT_DIR

assert_container $REDIS_NAME

for dir in $REGISTRY_ROOT $REGISTRY_DATA $REGISTRY_ETC; do
  makedir $dir
done

# Local Configuration
srcconf="$SCRIPT_DIR/registry.yml"
hostconf="$REGISTRY_ETC/config.yml"


if [ -f $srcconf -a ! -f "$hostconf" ]; then
  cp $srcconf $hostconf
  template_substitution $hostconf REGISTRY_REDIS_DB REGISTRY_REDIS_DB
  chmod a+r $hostconf
fi

#
# Add an nginx-proxy based htpasswd file to provide initial protection to the
# registry. # This can be deleted later one other authentication mechanisms
# are configured.
#
ADMIN_USER="admin"
make_password ADMIN_PASSWORD 32
add_password "$REGISTRY_HOST" "$ADMIN_USER" "$ADMIN_PASSWORD"
echo "nginx-proxy admin credentials: $ADMIN_USER:$ADMIN_PASSWORD"

systemctl stop "docker-container@${REGISTRY_NAME}.service"
rm_container $REGISTRY_NAME
docker run --name $REGISTRY_NAME --log-driver=journald \
  -e "VIRTUAL_HOST=$REGISTRY_HOST" \
  -e "VIRTUAL_PORT=5000" \
  -e "LETSENCRYPT_HOST=$REGISTRY_LETSENCRYPT_HOST" \
  -e "LETSENCRYPT_EMAIL=$REGISTRY_LETSENCRYPT_EMAIL" \
  --link $REDIS_NAME:$REGISTRY_REDIS_HOST \
  -p 5000:5000 \
  -v $REGISTRY_DATA:/var/lib/registry \
  -v $hostconf:/etc/docker/registry/config.yml:ro \
  -d ${REGISTRY_DOCKER_IMAGE}

assert_container $REGISTRY_NAME
configure_systemd $REGISTRY_NAME "docker-container@${REDIS_NAME}.service" "docker-container@${REDIS_NAME}.service"
enable_systemd ${REGISTRY_NAME}
