#!/bin/bash -e

################################################################################

# Create CA user database
if [ ! -e ${SERVER_USERDB_FILE} ]; then
  info "Adding user ${CA_USER_NAME} to CA user database ${SERVER_USERDB_FILE}"
  CA_USER_NAME_DIGEST=$(echo -n "${CA_USER_NAME}:${CA_USER_REALM}:${CA_USER_NAME_PWD}" | md5sum | cut -b -32)
  echo "${CA_USER_NAME}:${CA_USER_REALM}:${CA_USER_NAME_DIGEST}" > ${SERVER_USERDB_FILE}
else
  info "Using CA user database ${SERVER_USERDB_FILE}"
fi

# Set permissions
chown ${LIGHTTPD_FILE_OWNER} ${SERVER_USERDB_FILE}
chmod ${SERVER_USERDB_FILE_MODE} ${SERVER_USERDB_FILE}

# Export variables for /etc/lighttpd/server.conf
export SERVER_USERDB_FILE

################################################################################
