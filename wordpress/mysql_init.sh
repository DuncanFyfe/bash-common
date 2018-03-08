#!/bin/bash
# Create a container volume for the mysql DB
# Populate the DB from an existing DB dump if one exists.

# The development environment MYSQL_DATABASE, MYSQL_USER and MYSQL_PASSWORD
# which ultimately go into the wp-config.php file are different to those of
# the deployed site.
# The Wordpress mysql backup does not include the mysql user details
# but does include the wordpress user details.

# Docker compose environment variables
siteenv="site.env"
[ ! -f $siteenv ] && echo "Unable to find necessary file $siteenv" && exit 1

# Dev site environment variables.
. $siteenv
sitedev="sitedev.sh"
if [ -f $sitedev ]; then
  . $sitedev
fi

echo "MYSQL_DUMP=${MYSQL_DUMP}"
[ "X$MYSQL_VOL" = "X" ] && "Necessary environment variable MYSQL_VOL undefiend." && exit 1

# Look for a wordpress table prefix in the given dump.
# If found, add it to the site.env if we don't already have one.
if [ "X$MYSQL_DUMP" != "X" ]; then
  if [ "X$WORDPRESS_TABLE_PREFIX" = "X" -a -f "$MYSQL_DUMP" ] ; then
    export WORDPRESS_TABLE_PREFIX=$(grep '# Table prefix:' $MYSQL_DUMP | awk '{print $NF}')
    echo "WORDPRESS_TABLE_PREFIX=${WORDPRESS_TABLE_PREFIX}" >> $siteenv
  fi
fi

# If there is no existing docker volume for this wordpress site database
# create one.
# If MYSQL_DUMP points to an exsiting mysql dump then use it.
chk=$(docker volume ls --filter="name=$MYSQL_VOL" --format "{{.Name}}")
if [ "X$chk" = "X" ]; then
  echo "Trying to create docker volume: $MYSQL_VOL"
  chk=$(docker volume create --name "$MYSQL_VOL")
  if [ "X$chk" = "X" ]; then
    echo "Failed to create volume: ${MYSQL_VOL}" 1>&2
    exit 1
  fi
else
  echo "Mysql volume $MYSQL_VOL already exists. Leaving unchanged."
  exit 0
fi

# Use COMPOSE_PROJECT_NAME so we can find the created containers
mysql_container_name="${COMPOSE_PROJECT_NAME}_mysql"
cid=$(docker ps -a --filter "name=${mysql_container_name}" --format "{{.ID}}")
if [ "X$cid" = "X" ]; then
  docker-compose -f mysql-init.yml up -d
  cid=$(docker ps -a --filter "name=${mysql_container_name}" --format "{{.ID}}")
  echo "Database container created: $cid"

  # docker returns before the DB has finished setting up.
  # Monitor the logs for the right phrase count to indicate we have lift-off.
  cmax=20
  nmax=2
  c=0
  n=0
  echo "Allowing time for DB to come up..."
  while [ $c -lt $cmax -a $n -lt $nmax ]; do
    sleep 1
    n=$(docker logs $cid 2>&1 | grep -c 'mysqld: ready for connections')
    let ++c
  done
  if [ $c -eq $cmax -a $n -lt $nmax ]; then
    echo "Retry=$c/$cmax , Log Messages=$n/$nmax"
    echo "Waited too long.  Please manually check the state of the mysql container and volume."
    exit 1
  fi
  echo "Continuing..."

  #cid=$(docker ps -a --filter "name=${COMPOSE_PROJECT_NAME}_mysql" --format "{{.ID}}")
  [ "X$cid" = "X" ] && "Failed to create or find a database container." && exit 1
  echo "Using database container ID: $cid"
  if [ "X$MYSQL_DUMP" != "X" -a "X$cid" != "X" ]; then
    if [ -f $MYSQL_DUMP ]; then
      echo "Populating with database dump $MYSQL_DUMP."
      cat "$MYSQL_DUMP" | docker exec -i $cid /usr/bin/mysql -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE}

      # Allow update of siteurl (WP_SITEURL) and home (WP_HOME) fields.
      # If these are set to the original site then you will not get the
      # development site you are looking for.

      if [ "X$WP_SITEURL" != "X" ]; then
        echo "Using WP_SITEURL=$WP_SITEURL to update siteurl."
        echo "update ${WORDPRESS_TABLE_PREFIX}options set option_value='${WP_SITEURL}' where option_id=1;" | docker exec -i $cid /usr/bin/mysql -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE}
      fi
      if [ "X$WP_HOME" != "X" ]; then
        echo "Using WP_HOME=$WP_HOME to update home."
        echo "update ${WORDPRESS_TABLE_PREFIX}options set option_value='${WP_HOME}' where option_id=2;" | docker exec -i $cid /usr/bin/mysql -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} ${MYSQL_DATABASE}
      fi
    fi
  fi
  docker-compose -f mysql-init.yml stop
fi
echo "Done."
