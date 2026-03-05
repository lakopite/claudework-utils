# claudework-utils

Utilities for managing a multi-agent Claude Code environment running under a dedicated OS user in tmux.

## bash/

Shell utilities available on the agent user's PATH for managing agent windows within the `claude-work` tmux session.

| Script | Description |
|--------|-------------|
| `new-claude` | Create a new agent window (optionally with remote control and custom working dir) |
| `go-claude` | Switch to an agent window |
| `list-claudes` | List all managed windows in the session |
| `kill-claude` | Gracefully shut down a single agent window |
| `kill-claudes` | Gracefully shut down all agents (preserves bastion and session) |
| `kill-session` | Shut down all agents, bastion, and the session itself |
| `restart-remote` | Restart remote control on an agent window (disconnects first if already active) |
| `rotate-bastion` | Create or rotate the bastion window (supports `--loop` for continuous rotation) |
| `check-retiring` | UserPromptSubmit hook that rejects prompts on rotated-out bastions |

## setup/

Scripts and config for bootstrapping a claudework session from the host user. Includes the tmux session launcher and a bash passthrough workaround for remote control mode. See [setup/README.md](setup/README.md) for details.
