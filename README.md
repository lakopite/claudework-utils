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
| `rotate-bastion` | Create or rotate the bastion window (supports `--loop` for continuous rotation). Primes new bastions with role context and triggers a graceful hand-off when retiring the old one |

## commands/

Claude Code slash commands, installed to `~/.claude/commands/`. These modify Claude's behavior within a session.

| Command | Description |
|---------|-------------|
| `sh.md` | Bash passthrough for remote control mode (workaround for direct bash not working) |
| `discuss.md` | Switches session into free-form discussion mode — conversation over action |
| `dump-context.md` | Snapshots session understanding to `~/projects/shared/exports/` with auto-named, versioned files |
| `pickup-context.md` | Loads a previously dumped context snapshot — lists available or fuzzy-matches by name |
| `project-architect.md` | Interactive project architect — Socratic, discussion-first workflow for designing specs and scaffolding Claude project structure (CLAUDE.md, agents, commands, hooks, rules). Operates at a meta tier above the target project. Two phases: (1) what are we building, (2) how do we want to build it. Supports `ideate` arg for zero-overhead brainstorming. Persists state in `.claude/_custom/command-notes/` |

## setup/

Scripts for bootstrapping a claudework session from the host user. Includes the tmux session launcher. See [setup/README.md](setup/README.md) for details.
