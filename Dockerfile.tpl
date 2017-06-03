FROM sicz/lighttpd:%%BASE_IMAGE_TAG%%

ENV org.label-schema.schema-version="1.0"
ENV org.label-schema.name="%%DOCKER_PROJECT%%/%%DOCKER_NAME%%"
ENV org.label-schema.description="%%DOCKER_DESCRIPTION%%"
ENV org.label-schema.build-date="%%REFRESHED_AT%%"
ENV org.label-schema.url="https://github.com/sicz/docker-simple-ca"
ENV org.label-schema.vcs-url="https://github.com/%%DOCKER_PROJECT%%/docker-%%DOCKER_NAME%%"

COPY config /
RUN set -x && chmod +x /var/www/simple-ca.cgi

EXPOSE 443
