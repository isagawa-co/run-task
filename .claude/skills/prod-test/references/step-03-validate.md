# Step 3: Validate Master (Domain Setup)

Run domain-setup in the master repo to generate protocol + hooks, then verify.

## Process

1. **Spawn domain-setup agent:**
   ```bash
   claude -p --dangerously-skip-permissions \
     "You are operating in [master_path]. Use ABSOLUTE PATHS for all file operations — never cd. \
      Read [master_path]/CLAUDE.md. Then read and follow [master_path]/.claude/commands/kernel/domain-setup.md. \
      Discover the domain spec and build protocol + hooks. \
      Output DOMAIN_SETUP_COMPLETE when done."
   ```

   **IMPORTANT:** Do NOT use `--cwd` (not a valid flag). Do NOT tell the agent to `cd`.
   All file paths in the prompt must be absolute. The agent uses absolute paths for Read/Write/Bash.

2. **Verify protocol created:**
   ```bash
   ls [master_path]/.claude/protocols/*.md
   ```
   Read the protocol — confirm it references the domain spec.

3. **Verify hooks registered:**
   ```bash
   cat [master_path]/.claude/settings.local.json
   ```
   Confirm universal gate enforcer is registered.

4. **Verify commands exist:**
   ```bash
   ls [master_path]/.claude/commands/kernel/
   ```
   Confirm session-start.md, anchor.md, complete.md present.

## Failure Handling

| Failure | Action |
|---------|--------|
| domain-setup times out | Retry once with longer timeout |
| No protocol created | Check CLAUDE.md references correct skill path |
| No hooks in settings | Check hooks were copied to `.claude/hooks/` |
| Agent permission errors | Verify `--dangerously-skip-permissions` flag used |

## Verification

- [ ] Protocol file exists and references domain
- [ ] Settings file has hooks registered
- [ ] Kernel commands present (session-start, anchor, complete)
