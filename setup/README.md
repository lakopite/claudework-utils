# Setup

Two ways to create the sandboxed `claude-work` tmux session. Both produce the same environment — bash utilities on PATH, agents/commands/templates symlinked, projects directory ready. Everything downstream (agents, orchestration, slash commands) works identically regardless of which setup you choose.

| | [Dedicated OS User](os-user/README.md) | [Docker Container](docker/README.md) |
|---|---|---|
| **Isolation** | Separate OS user (`claude`) | Container filesystem |
| **Entry** | `sudo -u claude -i` into tmux | `docker exec` into tmux |
| **Auth** | Claude CLI interactive OAuth | API key via env vars (e.g. OpenRouter) |
| **Bastion/rotator** | Yes — remote control for Claude Code Web | No — not needed, not applicable with API key auth |
| **Persistence** | User's home directory | Host bind mount (`~/claude-home`) |
| **Platform** | Linux / macOS | Linux / macOS / Windows (WSL) |
| **Best for** | Claude Max users who want remote control access | API key users, cross-platform, simpler isolation |

## After setup

Both paths give you a `claude-work` tmux session with a `home-base` window. From there, usage is identical:

```bash
project-architect my-project    # Design a new project
run-orchestrate my-project engine  # Run autonomous pipeline
list-claudes                    # See what's running
```

See the [examples](../examples/README.md) for full walkthroughs.
