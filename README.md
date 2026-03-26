# Isagawa Run-Task

### Headless Task Execution for AI Agents

> Write the tasks. The scripts run them. No human in the loop.

Run-Task spawns isolated Claude Code agents (`claude -p`) to execute task files one at a time. Each agent reads the task, does the work, reports completion, and exits. The script handles retries, resume on crash, and progress tracking.

Ships with the full [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) — self-building, self-improving AI execution management. On first run, the kernel configures itself to your repo.

---

## Two Modes

| Script | Mode | How it works | Best for |
|--------|------|-------------|----------|
| `run-task.sh` | **One-shot** | One `claude -p` per task. Fresh context each time. | Production, CI/CD, unattended |
| `run-task-batch.sh` | **Batch** | Single `claude -p` handles all tasks. Agent keeps context. | Development, faster iteration |

---

## Quick Start

### 1. Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI installed and authenticated
- Python 3.10+
- Bash (Git Bash on Windows)

### 2. Clone

```bash
git clone https://github.com/isagawa-co/run-task.git
cd run-task
```

### 3. First run — kernel self-configures

```bash
claude
```

The agent reads `CLAUDE.md`, detects no domain exists, and runs `/kernel/domain-setup` automatically. It discovers the repo structure, builds a protocol, wires hooks, and asks you to restart.

```bash
claude
> continue
```

Now the kernel is active — every action is gated, every 10 actions triggers a protocol re-read, and failures become permanent lessons.

### 4. Write task files

Create `tasks/my-project/000-index.md` and numbered task files:

```
tasks/my-project/
├── 000-index.md          ← Task table with wikilinks
├── 001-first-task.md     ← One atomic action
├── 002-second-task.md
└── 003-third-task.md
```

Each task file follows a simple template:

```markdown
# Task Name

## Type
BUILD | TEST

## Executor
Spawned agent via run-task.sh

## Action
[What to do — one atomic action]

## Acceptance Criteria
- [ ] [Mechanical check 1]
- [ ] [Mechanical check 2]
```

### 5. Run

```bash
# One-shot: one agent per task (use task_count + 2 for retry buffer)
./run-task.sh . 5 my-project

# Batch: single agent handles all tasks
./run-task-batch.sh . my-project 600
```

---

## One-Shot Mode (`run-task.sh`)

One `claude -p` per task. The script controls task-to-task flow. Resume on failure, skip after retries.

```bash
./run-task.sh [repo_path] [max_iterations] [task_folder]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `repo_path` | `.` | Path to a kernel-enabled repo |
| `max_iterations` | `10` | Max tasks to attempt (use task_count + 2 for retry buffer) |
| `task_folder` | none | Subfolder under `tasks/` |

### Flow

```
pre_init_state() → set session_started + one_shot
  │
  ▼
claude -p (fresh, 5 min timeout)
  ├── ONE_SHOT_COMPLETE → next iteration
  ├── ALL_TASKS_COMPLETE → exit 0
  └── no signal → resume loop (up to 2 retries)
                    └── still fails → skip task, continue
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_CONSECUTIVE_FAILS` | `2` | Abort after N consecutive failures |
| `MAX_RESUME_RETRIES` | `2` | Resume attempts per failed iteration |
| `TASK_TIMEOUT` | `300` | Seconds per `claude -p` invocation |
| `SLEEP_BETWEEN` | `2` | Seconds between iterations |

---

## Batch Mode (`run-task-batch.sh`)

Single `claude -p` session handles ALL tasks via kernel cycling. Agent manages task-to-task flow internally. Faster and cheaper — the agent has cross-task context.

```bash
./run-task-batch.sh [repo_path] [task_folder] [timeout_seconds]
```

| Argument | Default | Description |
|----------|---------|-------------|
| `repo_path` | `.` | Path to a kernel-enabled repo |
| `task_folder` | none | Subfolder under `tasks/` |
| `timeout_seconds` | `600` | Max time for the batch run |

---

## What's Included

### Shell Scripts

| File | Purpose |
|------|---------|
| `run-task.sh` | One-shot task execution (one agent per task) |
| `run-task-batch.sh` | Batch task execution (single agent, all tasks) |
| `lib/common.sh` | Shared helpers (state management, signal detection, Python bridge) |

### Isagawa Kernel

The full kernel ships with this repo. On first run, it self-configures via `/kernel/domain-setup`.

| Component | Location | Purpose |
|-----------|----------|---------|
| Bootstrap | `CLAUDE.md` | Kernel loop, first action rule, commands reference |
| Commands | `.claude/commands/kernel/` | 12 commands (session-start, anchor, complete, learn, fix, etc.) |
| Hooks | `.claude/hooks/` | 4 hooks (gate enforcer, auto-approve, actions log, test failure) |
| Skills | `.claude/skills/` | 5 skills (domain-setup, cycling, task-builder, audit, prod-test) |
| Lessons | `.claude/lessons/` | Accumulated lessons from kernel development |

**The kernel is not pre-configured.** There is no protocol, no `settings.local.json`, no state files. Domain-setup creates all of these on first run by discovering the repo structure and building enforcement specific to what it finds.

---

## How the Kernel Works

```
First run:
  claude → reads CLAUDE.md → /kernel/session-start → no domain found
    → /kernel/domain-setup → discovers repo → builds protocol + hooks
    → restart required (hooks load at startup)

Every subsequent run:
  session-start → anchor (re-read protocol) → WORK → complete
                     ↑                              ↓
                     └── every 10 actions ←─────────┘
                               ↓
                     failure? → fix → learn (permanent improvement)
```

### Key Commands

| Command | What it does |
|---------|-------------|
| `/kernel/session-start` | Check state, resume from prior work |
| `/kernel/anchor` | Re-read protocol, review recent work, reset counter |
| `/kernel/complete` | Verify deliverables, mark task done |
| `/kernel/learn` | Record lesson after failure (clears block) |
| `/kernel/domain-setup` | Discover repo, build protocol + hooks (first run only) |
| `/kernel/task-builder` | Decompose a goal into atomic tasks |
| `/kernel/prod-test` | Full L1/L2/L3 production test against a deliverable |
| `/kernel/audit-workflow` | Scan kernel infrastructure for gaps |

### Enforcement

The kernel enforces via hooks (hard gates) and protocol (soft rules):

- **Gate enforcer** blocks all Write/Edit/Bash if session not started, not anchored, or lesson not recorded
- **Actions counter** auto-increments on every action, blocks at 10 until anchor
- **Anchor token** prevents quick-anchoring — agent must read the full protocol
- **Test failure detector** sets `needs_learn` flag when a test fails
- **Auto-approve** handles Claude Code's sensitive file guard for `.claude/` writes

---

## Project Structure

```
run-task/
├── CLAUDE.md                          ← Kernel bootstrap
├── run-task.sh                        ← One-shot task runner
├── run-task-batch.sh                  ← Batch task runner
├── lib/
│   └── common.sh                      ← Shared helpers
├── .claude/
│   ├── commands/kernel/               ← 12 kernel commands
│   │   ├── session-start.md
│   │   ├── anchor.md
│   │   ├── complete.md
│   │   ├── domain-setup.md
│   │   ├── learn.md
│   │   ├── fix.md
│   │   ├── task-builder.md
│   │   ├── prod-test.md
│   │   ├── audit-workflow.md
│   │   ├── autonomous-cycle.md
│   │   ├── backlog.md
│   │   └── reset.md
│   ├── hooks/                         ← 4 universal hooks
│   │   ├── universal-gate-enforcer.py
│   │   ├── auto-approve-claude-writes.py
│   │   ├── actions-log-appender.py
│   │   └── test-failure-detector.py
│   ├── skills/                        ← 5 skills
│   │   ├── kernel-domain-setup/       ← Self-building setup (11 steps)
│   │   ├── autonomous-cycling/        ← Task loop behavior
│   │   ├── task-builder/              ← Goal → tasks → execute
│   │   ├── audit-workflow/            ← Gap scanner + auto-fix
│   │   └── prod-test/                 ← L1/L2/L3 production testing
│   └── lessons/                       ← Accumulated lessons
├── README.md
└── TESTING.md
```

---

## Use Cases

| Scenario | Script | Example |
|----------|--------|---------|
| **Production testing** | `run-task.sh` | `/kernel/prod-test` runs inner test batch |
| **CI/CD pipeline** | `run-task.sh` | GitHub Action triggers task execution |
| **Task builder execution** | `run-task-batch.sh` | `/kernel/task-builder` cycles through generated tasks |
| **Autonomous cycling** | `run-task-batch.sh` | Agent works through a backlog unattended |

---

## The Bigger Picture

Run-Task is one component of the Isagawa ecosystem:

| Component | What it does |
|-----------|-------------|
| [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) | Self-building, self-improving enforcement for AI agents |
| **Run-Task** (this repo) | Headless task execution + full kernel |
| [QA Platform (Selenium)](https://github.com/isagawa-qa/platform-selenium) | AI-managed Selenium test automation |
| [SSH Platform](https://github.com/isagawa-qa/platform-ssh) | AI-managed infrastructure validation via SSH |
| Domain Specs | Vertical-specific agent configurations |

---

## License

[MIT](LICENSE) — Copyright (c) 2025 Isagawa

---

<sub>Built with the [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) — self-building, self-improving, safety-first.</sub>
