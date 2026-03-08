# Orchestration

Run a project component through an automated convergence loop — the orchestrator agent reads the component's playbook, delegates to role agents, and repeats until work is complete.

## Quick start

```bash
run-orchestrate <project-name> <component>
```

This creates a tmux window `orch-{project}-{component}` in the `claude-work` session and starts the loop.

**Example:**

```bash
run-orchestrate my-app backend-api
# Creates window: orch-my-app-backend-api
# Runs in: ~/projects/my-app/
```

## Prerequisites

- The `claude-work` tmux session must be running (start with `claudework`)
- The project directory must exist at `~/projects/<project-name>`
- The project must have a playbook that the orchestrator agent can find (per the project's CLAUDE.md conventions)

## How it works

```
run-orchestrate          creates tmux window, launches orchestrate
    └─ orchestrate       convergence loop (up to 25 iterations)
        └─ claude --agent orchestrator -p <component>
            └─ reads playbook, delegates to role agents (planner, developer, judge, etc.)
```

Each iteration, the orchestrator agent emits a sentinel:

| Sentinel | Meaning | Loop action |
|----------|---------|-------------|
| `ORCHESTRATOR_RESULT:continue` | Work done, more to do | Next iteration |
| `ORCHESTRATOR_RESULT:complete` | All work finished | Exit success (0) |
| `ORCHESTRATOR_RESULT:blocked` | Needs human attention | Exit failure (1) |

Missing or unrecognized sentinel also stops the loop (exit 1).

## Options

```bash
run-orchestrate my-app backend-api --max-iterations 10
```

`--max-iterations N` — Override the default limit of 25 iterations.

## Logs

Each iteration is logged to `~/projects/<project-name>/orchestrator-logs/iteration-NNN.log`.

## Managing orchestrators

```bash
list-orchestrators          # List all orch-* windows
kill-orchestrator <name>    # Kill a specific orchestrator (e.g. orch-my-app-backend-api)
kill-orchestrators          # Kill all orchestrators
```

## Troubleshooting

- **"claude-work session not found"** — Run `claudework` first to start the tmux session.
- **"Orchestrator already running"** — Use `kill-orchestrator orch-{project}-{component}` to stop the existing one.
- **"Project directory not found"** — Create the project at `~/projects/<name>` first (or use `project-architect`).
- **Loop exits with "no-sentinel"** — The orchestrator agent didn't emit a valid sentinel. Check the iteration log for errors.
