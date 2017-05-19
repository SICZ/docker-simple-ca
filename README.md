# docker-simple-ca

[![CircleCI Status Badge](https://circleci.com/gh/sicz/docker-simple-ca.svg?style=shield&circle-token=06deeca25c070ce627cd547f0631afdc2c700f10)](https://circleci.com/gh/sicz/docker-simple-ca)

**This project is not aimed at public consumption.
It exists to serve as a single endpoint for SICZ containers.**

A simple automated Certificate Authority. Such CA is useful on auto provisioned
clusters secured by certificates.

## Contents

This container only contains essential components:
* [sicz/lighttpd image](https://github.com/sicz/docker-lighttpd) provide web server.
* `simple-ca.cgi` script as certificate authority.

## Getting started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes. See deployment for notes
on how to deploy the project on a live system.

### Installing

Clone GitHub repository to your working directory:
```bash
git clone https://github.com/sicz/docker-simple-ca
```

### Usage

Use command `make` to simplify Docker container development tasks:
```bash
make all        # Destroy running container, build new image, run container and show logs
make build      # Build new image
make refresh    # Refresh Dockerfile
make rebuild    # Build new image without caching
make secrets    # Populate directory secrets with CA certificate and secrets
make run        # Run container
make stop       # Stop running container
make start      # Start stopped container
make restart    # Restart container
make status     # Show container status
make logs       # Show container logs
make logs-tail  # Connect to container logs
make shell      # Open shell in running container
make test       # Run tests
make rm         # Destroy running container
make clean      # Destroy running container and delete CA secrets
```

With default configuration `simple-ca` listens on TCP port 443 and sends all
logs to Docker console.

After first run is directory `secrets` populated with CA certificate and secrets:
* `ca_crt.pem` - CA certificate
* `ca_key.pem` - encrypted CA private key
* `ca_key.pwd` - CA private key passphrase
* `ca_user.pwd` - password for user `agent007`
* `ca_server.pem` - web server certificate nad private key

How to obtain CA certificate:
```bash
curl -k https://simple-ca/ca.pem > ca_crt.pem
```

How to obtain server certificate:
```bash
SERVER_KEY_PWD=$(openssl rand -hex 32)
openssl req -newkey rsa:2048 \
  -subj "/CN=${HOSTNAME}" \
  -keyout server_key.pem \
  -passout "pass:${SERVER_KEY_PWD}" |
curl \
  --cacert ca_crt.pem \
  --user "agent007:$(cat ca_user.pwd)"
  --data-binary @- \
  --output server_crt.pem \
  "https://simple-ca/sign?dn=CN=${HOSTNAME}&dns=${SERVER_CRT_NAMES}&ip=${SERVER_CRT_IP}&oid=${SERVER_CRT_OID}"
```

## Deployment

At first populate `secrets` directory with CA secrets:
```bash
docker run -v $PWD/secrets:/var/lib/simple-ca/secrets sicz/simple-ca:3.5 secrets
```

You can start with this sample `docker-compose.yml` file:
```yaml
services:
  simple-ca:
    image: sicz/simple-ca:3.5
    ports:
      - 9443:443
    volumes:
      - secrets:/var/lib/simple-ca/secrets
  lighttpd:
    image: sicz/lighttpd:3.5
    ports:
      - 8080:80
      - 8443:443
    volumes:
      - secrets/ca_crt.pem:/run/secrets/ca_crt.pem
      - secrets/ca_user.pwd:/run/secrets/ca_user.pwd
      - config/server.conf:/etc/lighttpd/server/conf
      - www:/var/www
    environment:
      - SIMPLE_CA_URL=https://simple-ca
      - SERVER_CRT_NAME=my-service.my-domain
```

## Authors

* [Joao Morais](https://github.com/jcmoraisjr) - original author of
  [jcmoraisjr/simple-ca](https://github.com/jcmoraisjr/simple-ca).
* [Petr Řehoř](https://github.com/prehor) - adapted it to the needs of SICZ.

See also the list of [contributors](https://github.com/sicz/docker-baseimage-alpine/contributors)
who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0 - see the
[LICENSE](LICENSE) file for details.

## Acknowledgments

This project is based on [jcmoraisjr/simple-ca](https://github.com/jcmoraisjr/simple-ca).
