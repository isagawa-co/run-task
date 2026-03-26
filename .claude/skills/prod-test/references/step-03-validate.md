# Step 3: Validate Master (Domain Setup)

Run domain-setup in the master repo to generate protocol + hooks, then verify.

## Process

1. **Pre-initialize state** (avoids permission deadlock on fresh repos):
   ```bash
   mkdir -p [master_path]/.claude/state [master_path]/.claude/protocols
   python -c "
   import json, pathlib
   f = pathlib.Path('[master_path]/.claude/state/session_state.json')
   f.write_text(json.dumps({'session_started': True, 'domain': None, 'needs_restart': False}, indent=2))
   "
   ```
   Claude Code's built-in sensitive file guard blocks `.claude/state/` writes from headless agents.
   Pre-creating the state file lets the agent proceed. Domain-setup overwrites it with real values.

2. **Spawn domain-setup agent:**
   ```bash
   claude -p --dangerously-skip-permissions \
     "You are operating in [master_path]. Use ABSOLUTE PATHS for all file operations — never cd. \
      Read [master_path]/CLAUDE.md. Then read and follow [master_path]/.claude/commands/kernel/domain-setup.md. \
      Discover the domain spec and build protocol + hooks. \
      Output DOMAIN_SETUP_COMPLETE when done."
   ```

   **IMPORTANT:** Do NOT use `--cwd` (not a valid flag). Do NOT tell the agent to `cd`.
   All file paths in the prompt must be absolute. The agent uses absolute paths for Read/Write/Bash.

3. **Verify protocol created:**
   ```bash
   ls [master_path]/.claude/protocols/*.md
   ```
   Read the protocol — confirm it references the domain spec.

4. **Verify hooks registered:**
   ```bash
   cat [master_path]/.claude/settings.local.json
   ```
   Confirm universal gate enforcer is registered.

5. **Verify commands exist:**
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
