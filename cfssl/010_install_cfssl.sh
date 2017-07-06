#!/bin/bash
# Download cfssl - SSL certificate tools
#!/bin/bash
export SCRIPT=$(readlink -f "$0")
export SCRIPT_DIR=$(dirname $SCRIPT)
export SCRIPT_NAME=$(basename $SCRIPT)
[ "X$DEBUG" = "XALL" -o "X${DEBUG#*$SCRIPT_NAME}" != "X$DEBUG" ] && echo "SCRIPT BEGIN $SCRIPT_NAME ${@:1}"
. $SCRIPT_DIR/project.sh

load 'cfssl' 'cfssl.sh'

#https://github.com/cloudflare/cfssl
if [ ! -f ${CFSSL} ]; then
  echo "curl -s -L -o \"${CFSSL}\" \"https://pkg.cfssl.org/${CFSSL_VERSION}/${CFSSL_DOWNLOAD}\""
  curl -s -L -o "${CFSSL}" "https://pkg.cfssl.org/${CFSSL_VERSION}/${CFSSL_DOWNLOAD}"
  chmod +x ${CFSSL}
fi

if [ ! -f ${CFSSLJSON} ]; then
  debug "$SCRIPT_NAME//Download cfssljson."
    echo "curl -s -L -o \"${CFSSLJSON}\" \"https://pkg.cfssl.org/${CFSSL_VERSION}/${CFSSLJSON_DOWNLOAD}\""
  curl -s -L -o "${CFSSLJSON}" "https://pkg.cfssl.org/${CFSSL_VERSION}/${CFSSLJSON_DOWNLOAD}"
  chmod +x ${CFSSLJSON}
fi
debug_end
