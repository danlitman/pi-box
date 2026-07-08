PI_BASE_IMAGE_NAME = pi-box:latest
PI_USER_IMAGE_NAME = pi-box:user-custom
REPO_DIR ?= $(CURDIR)
ARGS ?= -c
PROJECT ?= $(notdir $(REPO_DIR))

# How the agent config directory (data/config) is exposed to the container.
#
# Normal mode (PI_EDIT unset): mount the host config read-only as a *source*
# and give pi an in-memory (tmpfs) agent dir that the entrypoint populates from
# it. pi can lock/write settings.json — required to load installed
# packages/skills — but the agent's writes are ephemeral and never reach the
# host.
#
# Edit mode (PI_EDIT=1, via `make edit`): bind-mount the host config read-write
# so changes (installing packages/skills, editing settings) persist to the host.
ifeq ($(PI_EDIT),1)
AGENT_FLAGS = -v "$(MAKEFILE_DIR)/data/config:/root/.pi/agent:rw"
else
AGENT_FLAGS = -v "$(MAKEFILE_DIR)/data/config:/root/.pi/config-src:ro" \
	--tmpfs /root/.pi/agent:exec \
	-e PI_BOX_CONFIG_SRC=/root/.pi/config-src
endif

# Project data (sessions, per-project overrides) live relative to the
# Makefile's location on the host, using a sanitized version of the repo
# path (leading slashes stripped, slashes replaced with --) to make a
# per-project directory.
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_SAFE := $(shell echo "$(REPO_DIR)" | sed 's|^/*||; s|/|--|g')
SESSION_DIR := $(MAKEFILE_DIR)/data/projects/$(PROJECT_SAFE)

# Mount .git/config read-only if it exists (handles submodules, worktrees, etc.).
GIT_CONFIG_MOUNT := $(if $(wildcard $(REPO_DIR)/.git/config),-v "$(REPO_DIR)/.git/config:/projects/$(PROJECT)/.git/config:ro",)

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
	@$(MAKE) run PI_EDIT=1 ARGS="$(ARGS)"

run:
	@docker run --rm -it \
	  $(ENV_FLAGS) \
	  --env-file $(MAKEFILE_DIR)/data/.env \
	  -e npm_config_cache=/tmp/.npm \
	  -v "$(REPO_DIR):/projects/$(PROJECT)" \
	  $(GIT_CONFIG_MOUNT) \
	  -w "/projects/$(PROJECT)" \
	  $(AGENT_FLAGS) \
	  -v "$(SESSION_DIR):/root/.pi/agent/sessions:rw" \
	  --read-only \
	  --tmpfs /tmp:exec \
	  --cap-drop=ALL --security-opt no-new-privileges \
	  $(PI_USER_IMAGE_NAME) $(ARGS)
