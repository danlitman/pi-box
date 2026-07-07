PI_BASE_IMAGE_NAME = pi-box:latest
PI_USER_IMAGE_NAME = pi-box:user-custom
REPO_DIR ?= $(CURDIR)
ARGS ?= -c
PROJECT ?= $(notdir $(REPO_DIR))

# Project data (sessions, per-project overrides) live relative to the
# Makefile's location on the host, using a sanitized version of the repo
# path (leading slashes stripped, slashes replaced with --) to make a
# per-project directory.
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_SAFE := $(shell echo "$(REPO_DIR)" | sed 's|^/*||; s|/|--|g')
SESSION_DIR := $(MAKEFILE_DIR)/data/projects/$(PROJECT_SAFE)

.PHONY: build run

## Pi Agent

build:
	docker build -t $(PI_BASE_IMAGE_NAME) -f Dockerfile .
	docker build -t $(PI_USER_IMAGE_NAME) -f data/Dockerfile .

run:
	@docker run --rm -it \
	  $(ENV_FLAGS) \
	  --env-file $(MAKEFILE_DIR)/data/.env \
	  -v "$(REPO_DIR):/projects/$(PROJECT)" \
	  -w "/projects/$(PROJECT)" \
	  -v "$(MAKEFILE_DIR)/data/config:/root/.pi/agent:ro" \
	  -v "$(SESSION_DIR):/root/.pi/agent/sessions:rw" \
	  --read-only \
	  --tmpfs /tmp:exec \
	  --cap-drop=ALL --security-opt no-new-privileges \
	  $(PI_USER_IMAGE_NAME) $(ARGS)
