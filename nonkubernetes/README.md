# Non Kubernetes


This sub-project contains scripts useful for installing a docker containerized services. These include nginx-proxy with letsencrypt support.  

*  The files Inn-* initializing containers (docker run) and can configure them to be started and stopped using systemd.
*  Files RMnn-* are used to remove containers.
*  Files Knn* are used to (K)ill containers.
*  Files Tnn-* are used to run (T)est containers.

By default systemd is used to manage the containers rather than docker because
it brings sanity to managing dependencies between docker services and host
services.

## NGINX proxy

### Description

Once nginx-proxy, nginx-gen and nginx-letsencrypt are running, to start a
container which needs to sit behind the proxy pass the VIRTUAL_HOST,
VIRTUAL_PORT and VIRTUAL_PROTO environment variables to the docker container.
In most instances only VIRTUAL_HOST is needed but if the service exposes
multiple ports (eg. gitlab) it can be useful to set VIRTUAL_PORT too.

See <https://github.com/jwilder/nginx-proxy> for further details.

### Rancher Control Panel Proxy

This dockerized nginx-proxy does not work as a proxy for the rancher control
panel.  For that it is reported that you need to try and get
rancher-active-proxy working instead.  I've not got it working myself yet.

For further information see:
*   <https://hub.docker.com/r/adi90x/rancher-active-proxy/>
*   <https://github.com/adi90x/rancher-active-proxy>

The "simple way" (run it as a docker container) does not work.  Some people have reported success running rancher then running it within rancher but I hit a brick wall because my control panel is accessed from a host which is not a worker.   The proxy gets hived of to a worker which cannot act as a control panel proxy because it is running on the wrong host.
