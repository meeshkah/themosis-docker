PROJECT_NAME ?= themosis
REPO_NAME ?= themosis-docker

THEMOSIS_PATH := themosis
THEMOSIS_REPO := themosis/themosis

DEV_COMPOSE_FILE := docker-compose.development.yml

DEV_CERTIFICATE_KEY_FILE := themosis.dev.key
DEV_CERTIFICATE_CRT_FILE := themosis.dev.pem
DEV_CERTIFICATE_DHPARAM_FILE := dhparam.dev.pem

dev:
	${INFO} "Creating development database volume..."
	@ docker volume create --name db
	${INFO} "Creating development cache volume..."
	@ docker volume create --name cache
	${INFO} "Checking for Themosis..."
ifeq ("$(wildcard $(THEMOSIS_PATH)/.gitkeep)","")
	${INFO} "Installing Themosis. Sit tight..."
	@ rm -Rf $(THEMOSIS_PATH)
	@ git clone $(THEMOSIS_REPO) $(THEMOSIS_PATH)
	@ cd $(THEMOSIS_PATH) && composer install && cd ..
else
	${INFO} "Themosis exists. No need to install..."
endif
	${INFO} "Resolving certificates..."
ifneq ("$(wildcard $(DEV_CERTIFICATE_KEY_FILE))","")
	@ openssl req -x509 -newkey rsa:2048 -keyout certs/$(DEV_CERTIFICATE_KEY_FILE) -out certs/$(DEV_CERTIFICATE_CRT_FILE) -days 30 -nodes -subj '/CN=localhost'
else
	${INFO} "Keys exist"
endif
	${INFO} "Sorting out forward secrecy..."
ifneq ("$(wildcard $(DEV_CERTIFICATE_DHPARAM_FILE))","")
	@ openssl dhparam -out certs/$(DEV_CERTIFICATE_DHPARAM_FILE) 2048
else
	${INFO} "All is safe"
endif
	${INFO} "Creating development images..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) build
	${INFO} "Launching..."
	@ docker-compose -f $(DEV_COMPOSE_FILE) up
