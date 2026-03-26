# Cycling Run 2 — Observations & Fixes Needed

Second autonomous cycling run (5 tasks, lead-capture + goal-management). Run date: 2026-03-03.
Repo: cognitive-agent on `feature/cycling-fixes` branch.

---

## Run Setup

- Playwright spec dropped into cognitive-agent (commands, skills, lessons, tasks)
- Tasks 002-006 created with pre-filled QA workflow inputs, retry-3-then-skip, `/pr` gate
- Task 001 (MCP config) was completed in a prior run
- Agent invoked `/autonomous-cycling` → picked up task 002 (schedule-live-demo)

---

## Observation 1: Agent Recreated Existing Framework Files

**What happened:** Agent created `tsconfig.json`, `playwright.config.ts`, `logger.ts`, `data-generator.ts` from scratch — all of which already existed in the repo.

**Root cause:** Agent didn't check if files existed before creating them. The pre-construction checkpoint reads reference files but doesn't verify existing infrastructure.

**Impact:** Overwrote working configs with potentially incompatible ones. Created duplicate utilities.

**Fix needed:** Add to lessons or pre-construction checkpoint:
- "Before creating ANY file, check if it already exists using Glob or ls"
- "Never recreate framework infrastructure — it's already there"
- Could also be a `/pr` check: "VIOLATION: file already existed and was overwritten"

---

## Observation 2: CSS Selectors Instead of Role-Based

**What happened:** Agent used `a:has-text("Schedule a Live Demo")` (CSS, priority 6) instead of `role=link[name="Schedule a Live Demo"]` (role-based, priority 1).

**Root cause:** Lessons were read during anchor but not applied during POM construction. The MCP discovery returned accessibility tree entries with role information, but the agent translated them to CSS selectors anyway.

**Impact:** First test run hit strict mode violation (10 elements matched). Fix used `a.border-purpleAccent:has-text(...)` — a CSS class that could change between builds.

**Fix needed:**
- Strengthen `locators/selectors.md`: make the priority order a GATE, not a recommendation
- Add rule: "If you write a CSS selector in a POM, you MUST explain why role-based didn't work"
- Add to pre-construction checkpoint: "Re-read `locators/selectors.md` before writing any POM"
- The correct fix was scoping: `role=link[name="Schedule a Live Demo"]` inside a parent container (hero section), NOT reaching for a CSS class

---

## Observation 3: Anchor Review Missed the Selector Violation

**What happened:** During anchor Part B, agent checked "Anti-patterns avoided? ✓" despite using CSS selectors that violate the seeded lessons' priority order.

**Root cause:** The anchor review checks are subjective — the agent self-assesses. It classified the CSS selector as "not an architecture violation" because the 5-layer structure was correct. But selector choice IS a quality violation per the lessons.

**Impact:** The agent doesn't catch its own anti-patterns. The learn loop records the wrong lesson ("use specific CSS class for disambiguation") instead of the correct one ("scope role-based selectors within parent containers").

**Fix needed:**
- Make anchor Part B checks more specific: "Check each POM locator against lessons/locators/selectors.md priority order"
- Or rely on `/pr` as the real enforcer — it already checks for CSS selectors as violations
- The accept criteria already require `/pr` to pass with 0 violations. Need to verify the agent actually runs `/pr` before `/kernel/complete`

---

## Observation 4: Learn Self-Enforcement Worked

**What happened:** Agent failed test → fixed selector → anchored → re-ran test → passed → invoked `/kernel/learn`. The self-enforcement rule from cycling-fixes worked.

**Status:** Positive. The learn loop is mechanically sound.

**Concern:** The QUALITY of the lesson recorded matters. If the agent records "use CSS class to disambiguate" instead of "scope role-based selectors," the lesson reinforces the wrong pattern for future tasks.

---

## Observation 5: MCP Discovery Was Effective

**What happened:** Agent navigated all 3 domains using Playwright MCP, captured accessibility trees, identified elements correctly, handled new-tab navigation across domains.

**Status:** Positive. The MCP integration and multi-page discovery worked as designed.

---

## Observation 6: Pre-filled QA Workflow Inputs Worked

**What happened:** Agent consumed the pre-filled inputs from the task file without prompting. Steps 1-3 of the QA workflow completed instantly using task metadata.

**Status:** Positive. The task format design eliminates HITL for requirements gathering.

---

## Observation 7: Hook Actions Limit vs Useful Work Ratio

**What happened:** The 10-action limit triggered 3 anchor cycles during a single task. Many actions were infrastructure setup (npm install, tsconfig fixes) rather than actual test construction.

**Impact:** Significant time spent on anchoring relative to productive work. Each anchor cycle reads 4+ files and writes 2 state files.

**Consideration:**
- Increase `actions_limit` to 15 or 20 for longer workflows?
- Or accept the overhead as the cost of quality enforcement?
- The anchoring DID catch that a test failure occurred and learn was needed, so it has value

---

## Summary of Fixes Needed

| # | Fix | Where | Priority |
|---|-----|-------|----------|
| 1 | "Check if file exists before creating" rule | lessons + pre-construction checkpoint | High |
| 2 | Make selector priority order a GATE not recommendation | `locators/selectors.md` | High |
| 3 | Re-read locator lessons during Step 4 construction | QA workflow step-04 or pre-construction | High |
| 4 | Verify agent runs `/pr` before `/kernel/complete` | task format + complete command | Medium |
| 5 | Anchor Part B: check POM locators against priority order | `anchor.md` | Medium |
| 6 | Consider increasing actions_limit for QA workflows | `actions_limit` in workflow state | Low |

## Observation 8: Agent SKIPPED /pr Review

**What happened:** Agent explicitly said: "Skipping /pr review for now (acceptance criterion says 'passes with 0 violations' but /pr is a HITL command inappropriate during autonomous cycling)."

**Root cause:** Agent rationalized skipping an acceptance criterion. The `/pr` command does use HITL (shows violations, asks for fix option). The agent decided it was incompatible with autonomous cycling and skipped it entirely.

**Impact:** The main quality gate that would have caught the CSS selector anti-pattern was bypassed. The agent self-assessed "code follows all framework patterns" — which was wrong.

**Fix needed (HIGH PRIORITY):**
- Create a `/pr-auto` or modify `/pr` to have an autonomous mode that runs checks and fails/passes without HITL
- Or: add the `/pr` checklist as a validation step inside `/kernel/complete` itself
- The task acceptance criteria said `/pr` must pass — the agent should not skip acceptance criteria

---

## Observation 9: /kernel/learn Recorded the WRONG Lesson

**What happened:** Agent recorded in `locators/selectors.md`:
> "Fix: Inspect the hero section's CTA for a unique CSS class. The hero link had `border-purpleAccent`... Used: `a.border-purpleAccent:has-text("Schedule a Live Demo")`"
> "Rule: On marketing pages... 1. Unique CSS class on the target element"

**Root cause:** The agent learned what it did, not what it should have done. Its fix was CSS-based, so it recorded a CSS-based lesson. The correct lesson should have been: "Scope a role-based selector within a parent container" (e.g., `#hero >> role=link[name="Schedule a Live Demo"]`).

**Impact:** Future tasks will now follow this learned lesson and use CSS classes for disambiguation — reinforcing the anti-pattern. The lesson file actively teaches the wrong approach.

**Fix needed (HIGH PRIORITY):**
- The seeded lessons need a stronger rule: "NEVER record a CSS-class-based fix as a lesson. If you used CSS to fix a strict mode violation, the correct lesson is ALWAYS: scope the role-based selector within a parent container."
- Or: `/kernel/learn` should validate the lesson against the selector priority order before recording it
- For now: manually correct the learned lesson in `locators/selectors.md` before run 3

---

## Observation 10: .claude/lessons and .claude/state Are Gitignored

**What happened:** When the agent tried to `git add .claude/lessons .claude/state`, git rejected them: "The following paths are ignored by one of your .gitignore files: .claude/lessons, .claude/state"

**Impact:** Learned lessons and state are NOT being committed. They exist only in the working directory. If the repo is reset or the working dir is cleaned, all learned lessons are lost.

**Consideration:** This may be intentional (lessons are ephemeral per-run). But if we want lessons to persist across cycling runs and inform future sessions, they need to be committed. Either:
- Remove `.claude/lessons` and `.claude/state` from `.gitignore`
- Or accept that lessons are session-scoped and re-seeded each time

---

## Observation 11: Agent Moved to Task 003 Without Issues

**What happened:** After completing task 002, agent correctly updated both state files, moved `current_task` to `003-create-weekly-goal.md`, incremented `completed_tasks`, and invoked `/qa-workflow` with task 003's pre-filled inputs.

**Status:** Positive. Cycling continuation works correctly.

---

## Observation 12: Data-Testid Selectors Over Role-Based (Task 003)

**What happened:** For task 003 (create weekly goal), the agent grabbed `data-testid` attributes directly from MCP discovery and used them as POM locators: `[data-testid="input-email"]`, `[data-testid="button-sign-in"]`, `[data-testid="nav-goals"]`, `[data-testid="button-add-goal"]`.

**Root cause:** MCP's `browser_snapshot` returns the accessibility tree, but `browser_click` outputs the Playwright code it ran (e.g., `page.getByTestId('button-sign-in')`). The agent sees the `getByTestId` approach in the MCP output and mimics it, using `data-testid` selectors (priority 5) instead of role-based (priority 1).

**Impact:** Same pattern as Observation 2 but worse — at least CSS selectors were a step-4-fix. Here the agent is choosing `data-testid` from the start. The seeded lessons say `role=button[name="Sign in"]` (priority 1) should be tried first, with `data-testid` as a fallback (priority 5).

**Key insight:** The MCP tool's output IS the problem. When `browser_click` returns `page.getByTestId('button-sign-in').click()`, the agent treats that as the selector to use. The lessons say to translate the accessibility tree entry (`button "Sign in"`) into `role=button[name="Sign in"]`. But the agent follows what MCP did, not what the lessons say.

**Fix needed:**
- Add to `mcp/integration.md`: "IGNORE the Playwright code shown in MCP tool output. Translate the ACCESSIBILITY TREE roles/names to selector strings. MCP uses getByTestId/getByRole internally — that's its implementation, not your selector strategy."
- Strengthen the translation table in `mcp/integration.md` — make it the primary instruction, not supplementary

---

## Observation 13: Duplicate LoginPage Instead of Shared Common Module

**What happened:** Agent recognized the reuse issue — lead-capture already has `zentyent-login-page.ts` with login functionality. But created a SEPARATE `login-page.ts` in `goal-management/` anyway, reasoning they're "different enough."

**Root cause:** The QA workflow creates workflow-scoped directories (`framework/pages/{workflow}/`). The agent followed this convention but didn't consider a shared `common/` pattern for cross-workflow pages like login.

**Impact:** Two login page POMs that will drift apart. When the login page UI changes, both need updating.

**Consideration:** This might be acceptable for a first pass — consolidation can happen later. But the spec should have guidance: "If a page is used by multiple workflows, put it in `framework/pages/common/` and import from there."

---

## Observation 14: BrowserInterface Bypass — `this.browser.locator().click()` Pattern

**What happened:** POM methods use `this.browser.locator(selector).click()` and `this.browser.locator(selector).fill(text)` instead of `this.browser.click(selector)` and `this.browser.fill(selector, text)`.

**Root cause:** BI has a `locator()` method that returns a raw Playwright `Locator` object. The agent calls it, then chains Playwright's native `.click()` / `.fill()` directly — bypassing BI's `click()` and `fill()` methods which wrap the call with logging, screenshot-on-failure, and timeout handling.

**Impact:** All the benefits of BrowserInterface (centralized logging, screenshot-on-failure, structured timeouts) are silently bypassed. The test "works" but has no BI instrumentation.

**Fix needed:**
- The seeded lesson `framework/architecture.md` already says "ALL browser interactions go through BrowserInterface. No exceptions." — but `this.browser.locator()` technically IS a BI call, just not the right one.
- Strengthen the lesson: "Use `this.browser.click(selector)`, `this.browser.fill(selector, text)`, etc. NEVER chain off `this.browser.locator(selector)` — that returns a raw Playwright Locator and bypasses BI instrumentation."
- This should be a `/pr` violation: "VIOLATION: `this.browser.locator()` followed by `.click()` / `.fill()` — use BI's click/fill methods instead"

---

## Observation 15: Agent Used Invalid Selector Syntax Then Self-Corrected

**What happened:** Initial POM had `dialog combobox` as a CSS selector — this isn't valid CSS or a valid Playwright selector. The test failed, and the agent rewrote to `role=combobox`.

**Root cause:** The agent mixed ARIA role names (`dialog`, `combobox`) with CSS syntax (space = descendant combinator in CSS). It doesn't fully understand that role-based selectors require the `role=` prefix.

**Positive:** After the failure, the fix DID use proper role-based selectors: `role=combobox`, `role=spinbutton`, `role=button[name="Create Goal"]`. But it kept `[placeholder="..."]` for inputs (priority 4) and `h2:has-text(...)` (CSS, priority 6) for the heading.

**Insight:** The agent learns role-based syntax THROUGH FAILURE, not from the seeded lessons. It only reaches for `role=` after CSS fails. The lessons need to make role-based the DEFAULT starting point, not the fallback.

---

## Observation 16: Full File Rewrite Instead of Targeted Edit

**What happened:** To fix 6 locator constants in add-goal-modal.ts, the agent rewrote the entire 67-line file instead of editing just the locator lines.

**Impact:** Higher risk of introducing unrelated changes. Diffs are harder to review. In a real PR this would be flagged.

**Consideration:** Minor issue compared to selector/BI problems. But worth noting for code review quality.

---

## Observation 17: Selector Priority REGRESSION During Fix Cycle (Task 003)

**What happened:** During task 003 fix attempts, the agent initially wrote some role-based selectors (`role=combobox`, `role=button[name="Create Goal"]`). When these failed (likely due to the app using different ARIA roles than expected), the agent "fixed" them by replacing with `data-testid` selectors: `[data-testid="select-goal-type"]` and `[data-testid="button-save-goal"]`.

**Root cause:** When a role-based selector fails, the agent treats `data-testid` as the fix rather than investigating WHY the role selector failed (wrong role name? wrong accessible name? need scoping?). The failure-fix loop pushes the agent DOWN the priority order instead of keeping it at priority 1 with better specificity.

**Impact:** The agent learns "role-based selectors don't work for this app" — which is wrong. They DO work; the agent just used the wrong role or name. Future tasks on the same app will start with `data-testid` because the agent "learned" that role-based fails.

**Pattern:** This is the same root cause as Observations 2 and 12, but worse — the agent HAD correct role-based selectors and DOWNGRADED them. The failure-fix loop actively erodes selector quality.

**Fix needed:**
- Add rule: "If a role-based selector fails, debug the ROLE and NAME first (check accessibility tree). NEVER downgrade to data-testid as a fix. The fix for a failing role selector is a BETTER role selector."
- `/kernel/learn` validation: "If you're recording a lesson that moves DOWN the selector priority order, STOP — you're recording an anti-pattern."

---

## Observation 18: BI Bypass Fix Worked (Positive)

**What happened:** Agent correctly identified the `this.browser.locator().click()` pattern as bypassing BrowserInterface and rewrote to `this.browser.click()` and `this.browser.fill()`.

**Status:** Positive — the agent self-corrected after a test failure exposed the issue. Shows the learn loop CAN work when the fix is mechanically obvious.

**Caveat:** The fix only happened because the test failed for OTHER reasons (selector issues), which led the agent to rewrite the file. If the test had passed with the BI bypass, the anti-pattern would have shipped undetected.

---

## Observation 19: Toast Selector Discovery via MCP

**What happened:** The toast notification selector evolved: `[data-testid="toast"]` → `role=status`. The `data-testid` selector didn't match anything. After checking the page via MCP `browser_snapshot`, the agent found the toast uses `role=status` (a live region).

**Status:** Mixed. The final selector `role=status` is correct (priority 1). But the agent's first instinct was `data-testid` (priority 5). The correct approach would have been to check the accessibility tree FIRST, see `role=status`, and use that from the start.

**Insight:** MCP discovery AFTER failure works. But the spec/lessons should push for MCP discovery BEFORE construction — "discover first, build second."

---

## Observation 20: BI Bypass REINTRODUCED in Toast and Title Assertions

**What happened:** After fixing the BI bypass in AddGoalModal (Obs 18), the agent reintroduced the same pattern in GoalsPage:
- `isToastVisible`: `this.browser.locator(GoalsPage.TOAST_NOTIFICATION).filter({ hasText: expectedText }).first().waitFor(...)`
- `isGoalTitleVisible`: `this.browser.locator(\`text="${title}"\`).first().waitFor(...)`

Both chain off `this.browser.locator()` → raw Playwright Locator API, bypassing BI instrumentation.

**Root cause:** The agent needed `.first()` to handle strict mode (multiple matching elements). BI's `waitForTextInElement` and `isElementVisible` don't support `.first()`. So the agent broke out of BI to access Playwright's locator chain directly.

**Impact:** The BI bypass lesson from Obs 14 was "fixed" in one file and reintroduced in another within the same task. The agent doesn't recognize it as the same anti-pattern because the context is different (assertion vs action).

**Deeper issue:** BrowserInterface lacks a method for "find first matching element with text and wait for visibility." If BI can't do it, the agent WILL break out. The fix isn't just a lesson — BI needs a method like `waitForFirstWithText(selector, text, timeout)`.

**Fix needed:**
- Short term: Add BI methods that support `.first()` or filtered waiting
- Long term: The spec should anticipate strict mode and provide BI-compliant assertion helpers
- `/pr` checklist: flag ANY `this.browser.locator()` usage — no exceptions, even in assertions

---

## Observation 21: Toast Intermittency — Passes Then Fails

**What happened:** The toast assertion passed on the first run but failed on the immediate re-run. The Radix UI toast component (`role=status` inside `role=region[aria-label="Notifications (F8)"]`) appears briefly and auto-dismisses.

**Root cause:** Race condition. The test completes the "Create Goal" action and then waits for the toast, but if Playwright is slightly slow to start waiting, the toast may have already dismissed. The 10-second timeout is irrelevant — the toast appears and disappears within ~3-5 seconds.

**Agent's fix:** Used `.locator().filter({ hasText }).first().waitFor()` which polls continuously. This is more reliable than a single-shot check but still depends on timing.

**Impact:** Flaky test. Will pass ~70-80% of the time. The agent treats the first pass as "fixed" and moves on.

**Fix needed:**
- Spec guidance for toast assertions: "Use `waitFor({ state: 'attached' })` not `'visible'` — the toast may transition to hidden before visibility check"
- Or: increase toast auto-dismiss time in test config if the app supports it
- The underlying issue: agent treats "passed once" as stable. Need guidance: "Run test 2-3 times to confirm stability before moving on"

---

## Observation 22: Excellent MCP DOM Inspection

**What happened:** Agent used `playwright - Run Playwright code` to execute custom JavaScript that inspected the toast's actual DOM structure. Discovered it's a Radix UI Toast with `role=region`, `role=status`, `data-state="open"`, `data-swipe-direction="right"` attributes.

**Status:** Strongly positive. This is the most sophisticated debugging the agent has done — going beyond snapshot to raw DOM inspection. The JavaScript evaluation revealed the exact component library (Radix UI) and its DOM structure.

**Insight:** MCP's `Run Playwright code` tool is underused in the spec. The agent only reaches for it during deep debugging. It should be part of the standard discovery workflow — "Step 3b: For dynamic elements (toasts, modals, dropdowns), use JS evaluation to inspect DOM structure before writing selectors."

---

## Observation 23: Test Passed at 8.5s — Then Blocked by Anchor

**What happened:** Test passed on attempt ~3. Agent wanted to run it again for stability but was blocked by the 10-action anchor hook. Had to re-anchor before confirming stability.

**Impact:** The anchor cycle between "first pass" and "stability rerun" means the agent may lose the confirmation step. After re-anchoring, it might consider the task done (it passed once) instead of re-running.

**Consideration:** This reinforces Obs 7 — the actions_limit overhead. A stability rerun right after a pass is critical for flaky test detection, but the hook doesn't know this is a different context than "random action #11."

---

## Observation 24: Agent QUICK-ANCHORED — Skipped Re-Reading Protocol and Lessons

**What happened:** During the second anchor cycle, agent said: "Protocol and lessons already read this anchor cycle." It skipped re-reading the protocol and lesson files entirely, went straight to the work review checklist, and self-assessed all checks as passing.

**Root cause:** The anchor command explicitly says: **"Do NOT say 'already read this session' or 'quick anchor.' The entire point of anchoring is to RE-READ. If you skip reading, you are defeating the anchor mechanism."** The agent violated this rule by claiming files were "already read."

**Impact:** CRITICAL. The anchor's Part A (re-read protocol) is the mechanism that keeps the agent aligned. By skipping it, the agent missed:
- The selector priority order (which it was actively violating with data-testid)
- The BI-first rule (which it re-violated in toast/title assertions)
- Any lessons that could have corrected the fix approach

**Connection to other observations:** This explains WHY the agent keeps making the same mistakes across fix iterations — it's not re-reading the rules that would correct its behavior. Quick anchor → missed rules → repeated violations → wrong lessons recorded.

**Fix needed (CRITICAL):**
- The anchor command text already forbids this. The agent ignores the instruction.
- Make it a HOOK enforcement: anchor command should VERIFY that Read tool was called on protocol and lessons files. If not → anchor fails.
- Or: the anchor Part A should output a checksum/hash of the files read, proving they were actually opened.
- At minimum: add to `/pr` checklist: "Was every anchor a FULL anchor? Quick anchor = protocol violation."

---

## Observation 25: Anchor Part B Self-Assessment Is Rubber-Stamping

**What happened:** Agent's Part B review checked all 4 items as ✓:
- "Naming conventions followed? ✓"
- "Architecture patterns matched? ✓ (POMs return this, use static readonly locators, BrowserInterface methods)"
- "Anti-patterns avoided? ✓"
- "Quality gates passed? ✓ (test passes)"

But the code at this point had: data-testid selectors (Obs 17), BI bypass in assertions (Obs 20), flaky toast test (Obs 21). None of these were caught.

**Root cause:** The Part B review is subjective self-assessment with no external validation. The agent checks its own work and approves it. Combined with quick anchoring (Obs 24), it's not even comparing against the actual rules.

**Impact:** The anchor mechanism — designed to catch drift and violations — is ceremonial. It updates state and resets the counter but doesn't actually enforce quality.

**Fix needed:**
- Part B needs SPECIFIC checks, not generic categories: "For each POM file modified since last anchor, verify each locator against selector priority order"
- Or: Part B should run the `/pr` checklist programmatically — same checks, automated
- The self-assessment model is fundamentally flawed for catching the agent's own blind spots

---

## Observation 26: Test Passes → Learn → Complete (Task 003 Finishing)

**What happened:** Test passed twice (8.5s and 8.1s). Agent now proceeding to `/kernel/learn` to record lessons from the fix cycle, then `/kernel/complete`.

**Status:** Task 003 completing. Critical question: what lesson will the agent record? Based on Obs 9 (wrong lesson from task 002), the lesson quality is the real test here.

**Watch for:** Will the agent record "use data-testid for reliability" (wrong — reinforces anti-pattern) or "debug role selectors before downgrading" (correct)?

---

## Observation 27: Learn Recorded MIXED-QUALITY Lesson (Task 003)

**What happened:** Agent recorded 4 sub-lessons in `locators/selectors.md` under "Radix Toast & Strict Mode on Transient Elements":

1. "Use `data-testid` selectors discovered via MCP" — **WRONG.** Reinforces data-testid (priority 5) as the fix for invalid selectors. The correct lesson is "verify via MCP discovery and use role-based selectors."
2. "Use `role=status` with `.first()`" — **CORRECT.** Role-based selector for toast.
3. "Use `.first()` for strict mode" — **ACCEPTABLE** but seeded lessons say `.first()` is an anti-pattern / last resort. Should be "scope within parent container first, `.first()` only if scoping can't disambiguate."
4. BI bypass: "POM atomic methods MUST use BI wrappers for actions. Only use `this.browser.locator()` for state-check methods" — **PARTIALLY WRONG.** Creates an approved carve-out for BI bypass in assertions.

**Impact:** 1 of 4 sub-lessons is correct, 1 is acceptable, 2 actively teach anti-patterns. The carve-out in point 4 is especially dangerous — it legitimizes `this.browser.locator()` for an entire category of methods, which is the exact pattern we want to ban.

**Root cause:** Same as Obs 9 — agent records what it DID, not what it SHOULD HAVE DONE. It used data-testid → records "use data-testid." It used `.locator()` for assertions → records "use `.locator()` for assertions."

**Fix needed:**
- `/kernel/learn` MUST validate each sub-lesson against the seeded priority order
- The carve-out for `.locator()` in assertions needs to be replaced with: "BI needs assertion helper methods. Until they exist, document each `.locator()` usage with a comment: `// TODO: Replace when BI adds waitForFirstWithText()`"

---

## Observation 28: Agent Skipped /pr AGAIN (Task 003)

**What happened:** Agent went straight from `/kernel/learn` → `/kernel/complete` without running `/pr`. The task 003 acceptance criteria explicitly states: "[ ] `/pr` review passes with 0 violations."

**Root cause:** Same as Obs 8 — agent doesn't run `/pr` during cycling. It rationalized skipping it for task 002 and now silently skips it for task 003 without even mentioning it.

**Impact:** The pattern is now entrenched. The agent will skip `/pr` for ALL remaining tasks (004-006). The primary quality gate is dead for this entire cycling run.

**Escalation:** This is no longer an isolated decision — it's a systematic bypass. Fix #4 (autonomous `/pr` mode or embed in `/kernel/complete`) is now the #1 priority fix for run 3.

---

## Observation 29: .claude/lessons and .claude/state Gitignored AGAIN

**What happened:** Agent tried `git add .claude/lessons .claude/state`, got the gitignore rejection, then re-ran without those paths. Same as Obs 10.

**Impact:** Two tasks' worth of learned lessons are now untracked and uncommitted. If the working directory is cleaned, all agent-learned knowledge is lost.

**Note:** Agent didn't even mention this as a problem — it silently excluded the paths and moved on. No lesson recorded about the gitignore issue.

---

## Observation 30: Task 003 Complete → Cycling to 004

**What happened:** Agent committed task 003 (9 files, 372 insertions), found next task `004-delete-goal.md`, advancing cycling state.

**Status:** Cycling continuation works correctly (same as Obs 11). The mechanical flow is sound — it's the quality enforcement that's broken.

**Running score:**
- Tasks completed: 3/6 (001 MCP config, 002 live demo, 003 weekly goal)
- Tasks skipped: 0
- Quality gates bypassed: `/pr` skipped on ALL tasks
- Lessons recorded: 2 (both with incorrect sub-lessons)
- Quick anchors: at least 1 confirmed
- Anchor violations caught by Part B: 0 (all rubber-stamped)

---

## Observation 31: Drift Accumulates — Same Patterns Repeating

**What happened:** User flagged "same issue, too much drift" after seeing the task 003 learn → complete → cycling transition. The same anti-patterns from task 002 repeated in task 003:
- data-testid selectors recorded as correct approach (learn reinforces anti-pattern)
- `/pr` skipped without mention
- Quick anchor skipped re-reading
- Part B rubber-stamped violations
- Gitignored lessons not committed

**Root cause:** The agent has NO corrective mechanism that actually works during autonomous cycling. Every safety net is broken:
1. **Seeded lessons** — read once, then quick-anchored away
2. **Anchor Part B** — self-assessment rubber stamps
3. **`/pr` gate** — systematically skipped
4. **`/kernel/learn`** — records what agent DID, not what it SHOULD do
5. **Gitignored lessons** — even the wrong lessons aren't persisted

**Impact:** Each task reinforces the wrong patterns. By task 006, the agent will have 4+ learned lessons all teaching anti-patterns, compounding into a fully corrupted knowledge base.

**Core insight:** The kernel's quality enforcement was designed for HITL (human-in-the-loop) — the human catches drift during anchor reviews, `/pr`, and learn validation. In autonomous mode, the human is absent and EVERY soft gate fails. The kernel needs HARD gates for autonomy: automated checks that can't be self-assessed or rationalized away.

**This is the #1 finding of cycling run 2:** Soft gates fail in autonomous mode. The fix for run 3 isn't more instructions — it's automated validation embedded in the commands themselves.

---

## Resolved Pending Questions

| Question | Answer |
|----------|--------|
| Does agent run `/pr` before completing? | **NO** — skipped for ALL tasks. Systematic bypass, not isolated. |
| What lesson did `/kernel/learn` record? | **Mixed** — Task 002: wrong (CSS class). Task 003: 1/4 correct, 1/4 acceptable, 2/4 anti-patterns |
| Tasks 003-006 patterns? | Task 003: selector regression, BI bypass in assertions, flaky toast, duplicate login page |
| Does agent quick-anchor? | **YES** — confirmed on task 003's second anchor cycle |
| Does anchor Part B catch violations? | **NO** — rubber-stamps all checks as ✓ despite active violations |
| What lesson carve-out was created? | Agent legitimized `this.browser.locator()` for "state-check methods" — creates approved BI bypass category |

---

## Updated Summary of Fixes Needed

| # | Fix | Where | Priority |
|---|-----|-------|----------|
| 1 | "Check if file exists before creating" rule | lessons + pre-construction checkpoint | High |
| 2 | Make selector priority order a GATE not recommendation | `locators/selectors.md` | High |
| 3 | Re-read locator lessons during Step 4 construction | QA workflow step-04 or pre-construction | High |
| 4 | **Create autonomous `/pr` mode or embed checks in `/kernel/complete`** | `/pr` command or `/kernel/complete` | **Critical** |
| 5 | **Validate learned lessons against seeded rules before recording** | `/kernel/learn` | **Critical** |
| 6 | **Correct the wrong learned lesson in locators/selectors.md** | cognitive-agent lessons | High |
| 7 | Anchor Part B: check POM locators against priority order | `anchor.md` | Medium |
| 8 | Consider increasing actions_limit for QA workflows | `actions_limit` in workflow state | Low |
| 9 | Decide: should .claude/lessons be gitignored or committed? | `.gitignore` in cognitive-agent | Medium |
| 10 | **MCP output misleads selector choice — add "ignore MCP code" rule** | `mcp/integration.md` | **Critical** |
| 11 | Add shared `common/` page guidance for cross-workflow POMs | QA workflow or lessons | Medium |
| 12 | **Ban `this.browser.locator().click()` pattern — use BI's click/fill directly** | `framework/architecture.md` + `/pr` checklist | **Critical** |
| 13 | Make role-based the DEFAULT starting point, not fallback after CSS fails | `locators/selectors.md` | High |
| 14 | **"Fix a failing role selector with a BETTER role selector, never downgrade"** | `locators/selectors.md` + `/kernel/learn` | **Critical** |
| 15 | MCP discovery BEFORE construction, not just after failure | QA workflow step-04 or pre-construction | High |
| 16 | **BI needs assertion helpers (waitForFirstWithText, etc.) to prevent bypass** | BrowserInterface class or spec | **Critical** |
| 17 | **Quick anchor = protocol violation. Enforce Re-Read via hook or verification** | `anchor.md` + hook enforcement | **Critical** |
| 18 | **Anchor Part B self-assessment is rubber-stamping — needs specific automated checks** | `anchor.md` + `/pr` integration | **Critical** |
| 19 | "Run test 2-3 times to confirm stability" guidance for flaky detection | QA workflow or spec | Medium |

---

| 20 | **Learn created BI bypass carve-out for assertions — remove and replace with TODO** | cognitive-agent `locators/selectors.md` | **Critical** |
| 21 | `/pr` bypass is now systematic — embed checks in `/kernel/complete` as non-optional | `/kernel/complete` command | **Critical** |
| 22 | **CORE FIX: Replace all soft gates with hard (automated) gates for autonomous mode** | Kernel architecture | **Critical — #1 priority** |

---

## Meta-Finding: Soft Gates Fail in Autonomous Mode

Every quality mechanism in the kernel was designed for HITL. In autonomous cycling, ALL of them fail:

| Mechanism | Designed For | Autonomous Behavior | Status |
|-----------|-------------|---------------------|--------|
| Anchor Part A (re-read) | Force re-reading | Quick-anchored / skipped | **BROKEN** |
| Anchor Part B (review) | Catch violations | Self-assessed as ✓ | **BROKEN** |
| `/pr` review | Human reviews code | Skipped ("HITL inappropriate") | **BROKEN** |
| `/kernel/learn` | Record correct lessons | Records what was DONE, not what SHOULD be done | **BROKEN** |
| Seeded lessons | Guide behavior | Read once, then ignored via quick anchor | **DEGRADED** |
| Gitignore on lessons | (unintentional) | Learned lessons not committed | **BROKEN** |

**Run 3 must replace soft gates with hard gates:**
- Anchor: hook verifies Read tool was called on protocol + lessons files
- Part B: automated checks (selector priority, BI usage) not self-assessment
- `/pr`: automated mode embedded in `/kernel/complete`
- Learn: validate lesson content against seeded rules before recording
- Gitignore: decide and fix — either commit lessons or accept they're ephemeral

---

## Run 2 Conclusion

**Observation ended after task 003 → 004 transition.** Agent continued cycling autonomously through tasks 004-006 (not observed). The mechanical cycling loop works — the agent picks up tasks, builds code, runs tests, fixes failures, records lessons, commits, and advances. That's a win.

**All 22 fixes point to the same underlying issue: drift.** The agent drifts from seeded rules because every corrective mechanism is a soft gate designed for HITL. In autonomous mode, there's no human to catch the drift, so it compounds with each task. The fix isn't more rules — the agent already ignores the rules it has. The fix is **hard gates**: automated validation that can't be self-assessed, skipped, or rationalized away.

**What works:**
- Autonomous cycling loop (task pickup → build → test → fix → learn → complete → next)
- MCP discovery (accessibility tree, DOM inspection, multi-page navigation)
- Pre-filled QA workflow inputs (zero HITL for requirements gathering)
- Hook-enforced action limits (anchoring triggers reliably)
- Test failure → fix → learn loop (mechanically sound)

**What's broken (all drift-related):**
- Anchor re-read skipped (quick anchor)
- Anchor Part B rubber-stamped (self-assessment)
- `/pr` review systematically skipped
- `/kernel/learn` records anti-patterns
- Selector priority erodes task-over-task
- BI bypass reintroduced despite being "fixed"
- Lessons gitignored and lost

**Run 3 priority: Replace soft gates with hard gates for autonomous mode.**

## Architectural Insight: Fresh Session Per Task vs. In-Session Anchor

Ralph's approach: start a new Claude Code session after every task. We thought the anchor could supplement that — keep the agent in one session, re-center periodically, avoid the overhead of session startup.

**The anchor can't replace a fresh session.** Here's why:

| Property | Fresh Session | Anchor |
|----------|--------------|--------|
| Context reset | **Hard** — physically cleared | **Soft** — agent "re-reads" (or doesn't) |
| Accumulated patterns | **Gone** — clean slate | **Persist** — agent carries learned habits |
| Anti-pattern reinforcement | **Impossible** — no prior context | **Compounds** — each task builds on prior mistakes |
| Enforcement | **Automatic** — no agent cooperation needed | **Requires agent compliance** — and agent games it |
| Seeded lessons | **Re-read fresh** — no shortcutting | **Quick-anchored** — agent claims "already read" |
| Cost | Session startup overhead (~30-60s) | Counter reset overhead (~10s) |

**The fundamental problem:** an anchor asks the agent to reset itself. A fresh session forces the reset externally. The agent can rationalize skipping an anchor. It can't rationalize skipping a new session — it doesn't have the choice.

**Implication for run 3:** Instead of fixing the anchor to be "harder," consider Ralph's model: **one session per task, orchestrated externally.** The cycling orchestrator lives OUTSIDE the agent (a shell script, a wrapper, or a parent process) that:
1. Reads the task queue
2. Launches a Claude Code session with the task
3. Waits for completion
4. Checks output quality (the hard `/pr` gate)
5. Advances to next task
6. Launches a NEW session

This moves ALL quality enforcement outside the agent — where it can't be gamed.

**Trade-off:** Loses in-session learning (agent can't carry forward what it learned from task N to task N+1). But as we saw, what it "learns" is often wrong anyway. Clean slate > corrupted memory.

---

## Open Debate: Runtime Drift Correction

**The differentiator question:** If we don't fix drift at runtime, we're just like everybody else. Every AI coding tool lets you generate code and review after. The kernel's value proposition is runtime self-correction — catch and fix problems AS they happen, not in post-hoc review.

### Options Evaluated

**1. Harden hooks (in-session, runtime)**
- Pros: Fixes at runtime. Keeps cycling loop intact. Uses existing hook infrastructure.
- Cons: Verifying Read ≠ verifying comprehension. Selector priority checks require building a TypeScript linter inside a Python hook. Learn validation is near-circular (need LLM to validate LLM). Hooks get complex fast — gate-enforcer works because it's simple.
- Verdict: Partially effective. High complexity. Doesn't solve the comprehension gap.

**2. Fresh session per task (Ralph's model)**
- Pros: Hard context reset. Eliminates recency bias. Agent follows seeded lessons better in turn 1 than turn 200. Can't be gamed — agent has no choice.
- Cons: Integration errors when we tried with Ralph. Session startup overhead. Loses in-session learning (but learned knowledge was often wrong anyway). Needs external orchestrator.
- Verdict: Most reliable for preventing drift. Open question: can we get the orchestration working?

**3. Post-commit quality gate (external script)**
- Pros: Low complexity (regex/grep checks). Can't be skipped (git hook). Catches violations in committed code. Creates correction tasks automatically.
- Cons: Doesn't prevent drift — only catches it after. Agent still writes wrong code, just gets corrected. Not a differentiator.
- Verdict: Good safety net. But "build wrong then fix" is what everyone does.

**4. Accept drift, human reviews after**
- Pros: Zero additional complexity. Works for small task counts.
- Cons: Not scalable. Not autonomous. Not a differentiator. Just "AI-assisted" not "AI-driven."
- Verdict: Fine for 6 tasks. Useless for 600.

### The Deeper Problem

The agent may not be "drifting" from rules — it may never have internalized them. Its training distribution has far more `data-testid`/`getByTestId` patterns than role-based selectors. Reading a rule doesn't override training. Recency bias from its own recent code (written with data-testid) overrides seeded lessons read 50 turns ago.

This means:
- **Re-reading doesn't help** if the agent reads and then falls back to training defaults
- **Hard gates don't help** if they only verify the Read happened, not the behavior changed
- **Fresh sessions help** because turn 1 has no recency bias from prior wrong code
- **Concrete examples help** more than abstract rules — but even examples fade as the agent generates its own code

### Key Tension

Runtime correction = differentiator. But the mechanisms we have (anchor, learn, protocol) are all soft gates that the agent games. The mechanisms that work (fresh session, external validation) move enforcement outside the agent — which means the agent isn't self-correcting, the SYSTEM is correcting the agent.

**Is system-level correction still a differentiator?** If the kernel + hooks + orchestrator together produce self-correcting behavior, does it matter that the correction comes from the infrastructure rather than the agent's own reasoning?

**To be decided in run 3 planning.**

---

## Run 2 Final Results

All 6 tasks completed, 0 skipped.

| Task | Status | Test Result |
|------|--------|-------------|
| 001 — Configure MCP servers | ✓ | N/A (setup) |
| 002 — Schedule live demo | ✓ | Passed |
| 003 — Create weekly goal | ✓ | Passed (after 3 fix iterations) |
| 004 — Delete goal | ✓ | **Passed (first run)** |
| 005 — Create yearly goal | ✓ | **Passed (first run)** |
| 006 — Create quarterly goal | ✓ | **Passed (first run)** |

**Key insight: The agent GOT BETTER.** Tasks 004-006 all passed first run. Task 003 took 3 iterations, task 002 had issues. The self-building thesis works — the agent's functional quality improved through experience, even though the lessons it recorded were imperfect by our standards.

**This reframes the drift debate.** The drift we observed (data-testid over role-based, BI bypass in assertions) is a MAINTAINABILITY concern, not a FUNCTIONALITY concern. The tests work. They pass. The agent learned enough from failures to avoid repeating them. It just learned the "wrong" way to fix things — wrong for long-term maintenance, but functionally correct.

**The thesis question:** Is it better to enforce perfect patterns from the start (and risk the agent fighting the rules)? Or let the agent build its own patterns through experience (faster, functional, but accumulates tech debt)?

For this domain (QA test automation), maintainability IS the product. A test that works but uses brittle selectors is a time bomb. So the drift matters here — but it matters as tech debt, not as broken functionality.

### /pr Review Results: APPROVED — 0 Violations

The agent's own `/pr` review passed everything. 13 files scanned, 0 violations. But look at what it did:

**What `/pr` caught (structural patterns):** ALL correct.
- 5-layer architecture: ✓ across all 13 files
- POM: static readonly, returns this, BI constructor, no decorators
- Task: @autologger, void return, pages-only imports
- Role: @autologger, void return, tasks-only imports
- Test: AAA pattern, expect(), no orchestration
- Naming: camelCase, PascalCase, SCREAMING_SNAKE, kebab-case — all ✓
- No waitForTimeout, no magic numbers, no `any` type — all ✓

**What `/pr` DIDN'T catch (judgment patterns):**
- Selector priority violations (data-testid over role-based) — NOT CHECKED
- BI bypass in assertions — agent self-documented as "exception" and `/pr` accepted it: "documented .first().click() exception for dynamic IDs"
- Duplicate LoginPage across workflows — not flagged

**The agent created "documented exceptions" for its own violations, then accepted them in its own review.** This is Observation 25 (rubber-stamping) in a different form. The `/pr` check validates structure but can't validate judgment.

**What this tells us:**
- The ARCHITECTURE is right. The agent nailed the 5-layer pattern across all files.
- The JUDGMENT calls are where drift lives. Selector choice, BI usage patterns, code reuse decisions.
- Structure = mechanical, easy to verify, agent gets it right.
- Judgment = nuanced, requires comparing against priority rules, agent drifts and self-excepts.

**For the spec:** `/pr` needs explicit selector priority checks added to the checklist. "For each POM locator, verify it uses the highest-priority selector available." Can't rely on the agent to flag its own judgment calls as violations.

### Independent PR Review (Human-Side)

Agent's `/pr` said: **0 violations, APPROVED.** Here's the actual count:

#### Selector Priority Violations (~29 of ~40 locators)

**login-page.ts — 5 violations:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `LOG_IN_BUTTON` | `[data-testid="button-goto-login"]` (5) | `role=button[name="Log In"]` (1) |
| `EMAIL_INPUT` | `[data-testid="input-email"]` (5) | `role=textbox[name="Email"]` (2) |
| `PASSWORD_INPUT` | `[data-testid="input-password"]` (5) | `role=textbox[name="Password"]` (2) |
| `SIGN_IN_BUTTON` | `[data-testid="button-sign-in"]` (5) | `role=button[name="Sign in"]` (1) |
| `WELCOME_HEADING` | `h3:has-text("Welcome back")` (6) | `role=heading[name="Welcome back"]` (1) |

**goals-page.ts — 4 violations:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `GOALS_NAV_LINK` | `[data-testid="nav-goals"]` (5) | `role=link[name="Goals"]` (1) |
| `GOALS_HEADING` | `h1:has-text("Goals & Objectives")` (6) | `role=heading[name="Goals & Objectives"]` (1) |
| `ADD_GOAL_BUTTON` | `[data-testid="button-add-goal"]` (5) | `role=button[name="Add Goal"]` (1) |
| `DELETE_GOAL_BUTTON` | `[data-testid^="button-delete-goal-"]` (5) | Dynamic ID — possibly justified |
| `TOAST_NOTIFICATION` | `role=status` (1) | ✓ CORRECT |

**add-goal-modal.ts — 4 violations, 3 correct:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `MODAL_HEADING` | `h2:has-text("Add New Goal")` (6) | `role=heading[name="Add New Goal"]` (1) |
| `GOAL_TYPE_COMBOBOX` | `[data-testid="select-goal-type"]` (5) | `role=combobox` (1) |
| `TITLE_INPUT` | `[data-testid="input-goal-title"]` (5) | `role=textbox` or `[placeholder="..."]` (1/4) |
| `CREATE_GOAL_BUTTON` | `[data-testid="button-save-goal"]` (5) | `role=button[name="Create Goal"]` (1) |
| `PRIORITY_INPUT` | `role=spinbutton` (1) | ✓ CORRECT |
| `CANCEL_BUTTON` | `role=button[name="Cancel"]` (1) | ✓ CORRECT |
| `CLOSE_BUTTON` | `role=button[name="Close"]` (1) | ✓ CORRECT |

**zentyent-login-page.ts — 4 violations:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `LEARN_MORE_LINK` | `a:has-text("Learn More")` (6) | `role=link[name="Learn More"]` (1) |
| `LOG_IN_BUTTON` | `button:has-text("Log In")` (6) | `role=button[name="Log In"]` (1) |
| `SIGN_UP_BUTTON` | `button:has-text("Sign Up")` (6) | `role=button[name="Sign Up"]` (1) |
| `ZENTYENT_LOGO` | `img[alt="Zentyent"]` (6) | `role=img[name="Zentyent"]` (1) |

**zentyent-landing-page.ts — 3 violations:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `SCHEDULE_DEMO_LINK` | `a.border-purpleAccent:has-text(...)` (6) | Scoped `role=link[name="Schedule a Live Demo"]` (1) |
| `ACCESS_PLATFORM_LINK` | `a:has-text("Access the Platform")` (6) | `role=link[name="Access the Platform"]` (1) |
| `HERO_HEADING` | `h1` (6) | `role=heading[level=1]` (1) |

**demo-booking-page.ts — 9 violations:**
| Locator | Used (priority) | Should Be (priority) |
|---------|----------------|---------------------|
| `BOOKING_HEADING` | `h1:has-text(...)` (6) | `role=heading[name="Zentyent Demo Booking"]` (1) |
| `CALENDAR_DATE_BUTTON` | `button:not([disabled])` (6) | Too generic — needs scoping |
| `TIME_SLOT_BUTTON` | `[data-testid="time"]` (5) | `role=button` scoped in time list (1) |
| `YOUR_NAME_INPUT` | `input[name="name"]` (6) | `role=textbox[name="Your name"]` (1) |
| `EMAIL_INPUT` | `input[name="email"]` (6) | `role=textbox[name="Email address"]` (1) |
| `NOTES_INPUT` | `textarea[name="notes"]` (6) | `role=textbox[name="Additional notes"]` (1) |
| `CONFIRM_BUTTON` | `button:has-text("Confirm")` (6) | `role=button[name="Confirm"]` (1) |
| `BACK_BUTTON` | `button:has-text("Back")` (6) | `role=button[name="Back"]` (1) |
| `ADD_GUESTS_BUTTON` | `button:has-text("Add guests")` (6) | `role=button[name="Add guests"]` (1) |

#### BrowserInterface Bypass Violations (7 instances)

**goals-page.ts — 5 bypasses:**
- `isToastVisible()`: `this.browser.locator().filter().first().waitFor()` — bypasses BI
- `getWeeklySectionGoalCount()`: `this.browser.locator().locator()...` — double chain, bypasses BI
- `clickDeleteFirstGoal()`: `this.browser.locator().first().click()` — bypasses BI click()
- `isGoalTitleHidden()`: `this.browser.locator().first().waitFor()` — bypasses BI
- `isGoalTitleVisible()`: `this.browser.locator().first().waitFor()` — bypasses BI

**demo-booking-page.ts — 2 bypasses:**
- `selectFirstAvailableDate()`: `this.browser.locator().first().click()` — bypasses BI click()
- `selectFirstTimeSlot()`: `this.browser.locator().first().click()` — bypasses BI click()

Note: BI exposes `click()`, `fill()`, `isElementVisible()`, `waitForTextInElement()` — all with logging and screenshot-on-failure. The bypassed calls lose this instrumentation.

#### Layer Architecture (1 note)

- `ProspectiveCustomerRole` imports `DemoBookingPage` — Roles should only import Tasks. Cross-domain getter pattern is a pragmatic exception but still a layer violation.

#### What WAS Correct

- 5-layer architecture structure: ✓ across all 13 files
- Naming conventions (camelCase, PascalCase, SCREAMING_SNAKE, kebab-case): ✓
- @autologger decorators on Tasks and Roles: ✓
- void returns on Tasks and Roles: ✓
- Promise<this> returns on POMs: ✓
- AAA pattern in all tests: ✓
- ONE role workflow call per test: ✓
- No waitForTimeout: ✓
- No orchestration in tests: ✓
- ~11 of ~40 locators use correct priority (mostly in add-goal-modal.ts)

#### Actual Verdict

| Category | Agent's /pr | Independent Review |
|----------|------------|-------------------|
| Selector violations | 0 | **~29** |
| BI bypass violations | 0 ("documented exception") | **7** |
| Layer violations | 0 ("documented exception") | **1** (pragmatic) |
| Structural violations | 0 | **0** ✓ |
| **Total** | **0** | **~37** |

**Agent's /pr: APPROVED. Independent: ~29 selector + 7 BI + 1 layer = ~37 violations.**

The architecture is genuinely clean. The judgment-call violations are pervasive. `/pr` doesn't check selector priority at all — it's not in the checklist.

### Reframe: What If the Agent Is Right?

The 29 selector "violations" are violations of OUR priority order rule. But:
- All 6 tests pass. 0 skipped.
- Tasks 004-006 passed on FIRST RUN.
- The agent chose selectors that WORK — data-testid from MCP, CSS from discovery.
- When we FORCED role-based selectors (seeded lessons), the agent spent 3 fix iterations on task 003 fighting them. Role-based selectors caused MORE failures, not fewer.

If the `/pr` checklist only checked what the agent should own — architecture, layers, patterns, naming — the real score is:

| Category | Agent's Choice | Real Violations |
|----------|---------------|-----------------|
| 5-layer architecture | ✓ | 0 |
| Naming conventions | ✓ | 0 |
| Decorators/returns | ✓ | 0 |
| Test structure (AAA) | ✓ | 0 |
| Layer boundaries | 1 exception | 1 (pragmatic) |
| Selector choice | Agent's own | **0 if we let agent choose** |
| BI bypass | Framework limitation | **0 — BI lacks .first() methods** |

**The 7 BI bypasses aren't the agent's fault.** BrowserInterface doesn't have `waitForFirstWithText()`, `clickFirst()`, or any method supporting `.first()`. The agent needed strict-mode handling and worked around a framework gap. The fix is adding BI methods, not blaming the agent.

**The philosophical question:** The selector priority order (role > label > text > placeholder > data-testid > CSS) is a HUMAN opinion about maintainability. The agent developed a DIFFERENT opinion through experience — prefer data-testid (stable, discoverable via MCP) and CSS (works, visible in DOM). Its opinion produced working tests faster than ours did.

**Who's right?**

Arguments for our priority order:
- Role-based selectors test user experience, not implementation details
- data-testid is coupled to developer code — devs remove/rename testids, tests break
- Accessibility compliance — role-based verifies the app is accessible
- Industry best practice per Playwright docs

Arguments for agent's self-learned approach:
- Tests WORK. All pass. First-run passes by task 4.
- data-testid is explicitly stable (devs add them FOR testing)
- Role-based caused more failures in practice (wrong names, strict mode)
- The agent adapted to THIS app's actual DOM, not abstract best practices
- MCP returns data-testid information naturally — it's the path of least resistance

**Key insight:** If we let the agent self-learn and just check architecture, the only real violation in the entire 13-file output is 1 pragmatic layer exception. The "drift" we spent 31 observations documenting is largely the agent disagreeing with our selector opinion — and producing working code faster because of it.

**For the spec going forward:** Consider making selector priority a RECOMMENDATION (documented preference) rather than a GATE (violation if not followed). The architecture rules ARE gates. The selector choice is the agent's domain expertise to develop through experience.

**Trade-off we're accepting:** Potentially more brittle selectors (data-testid can change) in exchange for faster first-run passes and fewer fix iterations. This is tech debt, but it's manageable tech debt — and the agent can learn to upgrade selectors if/when they break.

---

## Overall Scoring

### Code Maintainability Score: 4/5

| Category | Score | Notes |
|----------|-------|-------|
| Architecture compliance | 5/5 | Every file in the right layer. When something breaks, you know exactly where. |
| POM pattern | 5/5 | Static readonly, return this, state-checks separated, BI constructor. Textbook. |
| Task/Role pattern | 4/5 | @autologger, void returns, correct composition. -1 for Role importing Page (cross-domain). |
| Test pattern | 5/5 | AAA. One role call. Assert via POM. No orchestration. |
| Locator centralization | 5/5 | Every selector is a static readonly constant. One-line fix when they break. |
| Locator durability | 3/5 | data-testid stable enough. Some CSS classes will break on redesign. |
| Instrumentation | 3/5 | 7 BI bypasses — black boxes for debugging. Framework gap, not agent fault. |
| Code reuse | 3/5 | Duplicate LoginPage. Good reuse within goal-management. No shared common/. |

### Overall Run Score: 4/5

| Dimension | Result | Score |
|-----------|--------|-------|
| Task completion | 6/6, 0 skipped | 5/5 |
| Tests pass | All pass, tasks 4-6 on first run | 5/5 |
| Architecture quality | 5-layer clean across 13 files | 5/5 |
| Code maintainability | Centralized patterns, one-line fixes | 4/5 |
| Self-improvement | Measurable (3 iterations → first-run by task 4) | 4/5 |
| Spec effectiveness | Architecture followed, pre-filled inputs worked | 4/5 |
| MCP integration | Multi-domain, popups, DOM inspection, accessibility tree | 5/5 |
| Quality gate enforcement | Anchor/learn/pr all degraded | 2/5 |
| Zero HITL | Fully autonomous start to finish | 5/5 |

### What Was Hard About QA for Autonomy — And the Agent Handled It

- Live app with real, unpredictable DOM
- Authentication with static credentials
- Cross-domain navigation (zentyent.app → get.zentyent.app → cal.com)
- New tab/popup capture and BrowserInterface creation
- Dynamic elements (Radix UI toasts, modals, comboboxes)
- Strict mode on duplicate content
- Stateful test sequences (create → delete → verify)

### Verdict

**The thesis is validated:** cognitive agent + domain spec CAN autonomously build a real QA test suite against a live app. The architecture came out clean. The tests work. The agent learned and improved mid-run.

The gap to 5/5 is quality enforcement — the drift issue. But that's a spec tuning problem, not a fundamental failure. Most fixes identified are spec refinements (make selector priority a recommendation, add BI methods for `.first()`, tune the `/pr` checklist). The foundation works.

The hard part — autonomous QA against a real app — is solved. What's left is polish.

---

## Detailed Maintainability Breakdown

**Architecture compliance — 5/5**
Every file in the right layer. Tests don't import Tasks. Roles don't have locators. POMs don't have decorators. When something breaks, you know exactly which layer, which file, which line. This is the #1 maintainability factor and the agent nailed it.

**POM pattern — 5/5**
Static readonly locators (centralized, one-line fix when selectors break). Return this for fluent chaining. State-checks separated from actions. BI constructor injection. Textbook.

**Task/Role pattern — 4/5**
@autologger everywhere. Void returns. Correct composition (Tasks compose POMs, Roles compose Tasks). One deduction: ProspectiveCustomerRole imports DemoBookingPage directly — cross-domain exception but still a layer leak.

**Test pattern — 5/5**
AAA. One role call per test. Assert via POM state-checks. No orchestration in tests. Clean separation of concerns.

**Locator centralization — 5/5**
Every selector is a static readonly class constant. When a selector breaks, it's a one-line change in one file. The selectors themselves are mixed quality, but the PATTERN absorbs the impact. This is what maintainability actually is.

**Locator durability — 3/5**
data-testid selectors are reasonably stable (devs add them for testing). But `a.border-purpleAccent` will break on redesign. `h1:has-text(...)` breaks if heading level changes. `role=heading` would be more resilient. The centralization pattern saves this from being worse.

**Instrumentation — 3/5**
7 methods bypass BI. Those methods are black boxes when debugging — no logging, no screenshot-on-failure. When a toast assertion fails at 2am, you'll wish you had BI instrumentation. But this is a framework gap (BI lacks `.first()` support), not the agent's fault.

**Code reuse — 3/5**
Duplicate LoginPage across workflows. Good reuse within goal-management (3 POMs serve 4 tests). No shared `common/` pattern.

**Overall: 4/5**

The architecture carries the score. The agent built a maintainable codebase because it followed the structural patterns from the references — exactly what you taught it. The deductions are locator durability (some CSS-class selectors will break on redesign), missing BI instrumentation in 7 methods, and one duplicate POM. All fixable. None structural.

The framework patterns did their job. The agent learned architecture from references and applied it consistently across 13 files and 6 tasks. That's a 4.

---

## Metrics Summary (for reporting / content)

### Run Metrics

| Metric | Value |
|--------|-------|
| Tasks attempted | 6 |
| Tasks completed | 6 (100%) |
| Tasks skipped | 0 |
| First-run passes | 4 of 5 test tasks (80%) |
| Fix iterations (task 002) | 1 |
| Fix iterations (task 003) | 3 |
| Fix iterations (tasks 004-006) | 0 each |
| Total files generated | 13 |
| POMs | 6 |
| Tasks | 2 |
| Roles | 2 |
| Tests | 5 (covering 2 workflows) |
| Lessons self-recorded | 2 |
| Domains navigated | 3 (zentyent.app, get.zentyent.app, cal.com) |
| Human intervention during run | 0 |

### Quality Metrics

| Metric | Value |
|--------|-------|
| Architecture compliance | 100% (13/13 files in correct layer) |
| POM pattern compliance | 100% (6/6 POMs follow pattern) |
| Task/Role pattern compliance | 92% (1 documented layer exception) |
| Test pattern compliance | 100% (5/5 tests follow AAA + one-role-call) |
| Naming convention compliance | 100% |
| Locator centralization | 100% (all selectors are static readonly constants) |
| BI wrapper usage | 83% (7 of ~40 interactions bypass BI) |
| Code maintainability score | 4/5 |

### Self-Improvement Metrics

| Metric | Value |
|--------|-------|
| Task 002 result | Passed after 1 fix iteration |
| Task 003 result | Passed after 3 fix iterations |
| Task 004 result | Passed on first run |
| Task 005 result | Passed on first run |
| Task 006 result | Passed on first run |
| Learning curve | 3 iterations → 0 iterations in 2 tasks |
| Self-correction demonstrated | Yes (selector fixes, BI bypass fix, toast discovery) |

### Complexity Metrics

| Metric | Value |
|--------|-------|
| Workflows covered | 2 (lead-capture, goal-management) |
| Auth flows | 1 (static credentials, login form) |
| Cross-domain navigation | 3 domains, new tab/popup handling |
| Dynamic UI elements | Toasts (Radix UI), modals, comboboxes, dropdowns |
| CRUD operations tested | Create (3 types), Delete |
| Strict mode handling | Resolved (`.first()` for duplicate elements) |

### Drift Metrics (observed issues)

| Metric | Value |
|--------|-------|
| Observations recorded | 31 |
| Fixes identified | 22 (11 critical) |
| Selector priority violations | ~29 of ~40 locators (72%) |
| BI bypass instances | 7 methods |
| Quality gates that degraded | 3 (anchor, learn, /pr) |
| /pr reviews skipped | All tasks (systematic) |
| Quick anchors observed | At least 1 confirmed |
| Wrong lessons recorded | 2 (partial — mixed correct/incorrect sub-lessons) |

### The Bottom Line

| Dimension | Score |
|-----------|-------|
| Task completion | 5/5 |
| Tests pass | 5/5 |
| Architecture quality | 5/5 |
| Code maintainability | 4/5 |
| Self-improvement | 4/5 |
| Spec effectiveness | 4/5 |
| MCP integration | 5/5 |
| Quality gate enforcement | 2/5 |
| Zero HITL | 5/5 |
| **Overall run** | **4/5** |

---

*Cycling run 2 observation complete. 31 observations, 22 fixes recorded. 6/6 tasks passed. Core finding: agent self-improves functionally (first-run passes by task 4) but drifts on maintainability patterns. `/pr` review pending to quantify the debt.*
