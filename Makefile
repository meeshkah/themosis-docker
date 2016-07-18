PROJECT_NAME ?= themosis
REPO_NAME ?= themosis-docker

THEMOSIS_PATH := themosis
THEMOSIS_REPO := themosis/themosis

DEV_COMPOSE_FILE := docker-compose.development.yml

DEV_CERTIFICATE_KEY_FILE := certs/themosis.dev.key
DEV_CERTIFICATE_CRT_FILE := certs/themosis.dev.pem
DEV_CERTIFICATE_DHPARAM_FILE := certs/dhparam.dev.pem

# Cosmetics
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
	printf $(NC)' VALUE

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: dev

dev:
	${INFO} "Creating development database volume..."
	@ docker volume create --name db
	${INFO} "Creating development cache volume..."
	@ docker volume create --name cache
	${INFO} "Checking for Themosis..."
ifeq (,$(wildcard '$(ROOT_DIR)/$(THEMOSIS_PATH)/.gitkeep'))
	${INFO} "Installing Themosis. Sit tight..."
	@ rm -Rf $(THEMOSIS_PATH)
	@ git clone git@github.com:$(THEMOSIS_REPO) $(THEMOSIS_PATH)
	@ cd $(THEMOSIS_PATH) && composer install && cd ..
else
	${INFO} "Themosis exists. No need to install..."
endif
	${INFO} "Resolving certificates..."
ifeq (,$(wildcard '$(ROOT_DIR)/$(DEV_CERTIFICATE_KEY_FILE)'))
	${INFO} "Keys exist"
else
	@ openssl req -x509 -newkey rsa:2048 -keyout $(DEV_CERTIFICATE_KEY_FILE) -out $(DEV_CERTIFICATE_CRT_FILE) -days 30 -nodes -subj '/CN=localhost'
endif
	${INFO} "Sorting out forward secrecy..."
ifeq (,$(wildcard '$(ROOT_DIR)/$(DEV_CERTIFICATE_DHPARAM_FILE)'))
	${INFO} "All is safe"
else
	@ openssl dhparam -out certs/$(DEV_CERTIFICATE_DHPARAM_FILE) 4096
endif
	${INFO} "Creating development images..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) build
	${INFO} "Launching..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) up
