#!/bin/bash

debug0 "Processing $(basename ${DOCKER_ENTRYPOINT:-$0})"

################################################################################
# Initialize CA's directory
if [ ! -e /var/lib/simple-ca/serial ]; then
  info "Initializing CA directory /var/lib/simple-ca"
  mkdir -p /var/lib/simple-ca/newcerts /var/lib/simple-ca/secrets
  touch /var/lib/simple-ca/index
  if [ -e ${SERVER_CRT} ]; then
    # SERVER_CRT has serial number 01, start from 02
    echo -n "02" > /var/lib/simple-ca/serial
  else
    echo -n "01" > /var/lib/simple-ca/serial
  fi
fi

# Create CA private key and certificate
if [ ! -e ${CA_KEY} -o ! -e ${CA_CRT} ]; then
  info "Creating CA private key ${CA_KEY}"
  info "Creating CA certificate ${CA_CRT}"
  openssl req -x509 -days 36520 \
    -subj "/${CA_CRT_SUBJECT}" \
    -newkey rsa:2048 \
    -keyout ${CA_KEY} \
    -passout file:${CA_KEY_PWD_FILE} \
    -out ${CA_CRT}
  chmod o-rwx ${CA_KEY}
else
  info "Using CA private key ${CA_KEY}"
  info "Using CA certificate ${CA_CRT}"
fi

################################################################################
# Only create CA private key, passphrase and certificate
if [ "$1" = "secrets" ]; then
  # Save CA web server password
  if [ ! -e ${CA_USER_PWD_FILE} ]; then
    info "Saving CA web server user password to ${CA_USER_PWD_FILE}"
    echo "${CA_USER_PWD}" > ${CA_USER_PWD_FILE}
  fi
  exit
fi

################################################################################
# Create server private key and cetificate
if [ ! -e "${SERVER_CRT}" ]; then
  info "Creating server certificate ${SERVER_CRT}"
  # Subject alternative names
  SERVER_CRT_NAMES="${SERVER_CRT_NAMES},${HOSTNAME},localhost"
  # Container IPv4 addresses
  SERVER_CRT_IP=$(
    ifconfig |
    grep "inet addr:" |
    sed -E "s/.*inet addr:([^ ]*).*/\1/" |
    tr "\n" ","
  )
  # Create private key and certificate
  # NOTE: lighttpd does not support server private key passphrase
  openssl req \
    -subj "/${SERVER_CRT_SUBJECT}" \
    -nodes \
    -newkey rsa:2048 \
    -keyout "${SERVER_KEY}" |
  env \
    PATH_INFO="/sign" \
    QUERY_STRING="dn=${SERVER_CRT_SUBJECT}&dns=${SERVER_CRT_NAMES}&ip=${SERVER_CRT_IP}&rid=${SERVER_CRT_RID}" \
  /var/www/simple-ca.cgi |
  egrep -v "^(HTTP/.*|Content-Type:.*|)$" > ${SERVER_CRT}
  cat ${SERVER_KEY} >> ${SERVER_CRT}
  chmod o-rwx ${SERVER_CRT}
  rm -f ${SERVER_KEY}
else
  info "Using server private key and certificate ${SERVER_CRT}"
fi

################################################################################
# Setup user database
if [ ! -e ${SERVER_USER_DB} ]; then
  info "Setting up user database ${SERVER_USER_DB}"
  info "- ${CA_USER}"
  CA_USER_DIGEST=$(echo -n "${CA_USER}:${CA_USER_REALM}:${CA_USER_PWD}" | md5sum | cut -b -32)
  echo "${CA_USER}:${CA_USER_REALM}:${CA_USER_DIGEST}" > ${SERVER_USER_DB}
else
  info "Using user database ${SERVER_USER_DB}"
fi

################################################################################
# Set permissions
chown -R lighttpd:lighttpd /var/lib/simple-ca ${SERVER_USER_DB}
chmod -R o-rwx /var/lib/simple-ca ${SERVER_USER_DB}
