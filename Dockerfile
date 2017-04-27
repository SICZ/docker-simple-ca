FROM sicz/lighttpd:3.5

ENV org.label-schema.schema-version="1.0"
ENV org.label-schema.name="sicz/simple-ca"
ENV org.label-schema.description="A simple automated Certificate Authority."
ENV org.label-schema.build-date="2017-04-18T20:36:03Z"
ENV org.label-schema.url="https://github.com/sicz/docker-simple-ca"
ENV org.label-schema.vcs-url="https://github.com/sicz/docker-simple-ca"

COPY config /etc
COPY docker-entrypoint.d /docker-entrypoint.d
COPY www /var/www
RUN set -x && chmod +x /var/www/simple-ca.cgi

EXPOSE 443
