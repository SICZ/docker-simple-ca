ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE_TAG
ARG DOCKER_PROJECT_DESC
ARG DOCKER_PROJECT_URL
ARG BUILD_DATE
ARG GITHUB_URL
ARG VCS_REF

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="${DOCKER_IMAGE_NAME}"
LABEL org.label-schema.version="${DOCKER_IMAGE_TAG}"
LABEL org.label-schema.description="${DOCKER_PROJECT_DESC}"
LABEL org.label-schema.url="${DOCKER_PROJECT_URL}"
LABEL org.label-schema.vcs-url="${GITHUB_URL}"
LABEL org.label-schema.vcs-ref="${VCS_REF}"
LABEL org.label-schema.build-date="${BUILD_DATE}"

COPY config /
RUN set -exo pipefail; \
  mkdir -p /var/lib/simple-ca; \
  chown lighttpd:lighttpd /var/lib/simple-ca; \
  chmod 750 /var/lib/simple-ca; \
  chmod 555 /var/www/simple-ca.cgi
