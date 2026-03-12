# Setup

Scripts and configuration for bootstrapping a claudework session.

## claudework

Entry point script to create or attach to the `claude-work` tmux session. Run this as your personal user (not as the `claude` user directly). It uses `sudo` to launch and manage the session under a dedicated `claude` OS user, which allows sandboxing (e.g. preventing automount access).

Install to your personal user's `~/.local/bin/claudework`.

## PATH setup (claude user)

Add the repo's `bash/` directory to the claude user's PATH in `~/.bashrc`:

```bash
export PATH="/path/to/claudework-utils/bash:$PATH"
```

This makes all bash utilities available without symlinks, and any scripts added to or removed from `bash/` are immediately available.

## Commands setup (claude user)

Symlink command files to `~/.claude/commands/`:

```bash
mkdir -p ~/.claude/commands
for f in /path/to/claudework-utils/commands/*.md; do
  ln -sf "$f" ~/.claude/commands/"$(basename "$f")"
done
```

This makes slash commands available across all sessions. Edits to the repo are immediately live.

## Agents setup (claude user)

Symlink agent files to `~/.claude/agents/`:

```bash
mkdir -p ~/.claude/agents
for f in /path/to/claudework-utils/agents/*.md; do
  ln -sf "$f" ~/.claude/agents/"$(basename "$f")"
done
```

This makes user-level agents available across all projects. Project-level agents (in `.claude/agents/`) take precedence. Edits to the repo are immediately live.
