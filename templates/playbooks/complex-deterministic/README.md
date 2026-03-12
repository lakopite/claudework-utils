# Playbook Pattern: Complex Deterministic

## When to Use

Projects where:
- The work product has deterministic, verifiable outputs (code, data transformations, configuration)
- Automated testing is the primary verification method
- The spec is detailed enough to derive expected values
- Quality is measured by spec compliance, not subjective judgment

Examples: simulation engines, data pipelines, API backends, libraries with well-defined interfaces, compilers, parsers.

**Not a fit for:** design-heavy work, exploratory research, documentation-only projects, or anything where "correct" is subjective.

## Pipeline Overview

```
┌─────────────────────────────────────────────────────────┐
│                    PRE-PLAN REVIEW                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │    Staff      │ │   Product    │ │    Project       │ │
│  │   Engineer    │ │   Manager    │ │    Manager       │ │
│  │   Reviewer    │ │   Reviewer   │ │    Reviewer      │ │
│  │  (alignment)  │ │  (relevance) │ │  (health)        │ │
│  └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘ │
│         └────────────────┼──────────────────┘           │
└──────────────────────────┼──────────────────────────────┘
                           ▼
                    ┌──────────────┐
                    │   Planner    │
                    │  (wonder/    │
                    │   reflect)   │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │ Task Select  │
                    │ + Branch     │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │    Route     │──── test-fix? ──┐
                    └──────┬───────┘                 │
                           │ standard                │
                    ┌──────┴───────┐          ┌──────┴───────┐
                    │   Analyzer   │          │  Test Fixer  │
                    │  (double     │          │ (diagnostic) │
                    │   diamond)   │          └──────┬───────┘
                    └──────┬───────┘                 │
                           │                         │
              ┌────────────┴────────────┐            │
              │                         │            │
       ┌──────┴───────┐  ┌─────────────┴─┐          │
       │  Test Writer  │  │   Developer   │          │
       │ (contrarian)  │  │ (simplifier)  │          │
       └──────┬───────┘  └──────┬────────┘          │
              │                  │                   │
              └────────┬─────────┘                   │
                       │                             │
                ┌──────┴───────┐◄────────────────────┘
                │    Judge     │
                │  (precision) │
                └──────┬───────┘
                       │
                       ▼
              pass → mark done, compact feedback, continue
              fail → write feedback, continue
              all done → convergence gate ▼

┌─────────────────────────────────────────────────────────┐
│                   CONVERGENCE GATE                       │
│                                                          │
│  ┌──────────────┐     ┌──────────────────────────────┐  │
│  │  QA Lead     │     │  QA Lead                     │  │
│  │  Audit       │────▶│  Write + Run + Benchmark     │  │
│  │  (Mode 1)    │     │  (Mode 2, always runs)       │  │
│  └──────────────┘     └──────────────┬───────────────┘  │
│                                      │                   │
│                              ┌───────┴────────┐         │
│                              │                │         │
│                         gaps found       all clean      │
│                              │                │         │
│                              ▼                ▼         │
│                        ┌──────────┐   ┌──────────────┐  │
│                        │ Planner  │   │Documentation │  │
│                        │(new tasks)│  │   Agent      │  │
│                        └────┬─────┘   └──────┬───────┘  │
│                             │                │          │
│                          continue      compact + merge  │
│                                        → complete       │
└─────────────────────────────────────────────────────────┘
```

## Agent Roster

| Role | Archetype | Thinking Discipline | Pipeline Position |
|------|-----------|---------------------|-------------------|
| Staff Engineer Reviewer | `templates/agents/staff-engineer-reviewer.md` | Alignment | Pre-plan (parallel) |
| Product Manager Reviewer | `templates/agents/product-manager-reviewer.md` | Relevance | Pre-plan (parallel) |
| Project Manager Reviewer | `templates/agents/project-manager-reviewer.md` | Pattern Recognition | Pre-plan (parallel) |
| Planner | `templates/agents/planner.md` | Wonder/Reflect | Plan |
| Analyzer | `templates/agents/analyzer.md` | Double Diamond | Per-task (standard) |
| Test Writer | `templates/agents/test-writer.md` | Contrarian | Per-task (parallel with developer) |
| Developer | `templates/agents/developer.md` | Simplifier | Per-task (parallel with test-writer) |
| Test Fixer | `templates/agents/test-fixer.md` | Diagnostic | Per-task (test-fix alternate) |
| Judge | `templates/agents/judge.md` | Precision | Per-task (after implementation) |
| QA Lead | `templates/agents/qa-lead.md` | Coverage Integrity | Convergence only |
| Documentation Agent | `templates/agents/documentation.md` | Clarity | Convergence only |

## Key Properties

### Convergence Model
One workflow that "closes the gap" between current state and spec. Same mechanics handle greenfield, change, and bugfix. "Done" = re-running the process finds nothing to do.

### One Task Per Run
Each orchestrator invocation: review → plan → pick one task → execute → judge → exit. The bash convergence loop re-runs until the plan says everything is done.

### Plan-Driven Execution
The plan is a living, persistent artifact — a derivative of the spec. Task order in the plan IS execution priority. The planner controls sequencing.

### Three Plan Artifacts
- `{component}.plan.md` — active tasks only, stays lean
- `{component}.plan.completed.md` — compacted convergence history
- `{component}.plan.calibrations.md` — calibration history

### Feedback Compaction
When the orchestrator marks a task done after a judge pass, it replaces the task's feedback section with just the `[judge:pass]` line. Full history preserved in git.

### Calibrations
Targeted corrections for systemic cross-task patterns. PM detects → planner creates → analyzer incorporates → target role receives correction through the implementation spec. Persist in a separate file, survive convergence compaction.

### Pipeline Routing
The planner tags tasks for alternate pipelines (e.g., `pipeline: test-fix`). The orchestrator reads the tag and routes accordingly. Standard pipeline is the default.

### Developer/Test-Writer Independence
Both work from the analyzer's spec in parallel. Neither sees the other's output. This enforces that tests validate spec behavior (not implementation) and implementation follows the spec (not tests).

### Short-Circuit Judge
If primary verification fails, no spec compliance review. Failed tests are the signal — investigating further wastes a cycle.

## Sentinel Convention

The orchestrator emits exactly one sentinel per run:
- `ORCHESTRATOR_RESULT:continue` — work done, keep looping
- `ORCHESTRATOR_RESULT:complete` — convergence achieved, stop
- `ORCHESTRATOR_RESULT:blocked` — needs human attention, stop

Missing sentinel = hard stop (agent crashed or hit session limit).

## Blocked Detection

Two consecutive `[judge:fail]` entries on the same task → planner marks it `blocked`. All remaining tasks blocked → orchestrator emits `blocked` sentinel.

## Git Strategy

### Two-Repo Structure
- **Parent repo** — metadata (specs, playbooks, plans, agents). Always on `main`. Never has feature branches.
- **Component submodule(s)** — code. Has `main`, `orchestrator-converged`, `orchestrator-in-progress`, and feature/attempt branches.

### Branch Hierarchy (submodule)
```
main                                        ← human-controlled
orchestrator-converged                      ← promotion target
  └─ orchestrator-in-progress               ← accumulates judge-passed tasks
       └─ orchestrator/feature/{task-slug}   ← one per task
            └─ ...--attempt-1, --attempt-2   ← one per pipeline iteration
```

### Responsibility Split
- **Orchestrator agent** owns all git operations (both repos): branch creation, commits, merges
- **Bash loop** owns loop control only: sentinel parsing, inflight tracking, run bookkeeping

### Attempt branches are never deleted
They are the audit trail. Archive as tags when cleaning up.

## Inflight Recovery

- Bash writes current session ID to `.inflight` before launching
- On clean sentinel: bash clears the file
- On crash: session ID stays for next run's orchestrator to inspect via `session-inspect`
- Orchestrator fires `session-inspect` for prior inflight sessions, passes summaries to planner

## Playbook Template

See `playbook.template.md` for the step-by-step pipeline with placeholder paths.

## Example Agents

See `agents/` for working agent definitions adapted from this pattern. These are generalized versions of agents used in a real project — they show how the archetypes are instantiated for a complex deterministic workflow.
