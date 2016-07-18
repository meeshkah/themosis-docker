PROJECT_NAME ?= themosis
REPO_NAME ?= themosis-docker

THEMOSIS_PATH := themosis
THEMOSIS_REPO := themosis/themosis

DEV_COMPOSE_FILE := docker-compose.development.yml

DEV_CERTIFICATE_KEY_FILE := .certs/themosis.dev.key
DEV_CERTIFICATE_CRT_FILE := .certs/themosis.dev.pem
DEV_CERTIFICATE_DHPARAM_FILE := .certs/dhparam.dev.pem

# Cosmetics
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
	printf $(NC)' VALUE

ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: dev setup

setup:
	${INFO} "Creating development database volume..."
	@ docker volume create --name db
	${INFO} "Creating development cache volume..."
	@ docker volume create --name cache
	${INFO} "Checking for Themosis..."
ifeq ($(wildcard $(ROOT_DIR)/$(THEMOSIS_PATH)/composer.json),)
	${INFO} "Installing Themosis. Sit tight..."
	@ rm -Rf $(ROOT_DIR)/$(THEMOSIS_PATH)
	@ git clone git@github.com:$(THEMOSIS_REPO) $(ROOT_DIR)/$(THEMOSIS_PATH)
	@ cd $(ROOT_DIR)/$(THEMOSIS_PATH)
	@ composer install
	@ sed -i "s|database_name|$DB_NAME|g" $(ROOT_DIR)/$(THEMOSIS_PATH)/.env.local.php
	@ sed -i "s|database_user|$DB_USER|g" $(ROOT_DIR)/$(THEMOSIS_PATH)/.env.local.php
	@ sed -i "s|database_password|$DB_PASSWORD|g" $(ROOT_DIR)/$(THEMOSIS_PATH)/.env.local.php
	@ sed -i "s|database_host|$DB_HOST|g" $(ROOT_DIR)/$(THEMOSIS_PATH)/.env.local.php
	@ sed -i "s|http://domain.tld|https://$WP_HOME|g" $(ROOT_DIR)/$(THEMOSIS_PATH)/.env.local.php
	@ cd $(ROOT_DIR)
else
	${INFO} "Themosis exists. Updating composer dependencies..."
	@ cd $(THEMOSIS_PATH) && composer install && cd $(ROOT_DIR)
endif
	# ${INFO} "Resolving certificates..."
	# @ openssl req -x509 -newkey rsa:2048 -keyout $(DEV_CERTIFICATE_KEY_FILE) -out $(DEV_CERTIFICATE_CRT_FILE) -days 30 -nodes -subj '/CN=localhost'
	# ${INFO} "Sorting out forward secrecy..."
	# @ openssl dhparam -out $(DEV_CERTIFICATE_DHPARAM_FILE) 4096
	${INFO} "Creating images..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) build

dev:
	${INFO} "Launching..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) up
