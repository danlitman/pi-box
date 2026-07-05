# pi-box

A secure, Docker-based sandbox for running [Pi Agent](https://github.com/earendil-works/pi) against your projects.

Pi runs inside a read-only container with all dangerous capabilities dropped — it can read and write your code, stage and commit git changes, but cannot push, pull, merge, or reach the network except through explicitly configured APIs. All configuration (models, API keys, system instructions) lives in plain files you edit — no shell config, no docker flags, no secrets in environment variables on your host.

## What it does

- **Isolates the agent** in a container with a read-only filesystem and no network access
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
   cp -r data.example/* data/
   cp data.example/.env .env
   ```
   The `data.example/` directory contains everything you need — models config, system instructions, env var mappings. Copy it to `data/` and edit to suit your setup.

2. **Configure models** in `data/models.json`. This file is mounted read-only into the container at `/root/.pi/agent/models.json`. See the [Pi docs on custom models](https://github.com/earendil-works/pi) for supported APIs (OpenAI-compatible, Anthropic, Google, etc.).

3. **Optionally add system instructions** in `data/APPEND_SYSTEM.md`. This file is mounted read-only into the container at `/root/.pi/agent/APPEND_SYSTEM.md`.

4. **Set literal env vars** in `.env`. Add `KEY=VALUE` lines for variables you want injected directly into the container:
   ```
   OPENAI_API_KEY=sk-...
   ANTHROPIC_API_KEY=sk-ant-...
   ```

5. **Run the agent:
   ```bash
   make run
   ```
   Pass an API key via environment variable (e.g., `ANTHROPIC_API_KEY`, or via `--api-key` flag).

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

## Environment Variables

Environment variables are injected into the container via two mechanisms, both configured entirely within the `data/` directory and `.env` — no shell config or `docker` flags needed.

The Makefile reads these files and generates `docker -e` flags automatically:

### 1. `.env` — literal values
Add `KEY=VALUE` lines. The Makefile passes them directly as `-e KEY=VALUE` to Docker.

```bash
# .env
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
```

Use this when you want to store secrets directly in the project. The values are injected as-is with the same variable name.

## How it works

The container runs `pi` with a read-only filesystem, mounting:

| Host Path | Container Path | Mode | Purpose |
|-----------|---------------|------|---------|
| `$(REPO_DIR)` | `/projects/<project>` | rw | Your project files |
| `.env` | *(injected as `-e` flags)* | ro | Literal env vars for the container |
| `data/models.json` | `/root/.pi/agent/models.json` | ro | Model/provider configuration |
| `data/APPEND_SYSTEM.md` | `/root/.pi/agent/APPEND_SYSTEM.md` | ro | Additional system instructions |

| `data/sessions/<hash>/` | `/root/.pi/agent` | rw | Pi agent state, sessions, and cache |
| `~/.gitconfig` | `/root/.gitconfig` | ro | Git credentials |

## Folder structure

```
data.example/            # Copy to data/ and edit to get started
├── models.json          # Model & provider configuration
├── APPEND_SYSTEM.md     # Optional: additional system instructions
└── .env                 # Literal env vars template
data/                    # Your working copy — edit these files
├── models.json          # Model & provider configuration
├── APPEND_SYSTEM.md     # Optional: additional system instructions
.env                     # Literal env vars for the container
└── sessions/
    └── <hash>/          # Per-project session directory
        ├── sessions/
        │   └── <project-path>/
        │       └── <timestamp>_id.jsonl   # Session history
        ├── models.json
        ├── settings.json
        └── auth.json
```

**Session directory naming:** The session directory name is the first 12 characters of a SHA-256 hash of the repo's absolute path. This ensures sessions are project-isolated — each repository gets its own session directory, and the same repo always maps to the same directory.

Session files live relative to the Makefile's location on the host, so the session state persists across runs and is tied to the project, not the working directory from which `make` is invoked.

## Requirements

- Docker
