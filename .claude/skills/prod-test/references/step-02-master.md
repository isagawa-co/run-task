# Step 2: Assemble Master Repo

Build the golden copy with deliverable code + kernel + domain spec + scripts.

## Process

1. **Create master repo directory:**
   ```bash
   mkdir -p [master_path]
   git -C [master_path] init
   ```

2. **Copy deliverable code:**
   ```bash
   cp -r [source_repo]/[code_dir] [master_path]/[code_dir]
   ```
   Also copy top-level files (requirements.txt, FRAMEWORK.md, README.md, etc.)

3. **Copy domain spec:**
   ```bash
   mkdir -p [master_path]/.claude/skills
   cp -r [source_repo]/.claude/skills/[domain-layer] [master_path]/.claude/skills/[domain-layer]
   ```

4. **Copy kernel infrastructure:**
   - Commands: `.claude/commands/kernel/*.md` (from sr-dev-workspace or kernel source)
   - Hooks: `.claude/hooks/*.py` (from sr-dev-workspace or kernel source)
   - Create empty dirs: `.claude/state/`, `.claude/protocols/`, `.claude/lessons/`

5. **Copy shell scripts:**
   ```bash
   cp [scripts_source]/run-task.sh [master_path]/
   cp [scripts_source]/run-task-batch.sh [master_path]/
   chmod +x [master_path]/run-task.sh [master_path]/run-task-batch.sh
   ```

6. **Write CLAUDE.md:**
   - Kernel loop reference (session-start → anchor → WORK → complete)
   - Commands table pointing to `.claude/commands/kernel/`
   - Domain spec reference to `.claude/skills/[domain-layer]/`

## Sources

| Component | Primary source | Fallback |
|-----------|---------------|----------|
| Kernel commands | sr-dev-workspace `.claude/commands/kernel/` | isagawa-kernel repo |
| Hooks | sr-dev-workspace `.claude/hooks/` | isagawa-kernel repo |
| Shell scripts | `run-task-resume-master/` | sr-dev-workspace root |
| Domain spec | source repo `.claude/skills/` | — |
| Code | source repo | — |

## Verification

- [ ] `[master_path]/CLAUDE.md` exists
- [ ] `[master_path]/.claude/skills/[domain]/SKILL.md` exists
- [ ] `[master_path]/.claude/commands/kernel/session-start.md` exists
- [ ] `[master_path]/run-task.sh` exists
- [ ] Deliverable code directory exists
