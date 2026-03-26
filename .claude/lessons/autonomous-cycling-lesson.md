# Autonomous Cycling

## 2026-03-23 Agent stops cycling to "save state" and skips HUMAN REQUIRED tasks

- **Issue:** Agent stopped cycling 3 times to "save context for next session" and skipped task 100 (git push to GitHub) marking it "HUMAN REQUIRED." User had to tell agent to keep going each time.
- **Root Cause:** Agent self-interrupts when context gets large, treating it as a natural stopping point. Also treats "HUMAN REQUIRED" label as a stop signal rather than a problem to solve programmatically.
- **Fix:** User told agent to never stop. Agent spawned sub-agent to create GitHub repo via `gh repo create` and push — no human needed.
- **Anti-Pattern Added:** Stopping cycling for any reason other than "all tasks done or skipped after 3 attempts." Pausing for user confirmation. Skipping tasks that can be automated.
- **Quality Gate Added:** When a task says HUMAN REQUIRED, first try to automate it (gh CLI, write state files, use APIs). Only truly skip if it literally requires physical human presence (e.g., plug in a USB device).

## The Pattern

The agent optimizes for "safety" by stopping early and asking permission. But autonomous cycling means autonomous. The user invoked `/kernel/autonomous-cycle` — that's the authorization. Don't second-guess it.

## Concrete Rules

- Cycling = don't stop until done
- "HUMAN REQUIRED" = try to automate first, skip only if impossible
- Context getting large = not a reason to stop (state files handle resume)
- "Save state for next session" = violation (cycling continues in current session)
- If the system literally cannot continue (out of context, tool error) it will stop on its own — the agent doesn't need to preemptively stop
