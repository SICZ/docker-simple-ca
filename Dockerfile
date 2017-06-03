FROM sicz/lighttpd:3.6

ENV org.label-schema.schema-version="1.0"
ENV org.label-schema.name="sicz/simple-ca"
ENV org.label-schema.description="A simple automated Certificate Authority."
ENV org.label-schema.build-date="2017-06-03T21:11:32Z"
ENV org.label-schema.url="https://github.com/sicz/docker-simple-ca"
ENV org.label-schema.vcs-url="https://github.com/sicz/docker-simple-ca"

COPY config /
RUN set -x && chmod +x /var/www/simple-ca.cgi

EXPOSE 443
