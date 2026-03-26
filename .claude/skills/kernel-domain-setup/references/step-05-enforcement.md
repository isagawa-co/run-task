# Step 5: Understand Enforcement

The kernel uses two enforcement layers:

## Layer 1: Universal Hook (automatic)

The universal hook (`.claude/hooks/universal-gate-enforcer.py`) enforces:

| Gate | What It Checks | Blocked Until |
|------|----------------|---------------|
| Session | `session_started = true` | `/kernel/session-start` |
| Learn | `needs_learn = false` | `/kernel/learn` |
| Anchor | `anchored = true` | `/kernel/anchor` |
| Actions | `actions_since_anchor <= limit` | `/kernel/anchor` |

The hook file is universal — it works for any domain without code changes.

**However, hooks must be REGISTERED in `settings.local.json` to run.** An unregistered hook is a dead file. See **Step 9** for the exact registration template.

## Hook Registration (REQUIRED)

Hooks are Python scripts, but Claude Code only executes them if they're registered in `.claude/settings.local.json` under the `hooks` key. Registration maps trigger events (PreToolUse, PostToolUse) to the hook script path.

**Without registration:**
- Hook file exists but never executes
- No gates fire, no counters increment
- Kernel enforcement is completely absent
- Agent appears to work but has zero safety rails

Registration is done in Step 9 alongside other state files.

## Layer 2: Agent Self-Enforcement (via protocol)

Domain-specific rules (architecture, patterns, anti-patterns) are enforced by the agent after reading the protocol during `/kernel/anchor`.

The protocol contains:
- Patterns: What to do
- Anti-patterns: What NOT to do
- Architecture: How layers compose

When agent anchors:
1. Reads protocol
2. Internalizes rules
3. Self-enforces while writing code

## What this means for domain-setup

Rules must be documented clearly in reference files (not protocol) so agent can self-enforce. Verify reference documentation contains:
- Architecture diagram
- Patterns with code examples
- Anti-patterns with examples

The protocol INDEXES these files. Agent reads actual files during anchor.
