# pi-box

A secure, Docker-based sandbox for running [Pi Agent](https://github.com/earendil-works/pi) against your projects.

Pi runs inside a read-only container with all dangerous capabilities dropped — it can read and write your code, stage and commit git changes. It has full network access, but can only authenticate to the APIs you provide keys for via model configs and `.env` — no docker flags, no secrets in environment variables on your host.

## What it does

- **Isolates the agent** in a container with a read-only filesystem and full network access (authenticates only to services you've provided keys for)
- **Mounts your project** at `/projects/<name>` so the agent can read and write your code
- **Manages sessions** per-project, preserving conversation history across runs
- **Configures models** via a simple JSON file supporting OpenAI-compatible, Anthropic, Google, and other APIs
- **Injects API keys** through `.env` — no shell setup required

## Quick Start

```bash
make build
make run
```

## Setup

1. **Copy the example data:**
   ```bash
   cp -r data.example/. data/
   ```
   The `data.example/` directory contains everything you need — models config, system instructions, env var mappings, and more. Copy it to `data/` and edit to suit your setup. Files ending in `.example.md` or `.env.example` are templates; rename them (e.g., `AGENTS.example.md` → `AGENTS.md`, `.env.example` → `.env`) when you want to use them.

2. **Configure models** in `data/config/models.json`. This file is mounted read-only into the container at `/root/.pi/agent/models.json`. See the [Pi docs on custom models](https://github.com/earendil-works/pi) for supported APIs (OpenAI-compatible, Anthropic, Google, etc.).

3. **Optionally add system instructions** in `data/config/APPEND_SYSTEM.md`. This file is mounted read-only into the container at `/root/.pi/agent/APPEND_SYSTEM.md`.

4. **Set literal env vars** in `data/.env` (copy from `data.example/.env.example`). Add `KEY=VALUE` lines for variables you want injected directly into the container:
   ```
   OPENAI_API_KEY=sk-proj-...
   ANTHROPIC_API_KEY=sk-ant-...
   ```

5. **Run the agent:**
   ```bash
   make run
   ```
   Pass an API key via environment variable (e.g., `ANTHROPIC_API_KEY`), or via the `--api-key` flag.

Run with custom arguments:
```bash
make run ARGS="--model llama3.1:8b"
```

### Shell alias

To avoid typing `make run` every time, add this function to your shell startup script (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
pibox() {
  make -C ~/projects/pi-box run REPO_DIR="$(pwd)" ARGS="$*"
}
```

Then you can just run `pibox` from any project directory, optionally passing arguments:

```bash
pibox --model llama3.1:8b
```

## Skills

### Global Skills

Place skills in `data/config/skills/` to make them available across all projects. Skills are [Pi Agent Skills](https://agentskills.io/specification) packages that provide specialized capabilities.

```bash
# Create a skill
cd data/config/skills
mkdir my-skill
cd my-skill

# Create SKILL.md with name and description
cat > SKILL.md << 'EOF'
---
name: my-skill
description: What this skill does
---

# My Skill

Usage instructions here...
EOF
```

Available skills include:
- [Pi Skills](https://github.com/badlogic/pi-skills) - Pre-built skills for common tasks
- [Anthropic Skills](https://github.com/anthropics/skills) - Document processing, web search

Create a custom skill by adding a `SKILL.md` file to `data/config/skills/`. Skills are loaded automatically and appear as `/skill:name` commands in the agent.

### Project-Level Skills

Place skills in `data/projects/<project-safe-path>/skills/` (where `<project-safe-path>` is the sanitized repo path, e.g. `Users--yourname--code--myproject`). These are project-specific and take precedence over global skills.

## Environment Variables

Environment variables are injected into the container via `data/.env` — no shell config or `docker` flags needed. Copy `data.example/.env.example` to `data/.env` and edit to add your variables.

### `.env` — file-based injection

Copy `data.example/.env.example` to `data/.env` and add `KEY=VALUE` lines. The Makefile passes this file to Docker via `--env-file`, which loads all variables into the container's environment:

```bash
# data/.env
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
```

Use this when you want to store secrets directly in the project. The variables are injected as-is with their original names.

## How it works

The container runs `pi` with a read-only filesystem, mounting:

| Host Path | Container Path | Mode | Purpose |
|-----------|---------------|------|---------|
| `$(REPO_DIR)` | `/projects/<project>` | rw | Your project files |
| `data/config/` | `/root/.pi/agent` | ro | All Pi config: models, settings, skills, extensions, prompts, themes, keybindings, trust decisions |
| `data/projects/<project-safe-path>/` | `/root/.pi/agent/sessions` | rw | Pi agent sessions and per-project overrides |

## Folder structure

```
data.example/            # Copy to data/ and edit to get started
├── .env.example         # Literal env vars template
├── config/
│   ├── models.json      # Model & provider configuration
│   ├── settings.json    # Global Pi settings
│   ├── AGENTS.example.md    # Global context file template
│   ├── APPEND_SYSTEM.example.md # System prompt append template
│   ├── SYSTEM.example.md    # System prompt replacement template
│   ├── keybindings.json # Custom keybindings
│   ├── trust.json       # Project trust decisions
│   ├── skills/          # Global skills directory (placeholder)
│   ├── extensions/      # Global extensions
│   ├── prompts/         # Prompt templates
│   ├── themes/          # Themes
│   ├── npm/             # npm pi packages
│   └── git/             # Git pi packages
data/                    # Your working copy — edit these files
├── .env                 # Literal env vars (copy from .env.example)
├── config/              # Same structure as data.example/config/
│   ├── models.json
│   ├── settings.json
│   ├── AGENTS.md
│   ├── APPEND_SYSTEM.md
│   ├── SYSTEM.md
│   ├── keybindings.json
│   ├── trust.json
│   ├── skills/
│   ├── extensions/
│   ├── prompts/
│   ├── themes/
│   ├── npm/
│   └── git/
└── projects/
    └── <project-safe-path>/  # Per-project session directory (sanitized repo path)
        ├── sessions/    # JSONL session files
        │   └── <project-path>/
        │       └── <timestamp>_id.jsonl   # Session history
        ├── models.json  # Per-project model overrides
        ├── settings.json # Per-project settings overrides
        ├── APPEND_SYSTEM.md # Per-project system prompt append
        ├── auth.json    # Per-project auth tokens
        └── skills/      # Project-specific skills
```

**Project directory naming:** The project directory name is the repo's absolute path with leading slashes stripped and slashes replaced with `--` (e.g., `/Users/daniel.litman/code/pi-box` becomes `Users--daniel.litman--code--pi-box`). This ensures sessions are project-isolated — each repository gets its own directory, and the same repo always maps to the same directory.

Session files live relative to the Makefile's location on the host, so the session state persists across runs and is tied to the project, not the working directory from which `make` is invoked.

## Requirements

- Docker
