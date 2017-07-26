################################################################################

BASEIMAGE_NAME		= $(DOCKER_PROJECT)/lighttpd
BASEIMAGE_TAG		= 3.6

################################################################################

DOCKER_PROJECT		?= sicz
DOCKER_NAME		= simple-ca
DOCKER_TAG		= $(BASEIMAGE_TAG)
DOCKER_TAGS		?= latest
DOCKER_DESCRIPTION	= A simple automated Certificate Authority
DOCKER_PROJECT_URL	= https://github.com/sicz/docker-simple-ca

DOCKER_RUN_OPTS		+= -v /var/run/docker.sock:/var/run/docker.sock \
			   -v $(abspath $(DOCKER_HOME_DIR))/secrets:/var/lib/simple-ca/secrets \
			   -e SERVER_CRT_SUBJECT=CN=sicz_simple_ca

DOCKER_SHELL_CMD	= /docker-entrypoint.sh /bin/bash

DOCKER_SUBDIR		+= devel

################################################################################

.PHONY: all build rebuild deploy run up destroy down rm start stop restart
.PHONY: status logs shell refresh test clean clean-all

all: destroy clean build deploy logs test
build: docker-build
rebuild: docker-rebuild
deploy run up: docker-deploy
destroy down rm: docker-destroy
start: docker-start
stop: docker-stop
restart: docker-stop docker-start
status: docker-status
logs: docker-logs
logs-tail: docker-logs-tail
shell: docker-shell
refresh: docker-refresh
test: docker-test
	@SECRETS="$$(ls secrets/test_* 2>/dev/null | tr '\n' ' ')"; \
	if [ -n "$${SECRETS}" ]; then \
		$(ECHO) "Removing secrets: $${SECRETS}"; \
		chmod u+w secrets; \
		rm -f $${SECRETS}; \
	fi

clean: destroy
	@SECRETS="$$(ls secrets/ca_* 2>/dev/null | tr '\n' ' ')"; \
	if [ -n "$${SECRETS}" ]; then \
		$(ECHO) "Removing secrets: $${SECRETS}"; \
		chmod u+w secrets; \
		rm -f $${SECRETS}; \
	fi

clean-all: clean
	@for SUBDIR in $(DOCKER_SUBDIR); do \
		cd $(abspath $(DOCKER_HOME_DIR))/$${SUBDIR}; \
		$(MAKE) clean; \
	done

################################################################################

.PHONY:  secrets

secrets: clean-all
	@$(MAKE) run DOCKER_RUN_CMD="secrets"; \
	sleep 1; \
	${MAKE} logs; \
	${MAKE} destroy

################################################################################

DOCKER_HOME_DIR		?= .
DOCKER_MK_DIR		?= $(DOCKER_HOME_DIR)/../Mk
include $(DOCKER_MK_DIR)/docker.container.mk

################################################################################
