# Isagawa Run-Task

### Headless Task Execution for AI Agents

> Write the tasks. The scripts run them. No human in the loop.

Run-Task spawns isolated Claude Code agents (`claude -p`) to execute task files one at a time. Each agent reads the task, does the work, reports completion, and exits. The script handles retries, resume on crash, and progress tracking.

Built for the [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) but works with any `claude -p` compatible setup.

---

## Two Modes

| Script | Mode | How it works | Best for |
|--------|------|-------------|----------|
| `run-task.sh` | **One-shot** | One `claude -p` per task. Fresh context each time. | Production, CI/CD, unattended |
| `run-task-batch.sh` | **Batch** | Single `claude -p` handles all tasks. Agent keeps context. | Development, faster iteration |

---

## Quick Start

### 1. Clone

```bash
git clone https://github.com/isagawa-co/run-task.git
```

### 2. Copy scripts into your kernel-enabled repo

```bash
cp run-task/run-task.sh /path/to/your-repo/
cp run-task/run-task-batch.sh /path/to/your-repo/
chmod +x /path/to/your-repo/run-task.sh /path/to/your-repo/run-task-batch.sh
```

### 3. Write task files

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

### 4. Run

```bash
# One-shot: one agent per task
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
set_one_shot_flag() → pre-init state (session_started + one_shot)
  │
  ▼
claude -p (fresh)
  ├── ONE_SHOT_COMPLETE → next iteration
  ├── ALL_TASKS_COMPLETE → exit 0
  └── no signal → resume loop
                    ├── claude -p --resume <session-id>
                    ├── retry up to 2 times
                    └── still fails → skip task, continue
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_CONSECUTIVE_FAILS` | `2` | Abort after N consecutive failures |
| `MAX_RESUME_RETRIES` | `2` | Resume attempts per failed iteration |

### Logs

All output saved to `.claude/state/iteration_N.log` (and `iteration_N_resume_M.log` for retries).

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

### Flow

```
pre_init_state() → set session_started = true
  │
  ▼
claude -p (single session, all tasks)
  ├── Agent cycles through tasks (session-start → anchor → work → complete → next)
  ├── ALL_TASKS_COMPLETE → exit 0
  ├── Timeout → resume once
  └── No signal → resume once
                   ├── ALL_TASKS_COMPLETE → exit 0
                   └── Still no signal → exit 1
```

### Logs

Output saved to `.claude/state/batch_run.log` (and `batch_run_resume.log` for retry).

---

## How It Works With the Kernel

The scripts work with the [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) enforcement loop:

```
run-task.sh sets one_shot + session_started in state
  │
  ▼
claude -p spawns with prompt:
  "Read CLAUDE.md → session-start → anchor → pick task → implement → complete"
  │
  ▼
Agent inside kernel enforcement:
  ├── Hooks gate every action (anchor every 10 actions)
  ├── Protocol read on every anchor
  ├── Learn after every failure
  └── Complete gate verifies deliverables
  │
  ▼
Agent outputs ONE_SHOT_COMPLETE or ALL_TASKS_COMPLETE
  │
  ▼
Script detects signal → next iteration or exit
```

### State Pre-initialization

Both scripts pre-set `session_started: true` in the state file before spawning the agent. This avoids a permission deadlock where Claude Code's sensitive file guard blocks writes to `.claude/state/`, preventing the agent from bootstrapping.

The agent still runs `/kernel/session-start` via the prompt — it just doesn't need to write the initial `true` value.

---

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed and authenticated
- Python 3 (for JSON state manipulation)
- Target repo must have:
  - `CLAUDE.md` — kernel bootstrap instructions
  - `.claude/commands/kernel/` — kernel commands (session-start, anchor, complete)
  - `.claude/state/` — state directory (created automatically)
  - `tasks/[folder]/` — task files to execute

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
| **Run-Task** (this repo) | Headless task execution via spawned agents |
| [QA Platform](https://github.com/isagawa-qa/platform-selenium) | AI-managed Selenium test automation |
| Domain Specs | Vertical-specific agent configurations |

---

## License

[MIT](LICENSE) — Copyright (c) 2025 Isagawa

---

<sub>Built with the [Isagawa Kernel](https://github.com/isagawa-co/isagawa-kernel) — self-building, self-improving, safety-first.</sub>
