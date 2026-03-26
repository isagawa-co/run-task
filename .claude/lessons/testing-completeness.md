# Testing Completeness

## 2026-03-23 Production tests never planned during atomization

- **Issue:** Level 3 production tests were missing from the task list. User had to identify the gap.
- **Root Cause:** production-testing.md was only referenced in step-06 (execute), but test tasks are planned in step-04 (atomize). Step 4 had zero mention of the 3-tier testing hierarchy. By the time the agent reached step 6, all tasks were already written.
- **Fix:** Added "Testing Completeness Check (MANDATORY)" section to step-04-atomize.md. References production-testing.md via wikilink. Includes mandatory per-deliverable L1/L2/L3 checklist.
- **Anti-Pattern Added:** Planning tests only during execution. Documenting testing requirements in a reference file that's read too late in the process.
- **Quality Gate Added:** Mandatory checklist in step 4: for each deliverable, verify L1/L2/L3 test tasks exist before proceeding to step 5.

## The Pattern

Requirements documented in the wrong step get skipped. If step N needs information from reference X, reference X must be read during step N — not "eventually" in a later step. The agent follows steps sequentially and doesn't look ahead.

## Concrete Rules

- Read production-testing.md during step 4 (atomize), not just step 6 (execute)
- For each deliverable, fill out the L1/L2/L3 checklist
- If any cell is MISSING, add a TEST task before proceeding
- "Simulate" (read/write state files manually) is Level 2, NOT Level 3
- Level 3 means: spawn the real tool, let it run, read the real output
