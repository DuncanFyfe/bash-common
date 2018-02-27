#!/bin/bash
if [ "$(id -u)" != "0" ]; then
    /usr/bin/sudo $0 $*
    exit 0
fi
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)

. $SCRIPT_DIR/common.sh
. $SCRIPT_DIR/config.sh
cd $SCRIPT_DIR

NGINX_TEST_NAME="nginx_test"
NGINX_TEST_ROOT="$HOST_ROOT/$NGINX_TEST_NAME"
hosthtml=$NGINX_TEST_ROOT/html
hostname="do-2gb-fra1-01.example.com"

for dir in $NGINX_TEST_ROOT $hosthtml; do
  makedir $dir
done

if [ ! -f "$hosthtml/index.html" ]; then
  echo '<!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>nginx-test</title> </head> <body> <h1>Hello, world!</h!> </body> </html>' > "$hosthtml/index.html"
  assert_file $hosthtml/index.html
fi

passwdfile="$NGINX_PROXY_ROOT/htpasswd/$hostname"
if [ ! -f "$passwdfile" ]; then
  user='testuser'
  password="Xdi2wigT8eWfzJqtOrUmGG33dUqQsYID"
  docker run --rm --entrypoint htpasswd registry:2 -bn $user $password > $passwdfile
  assert_file $passwdfile
fi

assert_docker_container $NGINX_LENTENCRYPT_NAME
rm_container $NGINX_TEST_NAME

docker run --name $NGINX_TEST_NAME --log-driver=journald \
  -e "VIRTUAL_HOST=$hostname" \
  -e "LETSENCRYPT_HOST=$hostname" \
  -e "LETSENCRYPT_EMAIL=accounts@example.com" \
  -v $hosthtml:/usr/share/nginx/html:ro \
  -d nginx:alpine

echo "docker inspect --format '{{ index (index .Config.Env) }}' nginx-test"
