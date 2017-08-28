### BASE_IMAGE #################################################################

BASE_IMAGE_NAME		?= $(DOCKER_PROJECT)/lighttpd
BASE_IMAGE_TAG		?= 1.4.45

### DOCKER_IMAGE ###############################################################

SIMPLE_CA_VERSION	?= 1.0.0

DOCKER_PROJECT		?= sicz
DOCKER_PROJECT_DESC	?= A simple automated Certificate Authority
DOCKER_PROJECT_URL	?= https://github.com/sicz/docker-simple-ca

DOCKER_NAME		?= simple-ca
DOCKER_IMAGE_TAG	?= $(SIMPLE_CA_VERSION)
DOCKER_IMAGE_TAGS	?= latest

### DOCKER_VERSIONS ############################################################

DOCKER_VERSIONS		?= latest devel

### BUILD ######################################################################

# Docker image build variables
BUILD_VARS		+= SIMPLE_CA_VERSION

# Allows a change of the build/restore targets to the docker-tag if
# the development version is the same as the production version
DOCKER_BUILD_TARGET	?= docker-build
DOCKER_REBUILD_TARGET	?= docker-rebuild

### DOCKER_EXECUTOR ############################################################

# Use Docker Compose executor
DOCKER_EXECUTOR		?= compose

# Docker Compose variables
COMPOSE_VARS		+= SERVER_CRT_HOST

# Subject aletrnative name in certificate
SERVER_CRT_HOST		+= simple-ca.local

### DOCKER_MAKE_VARS ###########################################################

MAKE_VARS		?= GITHUB_MAKE_VARS \
			   BASE_IMAGE_MAKE_VARS \
			   DOCKER_IMAGE_MAKE_VARS \
			   BUILD_MAKE_VARS \
			   BUILD_TARGETS_MAKE_VARS \
			   EXECUTOR_MAKE_VARS \
			   CONFIG_MAKE_VARS \
			   SHELL_MAKE_VARS \
			   DOCKER_REGISTRY_MAKE_VARS \
			   DOCKER_VERSION_MAKE_VARS

define BUILD_TARGETS_MAKE_VARS
SIMPLE_CA_VERSION:	$(SIMPLE_CA_VERSION)

DOCKER_BUILD_TARGET:	$(DOCKER_BUILD_TARGET)
DOCKER_REBUILD_TARGET:	$(DOCKER_REBUILD_TARGET)
endef
export BUILD_TARGETS_MAKE_VARS

define CONFIG_MAKE_VARS
SERVER_CRT_HOST:	$(SERVER_CRT_HOST)
endef
export CONFIG_MAKE_VARS

### DOCKER_VERSION_TARGETS #####################################################

DOCKER_ALL_VERSIONS_TARGETS ?= build rebuild ci clean

### MAKE_TARGETS ###############################################################

# Build and test image
.PHONY: all ci
all: build up wait logs test
ci:  all clean

# Display make variables
.PHONY: makevars vars
makevars vars: display-makevars

### BUILD_TARGETS ##############################################################

# Build Docker image with cached layers
.PHONY: build
build: $(DOCKER_BUILD_TARGET)
	@true

# Build Docker image without cached layers
.PHONY: rebuild
rebuild: $(DOCKER_REBUILD_TARGET)
	@true

### EXECUTOR_TARGETS ###########################################################

# Display Docker COmpose/Swarm configuration file
.PHONY: config-file
config-file: display-config-file

# Remove containers and then start fresh ones
.PHONY: run up
run up: docker-up

# Create containers
.PHONY: create
create: docker-create
	@true

# Start containers
.PHONY: start
start: create docker-start

# Wait to container start
.PHONY: wait
wait: start docker-wait

# List running containers
.PHONY: ps
ps: docker-ps

# Display containers logs
.PHONY: logs
logs: docker-logs

# Follow containers logs
.PHONY: logs-tail tail
logs-tail tail: docker-logs-tail

# Run shell in the container
.PHONY: shell sh
shell sh: start docker-shell

# Run tests for current executor configuration
.PHONY: test
test: start docker-test

# Run shell in test container
.PHONY: test-shell tsh
test-shell tsh:
	@$(MAKE) test TEST_CMD=/bin/bash

# Stop containers
.PHONY: stop
stop: docker-stop

# Restart containers
.PHONY: restart
restart: stop start

# Remove containers
.PHONY: down rm
down rm: docker-rm

# Clean project
.PHONY: clean
clean: docker-clean

### MAKE_TARGETS ###############################################################

PROJECT_DIR		?= $(CURDIR)
MK_DIR			?= $(PROJECT_DIR)/../Mk
include $(MK_DIR)/docker.image.mk

################################################################################
