# Cycling Run Lessons

Issues discovered during first autonomous cycling run (7 specs, 28 tests, ~15 min).

---

## Testing Context — What We're Doing

cognitive-agent is the testing ground for **kernel + autonomous cycling + domain spec**.

**The test flow:**
1. Reset cognitive-agent to `origin/main` (clean vanilla kernel)
2. Create `feature/cycling-fixes` with the 6 fixes cherry-picked on top
3. Drop the playwright spec into the repo (untracked — domain-setup discovers it)
4. Run: `session-start` → `domain-setup` → restart → `continue` → `/kernel/autonomous-cycle`
5. Verify all 6 fixes work during the cycling run

**Domain spec files are UNTRACKED on purpose.** Domain-setup reads them, builds protocol/state/hooks from them, then commits the output. The spec itself stays untracked until domain-setup commits it as part of "feat: domain-setup output for [domain]".

**Don't commit the spec before domain-setup.** Don't ask "should I commit this?" — the answer is always no. The spec is input, not output.

---

## 2026-03-03 First Autonomous Cycling Run — 5 Lessons

### Lesson 1: Learn Self-Enforcement — Hook Is Safety Net, Not Only Trigger
- **Issue:** Agent skipped `/kernel/learn` after test failures when `needs_learn` was not set in state.
- **Root Cause:** Treated `needs_learn: true` as the only trigger. Hook hadn't restarted yet, so it never fired.
- **Fix:** Self-enforce: test failed → fix → `/kernel/learn`. Always. Hook or no hook.

### Lesson 2: Complete Gate Possibly Skipped for Specs 003-005
- **Issue:** No visible `Skill(/kernel:complete)` invocation. Format was printed but skill may not have been invoked.
- **Root Cause:** Agent printed the COMPLETE format without invoking the actual skill.
- **Fix:** Invoke `/kernel/complete` via Skill tool. Printing without invoking is a protocol violation.

### Lesson 3: Stale Session State Between Specs
- **Issue:** `session_state.json` context not updated after spec completion — only during anchor.
- **Root Cause:** `/kernel/complete` updated workflow.json but not session_state.json.
- **Fix:** Dual state update after each spec. Both files MUST be updated.

### Lesson 4: Redundant Spec Created by Domain-Setup
- **Issue:** Step-07 created placeholder `001-setup.md` when `specs/` already had files.
- **Root Cause:** Blanket rule without checking if specs/ was already populated.
- **Fix:** Pre-existing specs check: if `specs/` has `.md` files, skip creation.

### Lesson 5: Uncommitted Domain-Setup Output
- **Issue:** After domain-setup, all generated files left untracked. Dirty state on restart.
- **Root Cause:** No step committed output before requesting restart.
- **Fix:** Commit all domain-setup artifacts before setting `needs_restart`.
