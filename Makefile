export COMPOSE_PROJECT_NAME=mw-presensi

HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)
PROJECT_NAME := -p ${COMPOSE_PROJECT_NAME}

ERROR_ONLY_FOR_HOST = @printf "\033[33mThis command for host machine\033[39m\n"

ifndef INSIDE_DOCKER_CONTAINER
	INSIDE_DOCKER_CONTAINER = 0
endif

INTERACTIVE := $(shell [ -t 0 ] && echo 1)
ifneq ($(INTERACTIVE), 1)
	OPTION_T := -T
endif

help: ## Shows available commands with description
	echo "\033[34mList of available commands:\033[39m"
	grep -E '^[a-zA-Z-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "[32m%-27s[0m %s\n", $$1, $$2}'

build: ## Build develp,ment image
	HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker compose -f docker-compose.base.yaml -f docker-compose.dev.yaml build

build-prod: ## Build production image
	docker compose -f docker-compose.base.yaml -f docker-compose.prod.yaml build

start: ## Start development environment
	HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker compose -f docker-compose.base.yaml -f docker-compose.dev.yaml $(PROJECT_NAME) up -d

start-prod: ## Start production environment
	docker compose -f docker-compose.base.yaml -f docker-compose.prod.yaml $(PROJECT_NAME) up -d

stop: ## Stop development environment
	HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker compose -f docker-compose.base.yaml -f docker-compose.dev.yaml $(PROJECT_NAME) down

stop-prod: ## Stop production environment
	docker compose -f docker-compose.base.yaml -f docker-compose.prod.yaml $(PROJECT_NAME) down

restart: stop start ## Restart development environment
restart-prod: stop-prod start-prod ## Restart production environment

logs: ## Show logs of all containers
	docker compose $(PROJECT_NAME) logs -f

remote-workspace: ## Open remote shell
ifeq ($(INSIDE_DOCKER_CONTAINER), 0)
	docker compose $(PROJECT_NAME) exec $(OPTION_T) workspace sh
else
	$(ERROR_ONLY_FOR_HOST)
endif

remote-app: ## Open remote shell
ifeq ($(INSIDE_DOCKER_CONTAINER), 0)
	docker compose $(PROJECT_NAME) exec $(OPTION_T) php-fpm sh
else
	$(ERROR_ONLY_FOR_HOST)
endif

remote-app-root: ## Open remote shell
ifeq ($(INSIDE_DOCKER_CONTAINER), 0)
	docker compose $(PROJECT_NAME) exec $(OPTION_T) -u root php-fpm sh
else
	$(ERROR_ONLY_FOR_HOST)
endif

exec: ## Run command in php-fpm container
ifeq ($(INSIDE_DOCKER_CONTAINER), 1)
	$$cmd
else
	docker compose $(PROJECT_NAME) exec $(OPTION_T) php-fpm $$cmd
endif

exec-sh: ## Run shell in php-fpm container
ifeq ($(INSIDE_DOCKER_CONTAINER), 1)
	sh -c "$(cmd)"
else
	docker compose $(PROJECT_NAME) exec $(OPTION_T) php-fpm sh -c "$(cmd)"
endif

exec-by-root: ## Run command in php-fpm container as root
ifeq ($(INSIDE_DOCKER_CONTAINER), 0)
	docker compose $(PROJECT_NAME) exec $(OPTION_T) -u root php-fpm $$cmd
else
	$(ERROR_ONLY_FOR_HOST)
endif

info: ## Shows Php and Laravel version
	make exec cmd="php artisan --version"
	make exec cmd="php artisan env"
	make exec cmd="php --version"
	make exec cmd="composer --version"

report-prepare: ## Prepare report directory
	make exec cmd="mkdir -p reports/coverage"

report-clean: ## Clean report directory
	make exec-by-root cmd="rm -rf reports"

pest: ## Run tests with Pest
	make exec cmd="./vendor/bin/pest -c phpunit.xml --coverage-html reports/coverage --coverage-text --colors=never --coverage-clover reports/clover.xml --log-junit reports/junit.xml"

composer-audit: ## Checks for security vulnerability advisories for installed packages
	make exec-sh cmd="COMPOSER_MEMORY_LIMIT=-1 composer audit"