PI_BASE_IMAGE_NAME = pi-box:latest
PI_USER_IMAGE_NAME = pi-box:user-custom
REPO_DIR ?= $(CURDIR)
ARGS ?= -c
PROJECT ?= $(notdir $(REPO_DIR))

# Mount mode for the agent config directory (data/config). Defaults to
# read-only; override with `make run CONFIG_MODE=rw` to allow writes.
CONFIG_MODE ?= ro

# Project data (sessions, per-project overrides) live relative to the
# Makefile's location on the host, using a sanitized version of the repo
# path (leading slashes stripped, slashes replaced with --) to make a
# per-project directory.
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_SAFE := $(shell echo "$(REPO_DIR)" | sed 's|^/*||; s|/|--|g')
SESSION_DIR := $(MAKEFILE_DIR)/data/projects/$(PROJECT_SAFE)

.PHONY: build run run-edit clean

## Pi Agent

build:
	@if [ ! -f "$(MAKEFILE_DIR)/data/.env" ]; then echo "ERROR: data/.env not found. Please copy from data.example/.env or create."; exit 1; fi
	@if [ ! -f "$(MAKEFILE_DIR)/data/Dockerfile" ]; then echo "ERROR: data/Dockerfile not found. Please copy from data.example/Dockerfile or create."; exit 1; fi
	@if [ ! -d "$(MAKEFILE_DIR)/data/config" ]; then echo "ERROR: data/config directory not found. Please create or copy from data.example/config/"; exit 1; fi
	@if [ ! -d "$(MAKEFILE_DIR)/data/projects" ]; then echo "ERROR: data/projects directory not found. Please create or copy from data.example/projects/"; exit 1; fi
	docker build -t $(PI_BASE_IMAGE_NAME) -f Dockerfile .
	docker build -t $(PI_USER_IMAGE_NAME) -f data/Dockerfile .

clean:
	docker rmi -f $(PI_BASE_IMAGE_NAME) $(PI_USER_IMAGE_NAME)

# Convenience alias: run with the agent config mounted read-write.
# WARNING: Only use edit mode when using pi to modify its own config.
# It mounts data/config read-write, so the agent can alter your config.
# For normal use, prefer `make run` (config mounted read-only).
edit:
	@echo "WARNING: edit mode mounts data/config read-write. Only use it when using pi to modify its own config."
	@$(MAKE) run CONFIG_MODE=rw ARGS="$(ARGS)"

run:
	@docker run --rm -it \
	  $(ENV_FLAGS) \
	  --env-file $(MAKEFILE_DIR)/data/.env \
	  -e npm_config_cache=/tmp/.npm \
	  -v "$(REPO_DIR):/projects/$(PROJECT)" \
	  -w "/projects/$(PROJECT)" \
	  -v "$(MAKEFILE_DIR)/data/config:/root/.pi/agent:$(CONFIG_MODE)" \
	  -v "$(SESSION_DIR):/root/.pi/agent/sessions:rw" \
	  --read-only \
	  --tmpfs /tmp:exec \
	  --cap-drop=ALL --security-opt no-new-privileges \
	  $(PI_USER_IMAGE_NAME) $(ARGS)
