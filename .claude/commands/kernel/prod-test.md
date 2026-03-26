# /kernel/prod-test

Run a full production test against a deliverable repo.

## Usage

```
/kernel/prod-test [source_repo_path]
/kernel/prod-test /path/to/your-repo
```

## Instructions

This command uses a skill-based approach with 8 steps.

### Load Skill

Read and follow: `.claude/skills/prod-test/SKILL.md`

### Quick Reference

| Step | Action |
|------|--------|
| 1 | Parse input + discover repo |
| 2 | Assemble master repo |
| 3 | Validate master (domain-setup) |
| 4 | Copy master → test repo |
| 5 | Set up test infrastructure |
| 6 | Write inner test tasks |
| 7 | Execute inner test batch |
| 8 | Collect report + cleanup |

### Key Principles

- **Master → test repo** — never test in-place
- **Domain-setup in master** — protocol + hooks pre-built before copying
- **Inner run-task.sh** — tests run inside test repo under kernel enforcement
- **L1/L2/L3 required** — every deliverable gets all three levels
- **Modular** — callable standalone or by other commands (task-builder, audit-workflow)
- **Auto-execute** — don't ask, just run

### Composability

This command is designed to be called by other commands:

```
# Standalone
/kernel/prod-test C:/path/to/my-repo

# From task-builder step 7 (after BUILD tasks complete)
# Agent reads prod-test skill, runs steps 1-8 against the build output

# From audit-workflow (verify a deliverable passes gates)
# Agent calls prod-test, reads validation report, flags failures
```

When called by another command, output the validation report path so the caller can read it.
