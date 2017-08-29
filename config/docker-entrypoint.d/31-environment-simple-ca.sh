#!/bin/bash

################################################################################

# Simple CA requires to have all certificates and secrets in /var/lib/simple-ca
SIMPLE_CA_DIR=/var/lib/simple-ca
SIMPLE_CA_PRIVATE_DIR=${SIMPLE_CA_DIR}/private
SIMPLE_CA_SECRETS_DIR=${SIMPLE_CA_DIR}/secrets
CA_CRT_DIR=${SIMPLE_CA_SECRETS_DIR}
CA_KEY_DIR=${SIMPLE_CA_PRIVATE_DIR}
SERVER_CRT_DIR=${SIMPLE_CA_PRIVATE_DIR}
SERVER_KEY_DIR=${SIMPLE_CA_PRIVATE_DIR}

################################################################################

# Default CA user realm
: ${CA_USER_REALM:=Simple CA}

# Default CA user name file location
if [ -e /run/secrets/ca_user.pwd ]; then
  : ${CA_USER_NAME_FILE:=/run/secrets/ca_user.name}
else
  : ${CA_USER_NAME_FILE:=${SIMPLE_CA_SECRETS_DIR}/ca_user.name}
fi

# Default CA user password file location
if [ -e /run/secrets/ca_user.pwd ]; then
  : ${CA_USER_PWD_FILE:=/run/secrets/ca_user.pwd}
else
  : ${CA_USER_PWD_FILE:=${SIMPLE_CA_SECRETS_DIR}/ca_user.pwd}
fi

################################################################################

# Default CA certificate subject
: ${CA_CRT_SUBJECT:=CN=${CA_USER_REALM}}

# Default CA certificate file location
if [ -e /run/secrets/ca.crt ]; then
  : ${CA_CRT_FILE:=/run/secrets/ca.crt}
else
  : ${CA_CRT_FILE:=${CA_CRT_DIR}/ca.crt}
fi

# Default CA private key file location
if [ -e /run/secrets/ca.key ]; then
  : ${CA_KEY_FILE:=/run/secrets/ca.key}
else
  : ${CA_KEY_FILE:=${CA_KEY_DIR}/ca.key}
fi

# Default CA private key passphrase file
if [ -e /run/secrets/ca.pwd ]; then
  : ${CA_KEY_PWD_FILE:=/run/secrets/ca.pwd}
else
  : ${CA_KEY_PWD_FILE:=${CA_KEY_DIR}/ca.pwd}
fi

################################################################################

# TODO Lighttpd does not support encrypted private key
# # Default server private key passphrase file location
# : ${SERVER_KEY_PWD_FILE:=${SERVER_KEY_DIR}/server.pwd}

################################################################################

# CA user database file
: ${SERVER_USERDB_FILE:=/var/lib/lighttpd/user.db}

################################################################################
