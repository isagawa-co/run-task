# Headless Task Runners for Isagawa Kernel

Two scripts for headless task execution. Both use `claude -p` with kernel enforcement.

| Script | Mode | Best for |
|--------|------|----------|
| `run-task.sh` | One-shot | Webhooks, unattended, per-task control |
| `run-task-batch.sh` | Batch | Interactive, supervised, faster |

## One-Shot Mode (`run-task.sh`)

One `claude -p` per task. Script controls task-to-task flow. Resume on failure, skip after retries.

```bash
./run-task.sh [repo_path] [max_iterations] [task_folder]
```

- `repo_path` — Path to a kernel-enabled repo (default: current directory)
- `max_iterations` — Max tasks to attempt (default: 10)
- `task_folder` — Subfolder under tasks/ (default: none, uses tasks/)

## How it works

```
Fresh run (claude -p --output-format json)
  ├── ONE_SHOT_COMPLETE → next iteration
  ├── ALL_TASKS_COMPLETE → exit 0
  └── no signal → resume loop
                    ├── claude -p --resume <session-id>
                    ├── retry up to MAX_RESUME_RETRIES times
                    └── if still fails → count as failure, continue
```

## Configuration

Edit variables at the top of `run-task.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_CONSECUTIVE_FAILS` | 2 | Abort after N consecutive failures |
| `MAX_RESUME_RETRIES` | 2 | Resume attempts per failed iteration |

## Requirements

- `claude` CLI installed and authenticated
- Python 3 (for JSON state manipulation)
- Target repo must have `CLAUDE.md` and kernel state files

## Logs (One-Shot)

All output saved to `.claude/state/iteration_N.log` (and `iteration_N_resume_M.log` for retries).

---

## Batch Mode (`run-task-batch.sh`)

Single `claude -p` session handles ALL tasks via kernel cycling. Agent manages task-to-task flow internally. Faster, cheaper, agent has cross-task context.

```bash
./run-task-batch.sh [repo_path] [task_folder] [timeout_seconds]
```

- `repo_path` — Path to a kernel-enabled repo (default: current directory)
- `task_folder` — Subfolder under tasks/ (default: none, uses tasks/)
- `timeout_seconds` — Max time for the batch run (default: 600)

### How it works

```
Batch run (claude -p, single session)
  ├── Agent cycles through ALL tasks
  ├── ALL_TASKS_COMPLETE → exit 0
  ├── Timeout → resume once
  └── No signal → resume once
                   ├── ALL_TASKS_COMPLETE → exit 0
                   └── Still no signal → exit 1
```

### Logs (Batch)

Output saved to `.claude/state/batch_run.log` (and `batch_run_resume.log` for retry).

---

## Requirements

- `claude` CLI installed and authenticated
- Python 3 (for JSON state manipulation)
- Target repo must have `CLAUDE.md` and kernel state files
