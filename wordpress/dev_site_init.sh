#!/bin/bash
# Initilize a directory with contents for docker wordpress site for development
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh
load 'docker' 'docker.sh'

if [ -f "setup-config.sh" ]; then
  # Allow the user to setup a configuration before running this script.
  # Keep it separate from sitedev.sh the runtime configuration.
  . setup-config.sh
fi

function user_help {
  echo "Usage:\n\t$SCRIPT_NAME WP_SITE [ MYSQL_DUMP_FILE [ WP_CONTENT_FOLDER ]]"
  echo "WP_SITE be the wordpress site (eg. www.example.com)"
  echo "MYSQL_DUMP_FILE MYSQL dump from an existing wordpress site."
  echo "WP_CONTENT the content from an existing wordpress site."
  echo ""
  echo "Help: This script should be run from the top-level directory of the wordpress site development directory."
  echo "By default, I name these directories the same as my \$WP_SITE value."
  echo ""
  echo "If a file 'setup-config.sh' exists in the current working directory it"
  echo "will be sources.  This allows environment variables to be set  before"
  echo "this script is run.  The command-line options WP_SITE, MYSQL_DUMP_FILE"
  echo "and WP_CONTENT_FOLDER can be set in this file rather than on the command line."
  echo ""
  echo "The following variables are used by the docker containers.  See the docker image documentation for details:"
  echo "\tMYSQL_ALLOW_EMPTY_PASSWORD, MYSQL_DATABASE, MYSQL_PASSWORD, "
  echo "\tMYSQL_ROOT_PASSWORD, MYSQL_USER, WORDPRESS_DB_NAME, "
  echo "\tWORDPRESS_DB_PASSWORD, WORDPRESS_DB_USER, WORDPRESS_DEBUG, "
  echo "\tWORDPRESS_TABLE_PREFIX"
  echo "Randomized passwords are created if none are given."
  echo "Database and user names are constructed from WP_SITE if not given."
  echo ""
  echo "The following variables are used to construct the docker-compose"
  echo "files:"
  echo "\tADMINER_IMAGE, MYSQL_IMAGE, WP_IMAGE"
  echo ""
  echo "The following variables are used by this and the other development init scripts:"
  echo "\tCOMPOSE_PROJECT_NAME, HTTP_USER, MYSQL_DUMP, MYSQL_VOL, WP_CONTENT,"
  echo "\tWP_HOME, WP_SITE, WP_SITEURL, WP_VOL"
  echo ""

  exit 1
}

# Command line options with no default
WP_SITE=${1:-$WP_SITE}
if [ "X$WP_SITE" = "X" ]; then
  user_help
fi
assert_var WP_SITE
MYSQL_DUMP=${2:-MYSQL_DUMP}
WP_CONTENT=${3:-WP_CONTENT}

# Options where a meaningful default can be assumed.
ADMINER_IMAGE=${ADMINSER:-"adminer"}
HTTP_USER=${HTTP_USER:-"www-data"}
MYSQL_IMAGE=${MYSQL_IMAGE:-"mysql:5.6"}
WP_IMAGE=${WP_IMAGE:-"wordpress:4-php7.0"}
_default_wp_siteurl="http://localhost:8080"
_default_wp_home="http://localhost:8080"
WP_SITEURL=${WP_SITEURL:-$_default_wp_siteurl}
WP_HOME=${WP_HOME:-$_default_wp_home}

# Root directory (local filesystem) of our development site.
# Assume we are in that directory.
WP_SITE_ROOT=$PWD

_default_compose_project_name=$(echo -n $WP_SITE| tr -cd '[[:alnum:]]')
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-$_default_compose_project_name}

# Setting COMPOSE_PROJECT_NAME causes it to be prefixed onto the volume names.
# That is why the docker-compose yml files do not have the prefix
# but _VOL variables below do.
MYSQL_VOL="${COMPOSE_PROJECT_NAME}_mysql_v"
debug "MYSQL_VOL=$MYSQL_VOL"
WP_VOL="${COMPOSE_PROJECT_NAME}_wordpress_v"
debug "WP_VOL=$WP_VOL"

for t in "mysql-init.yml" "docker-compose.yml"; do
  debug "template=$t"
  get_template tpl wordpress "$t"
  if [ "X${tpl}" != "X" ]; then
    if [ -f ${tpl} ]; then
      _dest="${WP_SITE_ROOT}/$(basename ${tpl})"
      debugenv _dest
      debug "cp ${tpl} $_dest"
      cp ${tpl} $_dest
      assert_file $_dest
      template_substitution $_dest ADMINER_IMAGE MYSQL_IMAGE WP_IMAGE
    fi
  fi
done

### Create the site.env file containing the necessary docker-compose
# environment variables.
###
siteenv="${WP_SITE_ROOT}/site.env"
debug "siteenv=$siteenv"
rm -f $siteenv
touch $siteenv

# Create random passwords if we need them

MYSQL_ALLOW_EMPTY_PASSWORD=${MYSQL_ALLOW_EMPTY_PASSWORD:-'N'}
_default_mysql_database=$(echo -n $WP_SITE| tr -c '[[:alnum:]]' '_')
MYSQL_DATABASE=${MYSQL_DATABASE:-$_default_mysql_database}
make_password _default_mysql_password 32
MYSQL_PASSWORD=${MYSQL_PASSWORD:-$_default_mysql_password}
make_password _default_mysql_root_password 32
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$_default_mysql_root_password}
_default_mysql_user=$(echo $MYSQL_DATABASE| tr -cd '[[:alnum:]]')
MYSQL_USER=${MYSQL_USER:-$_default_mysql_user}

echo "MYSQL_ALLOW_EMPTY_PASSWORD=${MYSQL_ALLOW_EMPTY_PASSWORD}" >> $siteenv
echo "MYSQL_DATABASE=${MYSQL_DATABASE}" >> $siteenv
echo "MYSQL_PASSWORD=${MYSQL_PASSWORD}" >> $siteenv
echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" >> $siteenv
echo "MYSQL_USER=${MYSQL_USER}" >> $siteenv

WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME:-$MYSQL_DATABASE}
WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD:-$MYSQL_PASSWORD}
WORDPRESS_DB_USER=${WORDPRESS_DB_USER:-$MYSQL_USER}
WORDPRESS_DEBUG=${WORDPRESS_DEBUG:-1}
echo "WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}" >> $siteenv
echo "WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}" >> $siteenv
echo "WORDPRESS_DB_USER=${WORDPRESS_DB_USER}" >> $siteenv
echo "WORDPRESS_DEBUG=${WORDPRESS_DEBUG}" >> $siteenv


### Create development site environment variables that may be needed
# by development scripts but not by docker-compose.
###

sitedevenv="${WP_SITE_ROOT}/sitedev.sh"
debug "sitedevenv=$sitedevenv"
rm -f $sitedevenv
touch $sitedevenv
echo "ADMINER_IMAGE=${ADMINER_IMAGE}" >> $sitedevenv
echo "COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}"  >> $sitedevenv
echo "HTTP_USER=${HTTP_USER}"  >> $sitedevenv
if [ "X$MYSQL_DUMP" != "X" ]; then
  echo "MYSQL_DUMP=$MYSQL_DUMP" >> $sitedevenv
else
  echo "#MYSQL_DUMP=" >> $sitedevenv
fi
echo "MYSQL_IMAGE=$MYSQL_IMAGE" >> $sitedevenv
echo "MYSQL_VOL=$MYSQL_VOL" >> $sitedevenv

if [ "X$WP_CONTENT" != "X" ]; then
  echo "WP_CONTENT=$WP_CONTENT" >> $sitedevenv
else
  echo "#WP_CONTENT=" >> $sitedevenv
fi
echo "WP_IMAGE=$WP_IMAGE" >> $sitedevenv
echo "WP_HOME=${WP_HOME}" >> $sitedevenv
echo "WP_SITE=$WP_SITE" >> $sitedevenv
echo "WP_SITEURL=$WP_SITEURL" >> $sitedevenv
echo "WP_VOL=$WP_VOL" >> $sitedevenv
