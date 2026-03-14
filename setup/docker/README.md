# Setup: Docker Container

Run Claude Code in a Docker container with its own isolated filesystem, SSH key, and API configuration. The container uses tmux for session management — agents and orchestrators run as tmux windows inside the container.

> **Windows users:** Run all commands from WSL.

## Prerequisites

- Docker (Docker Desktop or Docker Engine)
- An SSH key pair dedicated to the container's git access
- An API key (e.g. OpenRouter)

## 1. Create the host home directory

This directory becomes the container user's entire home directory. Everything persists here across container rebuilds — projects, `.claude/` config, `.bashrc`, etc.

```bash
mkdir -p ~/claude-home
```

## 2. Clone claudework-utils into the home directory

```bash
mkdir -p ~/claude-home/utilities
git clone <your-repo-url> ~/claude-home/utilities/claudework-utils
```

## 3. Generate a dedicated SSH key

Create a key pair that only the container uses. Add the public key to GitHub (or your git host) as a deploy key or SSH key.

```bash
ssh-keygen -t ed25519 -C "claude-docker" -f ~/.ssh/claude_docker_id_ed25519 -N ""
```

Then add the public key:

```bash
cat ~/.ssh/claude_docker_id_ed25519.pub
# Copy this and add to GitHub → Settings → SSH and GPG keys
```

## 4. Configure environment

```bash
cd ~/claude-home/utilities/claudework-utils/setup/docker
cp .env.example .env
```

Edit `.env` and fill in your API key:

```bash
ANTHROPIC_API_KEY=sk-or-v1-your-actual-key
ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1
CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
```

If your host paths differ from the defaults, also set `CLAUDE_HOME`, `SSH_KEY_PATH`, and `SSH_PUB_PATH` in `.env`.

## 5. Build the container

```bash
cd ~/claude-home/utilities/claudework-utils/setup/docker
docker compose build
```

## 6. Install the entry script

Symlink `claudework` to somewhere on your PATH:

```bash
ln -s ~/claude-home/utilities/claudework-utils/setup/docker/claudework ~/.local/bin/claudework
```

Make sure `~/.local/bin` is on your PATH (add to `~/.bashrc` or `~/.zshrc` if needed).

## 7. Start working

```bash
claudework
```

This starts the container (if not already running), then attaches to the `claude-work` tmux session inside it. You land on the `home-base` window.

```
┌──────────────────────────────────────────┐
│         Docker container: claude-work     │
│         tmux session: claude-work         │
│                                           │
│  ┌────────────┐  ┌───────────┐           │
│  │ home-base  │  │ agent-NNN │           │
│  │ (you are   │  │ (created  │           │
│  │  here)     │  │  later)   │           │
│  └────────────┘  └───────────┘           │
└──────────────────────────────────────────┘
```

## Daily usage

| Action | Command |
|--------|---------|
| Start / attach | `claudework` |
| Detach (container keeps running) | `Ctrl-B D` |
| Stop the container | `docker stop claude-work` |
| View container logs | `docker logs claude-work` |
| Rebuild after updating Claude CLI | `cd ~/claude-home/utilities/claudework-utils/setup/docker && docker compose build --no-cache` |

## What the entrypoint does on each start

The container's entrypoint script runs every time the container starts. It is idempotent:

1. Copies SSH key from `/run/secrets/` to `~/.ssh/` with correct permissions
2. Adds `claudework-utils/bash` to PATH in `.bashrc` (if not already present)
3. Creates symlinks for `~/.claude/agents/`, `~/.claude/commands/`, `~/templates/` (if not already present)
4. Creates `~/projects/` directory
5. Creates or attaches to the `claude-work` tmux session with a `home-base` window

## Verify the setup

Inside the container (after running `claudework`):

```bash
which orchestrate          # Should show ~/utilities/claudework-utils/bash/orchestrate
ls -la ~/.claude/agents/   # Should show symlink to claudework-utils/agents/
ls -la ~/.claude/commands/  # Should show symlink to claudework-utils/commands/
ssh -T git@github.com      # Should authenticate successfully
claude --version           # Should print Claude CLI version
```

## Updating Claude CLI

The Claude CLI is baked into the Docker image. To update:

```bash
cd ~/claude-home/utilities/claudework-utils/setup/docker
docker compose build --no-cache
docker compose up -d
```

Your volumes (home directory, SSH keys) are unaffected by image rebuilds.

## Design notes

- **Host dir = container home dir.** `~/claude-home` mounts to `/home/claude`. Everything persists — `.bashrc`, `.claude/`, projects, templates.
- **SSH keys via `/run/secrets/`.** Mounted read-only from host, copied by entrypoint with correct permissions (600). Avoids macOS bind-mount permission issues.
- **OpenRouter via env vars.** `ANTHROPIC_API_KEY` + `ANTHROPIC_BASE_URL` in `.env`.
- **No bastion/rotator.** Remote control rotation is not needed when you `docker exec` directly. The bastion-related scripts in `bash/` still exist but are simply unused.
- **Container stays running.** `restart: unless-stopped`. Attach/detach from tmux. Orchestrators survive detach.
