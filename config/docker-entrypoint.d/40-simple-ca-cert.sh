#!/bin/bash

################################################################################

# Initialize CA's directory
if [ ! -e /var/lib/simple-ca/serial ]; then
  info "Initializing CA directory ${SIMPLE_CA_DIR}"
  for DIR in . certs newcerts secrets; do
    mkdir -p ${SIMPLE_CA_DIR}/${DIR}
    chmod 750 ${SIMPLE_CA_DIR}/${DIR}
  done
  echo -n > ${SIMPLE_CA_DIR}/index
  echo -n "01" > ${SIMPLE_CA_DIR}/serial
  chmod 644 ${SIMPLE_CA_DIR}/index ${SIMPLE_CA_DIR}/serial
fi

################################################################################

# Create CA private key and certificate
if [ ! -e ${CA_KEY_FILE} -o ! -e ${CA_CRT_FILE} ]; then
  info "Creating CA private key file ${CA_KEY_FILE}"
  # Get CA private key passphrase
  if [ -e "${CA_KEY_PWD_FILE}" ]; then
    info "Using CA private key passphrase file ${CA_KEY_PWD_FILE}"
  else
    info "Creating random CA private key passphrase file ${CA_KEY_PWD_FILE}"
    mkdir -p $(dirname ${CA_KEY_PWD_FILE})
    openssl rand -hex 32 > ${CA_KEY_PWD_FILE}
  fi
  info "Creating CA certificate file ${CA_CRT_FILE}"
  openssl req -x509 -days 36520 \
    -subj "/${CA_CRT_SUBJECT}" \
    -newkey rsa:2048 \
    -keyout ${CA_KEY_FILE} \
    -passout file:${CA_KEY_PWD_FILE} \
    -out ${CA_CRT_FILE}
  chmod o-rwx ${CA_KEY_FILE}
else
  info "Using CA private key file ${CA_KEY_FILE}"
  info "Using CA certificate file ${CA_CRT_FILE}"
fi

################################################################################

# Paths in openssl.cnf must be hardcoded because LibreSSL removed support
# for ${ENV::VARIABLE}
if [ "$(dirname ${CA_CRT_FILE})" != "${SIMPLE_CA_DIR}/secrets" ]; then
  if [ ! -e "${SIMPLE_CA_DIR}/secrets/ca.crt" ]; then
    debug "Creating link ${SIMPLE_CA_DIR}/secrets/ca.crt => ${CA_CRT_FILE}"
    ln -s ${CA_CRT_FILE} ${SIMPLE_CA_DIR}/secrets/ca.crt
    debug "Changing owner of ${CA_CRT_FILE} to ${LIGHTTPD_FILE_OWNER}"
    chown ${LIGHTTPD_FILE_OWNER} ${CA_CRT_FILE}
  fi
fi
if [ "${CA_KEY_FILE}" != "${SIMPLE_CA_DIR}/secrets/ca.key" ]; then
  if [ ! -e "${SIMPLE_CA_DIR}/secrets/ca.key" ]; then
    debug "Creating link ${SIMPLE_CA_DIR}/secrets/ca.key => ${CA_KEY_FILE}"
    ln -s ${CA_KEY_FILE} ${SIMPLE_CA_DIR}/secrets/ca.key
    debug "Changing owner of ${CA_KEY_FILE} to ${LIGHTTPD_FILE_OWNER}"
    chown ${LIGHTTPD_FILE_OWNER} ${CA_KEY_FILE}
  fi
fi

################################################################################

# Get CA user name
if [ -e ${CA_USER_NAME_FILE} ]; then
  CA_USER_NAME=$(cat ${CA_USER_NAME_FILE})
  info "Using CA user name ${CA_USER_NAME} from ${CA_USER_NAME_FILE}"
else
  CA_USER_NAME=$(openssl rand -hex 8)
  info "Creating random CA user name ${CA_USER_NAME}"
fi
if [ ! -e ${CA_USER_NAME_FILE} ]; then
  info "Saving CA user name to ${CA_USER_NAME_FILE}"
  echo "${CA_USER_NAME}" > ${CA_USER_NAME_FILE}
fi

# Get CA user passowrd
if [ -e ${CA_USER_PWD_FILE} ]; then
  info "Using CA user password from ${CA_USER_PWD_FILE}"
  CA_USER_NAME_PWD=$(cat ${CA_USER_PWD_FILE})
else
  info "Creating random CA user password"
  CA_USER_NAME_PWD=$(openssl rand -hex 32)
fi
if [ ! -e ${CA_USER_PWD_FILE} ]; then
  info "Saving CA user password to ${CA_USER_PWD_FILE}"
  echo "${CA_USER_NAME_PWD}" > ${CA_USER_PWD_FILE}
fi

################################################################################

# Get server private key passphrase
if [ -e "${SERVER_KEY_PWD_FILE}" ]; then
  info "Using server private key passphrase from ${SERVER_KEY_PWD_FILE}"
  SERVER_KEY_PWD=$(cat ${SERVER_KEY_PWD_FILE})
else
  info "Creating random server private key passphrase"
  SERVER_KEY_PWD=$(openssl rand -hex 32)
fi
if [ ! -e ${SERVER_KEY_PWD_FILE} ]; then
  info "Saving CA user password to ${SERVER_KEY_PWD_FILE}"
  echo "${SERVER_KEY_PWD}" > ${SERVER_KEY_PWD_FILE}
fi

################################################################################

# Set permissions
debug "Changing owner of ${SIMPLE_CA_DIR} to ${LIGHTTPD_FILE_OWNER}"
chown -R ${LIGHTTPD_FILE_OWNER} ${SIMPLE_CA_DIR}
debug "Changing mode of ${CA_CRT_FILE} to 444"
chmod 444 ${CA_CRT_FILE}
debug "Changing mode of ${CA_KEY_FILE} to 440"
chmod 440 ${CA_KEY_FILE}
debug "Changing mode of ${CA_KEY_PWD_FILE} to 440"
chmod 440 ${CA_KEY_PWD_FILE}
debug "Changing mode of ${CA_USER_NAME_FILE} to 440"
chmod 440 ${CA_USER_NAME_FILE}
debug "Changing mode of ${CA_USER_PWD_FILE} to 440"
chmod 440 ${CA_USER_PWD_FILE}
debug "Changing mode of ${SERVER_KEY_PWD_FILE} to 440"
chmod 440 ${SERVER_KEY_PWD_FILE}

################################################################################

# Only create CA certificate, private key and passphrase and CA user secrets
# and then exit
if [ "$1" = "secrets" ]; then
  exit 0
fi

################################################################################

# Export variables for /etc/lighttpd/server.conf and /var/www/simple-cgi.sh
export SIMPLE_CA_DIR CA_KEY_PWD_FILE CA_CRT_FILE CA_USER_NAME CA_USER_REALM

################################################################################

# Create server private key and certificate
if [ ! -e "${SERVER_CRT_FILE}" ]; then
  info "Creating server private key file ${SERVER_KEY_FILE}"

  # Get server certificate attributes
  info "Creating server certificate file ${SERVER_CRT_FILE}"
  SERVER_CRT_REQ_HOST="${SERVER_CRT_HOST},${HOSTNAME},localhost"
  SERVER_CRT_REQ_IP="${SERVER_CRT_IP},$(
    ifconfig |
    grep "inet addr:" |
    sed -E "s/.*inet addr:([^ ]*).*/\1/" |
    tr "\n" ","
  )"
  debug "DN:  ${SERVER_CRT_SUBJECT}"
  debug "DNS: ${SERVER_CRT_REQ_HOST}"
  debug "IP:  ${SERVER_CRT_REQ_IP}"
  debug "OID: ${SERVER_CRT_OID}"

  # Create server private key and certificate
  openssl req \
    -subj "/${SERVER_CRT_SUBJECT}" \
    -newkey rsa:2048 \
    -keyout "${SERVER_KEY_FILE}" \
    -passout "pass:${SERVER_KEY_PWD}" |
  env \
    CA_DIR=${SIMPLE_CA_DIR} \
    PATH_INFO="/sign" \
    QUERY_STRING="dn=${SERVER_CRT_SUBJECT}&dns=${SERVER_CRT_REQ_HOST}&ip=${SERVER_CRT_REQ_IP}&rid=${SERVER_CRT_OID}" \
  /var/www/simple-ca.cgi |
  egrep -v "^(HTTP/.*|Content-Type:.*|)$" > ${SERVER_CRT_FILE}

  # Set permissions
  debug "Changing owner of ${SIMPLE_CA_DIR} to ${LIGHTTPD_FILE_OWNER}"
  chown -R ${LIGHTTPD_FILE_OWNER} ${SIMPLE_CA_DIR}
fi

################################################################################
