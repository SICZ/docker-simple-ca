ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY rootfs /
RUN set -exo pipefail; \
  chmod 555 /var/www/simple-ca.cgi
