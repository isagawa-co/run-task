#!/bin/bash
set -uo pipefail
#
# run-task.sh — One-shot task execution with session resume for Isagawa Kernel
#
# Each iteration: pre-init state → claude -p (JSON) → detect completion
# On failure: retry with --resume to preserve full conversation context
# State files on disk provide continuity between successful iterations.
#
# Usage:
#   ./run-task.sh [repo_path] [max_iterations] [task_folder]
#
# Arguments:
#   repo_path       Path to kernel-enabled repo (default: current directory)
#   max_iterations  Max tasks to attempt (default: 10, use task_count + 2 for buffer)
#   task_folder     Subfolder under tasks/ (default: none, uses tasks/)
#                   Example: "kernel-test" → tasks/kernel-test/

# --- Configuration ---
REPO="${1:-.}"
MAX_ITERATIONS="${2:-10}"
TASK_SUBFOLDER="${3:-}"
COMPLETED=0
FAILED=0
CONSECUTIVE_FAILS=0
MAX_CONSECUTIVE_FAILS=2
MAX_RESUME_RETRIES=2
TASK_TIMEOUT=300  # 5 min per claude -p invocation
SLEEP_BETWEEN=2

# --- Resolve script directory and source shared lib ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# --- Validate ---
validate_deps
REPO=$(cd "$REPO" && pwd)
validate_repo "$REPO"
resolve_paths "$REPO"

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

# --- Trap for clean exit on signals ---
cleanup() {
  echo ""
  echo "============================================"
  echo "  INTERRUPTED"
  echo "  Completed: $COMPLETED"
  echo "  Failed: $FAILED"
  echo "  Check logs: ${LOG_DIR}/iteration_*.log"
  echo "============================================"
  exit 130
}
trap cleanup SIGINT SIGTERM

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

  local raw_output
  raw_output=$(timeout "$TASK_TIMEOUT" claude "${cmd_args[@]}" "$prompt" 2>&1) || true

  # Save raw output to log
  write_log "$raw_output" "$logfile"

  # Extract fields
  LAST_SESSION_ID=$(extract_session_id "$raw_output")
  LAST_RESULT=$(extract_result "$raw_output")
  LAST_STATUS=$(check_completion "$LAST_RESULT")

  # Print result to screen
  printf '%s\n' "$LAST_RESULT"
}

# --- Banner ---
echo "============================================"
echo "  Isagawa Kernel - One-Shot Task Runner"
echo "  (with session resume)"
echo "============================================"
echo "Repo: $REPO"
echo "Task folder: $TASK_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# --- Main loop ---
# cd once before loop, not inside run_claude
cd "$REPO"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "=== Iteration $i/$MAX_ITERATIONS ==="

  # Show state before
  echo "[STATE before]"
  print_state
  echo ""

  # Pre-init state (session_started + one_shot)
  pre_init_state "session_started=True,one_shot=True"

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

  sleep "$SLEEP_BETWEEN"
done

echo ""
echo "============================================"
echo "  MAX ITERATIONS REACHED"
echo "  Completed: $COMPLETED"
echo "  Failed: $FAILED"
echo "  Iterations: $MAX_ITERATIONS"
echo "============================================"
exit 1
