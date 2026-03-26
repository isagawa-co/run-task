#!/bin/bash
set -uo pipefail
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

# --- Configuration ---
REPO="${1:-.}"
TASK_SUBFOLDER="${2:-}"
TIMEOUT_SECONDS="${3:-600}"

# --- Resolve script directory and source shared lib ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# --- Validate ---
validate_deps
REPO=$(cd "$REPO" && pwd)
validate_repo "$REPO"
resolve_paths "$REPO"

LOGFILE="${LOG_DIR}/batch_run.log"

# --- Resolve task folder ---
if [ -n "$TASK_SUBFOLDER" ]; then
  TASK_DIR="tasks/${TASK_SUBFOLDER}/"
else
  TASK_DIR="tasks/"
fi

# --- Prompts ---
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

# --- Trap for clean exit on signals ---
cleanup() {
  local end_time
  end_time=$(date +%s)
  local elapsed=$((end_time - START_TIME))
  echo ""
  echo "============================================"
  echo "  INTERRUPTED"
  echo "  Time: ${elapsed}s"
  echo "  Log: $LOGFILE"
  echo "============================================"
  exit 130
}
trap cleanup SIGINT SIGTERM

# --- Banner ---
echo "============================================"
echo "  Isagawa Kernel - Batch Task Runner"
echo "============================================"
echo "Repo: $REPO"
echo "Task folder: $TASK_DIR"
echo "Timeout: ${TIMEOUT_SECONDS}s"
echo ""

# Show state before
echo "[STATE before]"
print_state
echo ""

# Pre-initialize to avoid permission deadlock
pre_init_state "session_started=True"

# Record start time
START_TIME=$(date +%s)

# --- Run batch ---
echo "[RUNNING] claude -p (batch, timeout ${TIMEOUT_SECONDS}s) ..."
cd "$REPO"
RAW_OUTPUT=$(timeout "$TIMEOUT_SECONDS" claude -p --dangerously-skip-permissions --output-format json "$PROMPT" 2>&1) || true
EXIT_CODE=${PIPESTATUS[0]:-$?}

# Save log
write_log "$RAW_OUTPUT" "$LOGFILE"

# Extract fields
SESSION_ID=$(extract_session_id "$RAW_OUTPUT")
RESULT=$(extract_result "$RAW_OUTPUT")
STATUS=$(check_completion "$RESULT")

printf '%s\n' "$RESULT"

# --- Handle timeout ---
if [ "$EXIT_CODE" -eq 124 ] 2>/dev/null; then
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
RAW_OUTPUT=$(timeout "$TIMEOUT_SECONDS" claude -p --dangerously-skip-permissions --output-format json --resume "$SESSION_ID" "$RESUME_PROMPT" 2>&1) || true

write_log "$RAW_OUTPUT" "$RESUME_LOGFILE"

RESULT=$(extract_result "$RAW_OUTPUT")
STATUS=$(check_completion "$RESULT")

printf '%s\n' "$RESULT"

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
