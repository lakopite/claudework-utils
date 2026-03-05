# Setup

Scripts and configuration for bootstrapping a claudework session.

## claudework

Entry point script to create or attach to the `claude-work` tmux session. Run this as your personal user (e.g. `lakopite`), not as the `claude` user directly. It uses `sudo` to launch and manage the session under a dedicated `claude` OS user, which allows sandboxing (e.g. preventing automount access).

Install to your personal user's `~/.local/bin/claudework`.

## sh.md

Claude Code slash command (`/sh`) that provides a bash passthrough. This exists as a workaround because Claude Code's remote control mode doesn't handle direct bash passthrough correctly. By routing through a slash command with explicit `Bash(*)` tool permissions, commands execute reliably.

Install to `.claude/commands/sh.md` in the project or user config directory.
