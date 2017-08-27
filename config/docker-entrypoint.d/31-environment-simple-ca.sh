#!/bin/bash

################################################################################

# Simple CA requires to have all certificates and secrets in /var/lib/simple-ca
SIMPLE_CA_DIR=/var/lib/simple-ca
CA_CRT_DIR=${SIMPLE_CA_DIR}/secrets
CA_KEY_DIR=${SIMPLE_CA_DIR}/secrets
SERVER_CRT_DIR=${SIMPLE_CA_DIR}/certs
SERVER_KEY_DIR=${SIMPLE_CA_DIR}/certs

################################################################################

# Default CA user realm
: ${CA_USER_REALM:=Simple CA}

# Default CA user name file location
if [ -e /run/secrets/ca_user.pwd ]; then
  : ${CA_USER_NAME_FILE:=/run/secrets/ca_user.name}
else
  : ${CA_USER_NAME_FILE:=${CA_KEY_DIR}/ca_user.name}
fi

# Default CA user password file location
if [ -e /run/secrets/ca_user.pwd ]; then
  : ${CA_USER_PWD_FILE:=/run/secrets/ca_user.pwd}
else
  : ${CA_USER_PWD_FILE:=${CA_KEY_DIR}/ca_user.pwd}
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

# Default certificate and private key files mode
: ${CA_CRT_FILE_MODE:=444}
: ${CA_KEY_FILE_MODE:=440}

################################################################################

# Default server private key passphrase file location
if [ -e /run/secrets/server.pwd ]; then
  : ${SERVER_KEY_PWD_FILE:=/run/secrets/server.pwd}
else
  : ${SERVER_KEY_PWD_FILE:=${CA_KEY_DIR}/server.pwd}
fi

################################################################################

# CA user database file
: ${SERVER_USERDB_FILE:=/var/lib/lighttpd/user.db}

################################################################################
