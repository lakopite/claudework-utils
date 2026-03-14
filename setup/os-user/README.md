# Setup: Dedicated OS User

Run Claude Code under a dedicated sandboxed `claude` OS user. The `claudework` script uses `sudo -u claude -i` to create and manage a tmux session, with a bastion window for Claude Code Web remote control access.

## Prerequisites

- A dedicated `claude` OS user on the host
- `sudo` access to switch to the `claude` user
- `tmux`, `git`, `xxd`, `jq`, `python3`, `uuidgen` installed
- Claude CLI installed and authenticated (under the `claude` user)

## 1. Create the claude user

```bash
sudo useradd -m -s /bin/bash claude
```

## 2. Clone claudework-utils

As the `claude` user:

```bash
sudo -u claude -i
mkdir -p ~/utilities
git clone <your-repo-url> ~/utilities/claudework-utils
```

## 3. Add bash scripts to PATH

Add to the `claude` user's `~/.bashrc`:

```bash
export PATH="$HOME/utilities/claudework-utils/bash:$PATH"
```

Then reload:

```bash
source ~/.bashrc
```

## 4. Symlink agents, commands, and templates

```bash
# Agents (user-level)
mkdir -p ~/.claude/agents
for f in ~/utilities/claudework-utils/agents/*.md; do
  ln -sf "$f" ~/.claude/agents/"$(basename "$f")"
done

# Commands (slash commands)
mkdir -p ~/.claude/commands
for f in ~/utilities/claudework-utils/commands/*.md; do
  ln -sf "$f" ~/.claude/commands/"$(basename "$f")"
done

# Templates (architect reference library)
mkdir -p ~/templates
ln -sf ~/utilities/claudework-utils/templates/agents ~/templates/agents
ln -sf ~/utilities/claudework-utils/templates/playbooks ~/templates/playbooks
```

## 5. Install the entry script

From your personal user (not the `claude` user):

```bash
ln -s /path/to/claudework-utils/setup/os-user/claudework ~/.local/bin/claudework
```

Make sure `~/.local/bin` is on your PATH.

## 6. Start working

```bash
claudework
```

This creates (or attaches to) a `claude-work` tmux session under the `claude` user. You land on the `home-base` window. The bastion rotator starts automatically, keeping a fresh remote control session available.

```
┌───────────────────────────────────────────────────┐
│                tmux: claude-work                   │
│                                                    │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐ │
│  │ home-base  │  │  rotator  │  │   bastion    │ │
│  │ (you are   │  │ (auto-    │  │  (remote     │ │
│  │  here)     │  │  rotates  │  │   control)   │ │
│  │            │  │  bastion) │  │              │ │
│  └────────────┘  └───────────┘  └──────────────┘ │
└───────────────────────────────────────────────────┘
```

## Verify the setup

Inside the `claude-work` session:

```bash
which orchestrate          # Should resolve to claudework-utils/bash/orchestrate
ls -la ~/.claude/agents/   # Should show symlinks to claudework-utils/agents/
ls -la ~/.claude/commands/  # Should show symlinks to claudework-utils/commands/
ls ~/templates/agents/     # Should list template archetypes
claude --version           # Should print Claude CLI version
```

## OS-user-specific features

This setup includes features that rely on Claude Code's native authentication and Claude Max:

- **Bastion rotation** (`rotate-bastion --loop`): Continuously rotates a remote control session for Claude Code Web access. Runs automatically in the `rotator` window.
- **Remote control** (`restart-remote`, `new-claude --remote`): Enables `/rc` on agent windows for remote access.

These features require Claude's interactive OAuth (not API key auth) and are specific to the OS-user setup.
