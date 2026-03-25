#!/bin/bash
#
# run-task.sh — One-shot task execution with session resume for Isagawa Kernel
#
# Each iteration: set one_shot flag → claude -p (JSON) → detect completion
# On failure: retry with --resume to preserve full conversation context
# State files on disk provide continuity between successful iterations.
#
# Usage:
#   ./run-task.sh [repo_path] [max_iterations] [task_folder]
#
# Arguments:
#   repo_path       Path to kernel-enabled repo (default: current directory)
#   max_iterations  Max tasks to attempt (default: 10)
#   task_folder     Subfolder under tasks/ (default: none, uses tasks/)
#                   Example: "kernel-test" → tasks/kernel-test/

REPO="${1:-.}"
MAX_ITERATIONS="${2:-10}"
TASK_SUBFOLDER="${3:-}"
COMPLETED=0
FAILED=0
CONSECUTIVE_FAILS=0
MAX_CONSECUTIVE_FAILS=2
MAX_RESUME_RETRIES=2

# Resolve to absolute path
if [ ! -d "$REPO" ]; then
  echo "ERROR: Directory not found: $REPO"
  exit 1
fi
REPO=$(cd "$REPO" && pwd)

# Verify this is a kernel repo
if [ ! -f "$REPO/CLAUDE.md" ]; then
  echo "ERROR: Not a kernel repo (no CLAUDE.md): $REPO"
  exit 1
fi

# Convert paths for Windows compatibility (Git Bash /c/ → C:/)
if command -v cygpath &>/dev/null; then
  STATE_FILE=$(cygpath -m "$REPO/.claude/state/session_state.json")
  LOG_DIR=$(cygpath -m "$REPO/.claude/state")
else
  STATE_FILE="$REPO/.claude/state/session_state.json"
  LOG_DIR="$REPO/.claude/state"
fi

mkdir -p "$LOG_DIR"

# Resolve task folder path
if [ -n "$TASK_SUBFOLDER" ]; then
  TASK_DIR="tasks/${TASK_SUBFOLDER}/"
else
  TASK_DIR="tasks/"
fi

# The prompt must be explicit and self-contained
PROMPT="You have full permissions. Do not ask for permission — just act.

Read CLAUDE.md and follow the kernel workflow:
1. Read and follow .claude/commands/kernel/session-start.md
2. Read and follow .claude/commands/kernel/anchor.md
3. Pick the next incomplete task from ${TASK_DIR} (check completed_tasks in workflow state)
4. Implement the task and verify its acceptance criteria
5. Read and follow .claude/commands/kernel/complete.md

After completing the task, output the exact text ONE_SHOT_COMPLETE on its own line.
If there are no incomplete tasks remaining, output ALL_TASKS_COMPLETE on its own line."

RESUME_PROMPT="The previous run did not complete. You still have full context from that attempt.

Continue where you left off:
1. Check what was already done — don't repeat work
2. If the task is partially complete, finish it
3. If it failed, diagnose and fix
4. Read and follow .claude/commands/kernel/complete.md when done

After completing the task, output the exact text ONE_SHOT_COMPLETE on its own line.
If there are no incomplete tasks remaining, output ALL_TASKS_COMPLETE on its own line."

echo "============================================"
echo "  Isagawa Kernel - One-Shot Task Runner"
echo "  (with session resume)"
echo "============================================"
echo "Repo: $REPO"
echo "Task folder: $TASK_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# --- Helper: merge one_shot flag into session state ---
set_one_shot_flag() {
  python -c "
import json, pathlib
f = pathlib.Path('$STATE_FILE')
s = json.loads(f.read_text()) if f.exists() else {}
s['one_shot'] = True
s['session_started'] = True
f.parent.mkdir(parents=True, exist_ok=True)
f.write_text(json.dumps(s, indent=2))
" 2>/dev/null

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set one_shot flag in $STATE_FILE"
    exit 1
  fi
}

# --- Helper: print current state ---
print_state() {
  python -c "
import json, pathlib
sf = pathlib.Path('$STATE_FILE')
if not sf.exists():
    print('  (no state file)')
else:
    s = json.loads(sf.read_text())
    print('  session_started:', s.get('session_started'))
    print('  one_shot:', s.get('one_shot'))
    d = s.get('domain','')
    if d:
        wf = sf.parent / (d + '_workflow.json')
        if wf.exists():
            w = json.loads(wf.read_text())
            print('  anchored:', w.get('anchored'))
            print('  completed:', len(w.get('completed_tasks', [])))
            print('  current:', w.get('current_task'))
" 2>/dev/null || echo "  (state read failed)"
}

# --- Helper: extract session_id from JSON output ---
extract_session_id() {
  local json_output="$1"
  echo "$json_output" | python -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get('session_id', ''))
except:
    print('')
" 2>/dev/null
}

# --- Helper: extract result text from JSON output ---
extract_result() {
  local json_output="$1"
  echo "$json_output" | python -c "
import sys, json
try:
    data = json.loads(sys.stdin.read())
    print(data.get('result', ''))
except:
    # Not JSON — return raw
    print(sys.stdin.read() if False else '')
" 2>/dev/null
}

# --- Helper: skip current task in workflow state ---
skip_current_task() {
  python -c "
import json, pathlib
sf = pathlib.Path('$STATE_FILE')
if not sf.exists():
    exit(0)
s = json.loads(sf.read_text())
domain = s.get('domain', '')
if not domain:
    exit(0)
wf = sf.parent / (domain + '_workflow.json')
if not wf.exists():
    exit(0)
w = json.loads(wf.read_text())
task = w.get('current_task')
if task and task not in w.get('skipped_tasks', []):
    if 'skipped_tasks' not in w:
        w['skipped_tasks'] = []
    w['skipped_tasks'].append(task)
    w['current_task'] = None
    w['attempts_on_current'] = 0
    wf.write_text(json.dumps(w, indent=2))
    print('SKIPPED: ' + task)
else:
    print('(no task to skip)')
" 2>/dev/null
}

# --- Helper: check for completion signals in text ---
check_completion() {
  local text="$1"
  if echo "$text" | grep -q "ALL_TASKS_COMPLETE"; then
    echo "all_done"
  elif echo "$text" | grep -q "ONE_SHOT_COMPLETE"; then
    echo "task_done"
  elif echo "$text" | grep -qi "no incomplete tasks"; then
    echo "all_done"
  else
    echo "no_signal"
  fi
}

# --- Helper: run claude and return result ---
# Sets: LAST_SESSION_ID, LAST_RESULT, LAST_STATUS
run_claude() {
  local mode="$1"       # "fresh" or "resume"
  local session_id="$2" # only used for resume
  local logfile="$3"

  local cmd_args=("-p" "--dangerously-skip-permissions" "--output-format" "json")

  if [ "$mode" = "resume" ] && [ -n "$session_id" ]; then
    cmd_args+=("--resume" "$session_id")
    local prompt="$RESUME_PROMPT"
    echo "[RUNNING] claude -p --resume $session_id ..."
  else
    local prompt="$PROMPT"
    echo "[RUNNING] claude -p (fresh) ..."
  fi

  cd "$REPO"
  local raw_output
  raw_output=$(claude "${cmd_args[@]}" "$prompt" 2>&1)

  # Save raw output to log
  echo "$raw_output" > "$logfile"

  # Extract fields
  LAST_SESSION_ID=$(extract_session_id "$raw_output")
  LAST_RESULT=$(extract_result "$raw_output")
  LAST_STATUS=$(check_completion "$LAST_RESULT")

  # Also print result to screen
  echo "$LAST_RESULT"
}

# --- Main loop ---
for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "=== Iteration $i/$MAX_ITERATIONS ==="

  # Show state before
  echo "[STATE before]"
  print_state
  echo ""

  # Set one-shot flag
  set_one_shot_flag

  # Fresh run
  LOGFILE="${LOG_DIR}/iteration_${i}.log"
  run_claude "fresh" "" "$LOGFILE"

  # --- Handle result ---
  if [ "$LAST_STATUS" = "all_done" ]; then
    COMPLETED=$((COMPLETED + 1))
    echo ""
    echo "============================================"
    echo "  ALL TASKS COMPLETE"
    echo "  Tasks completed this run: $COMPLETED"
    echo "  Total iterations: $i"
    echo "============================================"
    exit 0

  elif [ "$LAST_STATUS" = "task_done" ]; then
    COMPLETED=$((COMPLETED + 1))
    CONSECUTIVE_FAILS=0
    echo ""
    echo "[STATE after]"
    print_state
    echo "-> Task done. ($COMPLETED completed this run)"

  else
    # No completion signal — attempt resume retries
    echo "-> No completion signal. Attempting resume..."

    RESUME_SESSION_ID="$LAST_SESSION_ID"
    RESUME_SUCCESS=false

    for r in $(seq 1 "$MAX_RESUME_RETRIES"); do
      if [ -z "$RESUME_SESSION_ID" ]; then
        echo "-> No session ID captured, cannot resume."
        break
      fi

      echo ""
      echo "--- Resume attempt $r/$MAX_RESUME_RETRIES (session: $RESUME_SESSION_ID) ---"

      RESUME_LOGFILE="${LOG_DIR}/iteration_${i}_resume_${r}.log"
      run_claude "resume" "$RESUME_SESSION_ID" "$RESUME_LOGFILE"

      if [ "$LAST_STATUS" = "all_done" ]; then
        COMPLETED=$((COMPLETED + 1))
        echo ""
        echo "============================================"
        echo "  ALL TASKS COMPLETE (after resume)"
        echo "  Tasks completed this run: $COMPLETED"
        echo "  Total iterations: $i"
        echo "============================================"
        exit 0

      elif [ "$LAST_STATUS" = "task_done" ]; then
        COMPLETED=$((COMPLETED + 1))
        CONSECUTIVE_FAILS=0
        RESUME_SUCCESS=true
        echo ""
        echo "[STATE after]"
        print_state
        echo "-> Task done after resume. ($COMPLETED completed this run)"
        break

      else
        # Update session ID in case resume created a new one
        RESUME_SESSION_ID="$LAST_SESSION_ID"
        echo "-> Resume attempt $r failed."
      fi
    done

    if [ "$RESUME_SUCCESS" = false ]; then
      FAILED=$((FAILED + 1))
      CONSECUTIVE_FAILS=$((CONSECUTIVE_FAILS + 1))
      echo "-> Task failed after $MAX_RESUME_RETRIES resume attempts. Skipping."
      skip_current_task

      if [ $CONSECUTIVE_FAILS -ge $MAX_CONSECUTIVE_FAILS ]; then
        echo ""
        echo "============================================"
        echo "  ABORTING: $MAX_CONSECUTIVE_FAILS consecutive failures"
        echo "  Completed: $COMPLETED"
        echo "  Failed: $FAILED"
        echo "  Check logs: ${LOG_DIR}/iteration_*.log"
        echo "============================================"
        exit 1
      fi
    fi
  fi

  sleep 2
done

echo ""
echo "============================================"
echo "  MAX ITERATIONS REACHED"
echo "  Completed: $COMPLETED"
echo "  Failed: $FAILED"
echo "  Iterations: $MAX_ITERATIONS"
echo "============================================"
exit 1
