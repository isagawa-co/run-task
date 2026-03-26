# Step 8: Collect Report + Cleanup

Gather results and tear down test infrastructure.

## Process

### Collect Report

1. **Read validation report** from test repo:
   ```bash
   cat [test_path]/_test/validation-report.json
   ```

2. **If report doesn't exist** (inner tasks didn't produce it):
   - Read workflow state: `[test_path]/.claude/state/[domain]_workflow.json`
   - Read iteration logs: `[test_path]/.claude/state/iteration_*.log`
   - Construct report manually from completed/skipped/failed tasks

3. **Copy report to orchestrator repo** (if called by another command):
   ```bash
   cp [test_path]/_test/validation-report.json [orchestrator_repo]/tasks/[task_folder]/_test/
   ```

4. **Present results:**

   ```
   PROD-TEST COMPLETE

   Source: [source_repo]
   Target: [test target description]

   L1 Structural: N/N passed
   L2 Functional: N/N passed
   L3 Production: N/N passed

   Overall: PASS | FAIL

   Report: [test_path]/_test/validation-report.json

   [If failures: list each failed gate with details]
   ```

### Cleanup

5. **Tear down test infrastructure:**

   | Infra type | Cleanup command |
   |------------|----------------|
   | Docker | `docker-compose -f [test_path]/_test/docker/docker-compose.yml down` |
   | Mock server | Kill background process |
   | None | Nothing to clean up |

6. **Verify cleanup:**
   - Docker: `docker ps --filter name=[container]` shows nothing
   - Processes: no orphaned test processes running

### Preserve or Delete Test Repo

| Context | Action |
|---------|--------|
| Standalone invocation | Keep test repo for inspection |
| Called by task-builder | Keep test repo, report path |
| CI/automation | Delete test repo after report collected |

The **master repo** is always preserved — it's the golden copy for re-runs.

## Validation Report Schema

→ `docs/research/prod-test-baseline.md` for the full JSON schema.
