#!/bin/bash

debug0 "Processing $(basename ${DOCKER_ENTRYPOINT:-$0})"

################################################################################
# OpenSSL random file
export RANDFILE=${SIMPLE_CA_DIR}/.rnd

################################################################################
# Default CA user name and realm
: ${CA_USER:=agent007}
: ${CA_USER_REALM:=Docker Simple CA}

# Default CA user password file location
if [ -e /run/secrets/ca_user.pwd ]; then
  : ${CA_USER_PWD_FILE:=/run/secrets/ca_user.pwd}
else
  : ${CA_USER_PWD_FILE:=${SIMPLE_CA_DIR}/secrets/ca_user.pwd}
fi

################################################################################
# Default CA certificate subject
: ${CA_CRT_SUBJECT:=CN=${CA_USER_REALM}}

# Default CA certificate file location
if [ -e /run/secrets/ca_crt.pem ]; then
  : ${CA_CRT:=/run/secrets/ca_crt.pem}
else
  : ${CA_CRT:=${SIMPLE_CA_DIR}/secrets/ca_crt.pem}
fi

# Default CA private key file location
if [ -e /run/secrets/ca_key.pem ]; then
  : ${CA_KEY:=/run/secrets/ca_key.pem}
else
  : ${CA_KEY:=${SIMPLE_CA_DIR}/secrets/ca_key.pem}
fi

# Default CA private key passphrase file
if [ -e /run/secrets/ca_key.pwd ]; then
  : ${CA_KEY_PWD_FILE:=/run/secrets/ca_key.pwd}
else
  : ${CA_KEY_PWD_FILE:=${SIMPLE_CA_DIR}/secrets/ca_key.pwd}
fi

# Paths must be hardcoded in openssl.cnf because LibreSSL removed support
# for ${ENV::VARIABLE} in openssl.cnf
sed -i -E \
  -e "s|%%SIMPLE_CA_DIR%%|${SIMPLE_CA_DIR}|" \
  -e "s|%%CA_CRT%%|${CA_CRT}|" \
  -e "s|%%CA_KEY%%|${CA_KEY}|" \
  /etc/ssl/openssl.cnf

# CA private key passphrase
if [ -e "${CA_KEY_PWD_FILE}" ]; then
  info "Using CA private key passphrase ${CA_KEY_PWD_FILE}"
else
  info "env"
  env | sort
  info "Creating random CA private key passphrase"
  mkdir -p $(dirname ${CA_KEY_PWD_FILE})
  openssl rand -hex 32 > ${CA_KEY_PWD_FILE}
  # Permissioins will be set later
fi

# Export variables for simple-ca.sh CGI scripts
export CA_CRT CA_KEY CA_KEY_PWD_FILE

################################################################################
# Default server certificate subject
: ${SERVER_CRT_SUBJECT:=CN=${DOCKER_CONTAINER_NAME}}

# Default server certificate file location
if [ -e /run/secrets/ca_server.pem ]; then
  : ${SERVER_CRT:=/run/secrets/ca_server.pem}
else
  : ${SERVER_CRT:=${SIMPLE_CA_DIR}/secrets/ca_server.pem}
fi

# Default server private key file location
if [ -e /run/secrets/ca_server_key.pem ]; then
  : ${SERVER_KEY:=/run/secrets/ca_server_key.pem}
else
  : ${SERVER_KEY:=${SIMPLE_CA_DIR}/secrets/ca_server_key.pem}
fi

# NOTE: lighttpd does not support server private key passphrase
# # Default server private key passphrase file location
# if [ -e /run/secrets/ca_server_key.pwd ]; then
#   : ${SERVER_KEY_PWD_FILE:=/run/secrets/ca_server_key.pwd}
# else
#   : ${SERVER_KEY_PWD_FILE:=${SIMPLE_CA_DIR}/secrets/ca_server_key.pwd}
# fi
#
# # Server private key passphrase
# if [ -e ${SERVER_KEY_PWD_FILE} ]; then
#   info "Using server private key passphrase file ${SERVER_KEY_PWD_FILE}"
#   SERVER_KEY_PWD=$(cat SERVER_KEY_PWD_FILE)
# else
#   info "Creating random server private key passphrase"
#   SERVER_KEY_PWD=$(openssl rand -hex 32)
# fi

# Export variables for lighttpd.conf
export SERVER_CRT SERVER_KEY

################################################################################
# CA user passowrd
if [ -e ${CA_USER_PWD_FILE} ]; then
  info "Using CA web server password ${CA_USER_PWD_FILE}"
  CA_USER_PWD=$(cat ${CA_USER_PWD_FILE})
else
  info "Creating random CA web server password"
  CA_USER_PWD=$(openssl rand -hex 32)
fi

# CA user database
SERVER_USER_DB=/var/lib/lighttpd/user.db

# Export variables for lighttpd.conf
export CA_USER CA_USER_REALM SERVER_USER_DB
