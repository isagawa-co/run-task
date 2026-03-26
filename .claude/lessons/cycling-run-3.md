# Cycling Run 3 — Observations

**Date:** 2026-03-04
**Repo:** cognitive-agent
**Tasks:** 007-016 (10 new tasks, continuing from 6 completed in run 2)
**Changes tested:** Cheat sheet index + anchor cite-rules step

---

## Key Changes Since Run 2

1. **Cheat sheet index** — `lessons.md` converted from description-based to actionable directives
2. **Anchor step 4: Cite rules** — Agent must list 3-5 cheat sheet rules mapped to current spec
3. **On Test Failure** — Updated to "Retry up to 3 times. Record what you learned."

---

## Raw Output

### Task 007: Create Monthly Goal

**Cycling restart:**
- Agent detected 10 new tasks (007-016), reactivated cycling from 6/16
- Recognized task 007 is identical in structure to 005/006 — reused existing POM infrastructure
- Updated workflow state: cycling: true, current_task: 007, total_tasks: 16, complete: false

**Code generation:**
- Added `createMonthlyGoal(title, description, priority)` task method (10 lines)
- Added `loginAndCreateMonthlyGoal()` role method (14 lines)
- Reused existing POM (goalsPage, addGoalModal) — did NOT recreate files
- Test file write blocked by hook at 10 actions

**Anchor (first of run 3):**
Hook blocked at 11 actions. Agent invoked `/kernel/anchor`.

**CITE-RULES STEP OUTPUT (NEW):**
```
Rules for this spec (task 007 — create monthly goal):
- role=button[name="Submit"] string works through this.browser.click()
  → Use existing role=option[name="Monthly Goals"] for goal type selection
- Toast (Radix): use role=status with .filter({ hasText }).first()
  → Reuse existing isToastVisible() which already follows this pattern
- State-check methods: use .first() when selector could match multiple elements
  → isGoalTitleVisible() already uses .first() — reuse as-is
- AAA pattern: Arrange objects → ONE Role workflow call → POM state-check assertions
  → Test will call loginAndCreateMonthlyGoal() then assert toast + title
- ALL browser interactions go through BrowserInterface
  → Task calls POM methods that use this.browser.fill() / this.browser.click()
```

**Observation 1: Cite-rules step is working.**
Agent cited 5 specific rules from the cheat sheet and mapped each to a concrete decision for this spec.
Not rubber-stamped — each rule connected to a specific POM method, selector pattern, or test structure.
This is the proof-of-read mechanism we designed.

**Observation 2: Agent reusing infrastructure.**
Run 2 problem: agent recreated existing files (observation from cycling-run-2.md).
Run 3: agent recognized "identical structure to 005/006" and reused existing POMs.
Added only new Task method + Role method. No file recreation.

**Observation 3: Part B review engaged.**
Agent reconstructed 11 actions from the log, reviewed each against protocol with specific checks.
Naming: ✓ (camelCase, UPPER_SNAKE, PascalCase). Architecture: ✓ (decorators, void returns).
Anti-patterns: ✓ (no locators in Task/Role). Quality gates: ✓.
More engaged than run 2's rubber-stamp "0 violations."

**Anchor 2 (mid-task 007):**
Hook blocked again at 11 actions before test file could be written. Second anchor produced identical cite-rules output — consistent, not random.

**Test execution:**
- Test file written after anchor cleared
- Test includes rules comment block in file header (new pattern)
- Passed first run: 12.7s
- Stability check passed: 7.1s
- 0 fix iterations — passed on first attempt

**Completion:**
- `/kernel/complete` invoked properly (not skipped like run 2)
- Git commit: `feat: implement create-monthly-goal (task 007)` — 5 files changed, 75 insertions
- Files: GoalManagementTasks, RegisteredUserRole, test-create-monthly-goal.spec.ts
- 0 lessons learned (no failures)

**State management:**
- Both state files updated after completion (dual state — fix from run 2 plan)
- completed_tasks array now includes 007
- current_task advanced to 008
- Session context updated with completion summary + next task requirements

**Observation 4: Complete gate invoked properly.**
Run 2 problem: `/kernel/complete` was possibly skipped for specs 003-005.
Run 3: agent invoked complete as skill, gates checked, git committed, state updated. Working as designed.

**Observation 5: Dual state update working.**
Both `playwright_automation_workflow.json` and `session_state.json` updated after task completion.
This was a run 2 fix — now confirmed working.

**Observation 6: First-run pass rate.**
Task 007 passed first run — same improvement curve from run 2 tasks 4-6.
Agent is leveraging accumulated knowledge from 6 prior tasks.

---

### Task 008: Create Weekly Goal (Full Form)

**Approach:**
Agent recognized task 008 adds description+priority to existing weekly goal flow (task 003 only had title).
Instead of creating a new method, extended existing `createWeeklyGoal(title)` with optional params:
`createWeeklyGoal(title, description?, priority?)` — backward compatible with task 003's test.

**Code changes:**
- `goal-management-tasks.ts`: Added `description?: string, priority?: number` optional params with conditional calls
- `registered-user-role.ts`: Same optional params passed through to task method
- New test file: `test-create-weekly-goal-full.spec.ts` (separate from 003's test)

**Backward compatibility check:**
Agent ran BOTH tests in parallel: task 003's original test AND task 008's new test.
Both passed in 8.8s. Explicit backward compatibility verification.

**Observation 7: Agent extended existing code instead of duplicating.**
Run 2: agent recreated files. Run 3: agent extended `createWeeklyGoal` with optional params.
This is genuine engineering judgment — backward-compatible API extension, not copy-paste.

**Observation 8: Agent tested backward compatibility unprompted.**
Not in the task spec. Agent decided on its own to verify the existing test 003 still passes
after modifying the shared method. Ran both tests in parallel (2 workers, 8.8s).

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement create-weekly-goal-full (task 008)`
- 0 fix iterations — passed first run
- 0 lessons learned

**State management:**
- Edit error on first attempt to update workflow.json (recovered by re-reading + retrying)
- Both state files updated: completed_tasks includes 008, current_task → 009
- Session context updated with completion summary noting backward compatibility

---

### Task 009: Create Daily Goal

**Approach:**
Agent recognized "same pattern — Daily Goals type." Noted hook near limit, built quickly.

**Code changes (partial — context compaction hit mid-task):**
- `goal-management-tasks.ts`: Added `createDailyGoal(title, description, priority)` — 10 lines, same pattern as monthly
- Role method and test file: awaiting output (context compacted during task)

**Observation 9: Context compaction recovery — seamless.**
Agent hit context compaction mid-task 009 (after adding Task method, before Role method + test).
On recovery: invoked `/kernel/session-start` → recognized cycling active on task 009 →
forced anchor → cite-rules produced 5 specific rules → noted "createDailyGoal task method already exists.
Need to add Role method and test file" → continued exactly where it left off.
Dual state update from run 2 fixes confirmed: session context preserved `work_in_progress` key
that told the agent what was already done.

**Post-compaction anchor cite-rules:**
```
Rules for this spec (task 009 — Create Daily Goal):
1. "Tests: ONE Role call in Act, POM state-check methods in Assert"
   → single loginAndCreateDailyGoal() call
2. "Layers: Test → Role → Task → POM → BI — never skip a layer"
   → Role → Task → POM chain
3. "Toast (Radix): use role=status with .filter({ hasText }).first()"
   → existing isToastVisible method
4. "Import test from ../fixtures/index"
   → test imports from ../fixtures
5. "POM action methods return Promise<PageClass> and return this"
   → fluent POM methods
```

**Code changes (post-compaction):**
- `registered-user-role.ts`: Added `loginAndCreateDailyGoal()` — 14 lines, same pattern
- New test file: `test-create-daily-goal.spec.ts`

**Test execution:**
- Passed first run: 8.2s
- Stability check passed
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement create-daily-goal (task 009)` — 2 files changed, 55 insertions
- 0 lessons learned

**Observation 10: State file Write vs Edit after compaction.**
Agent used Write (full overwrite) instead of Edit (merge) for both state files after compaction.
This rewrites all 33 lines. No data lost because it read first, but Edit would be safer for
preserving keys added by other processes. Not a violation — just a pattern difference.

---

### Task 010: Edit Goal

**Approach:**
New workflow — agent recognized it needed MCP discovery for edit button and modal structure.
Used MCP to navigate to goals page, click edit button, inspect modal via JS evaluation.
Key discovery: edit modal reuses same form fields and data-testids as Add Goal modal.

**MCP discovery:**
- Navigated to goals page (session already logged in)
- Clicked edit button on first goal → discovered edit modal
- Used `Evaluate JavaScript` to find all `[data-testid]` elements in dialog
- Found: edit button pattern `[data-testid^="button-edit-goal-"]`, modal reuses `button-save-goal`, `input-goal-title`, etc.
- Closed modal with Escape (ref-based close failed — stale ref after JS eval)

**Code changes:**
- `goals-page.ts`: Added `EDIT_GOAL_BUTTON` static readonly + `clickEditFirstGoal()` method (uses `.first()` — documented exception for dynamic IDs)
- `goal-management-tasks.ts`: Added `editFirstGoal(title, description, priority)` — 9 lines, reuses AddGoalModal
- `registered-user-role.ts`: Added `loginAndEditFirstGoal()` — 14 lines
- New test file: `test-edit-goal.spec.ts`

**Anchor cite-rules (task 010):**
```
Rules for this spec (task 010 — Edit Goal):
1. "Multiple matches? Scope with >> combinator or parent container — .first() is an
   anti-pattern for actions" → clickEditFirstGoal() uses .first() on dynamic IDs
   (same accepted exception as delete — documented with comment)
2. "Layers: Test → Role → Task → POM → BI — never skip a layer"
   → Role → Task → POM chain maintained
3. "Tests: ONE Role call in Act, POM state-check methods in Assert"
   → single loginAndEditFirstGoal() call
4. "MCP is for DISCOVERY only — test code uses BrowserInterface, not MCP tools"
   → used MCP to find edit button testid pattern and edit modal structure
5. "Locators are static readonly UPPER_SNAKE_CASE constants on the POM class"
   → EDIT_GOAL_BUTTON added as static readonly
```

**Observation 11: Agent cited `.first()` exception correctly.**
The cheat sheet says `.first()` is an anti-pattern for actions. Agent acknowledged the rule,
then cited the accepted exception (dynamic IDs like `button-edit-goal-{dbId}`) with documentation.
This is exactly how the exception was handled in run 2's delete task — consistent pattern.

**Observation 12: MCP used for discovery only.**
Agent used MCP to find the edit button pattern and modal structure, then built POM code
using BrowserInterface. No MCP tools in test code. Cited the exact cheat sheet rule for this.

**Observation 13: Agent reused AddGoalModal for edit.**
Discovered that edit modal shares form fields with add modal. Reused existing POM instead of
creating a new EditGoalModal class. Engineering judgment — reduce duplication.

**Test execution:**
- Passed first run: 4.6s
- Stability check passed
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement edit-goal (task 010)` — 4 files changed, 81 insertions
- 0 lessons learned

---

### Task 011: Delete Goal

**Approach:**
Agent recognized task 011 is a duplicate of task 004 — all POM/Task/Role/Test infrastructure
already exists. Ran existing `test-delete-goal.spec.ts` to verify it still passes.

**Code changes:** None — 0 new files.

**Test execution:**
- Ran existing test — passed
- No new code needed

**Observation 14: Agent detected duplicate task and skipped code generation.**
Instead of blindly creating new files, agent checked existing infrastructure, confirmed
the test passes, and completed with 0 files modified. Smart resource allocation.

**Completion:**
- `/kernel/complete` invoked, gates passed
- No git commit (no changes)
- 0 lessons learned

---

### Task 012: Mark Goal Complete

**Approach:**
New workflow — agent recognized it needed MCP discovery for the complete button.
Used MCP to navigate to goals page, used JavaScript evaluation to find complete button pattern,
then clicked it to verify toast behavior and immediate action (no confirmation dialog).

**MCP discovery:**
- Navigated to /goals, waited for page load
- Used `Evaluate JavaScript` with progressive fallback: checked `[data-testid^="button-complete-goal-"]`,
  then alternative patterns, then all goal-related testids
- Found: `[data-testid^="button-complete-goal-"]`
- Clicked complete button via MCP: verified "Goal completed" toast, immediate action (no dialog)
- Discovered Completed tab uses `role=tab[name=/Completed/]`

**Code changes:**
- `goals-page.ts`: Added `COMPLETE_GOAL_BUTTON` + `COMPLETED_TAB` static readonly locators + `clickCompleteFirstGoal()` method
- `goal-management-tasks.ts`: Added `completeFirstGoal()` — 5 lines
- `registered-user-role.ts`: Added `loginAndCompleteFirstGoal()` — 11 lines
- New test file: `test-mark-goal-complete.spec.ts`

**Anchor cite-rules (task 012):**
```
1. ".first() is an anti-pattern for actions" → accepted exception for dynamic complete button IDs (documented)
2. "Locators are static readonly UPPER_SNAKE_CASE" → COMPLETE_GOAL_BUTTON, COMPLETED_TAB added
3. "Tests: ONE Role call in Act" → single loginAndCompleteFirstGoal() call
4. "Toast (Radix): role=status with .filter({ hasText }).first()" → existing isToastVisible handles this
5. "MCP is for DISCOVERY only" → used MCP to discover complete button testid, code uses BI
```

**Observation 15: Consistent cite-rules across all anchors.**
Every anchor in run 3 has produced task-specific cite-rules output. The agent maps
cheat sheet rules to concrete implementation decisions. Not a single rubber-stamp.

**Test execution:**
- Passed first run: 5.4s
- Stability check blocked by hook → anchored → stability passed
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement mark-goal-complete (task 012)` — 4 files changed, 59 insertions
- 0 lessons learned

---

### Task 013: View Completed Goals

**Approach:**
Agent noted it already added `COMPLETED_TAB` locator in task 012. Used MCP to discover the
Completed tab content structure. Clicked "Completed (7)" tab via MCP, found `data-testid="tab-completed"`
and heading "Completed Goals".

**MCP discovery:**
- Navigated to /goals, found "Completed (7)" tab
- Clicked tab → discovered content: `data-testid="tab-completed"`, heading "Completed Goals"
- Updated COMPLETED_TAB locator from `role=tab[name=/Completed/]` to `[data-testid="tab-completed"]`

**Observation 16: Agent self-corrected locator during discovery.**
Originally set COMPLETED_TAB to `role=tab[name=/Completed/]` in task 012 (before clicking it).
After MCP discovery in task 013, updated to `[data-testid="tab-completed"]` — the actual data-testid
found in the DOM. Self-correction from discovery, not from failure.

**Code changes:**
- `goals-page.ts`: Updated `COMPLETED_TAB` locator, added `COMPLETED_GOALS_HEADING`,
  added `clickCompletedTab()` + `isCompletedGoalsHeadingVisible()` methods
- `goal-management-tasks.ts`: Added `viewCompletedGoals()` — 5 lines
- `registered-user-role.ts`: Added `loginAndViewCompletedGoals()` — 11 lines
- New test file: `test-view-completed-goals.spec.ts`

**Anchor cite-rules (task 013):**
```
1. "Locators are static readonly UPPER_SNAKE_CASE" → COMPLETED_TAB, COMPLETED_GOALS_HEADING
2. "Tests: ONE Role call in Act, POM state-check methods in Assert"
   → single loginAndViewCompletedGoals() call
3. "Layers: Test → Role → Task → POM → BI — never skip a layer" → full chain
4. "Import test from ../fixtures/index" → test imports from ../fixtures
```

**Test execution:**
- Passed first run: 4.5s
- Stability check passed
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked — hook blocked at commit → anchored → committed
- Git commit: `feat: implement view-completed-goals (task 013)` — 4 files changed, 66 insertions
- 0 lessons learned

---

### Task 014: View Calendar

**Context compaction hit again** — agent recovered seamlessly via session-start → anchor → continue.

**Anchor cite-rules (task 014):**
```
- MCP is for DISCOVERY only → Discover Calendar tab UI via MCP, build with BI
- role selector format: role=button[name="..."] → Translate calendar elements to role selectors
- Priority order: role > data-testid > CSS → Check for data-testid first, fall back to role
- ONE Role call in Act → loginAndViewCalendar() single workflow call
- State-check methods use .first() → Calendar assertions may need .first()
```

**MCP discovery:**
- Navigated to /goals, found tabs: Overview, Calendar, Completed
- Used JS evaluation to discover all `[role="tab"]` elements with data-testids
- Found: `data-testid="tab-calendar"`
- Clicked Calendar tab → discovered full calendar UI:
  - March 2026 heading, current date selected
  - Navigation: "Go to previous month" / "Go to next month" buttons
  - Right panel: "Goals for Tuesday, March 3, 2026" with goals listed
- Second JS eval on `[role="tabpanel"]` for data-testids → **empty array**
- No data-testids inside calendar panel → agent switching to role-based selectors

**Observation 17: Selector priority correctly applied.**
Calendar panel has no data-testids. Agent's cite-rules said "Priority order: role > data-testid > CSS
→ Check for data-testid first, fall back to role." Agent checked for data-testids via MCP,
found none, then said "I'll use role-based selectors." Priority order followed correctly.

**Observation 18: Second context compaction recovery.**
Agent recovered from compaction a second time — session-start → forced anchor → cite-rules → continue.
State preserved cycling progress (13/16), current task (014), and context. No work lost.

**Code changes:**
- `goals-page.ts`: Added 4 locators (`CALENDAR_TAB`, `CALENDAR_GRID` as `role=grid`,
  `CALENDAR_PREV_MONTH` as `role=button[name="Go to previous month"]`,
  `CALENDAR_NEXT_MONTH` as `role=button[name="Go to next month"]`)
- `goals-page.ts`: Added `clickCalendarTab()`, `isCalendarGridVisible()`,
  `isCalendarNavigationVisible()` (checks both prev+next), `isCurrentDateHighlighted()` (22 lines)
- `goal-management-tasks.ts`: Added `viewCalendar()` — 5 lines
- `registered-user-role.ts`: Added `loginAndViewCalendar()` — 11 lines
- New test file: `test-view-calendar.spec.ts`

**Observation 19: Role-based selectors used for calendar navigation.**
Calendar panel had no data-testids (empty array from MCP). Agent used:
- `role=grid` for the calendar grid
- `role=button[name="Go to previous month"]` and `role=button[name="Go to next month"]`
- `role=gridcell[name="3"]` for current date with aria-selected check
All role-based (priority 1). This is the selector compliance we wanted in run 2.
The cheat sheet directive worked: agent checked for data-testids first, found none, used role-based.

**Observation 20: isCurrentDateHighlighted() uses dynamic date.**
Agent computed `new Date().getDate().toString()` to find today's gridcell,
then checked `aria-selected === 'true'`. Documented `.first()` usage with comment:
"Multiple gridcells may share the same date number (current + adjacent month)."
Self-documenting code matching the cheat sheet rule.

**Test execution:**
- Passed first run: 6.6s
- Stability check passed: 6.3s
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement view-calendar (task 014)` — 4 files changed, 87 insertions
- 0 lessons learned
- Agent detected 17 total tasks (found task 017 we added mid-run)

---

### Task 015: Navigate Calendar Months

**Context:** Third context compaction before this task. Agent recovered seamlessly again.

**Anchor cite-rules (task 015):**
```
- role=button[name="..."] → Calendar nav uses role=button[name="Go to previous month"] / "Go to next month"
- POM action methods return Promise<PageClass> and return this
  → clickNextMonth/clickPreviousMonth must return Promise<GoalsPage>
- Tests: ONE Role call or chained Role calls for intermediate state
  → Test chains navigateCalendarForward/Backward with assertions
- ALL browser interactions through BI → Use this.browser.click() and this.browser.getAttribute()
- Layers: Test → Role → Task → POM → BI — never skip a layer
```

**Code changes:**
- `goals-page.ts`: Added `clickNextMonth()`, `clickPreviousMonth()` — both through BI, return this
- `goals-page.ts`: Added `getCalendarMonthHeading()` — reads `aria-label` from grid element
- `goal-management-tasks.ts`: Added `navigateCalendarNextMonth()`, `navigateCalendarPreviousMonth()` — 10 lines
- `registered-user-role.ts`: Added `navigateCalendarForward()`, `navigateCalendarBackward()` — 12 lines
  (Note: these Role methods don't take credentials — they're chained after loginAndViewCalendar)
- New test file: `test-navigate-calendar-months.spec.ts` — uses chained Role calls with
  intermediate assertions (documented as permitted for intermediate state checks)

**FIRST TEST FAILURE OF RUN 3:**
- `getCalendarMonthHeading()` used `this.browser.getAttribute(GoalsPage.CALENDAR_GRID, 'aria-label')` → returned null
- Grid doesn't have `aria-label` — uses `aria-labelledby="react-day-picker-1"` instead
- Agent used MCP JS evaluation to investigate:
  1. Found grid attributes: `aria-labelledby=react-day-picker-1`, no `aria-label`
  2. Found the labeled element: `<div id="react-day-picker-1">` with text "March 2026"
- Agent debugging to find the correct way to read the month heading

**Observation 21: First failure — proper diagnostic workflow.**
Agent didn't guess a fix. Used MCP JS eval to inspect the grid's attributes, found `aria-labelledby`
instead of `aria-label`, then traced to the referenced element. Methodical debugging via MCP discovery.

**Observation 22: Test noted chained Role calls as permitted exception.**
Test file header explicitly documents: "Uses chained Role calls with intermediate assertions
(permitted for capturing intermediate state between steps)." Agent self-documented the pattern exception.

**Fix:**
- Root cause: Grid uses `aria-labelledby="react-day-picker-1"` not `aria-label`
- The referenced `<div id="react-day-picker-1">` contains the month text "March 2026"
- Fixed `getCalendarMonthHeading()`: reads `aria-labelledby` attribute → then `getText(`#${labelledBy}`)` on the referenced element
- Documented with comment: "Grid uses aria-labelledby to reference the month heading element"

**Observation 23: First failure — 1 fix iteration, methodical debugging.**
Agent didn't guess. Used MCP to inspect grid attributes → found `aria-labelledby` →
traced to `react-day-picker-1` div → fixed the method to follow the `aria-labelledby` relationship.
Only 1 fix iteration needed. Run 2 task 003 took 3 fix iterations for its failures.

**Test execution (after fix):**
- Passed first run: 7.0s
- Stability check passed: 6.5s
- 1 fix iteration total (down from 3 in run 2's first failure)

**`/kernel/learn` invoked (first learn of run 3):**
- Issue: `getAttribute('aria-label')` returned null on calendar grid — expected "March 2026"
- Root cause: MCP snapshot shows grid "March 2026" but accessible name comes from `aria-labelledby`, not `aria-label`
- Fix: Read `aria-labelledby` from grid → `getText(`#${labelledBy}`)` on referenced element
- Lesson file updated + Locators & Selectors reference: added `aria-labelledby` vs `aria-label` verification rule
- Hooks updated: no
- New command created: no

**Observation 24: Learn invoked after first failure — self-enforcement confirmed.**
Agent invoked `/kernel/learn` immediately after fix + passing tests. Didn't skip it.
Lesson recorded to both lessons.md AND reference file (Locators & Selectors section).
Run 1 problem: agent skipped learn when hook didn't fire. Run 3: agent self-invoked learn.

**Observation 25: Learn updated reference file, not just lesson index.**
Agent added `aria-labelledby` vs `aria-label` rule to the Locators & Selectors reference section.
This is the learn command working as designed — codifying patterns for future tasks, not just recording.

**`/kernel/complete` invoked:**
- Gates passed (protocol_created: true, anchored: true)
- Git add: `.claude/lessons` is gitignored → agent excluded it, committed only framework/test files
- Hook blocked at 10 actions during commit → anchored again mid-complete

**Observation 26: Gitignored lessons handled gracefully.**
Agent got "The following paths are ignored by one of your .gitignore files" error for `.claude/lessons`.
Adapted immediately — committed without lessons file. No confusion, no `git add -f`.

**Anchor during complete (task 015):**
- Cite-rules: 3 rules cited (aria-labelledby lesson, POM returns this, layers never skip)
- 11 actions reviewed, 0 violations
- Learn self-enforcement check: test failure occurred, `/kernel/learn` was invoked ✓

**Completion:**
- COMPLETE: 4 files created/modified, 1 lesson learned
- Git commit: successful after anchor cleared hook block
- Next: 016-add-goal-from-calendar.md (15/17 complete, 0 skipped)

### Task 016: Add Goal from Calendar

**MCP discovery:**
- Browser had been reset → navigated fresh, already logged in
- Navigated: Goals → Calendar tab → clicked March 20 → date selected, sidebar updated
- Clicked "Add Goal" in calendar sidebar (`data-testid="button-add-daily-goal"`)
- Modal opened with date pre-populated ("Currently selected: 3/20/2026")
- JS eval confirmed same data-testids as existing AddGoalModal
- Key discovery: calendar "Add Goal" pre-selects "Daily Goals" type — no selectGoalType needed

**Observation 27: MCP discovery flow — systematic and efficient.**
Agent navigated fresh after browser reset, clicked through Calendar → date → Add Goal button,
verified modal structure with JS eval, confirmed testid reuse. Clean 6-step discovery sequence.

**Observation 28: Agent recognized modal reuse from calendar context.**
Same AddGoalModal POM used. Agent explicitly noted: "Modal pre-selects 'Daily Goals' when opened
from calendar — no selectGoalType needed." Understood the UX difference between entry points
and adapted the Task method accordingly.

**Code changes:**
- `goals-page.ts`: Added `CALENDAR_ADD_GOAL_BUTTON` locator (`[data-testid="button-add-daily-goal"]`)
- `goals-page.ts`: Added `clickCalendarDate(day)` — uses `.first()` with comment about adjacent month
- `goals-page.ts`: Added `clickCalendarAddGoal()` — clicks add goal button
- `goal-management-tasks.ts`: Added `addGoalFromCalendar(day, title, description, priority)` — 11 lines
  - Composes GoalsPage (date click + add goal button) then AddGoalModal (title, desc, priority, create)
  - Comment: "Modal pre-selects 'Daily Goals' when opened from calendar — no selectGoalType needed"
- `registered-user-role.ts`: Added `loginAndAddGoalFromCalendar(email, password, day, title, description, priority)` — 16 lines
  - Chains: login → navigateToGoals → viewCalendar → addGoalFromCalendar
- New test file: `test-add-goal-from-calendar.spec.ts`

**Observation 29: `.first()` exception documented again.**
`clickCalendarDate(day)` uses `.first()` on `role=gridcell[name="${day}"]` with comment:
"Adjacent month may show same day number — .first() targets current month."
Consistent with prior `.first()` exception documentation (tasks 010, 012).

**Observation 30: Task method skipped unnecessary step.**
Agent's `addGoalFromCalendar` does NOT call `selectGoalType()` because the calendar entry point
pre-selects "Daily Goals." This isn't just reuse — it's understanding the UI flow and omitting
the step that the calendar already handles. Engineering judgment from MCP discovery.

**Test execution:**
- Passed first run: 7.2s
- Stability check passed: 6.7s
- 0 fix iterations

**Completion:**
- `/kernel/complete` invoked, gates passed
- Git commit: `feat: implement add-goal-from-calendar (task 016)` — 4 files changed
- 0 lessons learned
- Next: 017-create-employee-and-assign-task.md (16/17 complete, 0 skipped)

**State management:**
- Both state files updated (dual state confirmed again)
- Workflow: completed_tasks now includes 016, current_task → 017
- Session context updated: completion summary + next task requires "new workflow domain, Employees + Tasks pages"
- Agent proactively noted task 017 requires entirely new page POMs — forward planning

**Observation 31: Dual state update consistent across all completions.**
Every task completion in run 3 has updated both `playwright_automation_workflow.json` and
`session_state.json`. This pattern is now deeply embedded — no longer needs explicit reminders.
Run 2 fix fully internalized.

Agent now reading task 017 spec — cross-workflow integration test (create employee + assign task).
This is the most complex task of the run: two new pages (/employees and /tasks), two workflows,
new POMs needed.

---

### Task 017: Create Employee and Assign Task

**Context:** Cross-workflow integration test — most complex task of the run. Spans /employees and
/tasks pages, requires new POMs for both, two-phase workflow (create employee → assign task).

**MCP discovery — Employees page:**
- Navigated to `https://zentyent.app/employees` — page loaded
- Found "Create employee" button (`ref=e216`)
- JS eval discovered all data-testids in main element (113+ lines of testids found)
- Proceeding to click Create employee to discover modal structure

**Context compaction #4 — hit during task 017 MCP discovery.**
Agent recovered via session-start → forced anchor → continue.
Preserved partial discovery in session context:
- `task_017_status: "MCP discovery in progress"`
- `task_017_known: "Employees page: button-create-employee, employee-card-{id}, nav-employees pattern"`

**Observation 32: Context compaction recovery #4 — discovery state preserved.**
Agent saved partial MCP discovery progress in session_state.json context before compaction.
On recovery, it knew which testids were already found and what remained (Create Employee modal,
Tasks page, Add Task modal). No redundant re-discovery of the Employees page layout.

**Post-compaction anchor cite-rules (task 017):**
```
- role=button[name="Submit"] format through this.browser.click()
  → New Employees/Tasks pages need role-based locator discovery
- MCP is for DISCOVERY only → Discover employee/task modals via MCP, build POMs with BI calls
- Layers: Test → Role → Task → POM → BI — never skip a layer
  → New domain needs full stack: employees-page POM, tasks-page POM, integration tasks, role, test
- ALL browser interactions go through BrowserInterface
  → New POMs must use this.browser.click(), this.browser.fill(), etc.
- .first() is an anti-pattern for actions, OK for state-checks
  → Employee/task lists may have multiples, scope locators carefully
```

**Observation 33: Cite-rules adapted to cross-domain task.**
Agent cited rules specifically about "new domain" needing "full stack" and "new Employees/Tasks
pages need role-based locator discovery." Rules mapped to the unique challenge of this task —
building POMs for previously-undiscovered pages. Not recycled from prior goal-management anchors.

**MCP discovery — Employees page (continued):**
- Re-navigated to /employees (already logged in)
- Re-ran JS eval for data-testids — found key patterns:
  - `button-create-employee` — Create employee button
  - `employee-card-{id}` — Employee cards
  - `button-menu-{id}` — Employee card menu buttons
  - `nav-employees`, `nav-tasks` — Sidebar links
- Clicked "Create employee" → modal opened

**MCP discovery — Create Employee modal:**
- Modal fields discovered:
  - textbox "Name" (`ref=e673`)
  - combobox "Role" — currently "Developer" (`ref=e675`)
  - textbox "Description" (`ref=e681`)
  - textbox "Capabilities" (`ref=e683`)
  - textbox "System Prompt (Optional)" (`ref=e686`)
  - button "Create Employee" (`ref=e690`)
  - button "Close" (`ref=e691`)
- JS eval for modal data-testids (28+ lines found)

**Create Employee modal data-testids:**
- `input-agent-name` — Name input
- `select-agent-role` — Role dropdown (default: Developer)
- `input-agent-description` — Description textarea
- `input-agent-capabilities` — Capabilities input (comma-separated)
- `input-agent-prompt` — System prompt textarea (optional)
- `button-cancel-create` — Cancel button
- `button-submit-create` — Create Employee button

**Role dropdown options discovered:** Developer (default), Marketing, SEO Specialist,
Maintenance, Designer, Analyst, Custom.

**MCP discovery — Tasks page:**
- Navigated to `https://zentyent.app/tasks`
- Page structure: heading "Tasks", tabs (All/Active/Completed), List/Board views
- "Create Task" button (`ref=e221`)
- JS eval for data-testids:
  - `button-create-task` — Create Task button
  - `task-card-{id}` — Task cards
  - `checkbox-task-{id}` — Task checkboxes
  - `button-run-task-{id}` — Run task buttons
  - `tab-all`, `tab-active`, `tab-completed` — Tabs

**MCP discovery — Create Task modal:**
- Clicked "Create Task" → large modal (12.1k tokens in MCP response)
- Modal fields:
  - textbox "Title" (`ref=e941`)
  - textbox "Description" (`ref=e943`)
  - combobox "Priority" — default "Medium" (`ref=e945`)
  - combobox "Assign to" — "Select an employee (optional)" (`ref=e950`)
  - combobox "Output Destination" — default "Results" (`ref=e955`)
  - checkbox "Run task automatically after creation" — checked by default (`ref=e960`)
  - button "Create Task" (`ref=e964`)
- Modal data-testids:
  - `input-task-title`, `input-task-description`
  - `select-task-priority`, `select-task-assignee`
  - `select-output-destination`, `checkbox-auto-execute`
  - `button-submit-task`

**Observation 34: Thorough two-page MCP discovery before coding.**
Agent discovered BOTH pages (/employees and /tasks) and BOTH modals before writing any code.
Read reference files (existing POMs, BrowserInterface, fixtures) to match patterns.
14 MCP calls total across both pages. Most thorough discovery sequence of the entire run.

**Observation 35: Agent read reference files before building.**
After MCP discovery, agent read 6 files: existing GoalsPage POM, LoginPage POM,
BrowserInterface (available methods), test fixtures, existing Role, existing Task.
Ensured all patterns were fresh before creating new domain files.

**Code generation — 7 files created:**
1. `employees-page.ts` — EmployeesPage POM for /employees
2. `create-employee-modal.ts` — CreateEmployeeModal POM for employee creation dialog
3. `tasks-page.ts` — TasksPage POM for /tasks
4. `create-task-modal.ts` — CreateTaskModal POM for task creation dialog
5. `employee-task-tasks.ts` — EmployeeTaskTasks module composing all 4 POMs
6. `employee-task-manager-role.ts` — EmployeeTaskManagerRole composing tasks
7. `test-create-employee-and-assign-task.spec.ts` — Integration test

All files organized in `employee-task-integration/` subdirectory (new domain — mkdir before writes).
Each file includes rules comment block in header.

**Observation 36: Full 5-layer architecture for new domain.**
Agent created the complete stack: 4 POMs + 1 Task + 1 Role + 1 Test = 7 files.
New directory structure `employee-task-integration/` for each layer. No shortcuts, no layer skipping.
This is the largest single-task code generation of the entire run.

**SECOND TEST FAILURE OF RUN 3:**
- Error: `TimeoutError: locator.click: Timeout 20000ms exceeded waiting for locator('role=option[name="Research Assistant"]')`
- Employee creation succeeded (0.79s) — the employee role dropdown `role=option[name="Analyst"]` worked fine
- Failure was in task assignee dropdown — the assignee options include the role in parentheses:
  `"Research Assistant (analyst)"` not `"Research Assistant"`

**Observation 37: Failure from undiscovered option naming pattern.**
Agent discovered modal data-testids and field structure but didn't open the assignee dropdown
during MCP discovery to check option names. The employee role dropdown had simple names
("Analyst", "Developer") but the task assignee dropdown includes role metadata ("Research Assistant (analyst)").
Different naming convention between two dropdowns on two different pages.

**Debugging approach:**
- Navigated to /tasks, opened Create Task modal
- Clicked "Assign to" dropdown via MCP → discovered option names include role in parentheses
- Root cause clear: exact `role=option[name="..."]` doesn't match when name includes extra context

**Fix applied (1 edit):**
- `create-task-modal.ts`: Changed `selectAssignee` from exact `role=option[name="${assigneeName}"]`
  to `.filter({ hasText: assigneeName }).first().click()`
- Comment: "Assignee options include role in parentheses, e.g., 'Research Assistant (analyst)'"

**Anchor hit at 10 actions during fix:**
- Agent anchored mid-fix, reviewed all 11 actions
- Part B review: noted `.first()` usage in selectAssignee but classified as acceptable
  (all "Research Assistant" entries are equivalent in dropdown)
- Cite-rules: 4 rules cited, specifically addressed `.first()` exception for assignee dropdown
- Learn self-enforcement: test failure occurred, lesson pending verification of fix → correct approach

**Observation 38: Anchor Part B caught potential anti-pattern.**
During mid-fix anchor, Part B review flagged the `.first()` in selectAssignee as potential
anti-pattern violation but reasoned through it: "all 'Research Assistant' entries are equivalent"
and classified as acceptable. Not rubber-stamped — actually engaged with the rule and justified the exception.

**Test re-run after fix:**
- Passed first run: 6.8s
- Stability check passed: 8.3s
- 1 fix iteration (same as task 015 failure)

**`/kernel/learn` invoked (second learn of run 3):**
- Issue: Assignee dropdown option names include role metadata — exact `role=option[name="..."]` failed
- Root cause: Task assignee options format is "Name (role)" not just "Name"
- Fix: Use `.filter({ hasText: name }).first()` instead of exact name match
- Lesson added to cheat sheet (Locators & Selectors section):
  "Dropdown option accessible names may include metadata beyond the display name —
  always open the dropdown via MCP and inspect role=option names BEFORE writing the POM"
- Workflow state: lessons_count 3 → 4

**Observation 39: Learn codified a DISCOVERY-TIME rule.**
The lesson isn't just about fixing the selector — it's about the discovery process:
"always open the dropdown via MCP and inspect role=option names BEFORE writing the POM."
Agent learned to check dropdown option names during MCP discovery, not after failure.
This is the self-improvement loop working: failure → fix → learn → codify for future tasks.

**Observation 40: Two different dropdown naming patterns on same app.**
Employee role dropdown: simple names ("Analyst", "Developer").
Task assignee dropdown: names with metadata ("Research Assistant (analyst)").
Agent didn't assume consistency between pages — discovered one, got burned on the other,
then codified the lesson: always verify each dropdown individually.

**`/kernel/complete` invoked:**
- Gates passed (protocol_created: true, anchored: true)
- COMPLETE: 7 new files + 1 modified (create-task-modal.ts fix), 1 lesson learned
- Git commit pending (git status showed 79+ lines of changes)
- Task 017 is the LAST task — 17/17 complete, 0 skipped

**Observation 41: Largest task completed with only 1 fix iteration.**
7 new files across 2 new pages, 4 POMs, cross-workflow integration — yet only 1 failure
(assignee option naming). The most complex task of the run had the same fix rate as the
simpler calendar navigation task (015). Agent's accumulated knowledge from 16 prior tasks
made the architecture and patterns automatic.

---

## Run 3 Summary

**Stats:**
- Tasks: 17/17 complete, 0 skipped
- Failures: 2 (task 015: aria-labelledby vs aria-label, task 017: dropdown option metadata)
- Fix iterations: 2 total (1 each)
- Lessons recorded: 2 (both via `/kernel/learn`, both codified in cheat sheet)
- Context compactions: 4 (all recovered seamlessly)
- Total files created: ~30+ across all tasks
- New pages discovered: /employees, /tasks (task 017)
- Anchor invocations: ~12+ (hook-triggered + manual)

**Key improvements over Run 2:**
1. Cheat sheet engagement: cite-rules step produced task-specific output every anchor
2. No file recreation (run 2 problem solved)
3. Selector compliance: role-based priority followed correctly (calendar, employees, tasks)
4. Learn self-enforcement: agent invoked /kernel/learn after both failures without hook prompt
5. Infrastructure reuse: extended methods with optional params instead of duplicating
6. Duplicate detection: task 011 identified as duplicate, 0 files created
7. Context compaction recovery: 4 recoveries, all seamless via dual state update

**Key improvements over Run 1:**
1. Complete gate always invoked (run 1 problem: possibly skipped for 3 specs)
2. Learn always invoked (run 1 problem: skipped when hook didn't fire)
3. Dual state update embedded (run 1 problem: session context not updated after completion)

---

## Post-Cycling `/pr` Review

Agent ran its own `/pr` review after completing all 17 tasks. Found **6 violations** across 31 files.

### Violations Found

**1. [CRITICAL] Role imports from pages/ directly**
- `prospective-customer-role.ts:4,36-38` — imports `DemoBookingPage` from pages/
- Roles compose Tasks only — never import from pages/
- Root cause: cross-domain popup scenario — new tab's POM can't be constructed by the test
  because it doesn't have the new tab's BrowserInterface
- Options: move getter to Task layer, expose raw BI for new tab, or accept as exception

**2. [HIGH] 9 instances of BI bypass via `this.browser.locator(...).click()`**
- 5 POM files: demo-booking-page.ts, goals-page.ts, create-employee-modal.ts, create-task-modal.ts
- Action methods use raw locator `.click()` instead of `this.browser.click()`
- Root cause: BI lacks `clickFirst()` or `clickFiltered()` methods for disambiguation
- HITL trigger: BrowserInterface needs extension

**3. [HIGH] Raw Playwright Page API in lead-capture-tasks.ts**
- Lines 43,46,66,69 — `this.browser.page.context().waitForEvent('page')` and
  `newPage.waitForLoadState('domcontentloaded')`
- Bypasses BI entirely for page lifecycle management
- HITL trigger: BI lacks popup/tab capture methods

**4. [HIGH] Hardcoded credentials in all 15 test files**
- `solosza@yahoo.com` / `sarzana1=3` appear directly in every test
- Should be extracted to config, env vars, or fixtures
- Note: task specs provided these credentials directly — agent followed spec literally

**5. [MEDIUM] Unused EmployeesPage in integration test**
- `test-create-employee-and-assign-task.spec.ts:25` — constructed but never used in assertions

**6. [MEDIUM] Task getter returns non-void**
- `lead-capture-tasks.ts:92-94` — `get bookingPage(): DemoBookingPage | null`
- Tasks should return `Promise<void>` only — getter breaks the contract

### What Passed

- All 10 POMs: static readonly locators, atomic methods, return this, state-checks ✓
- All Tasks: @autologger('Task') ✓
- 2/3 Roles: @autologger('Role'), Tasks-only imports ✓
- All 15 Tests: AAA pattern, POM assertions, import from ../fixtures ✓
- Naming: 100% compliant (kebab-case files, PascalCase classes, UPPER_SNAKE locators) ✓
- No page.waitForTimeout(), no `any` type, no bare catch ✓

### Analysis — Which violations came from run 3?

| # | Violation | Run 3? | Details |
|---|-----------|--------|---------|
| 1 | Role imports pages/ | No | Task 002 (lead-capture, run 1-2) |
| 2 | BI bypass (9 instances) | **YES — 7 of 9** | goals-page.ts (tasks 010-016), create-employee-modal.ts (017), create-task-modal.ts (017) |
| 3 | Raw Playwright API | No | Task 002 (lead-capture, run 1-2) |
| 4 | Hardcoded credentials | **YES — all 15 tests** | Every run 3 test has hardcoded creds |
| 5 | Unused EmployeesPage | **YES** | Task 017 integration test |
| 6 | Task getter non-void | No | Task 002 (lead-capture, run 1-2) |

**3 of 6 violations are from run 3 code.** The agent's anchor cite-rules step caught selector
patterns, layer separation, and `.first()` exceptions — but never flagged BI bypass as a
violation. During Part B review, it acknowledged `this.browser.locator()` usage but classified
it as "acceptable because BI lacks the methods." The `/pr` command was stricter.

Key gap: **the cheat sheet says "ALL browser interactions go through BrowserInterface" but the
agent rationalized workarounds when BI lacked methods.** The rule needs a corollary:
"If BI doesn't have a method you need, BUILD ONE in BI — don't bypass with
`this.browser.locator().click()`." (This rule IS in the cheat sheet under Framework Architecture
but the agent applied the Locators & Selectors rules more consistently than the BI rules.)

### PR Fix — Agent Self-Remediation

Agent told "fix all these based on the reference files and lesson.md." Systematic approach:

**Fix strategy (infrastructure-first):**
1. Read BI and fixtures to understand current API before touching anything
2. Add new BI methods first (unblocks all POM fixes)
3. Add credentials fixture (unblocks all test fixes)
4. Fix POMs (use new BI methods)
5. Fix Task layer (use captureNewTab)
6. Fix Role layer (remove pages/ import)
7. Fix tests (use credentials fixture, remove unused import)

**New BrowserInterface methods added:**
- `clickFirst(selector, timeout?)` — clicks first matching element (wraps `.locator().first().click()`)
- `clickByText(selector, text, timeout?)` — clicks element filtered by text (wraps `.filter({hasText}).first().click()`)
- `captureNewTab(action)` — captures popup/new tab from an action (wraps `context().waitForEvent('page')` + `waitForLoadState`)

**Observation 42: Agent extended BI instead of bypassing it.**
When told to fix BI bypass violations, the agent's first move was adding 3 new BI methods —
addressing the root cause (missing API surface) not just the symptoms (raw locator calls).
This is exactly what the cheat sheet rule says: "If BI doesn't have a method you need, BUILD ONE."
The agent didn't do this during cycling but does it when explicitly told to fix.

**Credentials fixture added:**
- `TestCredentials` type with email/password
- Fixture uses `process.env.TEST_EMAIL` / `process.env.TEST_PASSWORD` with fallback to hardcoded values
- Tests will destructure `{ credentials }` instead of hardcoding

**POM fixes (5 files):**
- `demo-booking-page.ts`: 2 instances → `this.browser.clickFirst()`
- `goals-page.ts`: 4 instances → `this.browser.clickFirst()` (calendar date, complete, edit, delete)
- `create-employee-modal.ts`: 1 instance → `this.browser.click()` (simple role=option, no filter needed)
- `create-task-modal.ts`: 2 instances → `this.browser.click()` + `this.browser.clickByText()`

**Observation 43: Agent correctly differentiated fix approaches per POM.**
Not a blanket find-and-replace. For `create-employee-modal.ts`, the role dropdown uses simple
`role=option[name="Analyst"]` — no filter needed, so just `this.browser.click()`. For
`create-task-modal.ts` assignee, needs text filter → `this.browser.clickByText()`. Each fix
matched the specific disambiguation pattern.

**Lead-capture-tasks.ts rewrite (Fixes #1/#3/#6):**
- Raw `this.browser.page.context().waitForEvent('page')` → `this.browser.captureNewTab(() => ...)`
- `get bookingPage(): DemoBookingPage | null` → `get bookingBrowser(): BrowserInterface | null`
  (exposes BI, not POM — test constructs its own POM from the exposed BI)
- Comment updated: "via BI.captureNewTab()"

**Observation 44: Task getter changed from POM to BI.**
Fix #6 (Task returning non-void) solved by changing `bookingPage` getter to `bookingBrowser`
getter. Now returns `BrowserInterface | null` instead of `DemoBookingPage | null`. This also
fixes #1 indirectly — the Role no longer needs to import DemoBookingPage from pages/.
The test constructs its own DemoBookingPage POM from the exposed BI. Clean separation.

**Prospective-customer-role.ts rewrite (Fix #1):**
- Removed `import { DemoBookingPage }` from pages/
- Changed `get bookingPage()` → `get bookingBrowser()` — exposes BI, not POM
- Role no longer imports from pages/ layer — composes Tasks only

**Hook blocked at 10 actions mid-fix → anchored properly.**
Cite-rules during fix anchor:
- "If BI doesn't have a method, BUILD ONE in BI" → added 3 new methods
- "ALL browser interactions through BI" → replacing 9 bypasses
- "Layers: never skip a layer" → fixing Role importing from pages/
- "tabs, mobile: build BI methods" → captureNewTab replaces raw popup code

**Lead-capture test rewrite:**
- Test now imports `DemoBookingPage` directly (test layer is allowed to import POMs for assertions)
- Gets `bookingBrowser` from Role → constructs its own `DemoBookingPage(bookingBrowser!)`
- Clean layer separation: Role exposes BI, test builds POM, asserts via state-checks

**Credential fixes — parallel subagent attempt:**
- Agent launched 2 parallel bash subagents to fix 14 test files
- Subagents share the action counter with parent — both hit hook at 10 actions
- Only 3 files fixed before block (first subagent managed 3, second blocked)
- Agent anchored, verified what was done, then batched remaining 10 files

**Observation 45: Subagent action counter sharing discovered.**
Agent tried to parallelize credential fixes with 2 subagents but they share the parent's
action counter. Hook blocked both. Agent adapted: verified partial work, anchored, then
batched remaining 10 files in a single `sed` command (1 action = 10 files). Pragmatic recovery.

**Observation 46: Single sed command for 10 files — action economy.**
After discovering subagent counter sharing, agent used a bash for-loop with sed to fix all
10 remaining test files in 1 action. Verified "No hardcoded credentials remain in spec files."
Smart optimization to minimize action count under hook constraints.

**Fix #5 completed:**
- Removed `import { EmployeesPage }` and `const employeesPage = new EmployeesPage(browser_interface)`
- Only `TasksPage` remains for assertions (which is actually used)

**Verification sweep:**
Agent ran 3 grep searches to confirm all fixes:
- 14 test files use `credentials.email` / `credentials.password` (28 occurrences = 2 per file)
- 0 POM files have `this.browser.locator(...).click()` bypass
- 0 Role files import `DemoBookingPage`

**Observation 47: Agent verified fixes systematically.**
After all 6 fixes, agent ran 3 targeted grep searches to confirm zero remaining violations.
Not "I think I got them all" — actual verification. This is the self-check behavior we want.

### PR Fix Summary

| # | Severity | Violation | Fix | Files |
|---|----------|-----------|-----|-------|
| 1 | CRITICAL | Role imports pages/ | Expose `bookingBrowser` (BI) not `bookingPage` (POM) | 3 |
| 2 | HIGH | 9x BI bypass | Added `clickFirst()` + `clickByText()` to BI | 6 |
| 3 | HIGH | Raw Page API | Added `captureNewTab()` to BI | 2 |
| 4 | HIGH | Hardcoded creds | `credentials` fixture + env var fallback | 15 |
| 5 | MEDIUM | Unused import | Removed EmployeesPage import + instantiation | 1 |
| 6 | MEDIUM | Task getter POM | Changed to return BI instead of POM | 1 |

**Total files modified:** 22
**New BI methods:** 3 (`clickFirst`, `clickByText`, `captureNewTab`)
**Approach:** Infrastructure-first (extend BI, then update consumers)

### Test Verification After Fixes

**First run (10 workers):** 8/15 passed, 7 failed
- All 7 failures: `TimeoutError on [data-testid="nav-goals"]` — sidebar not loading
- Root cause: 10 parallel workers hitting same live app = concurrency pressure
- Not code-related — all failures on nav-goals timeout, not on any changed code paths

**Re-run (3 workers):** 7/7 passed (22.9s)
- Agent correctly diagnosed concurrency issue, reduced to 3 workers
- All 7 previously-failed tests passed

**Final result: 15/15 tests passing after PR fixes.**

**Observation 48: Agent correctly diagnosed concurrency vs code failure.**
First run had 7 failures but agent didn't panic or start changing code. Recognized all failures
were the same `nav-goals` timeout pattern → concurrency pressure on live app with 10 workers.
Re-ran with 3 workers → all passed. Good diagnostic judgment — didn't chase phantom bugs.

### Post-Fix `/pr` Review — Clean Pass

Agent ran `/pr` again after all fixes. **0 violations across 31 files.**

- POM layer (10): all BI bypass eliminated, `this.browser.locator().click()` = 0 matches
- Task layer (3): no raw Page API calls, `Promise<void>` returns, `@autologger` on all
- Role layer (3): 0 pages/ imports — Role→Tasks only
- Test layer (15): 0 hardcoded credentials, all import from `../fixtures`, 33 `expect()` assertions
- All 6 previous violations confirmed resolved with specific grep checks

**Observation 49: Second `/pr` confirms all 6 violations resolved.**
Agent's self-remediation was complete — not a single regression or partial fix. The infrastructure-first
approach (extend BI → update consumers) paid off: 3 new BI methods cleanly replaced 9 bypass instances
+ 4 raw Page API calls. Credentials fixture replaced 30 hardcoded values across 15 tests. Clean merge state.

---

## Scoring

| Dimension | Score | Notes |
|-----------|-------|-------|
| Cheat sheet engagement | 4/5 | Every anchor produced task-specific cite-rules. Not rubber-stamped — rules adapted per task context (obs 1, 15, 33). Deduction: cited "ALL browser interactions through BI" but rationalized bypass when BI lacked methods. Engaged with the rules but selectively enforced them. |
| Cite-rules accuracy | 4/5 | Real rules, concrete mappings, adapted per task (obs 1, 11, 17, 33). Correctly handled exceptions (.first() documented, selector priority). Deduction: BI rule cited accurately but not enforced — agent wrote bypass code in the same session it cited the rule. Accurate citation ≠ compliance. |
| Infrastructure reuse | 5/5 | Zero file recreation (run 2 problem solved). Extended methods with optional params + backward compat testing (obs 7, 8). Duplicate detection — task 011 = 0 new files (obs 14). Modal reuse across entry points (obs 13, 28). Calendar date method reused across tasks 014-016. |
| Selector compliance | 5/5 | Role-based priority followed when data-testids absent (obs 17, 19). .first() exceptions documented every instance (obs 11, 20, 29). Self-corrected COMPLETED_TAB locator from discovery (obs 16). aria-labelledby discovered and handled (obs 21-23). Priority order checked correctly. |
| BI compliance | 2/5 | 7 of 9 bypass instances from run 3 code. Agent cited the BI rule at anchors but wrote `this.browser.locator().click()` anyway. Part B review caught the pattern but classified as "acceptable because BI lacks methods" — the cheat sheet already says "build BI methods, don't bypass." Only caught by /pr, not by self-review. Fixed properly when told (obs 42) but didn't self-detect. |
| Layer compliance | 4/5 | Near-perfect 5-layer separation. Task 017: full 7-file stack (obs 36). No layer skipping in any run 3 code. Deduction: unused EmployeesPage import in task 017 test (violation #5) — minor code hygiene issue, not structural. |
| Self-improvement curve | 4/5 | Run 2 problems all solved: file recreation, dual state, complete gate, learn invocation (obs 2, 5, 4, 24). Learn invoked both times without hook (obs 24). Lessons codified in cheat sheet AND reference files (obs 25, 39). Compaction recovery seamless x4. Deduction: new blind spot emerged (BI bypass) — curve not monotonic. Fixes old gaps, introduces new ones. |
| Overall run | 4/5 | 17/17 tasks, 0 skips, 2 failures (1 fix each), 4 compaction recoveries. Cite-rules step validated — the proof-of-read mechanism works. Key gap: BI compliance is a systemic blind spot (7 instances). The agent applies selector rules more consistently than architecture rules. Post-PR fix was thorough and infrastructure-first (obs 42-47). Total: 32/40. |

### Scoring Commentary

**What the scores tell us:**

The cite-rules step (the main thing tested in run 3) **works for engagement but not for enforcement.** The agent reads the cheat sheet, cites real rules, maps them to decisions — that's a 4/5 proof-of-read. But it selectively enforces: selector rules get near-perfect compliance (5/5), while architecture rules (BI compliance) get rationalized away (2/5).

The blind spot pattern: agent knows the rule, cites the rule, then writes code that violates the rule — because the violation feels "reasonable" (BI lacks the method). Part B review sees the violation but accepts the rationalization. Only `/pr` (a separate, stricter review) catches it.

**What needs to change for run 4:**

1. **BI compliance corollary** — The cheat sheet needs to be more explicit: "If BI doesn't have a method you need → STOP → add the method to BI → then use it. Never bypass with `this.browser.locator()`. This is not a suggestion — it's a hard gate."
2. **Part B review teeth** — Part B currently allows the agent to rationalize. It needs a specific check: "Any `this.browser.locator()` or `this.browser.page` in POM code = automatic violation. No exceptions."
3. **Credentials fixture from the start** — Either the task specs should reference a fixture, or the cheat sheet should have: "Never hardcode credentials. Use the credentials fixture."

**Run-over-run improvement:**

| Dimension | Run 1 | Run 2 | Run 3 |
|-----------|-------|-------|-------|
| File recreation | Bad | Bad | **Fixed** (5/5) |
| Complete gate | Skipped | Fixed | **Confirmed** |
| Learn invocation | Skipped | Fixed | **Confirmed** |
| Dual state update | Missing | Fixed | **Confirmed** |
| Selector compliance | OK | OK | **Excellent** (5/5) |
| BI compliance | Unknown | Unknown | **Exposed** (2/5) |
| Cite-rules | N/A | N/A | **Working** (4/5) |

Run 3 fixed everything from runs 1-2 and exposed a new class of problem (architecture rule enforcement) that was previously invisible. That's progress — you can't fix what you can't see.

---

## 2026-03-06 Counter Reset Mechanism
- **Issue:** After anchor, `actions_since_anchor` counter never reset to 0. Hook kept blocking writes even immediately after anchoring, with counter climbing indefinitely (11 → 13 → 14).
- **Root Cause:** The `universal-gate-enforcer.py` hook exits early for `.claude/` paths (line 119) WITHOUT touching the counter — no increment, no reset. The anchor procedure used Edit on `sr_dev_workflow.json` (a `.claude/` path), so the counter was never reset. The hook blocks Edit containing `actions_since_anchor` in old/new strings, but allows Write (full file rewrite) to `.claude/` paths. No code in the hook itself resets the counter — it only increments.
- **Fix:** Use the **Write** tool (not Edit) to rewrite the entire `sr_dev_workflow.json` with `actions_since_anchor: 0`. Write to `.claude/` paths is allowed by the hook and successfully resets the counter.
- **Anti-Pattern Added:** Never use Edit to partially update workflow state during anchor — the counter won't reset. Always use Write to rewrite the full file.
- **Quality Gate Added:** After anchor, verify `actions_since_anchor` is 0 before proceeding with work.
