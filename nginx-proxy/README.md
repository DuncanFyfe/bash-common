# NGINX proxy

# Description

This sub-project contains scripts useful for installing a containerized Nginx proxy with letsencrypt support.

To start a container which needs to sit behind the proxy pass the VIRTUAL_HOST, VIRTUAL_PORT and VIRTUAL_PROTO environment variables to the docker container.
In most instances only VIRTUAL_HOST is needed but if the service exposes multiple ports (eg. gitlab) it can be useful to set VIRTUAL_PORT too.

See <https://github.com/jwilder/nginx-proxy> for further details.

# Rancher

This dockerized nginx-proxy does not work with Rancher managed orchestration.
For that you need to try and get rancher-active-proxy working instead.

For further information see:
*   <https://hub.docker.com/r/adi90x/rancher-active-proxy/>
*   <https://github.com/adi90x/rancher-active-proxy>

Simply running it so:
~~~
docker run -p 80:80 -p443:443 --name rancher-active-proxy  \
  --log-driver=journald \
  -e DEFAULT_EMAIL="admin@example.com"
  -v /srv/production/rancher-active-proxy/0/letsencrypt:/etc/letsencrypt
  -v /srv/production/rancher-active-proxy/0/vhost.d:/etc/nginx/vhost.d \
  -v /srv/production/rancher-active-proxy/0/conf.d:/etc/nginx/conf.d \
  -v /srv/production/rancher-active-proxy/0/certs:/etc/nginx/certs \
  -v /srv/production/rancher-active-proxy/0/htpasswd:/etc/nginx/htpasswd:ro \
  -d  adi90x/rancher-active-proxy
~~~
~~~
docker run -d -p 8080:8080 --name=rancher-server -l rap.host=rancher.example.com -l rap.port=8080 -l rap.le_host=rancher.example.com -l rap.le_email=admin@example.com -l io.rancher.container.pull_image=always rancher/server
~~~

does not work as a proxy of the rancher control panel because the proxy needs to run within rancher.
