# Step 4: Copy Master → Test Repo

Create a fresh, disposable copy of the validated master for testing.

## Process

1. **Remove existing test repo** (if present from prior run):
   ```bash
   rm -rf [test_path]
   ```

2. **Copy master to test repo:**
   ```bash
   cp -r [master_path] [test_path]
   ```

3. **Verify the copy is complete:**
   - [ ] `[test_path]/CLAUDE.md` exists
   - [ ] `[test_path]/.claude/protocols/` has protocol file
   - [ ] `[test_path]/.claude/skills/[domain]/SKILL.md` exists
   - [ ] `[test_path]/run-task.sh` exists
   - [ ] Deliverable code directory exists

## Why Copy?

- Tests may modify state, create files, change configs
- Disposable workspace means the master stays clean
- Re-running prod-test just copies again — no cleanup needed
- Master is the **golden copy** — never polluted by test artifacts
