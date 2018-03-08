#!/bin/bash
# Create a container volume for the wordpress content.
# Populate with existing data if provided.

siteenv="site.env"

[ ! -f $siteenv ] && echo "Unable to find necessary file $siteenv" && exit 1

. $siteenv
sitedev="sitedev.sh"
if [ -f $sitedev ]; then
  . $sitedev
fi

[ "X$WP_VOL" = "X" ] && "Necessary environment variable WP_VOL undefiend." &&

WP_CONTENT=${1:-WP_CONTENT}
echo "WP_CONTENT=$WP_CONTENT"

# If there is no existing docker volume for the wordpress site content then
# create one.  If WORDPRESS_CONTENT points to exsiting content
# (/var/www/html/wp-content) for a wordpress site then copy it into the volume.
vid=$(docker volume ls --filter="name=$WP_VOL" --format "{{.Name}}")
if [ "X$vid" = "X" ]; then
  docker volume create --name "$WP_VOL"
  vid=$(docker volume ls --filter="name=$WP_VOL" --format "{{.Name}}")
  if [ "X$vid" = "X" ]; then
    echo "Failed to create volume: ${WP_VOL}" 1>&2
    exit 1
  fi

  if [ "X$WP_CONTENT" != "X" ]; then
    if [ -d $WP_CONTENT ]; then
      _pwd=$PWD
      cd $WP_CONTENT
      # Use busybox helper container to copy wordpress content into the
      # volume.
      busybox_container_helper="${COMPOSE_PROJECT_NAME}_helper"
      docker rm ${busybox_container_helper}

      docker run -v "$WP_VOL:/docroot" --name $busybox_container_helper busybox mkdir /docroot/wp-content
      cid=$(docker ps -a --filter "name=${busybox_container_helper}" --format "{{.ID}}")
      echo "WP Helper container = $cid"
      if [ "X$cid" = "X" ]; then
        echo "Failed to create busybox container to copy given worpress content."
      fi
      docker cp . ${busybox_container_helper}:/docroot/wp-content
      docker stop ${busybox_container_helper}
      docker rm ${busybox_container_helper}

      # Make sure permissions are set correctly for the WP content.
      echo "Setting owner of files to ${HTTP_USER}."
      docker run --rm -v "$WP_VOL:/docroot" --name $busybox_container_helper busybox chown -R ${HTTP_USER}:${HTTP_USER} /docroot/wp-content
      echo "Done."

      cd $_pwd
    fi
  fi
else
  echo "Docker volume $WP_VOL already exists. Leaving unchanged."
  exit 0
fi
