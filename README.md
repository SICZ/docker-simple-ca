# docker-simple-ca

[![CircleCI Status Badge](https://circleci.com/gh/sicz/docker-simple-ca.svg?style=shield&circle-token=06deeca25c070ce627cd547f0631afdc2c700f10)](https://circleci.com/gh/sicz/docker-simple-ca)

**This project is not aimed at public consumption.
It exists to serve as a single endpoint for SICZ containers.**

A simple automated Certificate Authority. Such CA is useful on auto provisioned
clusters secured by certificates.

## Contents

This container only contains essential components:
* [sicz/lighttpd image](https://github.com/sicz/docker-lighttpd) provides a web server.
* `simple-ca.cgi` script as a certificate authority.

## Getting started

These instructions will get you a copy of the project up and running on your
local machine for development and testing purposes. See deployment for notes
on how to deploy the project on a live system.

### Installing

Clone the GitHub repository into your working directory:
```bash
git clone https://github.com/sicz/docker-simple-ca
```

### Usage

Use the command `make` in the project directory:
```bash
make all                # Build a new image and run the tests
make ci                 # Build a new image and run the tests
make build              # Build a new image
make rebuild            # Build a new image without using the Docker layer caching
make config-file        # Display the configuration file for the current configuration
make vars               # Display the make variables for the current configuration
make up                 # Remove the containers and then run them fresh
make create             # Create the containers
make start              # Start the containers
make stop               # Stop the containers
make restart            # Restart the containers
make rm                 # Remove the containers
make wait               # Wait for the start of the containers
make ps                 # Display running containers
make logs               # Display the container logs
make logs-tail          # Follow the container logs
make shell              # Run the shell in the container
make test               # Run the tests
make test-shell         # Run the shell in the test container
make clean              # Remove all containers and work files
make docker-pull        # Pull all images from the Docker Registry
make docker-pull-dependencies # Pull the project image dependencies from the Docker Registry
make docker-pull-image  # Pull the project image from the Docker Registry
make docker-pull-testimage # Pull the test image from the Docker Registry
make docker-push        # Push the project image into the Docker Registry
```

`simple-ca`  with the default configuration listens on TCP port 443 and sends
all logs to the Docker console.

After the first run, the container's directory `/var/lib/simple-ca/secrets` is
populated with the CA certificate and secrets:
* `ca.crt` - CA certificate
* `ca_user.name` - CA user name
* `ca_user.pwd` - CA user password

## Deployment

Then you can start with this sample `docker-compose.yml` file:
```yaml
services:
  simple-ca:
    image: sicz/simple-ca
    ports:
      - 9443:443
    volumes:
      - simple_ca_data:/var/lib/simple-ca
      - ./secrets:/var/lib/simple-ca/secrets
volumes:
  simple_ca_data:
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
