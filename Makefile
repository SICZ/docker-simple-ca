ALPINE_VERSION		?= latest

DOCKER_PROJECT		= sicz
DOCKER_NAME		= simple-ca
DOCKER_TAG		= $(ALPINE_VERSION)

DOCKER_RUN_OPTS		+= -v $(CURDIR)/secrets:/var/lib/simple-ca/secrets \
			   -v /var/run/docker.sock:/var/run/docker.sock
DOCKER_SHELL_CMD	= /docker-entrypoint.sh bash

.PHONY: all build rebuild deploy run up destroy rm down start stop restart
.PHONY: status logs shell refresh test clean secrets

all: destroy build secrets deploy logs-tail
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

clean: destroy
	@SECRETS="$$(ls secrets/ca_* 2>/dev/null | tr '\n' ' ')"; \
	if [ -n "$${SECRETS}" ]; then \
		$(ECHO) "Removing secrets: $${SECRETS}"; \
		chmod u+w secrets; \
		rm -f $${SECRETS}; \
	fi

secrets: clean
	@$(MAKE) run DOCKER_RUN_CMD="secrets"; \
	sleep 1; \
	${MAKE} logs; \
	${MAKE} destroy

include ../Mk/docker.container.mk
