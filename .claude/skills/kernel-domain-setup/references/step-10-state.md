# Step 9: Update State

Three files MUST be created/updated. All three are required for the kernel to function.

## 1. Session State

Create/update `.claude/state/session_state.json`:

```json
{
  "session_started": true,
  "domain": "[domain]",
  "timestamp": "[ISO-8601]",
  "needs_restart": true,
  "resume_after_restart": "anchor"
}
```

## 2. Workflow State

Create `.claude/state/[domain]_workflow.json`:

```json
{
  "domain": "[domain]",
  "setup_complete": true,
  "protocol_created": true,
  "protocol_path": ".claude/protocols/[domain]-protocol.md",
  "anchored": false,
  "actions_since_anchor": 0,
  "actions_limit": 10,
  "timestamp": "[ISO-8601]"
}
```

## 3. Hook Registration (REQUIRED)

Create/update `.claude/settings.local.json` to register hooks.

**MERGE RULE:** If `settings.local.json` already exists (e.g., MCP config from Step 1), MERGE the `hooks` key into the existing file. Do NOT overwrite — you will destroy MCP server config and other settings.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/universal-gate-enforcer.py"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python .claude/hooks/test-failure-detector.py"
          }
        ]
      }
    ]
  }
}
```

**If file already exists:** Read it first, add the `hooks` key, preserve all other keys (`enableAllProjectMcpServers`, `enabledMcpjsonServers`, etc.).

**If PostToolUse hook doesn't exist yet:** Omit the PostToolUse entry. Only register hooks that have corresponding Python files in `.claude/hooks/`.

## Verification Checklist

Before proceeding to Step 10, verify ALL three files exist:

| File | Check |
|------|-------|
| `.claude/state/session_state.json` | Contains `domain`, `needs_restart: true` |
| `.claude/state/[domain]_workflow.json` | Contains `setup_complete: true`, `anchored: false` |
| `.claude/settings.local.json` | Contains `hooks` key with PreToolUse entry |

**If any file is missing, Step 9 is incomplete. Do not proceed.**

## State Fields

| Field | Purpose |
|-------|---------|
| `session_started` | Session initialized |
| `domain` | Active domain name |
| `needs_restart` | Hooks require restart |
| `resume_after_restart` | What to do after restart |
| `anchored` | Protocol read this session |
| `actions_since_anchor` | Counter (auto-incremented by hook) |
| `actions_limit` | Threshold before re-anchor required |
