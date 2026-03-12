# Example: Complex Deterministic Project — Soup to Nuts

Build a project with deterministic, testable outputs using the full claudework-utils pipeline. This walkthrough assumes a completely fresh environment — nothing installed, no project, no spec.

**What you'll end up with:**

```
~/projects/my-project/                    <-- parent repo (metadata)
  CLAUDE.md
  specs/core/engine.md                    <-- your spec (source of truth)
  playbooks/core/engine.md                <-- orchestration playbook
  playbooks/core/engine.plan.md           <-- living plan (planner-managed)
  playbooks/core/engine.plan.completed.md
  playbooks/core/engine.plan.calibrations.md
  .claude/agents/                         <-- project-level role agents
  core/engine/                            <-- component submodule (code)
    src/
    tests/
    tests/integration/
```

---

## Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        YOUR JOURNEY                                  │
│                                                                      │
│  ┌─────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────────┐  │
│  │ Install  │──▶│ Architect│──▶│  Review  │──▶│ Run Orchestrator │  │
│  │ Tooling  │   │  Project │   │  Output  │   │  (autonomous)    │  │
│  └─────────┘   └──────────┘   └──────────┘   └──────────────────┘  │
│                                                                      │
│  You do this    Interactive     You approve    Hands-off             │
│  once           Socratic        the scaffold   convergence loop      │
│                 interview                                            │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Phase 0: Install claudework-utils

You need a dedicated `claude` OS user and the claudework-utils repo. If you already have these, skip ahead.

### Clone the repo

```bash
# As the claude user
mkdir -p ~/utilities
git clone <your-repo-url> ~/utilities/claudework-utils
```

### Add bash scripts to PATH

Add to `~/.bashrc`:

```bash
export PATH="$HOME/utilities/claudework-utils/bash:$PATH"
```

Then reload:

```bash
source ~/.bashrc
```

### Symlink agents, commands, and templates

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

### Verify installation

```bash
which orchestrate         # should resolve
ls ~/.claude/agents/      # orchestrator.md, session-inspect.md, workflow-reporter.md
ls ~/.claude/commands/    # sh.md, discuss.md, dump-context.md, etc.
ls ~/templates/agents/    # analyzer.md, developer.md, judge.md, etc.
```

---

## Phase 1: Start a claudework session

The `claudework` script creates (or attaches to) a tmux session called `claude-work`. This is your workspace — all agents, orchestrators, and the bastion run as windows inside it.

```bash
# From your personal user (not the claude user)
claudework
```

What happens:

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

You land in the `home-base` window. The rotator keeps the bastion fresh for remote control. From here, you manage everything.

---

## Phase 2: Architect your project

This is the interactive part. The project architect conducts a Socratic interview to design your spec (Phase 1) and workflow (Phase 2).

### Launch the architect

From `home-base`:

```bash
project-architect my-project
```

This does three things:
1. Creates `~/projects/my-project/` and initializes a git repo
2. Spins up a new agent window (e.g., `agent-001`)
3. Sends `/project-architect` to that agent

```
┌───────────────────────────────────────────────────┐
│                tmux: claude-work                   │
│                                                    │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐ │
│  │ home-base  │  │ agent-001 │  │   bastion    │ │
│  │            │  │ (architect│  │              │ │
│  │            │  │  session) │  │              │ │
│  └────────────┘  └───────────┘  └──────────────┘ │
└───────────────────────────────────────────────────┘
```

Switch to the architect window:

```bash
go-claude agent-001
```

### The Socratic interview

The architect reads templates and asks you questions. It's a conversation, not a form. Expect questions like:

**Phase 1 — What are we building?**
```
Architect: What does this project do? Who is it for?
You:       It's a Markdown-to-HTML compiler with plugin support.

Architect: When you say "plugin support" — what can plugins do?
           Can they add new syntax? Transform output? Both?
You:       Both. Plugins can register new block-level syntax and
           post-process the HTML output.

Architect: How do you know it's correct? What's your test oracle?
You:       Given input markdown + plugins, the output HTML should
           match exactly. Deterministic transformation.

Architect: That's a clean fit for complex-deterministic. Let me
           push on the plugin API — how does registration work?
           ...
```

The architect keeps probing until the spec is solid across four dimensions:
- **Goal clarity** — exactly what we're building
- **Constraint clarity** — tech stack, boundaries, limitations
- **Success criteria** — how we know it works
- **Domain clarity** — key concepts and their relationships

**Phase 2 — How do we build it?**

The architect reads playbook templates and proposes a workflow:

```
Architect: Your project has deterministic outputs and a clear test
           oracle. The complex-deterministic playbook is a natural
           fit. Here's what that gives you:

           - 3 parallel reviewers check alignment before planning
           - Planner owns the living plan
           - Analyzer produces implementation specs per task
           - Developer and test-writer work independently in parallel
           - Judge short-circuits on test failure
           - QA lead runs convergence audit

           Any of these roles feel wrong for your project?
You:       That looks right. Let's go with it.
```

### What the architect produces

When you approve, the architect creates:

```
~/projects/my-project/
  CLAUDE.md                                    <-- project identity + conventions
  specs/core/engine.md                         <-- your spec
  playbooks/core/engine.md                     <-- orchestration playbook
  .claude/agents/
    planner.md                                 <-- adapted from archetype
    analyzer.md
    developer.md
    test-writer.md
    test-fixer.md
    judge.md
    qa-lead.md
    documentation.md
    staff-engineer-reviewer.md
    product-manager-reviewer.md
    project-manager-reviewer.md
```

Each agent is adapted from the template archetypes — same thinking discipline and structure, but with project-specific paths, conventions, and context baked in.

---

## Phase 3: Set up the component submodule

The architect creates the parent repo structure. You need to create the component repo (where the actual code lives) and wire it up as a submodule.

```bash
# Create the component repo
cd ~/projects/my-project
mkdir -p core/engine
cd core/engine
git init
# Add initial structure (e.g., src/, tests/, tests/integration/)
mkdir -p src tests tests/integration
touch src/.gitkeep tests/.gitkeep tests/integration/.gitkeep
git add -A && git commit -m "Initial component structure"

# Back in parent repo, add as submodule
cd ~/projects/my-project
git submodule add ./core/engine core/engine
git add -A && git commit -m "Add engine component submodule and project scaffold"
```

The two-repo structure:

```
~/projects/my-project/          <-- PARENT REPO (metadata)
│                                   Always on main.
│                                   Specs, playbooks, plans, agents.
│
├── specs/core/engine.md
├── playbooks/core/engine.md
├── .claude/agents/*.md
│
└── core/engine/                <-- COMPONENT SUBMODULE (code)
    │                               Has feature/attempt branches.
    │                               Orchestrator manages all branching.
    ├── src/
    ├── tests/
    └── tests/integration/
```

**Why two repos?** The parent repo stays on `main` — metadata changes are always safe to commit. The component submodule gets feature branches, attempt branches, and convergence branches that the orchestrator manages. Clean separation of concerns.

---

## Phase 4: Run the orchestrator

This is where it gets autonomous. The orchestrator reads your playbook, delegates to role agents, and loops until convergence.

### Launch

From `home-base`:

```bash
run-orchestrate my-project engine
```

This creates a new tmux window and starts the convergence loop:

```
┌──────────────────────────────────────────────────────────────────┐
│                       tmux: claude-work                           │
│                                                                   │
│  ┌────────────┐  ┌─────────────────────────┐  ┌──────────────┐  │
│  │ home-base  │  │ orch-my-project-engine   │  │   bastion    │  │
│  │            │  │                           │  │              │  │
│  │            │  │  orchestrate loop running │  │              │  │
│  │            │  │  iteration 1 / 25...      │  │              │  │
│  └────────────┘  └─────────────────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### What happens each iteration

```
orchestrate (bash)
  │
  ├─ Generate session UUID
  ├─ Write session ID to .inflight
  ├─ Invoke: claude --agent orchestrator --dangerously-skip-permissions -p engine
  │    │
  │    │  ┌─────────────────────────────────────────────────────┐
  │    │  │           ORCHESTRATOR (one iteration)               │
  │    │  │                                                      │
  │    │  │  1. Read playbook: playbooks/core/engine.md          │
  │    │  │  2. Read plan (or let planner create it)             │
  │    │  │                                                      │
  │    │  │  3. REVIEW (parallel)                                │
  │    │  │     ├─ Staff Engineer Reviewer → alignment brief     │
  │    │  │     ├─ Product Manager Reviewer → relevance brief    │
  │    │  │     └─ Project Manager Reviewer → health brief       │
  │    │  │                                                      │
  │    │  │  4. PLAN                                             │
  │    │  │     └─ Planner synthesizes briefs → updates plan     │
  │    │  │                                                      │
  │    │  │  5. SELECT first unblocked task                      │
  │    │  │                                                      │
  │    │  │  6. ANALYZE (analyzer produces implementation spec)  │
  │    │  │                                                      │
  │    │  │  7. IMPLEMENT (parallel)                             │
  │    │  │     ├─ Test Writer ──┐  (neither sees                │
  │    │  │     └─ Developer ───┘   the other)                   │
  │    │  │                                                      │
  │    │  │  8. JUDGE                                            │
  │    │  │     ├─ Tests pass + spec compliant → [judge:pass]    │
  │    │  │     └─ Tests fail → [judge:fail] (short-circuit)     │
  │    │  │                                                      │
  │    │  │  9. Emit sentinel                                    │
  │    │  └─────────────────────────────────────────────────────┘
  │    │
  │    └─ stdout: ORCHESTRATOR_RESULT:continue
  │
  ├─ Parse sentinel
  ├─ Record iteration in runs.json
  ├─ Clear .inflight
  └─ Loop back to next iteration (or stop on complete/blocked)
```

### The convergence loop

```
Iteration 1:  Review → Plan (creates plan with 8 tasks) → Task 1 → Pass    ✓
Iteration 2:  Review → Plan (no changes) → Task 2 → Pass                   ✓
Iteration 3:  Review → Plan (no changes) → Task 3 → Fail                   ✗
Iteration 4:  Review → Plan (notes failure) → Task 3 retry → Pass          ✓
Iteration 5:  Review → Plan (no changes) → Task 4 → Pass                   ✓
   ...
Iteration N:  Review → Plan (all tasks done!) → Convergence Gate
              QA Lead audit → QA Lead write+run → Documentation → Complete  ✓

>>> Sentinel: complete
```

Each iteration does ONE task. The bash loop handles the repetition. If a task fails twice, the planner marks it `blocked` and the orchestrator moves on or stops.

### Git branch management

The orchestrator manages all branching in the component submodule:

```
main                                          <-- human-controlled
└─ orchestrator-converged                     <-- promotion target
   └─ orchestrator-in-progress                <-- accumulates passed tasks
      ├─ orchestrator/feature/parse-blocks
      │  ├─ ...--attempt-1                    <-- first try (judge:fail)
      │  └─ ...--attempt-2                    <-- second try (judge:pass) ✓
      ├─ orchestrator/feature/plugin-api
      │  └─ ...--attempt-1                    <-- first try (judge:pass) ✓
      └─ orchestrator/feature/html-render
         └─ ...--attempt-1                    <-- (in progress)
```

Attempt branches are the audit trail — never deleted. When a task passes, its changes merge into `orchestrator-in-progress`. When convergence completes, `orchestrator-in-progress` merges into `orchestrator-converged`. You promote `orchestrator-converged` to `main` when you're satisfied.

---

## Phase 5: Monitor and interact

### Check status

From `home-base`:

```bash
# List what's running
list-claudes              # all windows
list-orchestrators        # just orchestrator windows

# View the plan directly
cat ~/projects/my-project/playbooks/core/engine.plan.md
```

### Run a workflow report

Spin up an interactive agent and ask for a report:

```bash
new-claude --path ~/projects/my-project
go-claude agent-002
```

Then in the agent session, use the workflow reporter:

```
You: Give me a workflow report for the engine component
```

Or from the bastion via remote control. The workflow reporter reads `runs.json`, plan files, and git history to produce metrics: iteration counts, pass/fail rates, completion velocity, and blocked items.

### Stop the orchestrator

```bash
kill-orchestrator orch-my-project-engine     # stop one
kill-orchestrators                            # stop all
```

### Handle blocked tasks

When the orchestrator emits `blocked`, check the plan:

```bash
cat ~/projects/my-project/playbooks/core/engine.plan.md
```

Look for tasks marked `blocked` and their feedback history. Fix the issue (update the spec, clarify requirements, fix infrastructure), then re-run:

```bash
run-orchestrate my-project engine
```

The next iteration's planner will see the unblocked state and continue.

---

## Phase 6: Promote and ship

When the orchestrator completes (all tasks done, QA passes, docs generated):

```bash
cd ~/projects/my-project/core/engine

# Review what was built
git log orchestrator-converged --oneline

# Promote to main when satisfied
git checkout main
git merge orchestrator-converged
git push
```

---

## The Full Picture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          COMPLETE FLOW                                   │
│                                                                          │
│  YOU                            CLAUDEWORK                               │
│  ───                            ─────────                                │
│                                                                          │
│  claudework ──────────────────▶ tmux session created                     │
│                                    │                                     │
│  project-architect my-project ──▶ Agent window + /project-architect      │
│    │                                 │                                   │
│    ├─ Answer questions ◀──────────── Socratic interview                  │
│    ├─ Review spec      ◀──────────── Spec draft                          │
│    ├─ Approve scaffold ◀──────────── Agent/playbook/CLAUDE.md proposal   │
│    │                                 │                                   │
│    └─ Create component submodule     │                                   │
│                                      │                                   │
│  run-orchestrate my-project engine ─▶ Convergence loop starts            │
│    │                                    │                                │
│    │  (autonomous — you can walk away)  │                                │
│    │                                    ├─ Iteration 1: task 1 pass      │
│    │                                    ├─ Iteration 2: task 2 pass      │
│    │                                    ├─ Iteration 3: task 3 fail      │
│    │                                    ├─ Iteration 4: task 3 pass      │
│    │                                    ├─ ...                           │
│    │                                    ├─ Iteration N: convergence gate │
│    │                                    └─ complete ✓                    │
│    │                                                                     │
│    ├─ Review results                                                     │
│    └─ git merge orchestrator-converged                                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

| What you want | Command |
|---------------|---------|
| Start session | `claudework` |
| Architect a new project | `project-architect my-project` |
| Brainstorm before committing | `project-architect my-project --ideate` |
| Launch orchestrator | `run-orchestrate my-project engine` |
| List running agents | `list-claudes` |
| Switch to an agent window | `go-claude agent-001` |
| Spin up interactive agent | `new-claude --path ~/projects/my-project` |
| Check orchestrator status | `list-orchestrators` |
| Stop one orchestrator | `kill-orchestrator orch-my-project-engine` |
| Stop all orchestrators | `kill-orchestrators` |
| Stop all agents | `kill-claudes` |
| Tear down everything | `kill-session` |
| Get workflow report | Use `workflow-reporter` agent in an interactive session |
| Dump session context | `/dump-context` in any agent session |
| Pick up where you left off | `/pickup-context` in a new agent session |

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `claude-work session not found` | Haven't started session | Run `claudework` |
| `Orchestrator already running` | Window exists | `kill-orchestrator orch-my-project-engine` then re-run |
| `Project directory not found` | No `~/projects/my-project` | Run `project-architect my-project` first |
| Orchestrator exits with no-sentinel | Agent crashed or hit context limit | Check `.claude/_custom/orchestrator/.inflight` — next run auto-recovers |
| Task stuck (two consecutive fails) | Planner marks it blocked | Check plan feedback, fix spec or code, re-run |
| Convergence gate finds gaps | QA lead identifies missing coverage | Planner gets new tasks, loop continues automatically |
