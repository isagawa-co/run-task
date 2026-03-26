# Step 6: Write Inner Test Tasks

Create the test task files that will run inside the test repo via inner `run-task.sh`.

## Process

1. **Create task directory:**
   ```bash
   mkdir -p [test_path]/tasks/prod-test
   ```

2. **Read the gate contract:**
   Read `[test_path]/.claude/skills/[domain]/gate-contract.md` to get the structural and functional gates.

3. **Write task files** — one per atomic action, all using **relative paths** (they run inside the test repo):

### Required inner tasks (in order):

| # | Task | Level | What |
|---|------|-------|------|
| 000 | Index | — | Task table with wikilinks |
| 001 | L1 structural gates | L1 | Run all file_exists + grep checks from gate contract |
| 002 | L2 import checks | L2 | Run all run_code import checks from gate contract |
| 003 | L2 pytest/unit tests | L2 | Run existing test suite |
| 004 | Write test config | L3 prep | Host config / test fixtures pointing to test target |
| 005+ | L3 component tests | L3 | One task per testable component (interface, validators, etc.) |
| N-1 | L3 end-to-end | L3 | Full pipeline / batch execution against live target |
| N | Validation report | — | Aggregate results into `_test/validation-report.json` |

### L3 task template:

```markdown
# L3: Test [Component]

## Type
TEST

## Executor
Spawned agent via `run-task.sh`

## Action
Write and run a Python script:
- Import from framework (relative path)
- Configure with test target (from _test/fixtures/)
- Execute the component
- Assert expected results
- Print PASS/FAIL

## Acceptance Criteria
- [ ] Script exits 0
- [ ] Output contains "PASS"
```

4. **Adapt L3 tasks to the deliverable:**
   - Read the source code to understand what components exist
   - One L3 task per independently testable component
   - Final L3 task is always an end-to-end that exercises the full pipeline

## Rules

- All paths relative to test repo root
- One task = one action
- L3 tasks test the **deliverable code directly**, not through the domain spec
- Every task has mechanical acceptance criteria
