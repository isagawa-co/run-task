# Testing Workflow

Run from an active Claude Code session on the sr-dev-workspace.

## 1. Setup test repo

```bash
# Clean and copy from one-shot-master (working baseline)
cd C:/Users/solos/my_ai_projects/test-run-task-resume
find . -not -path './.git/*' -not -path './.git' -not -name '.' -delete
cp -r C:/Users/solos/my_ai_projects/one-shot-master/* .
cp -r C:/Users/solos/my_ai_projects/one-shot-master/.claude .

# Apply changes under test
cp C:/Users/solos/my_ai_projects/run-task-resume-master/run-task.sh .
cp C:/Users/solos/my_ai_projects/sr-dev-workspace/.claude/hooks/universal-gate-enforcer.py .claude/hooks/
```

- Verify structure: `find . -not -path '*/.git/*' | sort`
- Verify state is clean: read session_state.json + workflow.json

## 2. Run

```bash
cd C:/Users/solos/my_ai_projects/test-run-task-resume
bash run-task.sh . 5 2>&1
```

Run in background from Claude Code session — get notified on completion.

## 3. Inspect results

- State files: `.claude/state/session_state.json`, `*_workflow.json`
- Output files: whatever the tasks produce
- Iteration logs: `.claude/state/iteration_*.log`
- Resume logs: `.claude/state/iteration_*_resume_*.log` (if any)
- Counter: `actions_since_anchor` in workflow state
- Lessons: `.claude/lessons/lessons.md`

## 4. Diagnose failures

- Compare iteration logs to find where it broke
- Check if resume kicked in and what happened
- Diff state before/after failed iteration

## 5. Fix and re-run

- Edit hooks, commands, or run-task.sh in the master or sr-dev-workspace
- Reset test repo state (re-run step 1)
- Back to step 2

## 6. Sync to master

When all tests pass, copy changes to `isagawa-kernel` and `run-task-resume-master`.
