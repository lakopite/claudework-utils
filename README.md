# claudework-utils

Tooling ecosystem for multi-agent Claude Code development. Runs under a dedicated sandboxed OS user in tmux. Provides bash scripts, agents, commands, and templates that together enable autonomous orchestrated workflows.

## How It All Fits Together

```
┌─────────────────────────────────────────────────────────────┐
│                     tmux session: claude-work               │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────┐  │
│  │  home-base   │  │   bastion   │  │   agent-NNN        │  │
│  │  (user)      │  │ (coordinator│  │   (interactive     │  │
│  │              │  │  rotates)   │  │    claude session)  │  │
│  └─────────────┘  └─────────────┘  └────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  orch-{project}-{component}                          │   │
│  │  (bash convergence loop → claude -p invocations)     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Orchestration Flow

```
User/Bastion
  └─ run-orchestrate {project} {component}
       └─ orchestrate (bash convergence loop)
            └─ claude --agent orchestrator -p {component}
                 │
                 ├─ Reads project playbook
                 ├─ Delegates to project-level role agents
                 ├─ Emits sentinel (continue/complete/blocked)
                 └─ Loop continues or stops based on sentinel
```

The **orchestrator agent** is a generic playbook executor — it reads a project's playbook and follows its steps, delegating to project-level role agents (planner, analyzer, developer, judge, etc.). The **bash loop** handles iteration control, inflight tracking, and run bookkeeping. The project's **playbook** defines the pipeline — agent order, inputs, conditions, parallelism.

### Two-Layer Architecture

1. **User-level (this repo):** Bash scripts, orchestrator agent, session-inspect agent, workflow-reporter agent, slash commands, templates. Works on any project that follows the conventions.
2. **Project-level:** Role agents, playbooks, specs, CLAUDE.md files. Define what to build and how agents should behave for this specific project.

User-level tools read project-level content. The orchestrator agent reads project playbooks. The architect command reads project specs. Generic infrastructure, project-specific context.

### Templates

Templates in `templates/` are the architect's reference library — not runnable agents, but design patterns the `/project-architect` command draws from when scaffolding a new project or refining an existing one.

- `templates/agents/` — role archetypes with thinking disciplines, universal behaviors, and "what varies per project" guidance
- `templates/playbooks/{pattern}/` — workflow patterns with README, pipeline template, and working example agents

See [Templates](#templates-1) below for details.

## Installation

All content is installed via symlinks — edits to this repo are immediately live.

```bash
# Bash scripts on PATH (in .bashrc)
export PATH="$HOME/utilities/claudework-utils/bash:$PATH"

# Commands symlinked to ~/.claude/commands/
ln -sf ~/utilities/claudework-utils/commands/*.md ~/.claude/commands/

# Agents symlinked to ~/.claude/agents/
ln -sf ~/utilities/claudework-utils/agents/*.md ~/.claude/agents/

# Templates symlinked to ~/templates/
ln -sf ~/utilities/claudework-utils/templates/agents ~/templates/agents
ln -sf ~/utilities/claudework-utils/templates/playbooks ~/templates/playbooks
```

## bash/

Shell utilities on PATH for managing the `claude-work` tmux session.

### Agent Management

| Script | Description |
|--------|-------------|
| `new-claude` | Create agent window. `--remote` for remote control, `--path <dir>` for working dir |
| `go-claude` | Switch to an agent window |
| `list-claudes` | List all managed windows (agents and orchestrators) |
| `kill-claude` | Shut down a single agent window |
| `kill-claudes` | Shut down all agents (preserves bastion and session) |
| `kill-session` | Shut down everything |
| `restart-remote` | Restart remote control on an agent window |
| `rotate-bastion` | Create or rotate bastion window. `--loop` for continuous rotation |
| `project-architect` | Spin up architect agent for a project. `--ideate` for brainstorming mode |

### Orchestration

| Script | Description |
|--------|-------------|
| `run-orchestrate` | Create tmux window and run orchestration loop for a component |
| `orchestrate` | Convergence loop — runs `claude --agent orchestrator -p` repeatedly, parses sentinels, manages inflight tracking and run bookkeeping. Fully autonomous, no permission prompts |
| `list-orchestrators` | List orchestrator windows |
| `kill-orchestrator` | Kill a specific orchestrator window |
| `kill-orchestrators` | Kill all orchestrator windows |

## agents/

User-level agent prompts installed to `~/.claude/agents/`.

| Agent | Description |
|-------|-------------|
| `orchestrator` | Generic playbook executor. Reads project playbook, delegates to role agents, manages git operations in parent repo and component submodules, emits sentinels. Handles inflight recovery via session-inspect |
| `session-inspect` | Summarizes a Claude Code session from its logs. Used by orchestrator for crash recovery, also useful standalone |
| `workflow-reporter` | Ad-hoc agent that summarizes orchestrator run history and project progress since last report. Reads runs.json, git history, plan state. Produces workflow metrics (iterations, pass rates, completion velocity) |

## commands/

Slash commands installed to `~/.claude/commands/`.

| Command | Description |
|---------|-------------|
| `sh` | Bash passthrough for remote control mode |
| `discuss` | Switch to free-form discussion mode |
| `dump-context` | Snapshot session context to `~/projects/shared/exports/` |
| `pickup-context` | Load a previously dumped context snapshot |
| `project-architect` | Interactive project architect — Socratic interview for designing specs and project structure. Phases: (1) what are we building, (2) how do we want to build it. Supports `ideate`, `spec`, `workflow` args for scoped invocation |

## templates/

The architect's reference library. Used by `/project-architect` when scaffolding or refining projects.

### Agent Archetypes (`templates/agents/`)

Role definitions with thinking disciplines, universal behaviors, and guidance on what varies per project. Not runnable agent files — design reference for the architect.

| Archetype | Thinking Discipline | Role |
|-----------|---------------------|------|
| `planner` | Wonder/Reflect | Tech lead — owns the plan, synthesizes reviewer inputs |
| `analyzer` | Double Diamond | Senior engineer — produces implementation specs |
| `developer` | Simplifier | Junior producer — minimum faithful implementation |
| `test-writer` | Contrarian | Adversarial — attacks boundaries and assumptions |
| `test-fixer` | Diagnostic | Specialist — traces stale test failures to root cause |
| `judge` | Precision | Quality gate — exact discrepancies, short-circuits on failure |
| `qa-lead` | Coverage Integrity | Convergence gatekeeper — spec-level audit and integration tests |
| `documentation` | Clarity | Documentation producer — READMEs, generated artifacts, benchmark persistence |
| `staff-engineer-reviewer` | Alignment | Codebase-to-spec trajectory check |
| `product-manager-reviewer` | Relevance | Plan-to-spec validity check |
| `project-manager-reviewer` | Pattern Recognition | Execution health and systemic pattern detection |

### Playbook Patterns (`templates/playbooks/`)

Each pattern directory contains a README (when to use, pipeline diagram, key properties), a playbook template, and working example agents.

| Pattern | Description |
|---------|-------------|
| `complex-deterministic` | For projects with deterministic, testable outputs. Review tier → planner → analyzer → test-writer/developer (parallel) → judge. Convergence gate with QA lead + documentation agent. Includes test-fix alternate pipeline, calibrations mechanism, plan file management |

### How Templates Are Used

1. Architect reads archetypes to understand available roles
2. Architect reads playbook pattern that fits the project type
3. Architect interviews user about project-specific needs (Phase 2)
4. Architect produces project-level agents (adapted from archetypes) and playbook (adapted from template)

Templates are never deployed directly. The project agents are the runtime artifacts.

## setup/

Scripts for bootstrapping a claudework session from the host user. See [setup/README.md](setup/README.md).

## Project Conventions

Projects using this ecosystem follow these conventions:

```
{project}/
  CLAUDE.md                               # project identity, conventions
  specs/{category}/{component}.md         # source of truth specs
  playbooks/{category}/{component}.md     # orchestration playbooks
  playbooks/{category}/{component}.plan.md            # active tasks
  playbooks/{category}/{component}.plan.completed.md  # convergence history
  playbooks/{category}/{component}.plan.calibrations.md
  {category}/{component}/                 # implementation (submodule)
  .claude/agents/                         # project-level role agents
  .claude/_custom/orchestrator/           # run tracking, inflight state
```

### Two-Repo Structure

- **Parent repo** — metadata: specs, playbooks, plans, agents. Always on `main`.
- **Component submodule(s)** — code: implementation and tests. Feature/attempt branches for orchestrator work.

### Monitoring

Monitor autonomous workflows via their artifacts (plan files, test results, git history) — NOT via log scraping. Raw claude output may contain tool calls and agent prompts that pose prompt injection risk if piped into other sessions.
