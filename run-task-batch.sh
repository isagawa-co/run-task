#!/bin/bash
#
# run-task-batch.sh — Batch task execution for Isagawa Kernel
#
# Single claude -p session handles ALL tasks via kernel cycling.
# Agent manages task-to-task flow internally (skip after 3 fails).
# Script's job: start, timeout guard, resume on crash, report.
#
# Usage:
#   ./run-task-batch.sh [repo_path] [task_folder] [timeout_seconds]
#
# Arguments:
#   repo_path       Path to kernel-enabled repo (default: current directory)
#   task_folder     Subfolder under tasks/ (default: none, uses tasks/)
#                   Example: "kernel-test" → tasks/kernel-test/
#   timeout_seconds Max time for the batch run (default: 600)

REPO="${1:-.}"
TASK_SUBFOLDER="${2:-}"
TIMEOUT_SECONDS="${3:-600}"

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
LOGFILE="${LOG_DIR}/batch_run.log"

# Resolve task folder path
if [ -n "$TASK_SUBFOLDER" ]; then
  TASK_DIR="tasks/${TASK_SUBFOLDER}/"
else
  TASK_DIR="tasks/"
fi

# Batch prompt — agent cycles through ALL tasks in one session
PROMPT="You have full permissions. Do not ask for permission — just act.

Read CLAUDE.md and follow the kernel workflow:
1. Read and follow .claude/commands/kernel/session-start.md
2. Read and follow .claude/commands/kernel/anchor.md
3. Cycle through ALL incomplete tasks in ${TASK_DIR} (check completed_tasks in workflow state)
4. For each task: implement, verify acceptance criteria, invoke /kernel/complete
5. If a task fails 3 times, skip it and move to the next
6. Continue until all tasks are completed or skipped

After all tasks are done, output the exact text ALL_TASKS_COMPLETE on its own line."

RESUME_PROMPT="The previous run did not complete. You still have full context from that attempt.

Continue where you left off:
1. Check what was already done — don't repeat completed tasks
2. Pick up from the current or next incomplete task
3. Continue cycling through remaining tasks
4. If a task fails 3 times, skip it and move to the next

After all tasks are done, output the exact text ALL_TASKS_COMPLETE on its own line."

echo "============================================"
echo "  Isagawa Kernel - Batch Task Runner"
echo "============================================"
echo "Repo: $REPO"
echo "Task folder: $TASK_DIR"
echo "Timeout: ${TIMEOUT_SECONDS}s"
echo ""

# --- Helper: print current state ---
print_state() {
  python -c "
import json, pathlib
sf = pathlib.Path('$STATE_FILE')
if not sf.exists():
    print('  (no state file)')
else:
    s = json.loads(sf.read_text())
    d = s.get('domain','')
    if d:
        wf = sf.parent / (d + '_workflow.json')
        if wf.exists():
            w = json.loads(wf.read_text())
            print('  completed:', len(w.get('completed_tasks', [])))
            print('  skipped:', len(w.get('skipped_tasks', [])))
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
    print('')
" 2>/dev/null
}

# --- Helper: check for completion signal ---
check_completion() {
  local text="$1"
  if echo "$text" | grep -q "ALL_TASKS_COMPLETE"; then
    echo "all_done"
  elif echo "$text" | grep -qi "no incomplete tasks"; then
    echo "all_done"
  else
    echo "no_signal"
  fi
}

# --- Helper: pre-initialize session state ---
# Avoids deadlock where agent can't write session_started=true
# because Claude Code's sensitive file guard blocks .claude/state/ writes
pre_init_state() {
  python -c "
import json, pathlib
f = pathlib.Path('$STATE_FILE')
s = json.loads(f.read_text()) if f.exists() else {}
s['session_started'] = True
f.parent.mkdir(parents=True, exist_ok=True)
f.write_text(json.dumps(s, indent=2))
" 2>/dev/null
}

# Show state before
echo "[STATE before]"
print_state
echo ""

# Pre-initialize to avoid permission deadlock
pre_init_state

# Record start time
START_TIME=$(date +%s)

# --- Run batch ---
echo "[RUNNING] claude -p (batch, timeout ${TIMEOUT_SECONDS}s) ..."
cd "$REPO"
RAW_OUTPUT=$(timeout "$TIMEOUT_SECONDS" claude -p --dangerously-skip-permissions --output-format json "$PROMPT" 2>&1)
EXIT_CODE=$?

# Save log
echo "$RAW_OUTPUT" > "$LOGFILE"

# Extract fields
SESSION_ID=$(extract_session_id "$RAW_OUTPUT")
RESULT=$(extract_result "$RAW_OUTPUT")
STATUS=$(check_completion "$RESULT")

echo "$RESULT"

# --- Handle timeout ---
if [ $EXIT_CODE -eq 124 ]; then
  echo ""
  echo "-> TIMEOUT after ${TIMEOUT_SECONDS}s"
  STATUS="no_signal"
fi

# --- Handle completion ---
if [ "$STATUS" = "all_done" ]; then
  END_TIME=$(date +%s)
  ELAPSED=$((END_TIME - START_TIME))
  echo ""
  echo "[STATE after]"
  print_state
  echo ""
  echo "============================================"
  echo "  BATCH COMPLETE"
  echo "  Time: ${ELAPSED}s"
  echo "  Log: $LOGFILE"
  echo "============================================"
  exit 0
fi

# --- Resume once on crash/timeout/no-signal ---
echo ""
echo "-> No completion signal. Attempting resume..."

if [ -z "$SESSION_ID" ]; then
  echo "-> No session ID captured, cannot resume."
  echo ""
  echo "[STATE after]"
  print_state
  echo ""
  echo "============================================"
  echo "  BATCH FAILED (no session ID for resume)"
  echo "  Log: $LOGFILE"
  echo "============================================"
  exit 1
fi

RESUME_LOGFILE="${LOG_DIR}/batch_run_resume.log"
echo "[RUNNING] claude -p --resume $SESSION_ID ..."
RAW_OUTPUT=$(timeout "$TIMEOUT_SECONDS" claude -p --dangerously-skip-permissions --output-format json --resume "$SESSION_ID" "$RESUME_PROMPT" 2>&1)
EXIT_CODE=$?

echo "$RAW_OUTPUT" > "$RESUME_LOGFILE"

RESULT=$(extract_result "$RAW_OUTPUT")
STATUS=$(check_completion "$RESULT")

echo "$RESULT"

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

if [ "$STATUS" = "all_done" ]; then
  echo ""
  echo "[STATE after]"
  print_state
  echo ""
  echo "============================================"
  echo "  BATCH COMPLETE (after resume)"
  echo "  Time: ${ELAPSED}s"
  echo "  Log: $LOGFILE, $RESUME_LOGFILE"
  echo "============================================"
  exit 0
fi

echo ""
echo "[STATE after]"
print_state
echo ""
echo "============================================"
echo "  BATCH FAILED"
echo "  Time: ${ELAPSED}s"
echo "  Log: $LOGFILE, $RESUME_LOGFILE"
echo "============================================"
exit 1
