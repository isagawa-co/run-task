# Production Test — Skill

**Type:** Prescriptive
**Style:** Indexed — SKILL.md + references/

## What

Takes a deliverable repo and runs a full production test against it. Assembles a master repo with kernel, runs domain-setup, copies to a disposable test repo, sets up test infrastructure, then executes L1/L2/L3 tests via `run-task.sh` inside the test repo. Produces a validation report.

## Usage

```
/kernel/prod-test [source_repo_path]
/kernel/prod-test /path/to/your-repo
```

**Arguments:**
- `source_repo_path` — path to the repo containing the deliverable code + domain spec

## Steps

| Step | Action | Reference |
|------|--------|-----------|
| 1 | Parse input + discover repo | → `references/step-01-parse.md` |
| 2 | Assemble master repo | → `references/step-02-master.md` |
| 3 | Validate master (domain-setup) | → `references/step-03-validate.md` |
| 4 | Copy master → test repo | → `references/step-04-copy.md` |
| 5 | Set up test infrastructure | → `references/step-05-infra.md` |
| 6 | Write inner test tasks | → `references/step-06-inner-tasks.md` |
| 7 | Execute inner test batch | → `references/step-07-execute.md` |
| 8 | Collect report + cleanup | → `references/step-08-report.md` |

## Composability

This command is **modular and stackable**:

| Caller | How |
|--------|-----|
| **Standalone** | User invokes `/kernel/prod-test [repo]` directly |
| **Task builder** | Step 7 calls `/kernel/prod-test` after BUILD tasks complete |
| **Audit workflow** | Calls `/kernel/prod-test` to verify a deliverable passes all gates |
| **CI/automation** | `run-task.sh` task invokes prod-test via `claude -p` |

When called by another command, the caller provides the source repo path. Prod-test handles everything else.

## Key Principles

- **Master → test repo pattern** — never test in-place, always copy to disposable workspace
- **Domain-setup in master** — protocol + hooks pre-built before copying
- **Inner run-task.sh** — tests execute inside test repo under kernel enforcement
- **L1/L2/L3 required** — structural, functional, and production gates
- **Validation report** — JSON artifact at `_test/validation-report.json`
- **One task = one action** — inner test tasks are atomic
- **Relative paths inside test repo** — inner tasks never use absolute paths

## Outcome

After completion:
- Master repo at `[source]-master/` (reusable golden copy)
- Test repo at `[source]-test/` (disposable, contains results)
- Validation report at `[source]-test/_test/validation-report.json`
- Test infrastructure torn down (Docker, etc.)
- Results presented to caller

## Baseline Reference

→ `docs/research/prod-test-baseline.md`
