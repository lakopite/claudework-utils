# Playbook: {component-name}

## References

- **Spec:** `specs/{category}/{component}.md`
- **Plan:** `playbooks/{category}/{component}.plan.md`
- **Completed plan:** `playbooks/{category}/{component}.plan.completed.md`
- **Calibrations:** `playbooks/{category}/{component}.plan.calibrations.md`
- **Unit tests:** `{category}/{component}/tests/`
- **Integration tests:** `{category}/{component}/tests/integration/`

## Prerequisites

{List any ad-hoc agents or manual steps that must run before the pipeline. Example: a research agent that produces reference data, a manual configuration step, etc.}

## Pipeline

The orchestrator reads this playbook and follows these steps exactly. All sequencing logic lives here — the orchestrator is a generic executor.

Every step is an Agent tool delegation unless noted otherwise. If a step says "parallel," the orchestrator fires both Agent tool calls simultaneously.

---

### Step 1: Review (parallel)

Fire all three reviewers simultaneously. None depend on each other's output.

#### Step 1a: Staff Engineer Review

- **agent:** staff-engineer-reviewer
- **input:** Assess whether the codebase aligns with the spec's intent. Check coverage, proportionality, and drift. Use pending task scopes to avoid flagging planned work.
- **receives:** spec path, codebase root (`{category}/{component}/`), plan path
- **output:** alignment brief (held in orchestrator context for Step 2)

#### Step 1b: Product Manager Review

- **agent:** product-manager-reviewer
- **input:** Assess whether planned tasks are still relevant to the current spec. Identify stale tasks, spec gaps with no plan coverage, and misaligned task scopes.
- **receives:** plan path, spec path, completed plan path
- **output:** relevance brief (held in orchestrator context for Step 2)

#### Step 1c: Project Manager Review

- **agent:** project-manager-reviewer
- **input:** Assess plan execution health. Look for stagnation patterns, progress plateaus, deferred issues, and cross-task systemic patterns.
- **receives:** plan path, calibrations file path
- **output:** health brief (held in orchestrator context for Step 2)

---

### Step 2: Refine Plan

- **agent:** planner
- **input:** Read the spec, read the current plan (create if it doesn't exist), read the completed plan for foundation context, read the calibrations file, and review all inputs. Converge the plan: identify gaps between spec and current state, update task list, mark completed work, note any agent feedback from previous runs. Create or update calibrations if the health brief surfaces systemic patterns. Write the updated plan and calibrations files.
- **receives:** spec path, plan path, completed plan path, calibrations file path, alignment brief from Step 1a, relevance brief from Step 1b, health brief from Step 1c, user direction (if provided)
- **output:** updated plan file and calibrations file written to disk

---

### Step 3: Check Convergence

The orchestrator reads the plan file after Step 2 and evaluates task statuses.

**If actionable tasks exist** (`pending`, `failed`, or `needs-replan`)**:** proceed to Step 4.

**If all tasks are `done` (none `blocked`):** proceed to Step 8 (Convergence Gate).

**If no actionable tasks remain but some are `blocked`:** skip to sentinel with `ORCHESTRATOR_RESULT:blocked`.

---

### Step 4: Select Task and Branch Setup

The orchestrator reads the plan and selects the first unblocked task in plan order (no unmet dependencies). Task order in the plan = execution priority — the planner controls sequencing.

In directed mode (user-initiated session), the user may override task selection conversationally.

After selecting the task, the orchestrator sets up the git branch for this iteration per its own branching instructions.

---

### Step 4b: Route Pipeline

Read the selected task's `pipeline:` field.

- If `test-fix`: skip to Step 5alt.
- Otherwise (standard or field omitted): proceed to Step 5.

---

### Step 5: Analyze Task (standard pipeline)

- **agent:** analyzer
- **input:** The selected task description from the plan, plus access to the full codebase. Produce a detailed implementation spec for this task using the double diamond approach. If the task has calibration references, read and incorporate them.
- **receives:** selected task from plan, spec path, calibrations file path (if task has calibration references)
- **output:** implementation spec (held in orchestrator context for Steps 6a/6b)
- **feedback:** If the analyzer discovers the task is bigger than expected, has hidden dependencies, or needs to be split, it should say so clearly. The orchestrator will write these findings back to the plan and skip to the sentinel with `continue`.

---

### Step 5alt: Fix Tests (test-fix pipeline)

- **agent:** test-fixer
- **input:** The selected task description from the plan. Run the test suite (unit tests only, exclude integration test directory) to identify failures. Read the spec to determine correct behavior. Classify each failure as stale test assertion or spec violation. Fix all stale assertions and rerun to confirm. If any spec violation is found, stop immediately and report all findings without fixing anything.
- **receives:** selected task from plan, spec path, calibrations file path (if task has calibration references), unit test directory, integration test directory
- **output:** test-fixer report (held in orchestrator context for Step 7)
- **escape valve:** If the test-fixer reports spec violations, the orchestrator writes findings as `[test-fixer]` feedback on the task and skips to the sentinel with `continue`. The next iteration's planner creates a standard pipeline task for the fix.
- **then:** Skip to Step 7 (judge receives test-fixer report instead of analyzer spec).

---

### Step 6: Implement (standard pipeline, parallel)

Fire both agents simultaneously. Neither sees the other's output.

#### Step 6a: Write Tests

- **agent:** test-writer
- **input:** The analyzer's implementation spec from Step 5. Write unit tests that validate this task's implementation. Apply contrarian thinking — attack boundaries, invert assumptions, expose hidden edge cases.
- **receives:** analyzer's implementation spec, spec path
- **output:** test files written to disk

#### Step 6b: Develop

- **agent:** developer
- **input:** The analyzer's implementation spec from Step 5. Implement exactly what the spec describes. Apply simplifier discipline — minimum faithful implementation, nothing extra. Do NOT run tests. Do NOT execute code.
- **receives:** analyzer's implementation spec (NO test files, NO test output)
- **output:** implementation written to disk

---

### Step 7: Judge

- **agent:** judge
- **input:** Run the task-scoped tests first. If tests fail, report failures precisely and stop (short-circuit — no spec compliance review on broken work). If tests pass, review the changes against the spec. Pass only if all tests pass AND changes are correct per spec.
- **receives:**
  - *Standard pipeline:* analyzer's implementation spec, test file paths from Step 6a
  - *Test-fix pipeline:* test-fixer report from Step 5alt, spec path
- **output:** verdict (pass/fail with precise details)

**If pass:** The orchestrator marks the task done, compacts its feedback to just the `[judge:pass]` line (removing intermediate feedback entries — full history preserved in git), and writes the updated plan. Emit sentinel: `ORCHESTRATOR_RESULT:continue`

**If fail:** The orchestrator writes the judge's failure details as feedback on the task in the plan file. Do NOT retry in this run. Emit sentinel: `ORCHESTRATOR_RESULT:continue`

---

### Step 8: Convergence Gate

This step is ONLY reached when Step 3 determines there is nothing to do.

#### Step 8a: QA Lead Audit

- **agent:** qa-lead (audit mode)
- **input:** Perform spec-level test coverage audit. Map every spec requirement to test coverage. Identify coverage gaps, false confidence, and property/invariant gaps. Report gaps that need new tasks or integration tests. Do NOT write tests in this step — audit only.
- **receives:** spec path, codebase root, unit test directory, integration test directory
- **output:** coverage audit report

#### Step 8b: QA Lead Write + Run + Benchmark

Always runs, regardless of whether Step 8a found gaps.

- **agent:** qa-lead (write+run mode)
- **input:** Take the coverage audit report from Step 8a. Write integration tests for identified gaps (if none, skip writing). Run ALL integration tests (existing + new). Capture benchmarks. Report results.
- **receives:** coverage audit report from Step 8a, spec path, codebase root, integration test directory
- **output:** integration test results and benchmark data

#### Step 8c: Evaluate Results

**If all integration tests pass and no unit-test/implementation gaps from Step 8a:** Proceed to Step 8e.

**If integration tests fail or unit-test/implementation gaps exist:** Proceed to Step 8d.

#### Step 8d: Feed Back to Planner

- **agent:** planner
- **input:** Read the spec, read the current plan, and review the QA lead's audit and test results. Create tasks to address the gaps. Write the updated plan.
- **receives:** spec path, plan path, completed plan path, calibrations file path, QA lead reports from Steps 8a/8b
- **output:** updated plan file written to disk
- **then:** Emit sentinel: `ORCHESTRATOR_RESULT:continue`

#### Step 8e: Documentation

- **agent:** documentation
- **input:** Generate or update component documentation from the current spec, codebase, and QA lead outputs. Include coverage summary and benchmark data.
- **receives:** spec path, codebase root, QA lead audit report from Step 8a, benchmark data from Step 8b
- **output:** documentation files written to disk

#### Step 8f: Compact and Merge

The orchestrator performs plan compaction (mechanical — no agent delegation):

1. Read the active plan. For each completed task, write a concise summary (task ID, title, one-liner, key files) to the completed plan file in ascending task ID order.
2. Update the `<!-- last_task_id: N -->` marker at the top of the completed plan file.
3. Strip completed tasks from the active plan, leaving it clean for the next cycle.

Then emit sentinel: `ORCHESTRATOR_RESULT:complete`

---

## Sentinel Convention

The orchestrator emits exactly one sentinel line to stdout before exiting. The sentinel controls the bash loop:

- `ORCHESTRATOR_RESULT:continue` — work done, keep looping
- `ORCHESTRATOR_RESULT:complete` — all plan tasks done AND QA lead audit passes; stop
- `ORCHESTRATOR_RESULT:blocked` — something needs human attention; stop

If the orchestrator crashes or fails to emit a sentinel, the bash loop stops the run.

## Blocked Conditions

The orchestrator emits `blocked` when all remaining tasks in the plan are `done` or `blocked` (i.e., no `pending`, `in-progress`, `failed`, or `needs-replan` tasks remain). The planner is responsible for marking tasks `blocked` — see the planner agent for the two-strikes rule.

Before emitting `blocked`, the orchestrator outputs a summary of all blocked tasks and their feedback history so the user can investigate.
