# Task Atomicity

## 2026-03-23 Agent bundles actions despite user correction (3x)

- **Issue:** User asked for maximum granularity 3 times. Agent kept bundling 3-10 actions into single task files. E2E test (043) had 6+ actions. Validation tasks (037-040) bundled setup+run+verify.
- **Root Cause:** step-04-atomize.md had "merge if <3 subtasks" rule. step-03-decompose.md had "too small → merge" and "3-10 tasks, not 40" cap. These rules directly contradicted the atomicity definition ("one action per task") and gave the agent permission to bundle.
- **Fix:** Removed all merge rules. Added explicit "NEVER bundle" to RULE ZERO in lessons.md. Added granularity rules to step-04-atomize.md and step-03-decompose.md. Removed task count cap.
- **Anti-Pattern Added:** Bundling multiple file writes, copies, or commands into one task. Writing "Step 1... Step 2... Step 3..." in Requirements (each step should be its own task).
- **Quality Gate Added:** When decomposing, count distinct actions → that count = number of task files. If it feels like "too many," it's the right number.

## The Pattern

Agent tendency: optimize for fewer tasks (feels more efficient, cleaner).
User need: maximum granularity (one-shot execution, independent verification, clear failure isolation).

The agent's instinct to consolidate is WRONG in this context. The kernel runs tasks one at a time via run-task.sh. Each task is one iteration. Bundled tasks can't be partially completed, retried individually, or verified in isolation.

## Concrete Rule

When writing task files, ask: "Does this task touch more than one file or run more than one command?"
- If YES → split into N tasks (one per file/command)
- If NO → it's correctly atomic

Examples:
- "Copy 4 hook files" → 4 tasks (one per file)
- "Create workspace + install deps" → 2 tasks
- "Run test + verify results" → 2 tasks
- "Write ssh_interface.py" → 1 task (correct)
