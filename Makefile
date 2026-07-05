PI_IMAGE_NAME = pi-box
REPO_DIR ?= $(CURDIR)
ARGS ?= -c
PROJECT ?= $(notdir $(REPO_DIR))

# Session files live relative to the Makefile's location on the host,
# using a sanitized version of the repo path (leading slashes stripped,
# slashes replaced with --) to make a per-project directory.
MAKEFILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_SAFE := $(shell echo "$(REPO_DIR)" | sed 's|^/*||; s|/|--|g')
SESSION_DIR := $(MAKEFILE_DIR)data/sessions/$(PROJECT_SAFE)

# Read literal env vars from .env: KEY=VALUE lines → -e KEY=VALUE
ENV_FLAGS := $(shell grep -E '^[A-Za-z_][A-Za-z0-9_]*=' $(MAKEFILE_DIR)/data/.env 2>/dev/null | sed 's/^\([^=]*\)=\(.*\)/-e \1=\2/')


.PHONY: build run

## Pi Agent

build:
	docker build -t $(PI_IMAGE_NAME) -f Dockerfile .

run:
	docker run --rm -it \
	  $(ENV_FLAGS) \
	  -v "$(REPO_DIR):/projects/$(PROJECT)" \
	  -w "/projects/$(PROJECT)" \
	  -v "$$HOME/.gitconfig:/root/.gitconfig:ro" \
	  -v "$(MAKEFILE_DIR)/data/models.json:/root/.pi/agent/models.json:ro" \
	  -v "$(MAKEFILE_DIR)/data/APPEND_SYSTEM.md:/root/.pi/agent/APPEND_SYSTEM.md:ro" \
	  -v "$(MAKEFILE_DIR)/data/skills:/root/.pi/agent/skills:ro" \
	  -v "$(SESSION_DIR):/root/.pi/agent" \
	  --read-only \
	  --tmpfs /tmp:exec \
	  --cap-drop=ALL --security-opt no-new-privileges \
	  $(PI_IMAGE_NAME) $(ARGS)
