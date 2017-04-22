FROM sicz/lighttpd:%%BASE_IMAGE_TAG%%

ENV \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="%%DOCKER_PROJECT%%/%%DOCKER_NAME%%" \
  org.label-schema.description="A simple automated Certificate Authority." \
  org.label-schema.build-date="%%REFRESHED_AT%%" \
  org.label-schema.url="https://github.com/sicz/docker-simple-ca" \
  org.label-schema.vcs-url="https://github.com/%%DOCKER_PROJECT%%/docker-%%DOCKER_NAME%%"

ENV \
  LIGHTTPD_PORT=9443 \
  SIMPLE_CA_DIR=/var/lib/simple-ca

COPY config /etc
COPY docker-entrypoint.d /docker-entrypoint.d
COPY www ${LIGHTTPD_DIR}
RUN set -x && chmod +x ${LIGHTTPD_DIR}/*.cgi

EXPOSE ${LIGHTTPD_PORT}
