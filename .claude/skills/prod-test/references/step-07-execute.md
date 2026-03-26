# Step 7: Execute Inner Test Batch

Run the inner test tasks inside the test repo via `run-task.sh`.

## Process

1. **Count inner tasks:**
   ```bash
   ls [test_path]/tasks/prod-test/*.md | grep -v 000-index | wc -l
   ```

2. **Run inner batch:**
   ```bash
   bash [test_path]/run-task.sh [test_path] [task_count + 2] prod-test
   ```

   **IMPORTANT:** Use `task_count + 2` for max_iterations, not `task_count`. The +2 buffer
   accounts for retries when a permission deadlock or transient failure consumes an iteration
   without completing a task.

   This spawns one `claude -p` agent per task, sequentially:
   - Each agent reads CLAUDE.md, does session-start + anchor
   - Picks the next incomplete task
   - Executes it (runs the L1/L2/L3 check)
   - Marks complete via /kernel/complete
   - Exits

3. **Wait for completion:**
   - run-task.sh reports `ALL_TASKS_COMPLETE` or exits with failure
   - Do NOT poll — wait for the process to finish

4. **Read results:**
   - Check exit code of run-task.sh
   - Read test repo workflow state for completed/skipped tasks
   - Read `_test/validation-report.json` if it was produced

## Timeout

Default: 10 minutes per task × task count. For large test suites, increase the timeout.

```bash
# Example: 15 tasks, 10 min each = 150 min = 9000 seconds
bash [test_path]/run-task.sh [test_path] 15 prod-test
```

## Failure Handling

| Outcome | Action |
|---------|--------|
| ALL_TASKS_COMPLETE | Proceed to step 8 |
| Some tasks skipped | Report which tasks failed, proceed to step 8 |
| run-task.sh exits non-zero | Read logs at `.claude/state/iteration_*.log`, report failures |
| Timeout | Kill process, read partial results, report |
