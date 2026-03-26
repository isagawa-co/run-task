# Meta-Spec Validation — Gate-Contract-Driven, Task-Based Architecture

## Key Insight

The spec's own `gate-contract.md` IS the test specification. The orchestrator writes atomic tasks to `tasks/`, Sub2 runs `/kernel/autonomous-cycle` to execute them, and the orchestrator verifies each gate afterward. No validation skill. No vague prompts.

## Evolution

1. **v1**: Validation skill with 4 phases — Sub2 was both builder AND validator
2. **v2**: Orchestrator-driven, Sub2 builds, orchestrator reads gate-contract.md
3. **v3**: Task-based — orchestrator writes granular tasks to `tasks/`, Sub2 runs autonomous-cycle, orchestrator verifies gates

**Why v3 wins**: Tasks are explicit and atomic (Sub2 can't skip steps). The kernel's cycling mechanism handles execution order. Each task maps to specific gates. Fully programmatic — no special prompting.

## Validation Flow

| Step | Actor | Task |
|------|-------|------|
| 1 | **Orchestrator** | Create test workspace (kernel + spec) |
| 2 | **Sub1** | `/kernel/session-start` → `/kernel/domain-setup` → stop at restart |
| 3 | **Orchestrator** | Verify Sub1 output. Write atomic tasks to `tasks/` (one per action, mapped to gates) |
| 4 | **Sub2** | `/kernel/session-start` → `/kernel/anchor` → `/kernel/autonomous-cycle` |
| 5 | **Orchestrator** | Read spec's `gate-contract.md` → verify each gate against Sub2's output |
| 6 | **Orchestrator** | FAIL → fix spec or tasks, learn, retry (max 3). PASS → ship. |

## Why Two Subagents

- Domain-setup sets `needs_restart: true` — subagents can't restart
- Sub1 ends at restart request
- Sub2 starts fresh, simulating a new session
- Both are kernel-governed (session-start, anchor)

## Task Design Principles

- **One task per gate (1:1 mapping)** — never combine multiple gates into one task. Zero drift.
- **Explicit acceptance criteria** — Sub2 knows exactly what "done" looks like
- **Generated dynamically** — orchestrator reads gate-contract.md, generates one task per gate row. Never hardcoded.
- **Executed by cycling** — `/kernel/autonomous-cycle` picks tasks in order
- **Task count ≈ gate count** — if the spec has 28 gates, write ~28-29 tasks

## Gate Contract Design Principles

- **One check per gate** — never combine verifications
- **Explicit verification method** — `file_exists`, `grep`, `run_code`, `run_test`, `manual`
- **Machine-verifiable preferred** — `grep` and `run_code` over `manual`
- **Domain-specific** — gates test domain patterns, not generic existence
- **20-30 gates per spec** — granular enough to catch issues

## Test Workspace Location (CRITICAL)

**NEVER create test workspaces inside sr_dev_test.** The sr_dev_test hooks resolve CWD into subdirectories that have `.claude/` folders, causing a bootstrapping deadlock — the hook can't find its own files, blocking ALL Bash/Write/Edit operations with no way to recover.

**Always create test workspaces at `D:\my_ai_projects\project_test_repos\test-[name]-validation\`** — sibling to sr_dev_test, never inside it.

## Key Principles

- No validation skill — gate contract IS the test spec
- No vague prompts — atomic tasks in `tasks/` folder
- Sub2 runs autonomous-cycle — kernel handles execution
- No nested agents — orchestrator spawns Sub1 and Sub2 directly
- Builder (Sub2) never validates itself — orchestrator is the judge
- Dynamic — orchestrator adapts tasks and gate checks to any domain
- **Test workspaces OUTSIDE sr_dev_test** — never nested inside the orchestrating repo
