# Lessons Learned — Index

<!-- Updated by /kernel/learn after failures -->
<!-- Tiered: this file is the index. Details in topic files. -->

## RULE ZERO — Read this every anchor

**NEVER ASSUME. ALWAYS VERIFY.** Read the actual files before acting. Don't guess what a file contains, what a config looks like, or what's wired up. Open it and read it. This applies to hooks, state, settings, code — everything. Assumptions caused: missing hooks (settings.local.json never created), stale counters (27 actions untracked), wrong backlog location, wrong naming conventions. Verify first, act second.

**NEVER QUICK-ANCHOR.** When the counter hits the limit, do a FULL anchor — Read protocol, Read lessons, apply rules to next action with concrete verbs, review inter-anchor work. Skipping any part is a violation. The anchor exists to re-center, not to reset a counter. This violation recurred 2026-03-22 even after the lesson was already recorded and read earlier in the same session.

**ALWAYS USE WIKILINK TIERED INDEXING.** Every file that exceeds ~50 lines of detail on a subtopic MUST extract that subtopic into its own reference file and link to it with `→ [[references/file.md]]`. Parent files are indexes — they have step tables and pointers, never inline implementation. This applies to: SKILL.md, workflow.md, step files, commands, protocol. If you're writing a long section inline, stop and extract it. The user has repeated this multiple times — it is a core design pattern of the kernel, not optional.

**NEVER IMPROVISE. NEVER SKIP STEPS. FOLLOW THE COMMANDS EXACTLY.** When a command or skill has written instructions, follow them to the letter. Do not decide a step is "unnecessary" or "inefficient" and skip it. Do not bundle, consolidate, or "optimize" what the instructions say to do separately. The instructions exist because past failures proved they're needed. Every time the agent improvises — quick-anchoring, bundling atomic tasks, skipping verification, assuming a path syntax — it produces a violation the user has to catch. The pattern: agent reads rule → decides it knows better → skips/modifies rule → user corrects → lesson recorded → agent does it again. STOP. Follow the instructions. If you think a step is wrong, flag it — don't silently skip it.

**NEVER USE `cd` IN BASH COMMANDS.** Hooks resolve relative to cwd. Any `cd` shifts cwd for the rest of the session and breaks hook path resolution (`python .claude/hooks/...` fails). Use absolute paths in all Bash commands. If you must reference another directory, use the full path — never `cd` into it. This broke hooks twice in one session (2026-03-22).

**ALWAYS VERIFY TESTING COMPLETENESS (L1/L2/L3) DURING ATOMIZATION.** Every deliverable needs 3 levels of tests: Level 1 (does it exist?), Level 2 (does it run?), Level 3 (does it produce correct results in a real scenario?). Plan ALL test tasks during step 4 (atomize), not step 6 (execute). Read production-testing.md during step 4. "Simulate" is NOT Level 3 — Level 3 means actually running the deliverable under real conditions (spawn run-task.sh, invoke the kernel loop, run the workflow). This gap caused production tests to be missing entirely until the user caught it (2026-03-23). The requirement was documented in step-06 and production-testing.md but step-04 never referenced either file.

**NEVER STOP CYCLING. NEVER SKIP "HUMAN REQUIRED" TASKS.** Autonomous cycling means autonomous — don't stop to "save state," don't pause for user confirmation, don't skip tasks labeled HUMAN REQUIRED. If a task needs a human action (create GitHub repo, restart Claude Code, approve a PR), spawn a sub-agent to do it programmatically (e.g., `gh repo create`, write state files, use CLI tools). The agent stopped cycling 3 times in one session (2026-03-23) to "save context" and skipped task 100 (git push) as "HUMAN REQUIRED." Both are violations. The cycling contract says: don't stop until all tasks are done or skipped after 3 attempts.

**NEVER BUNDLE ACTIONS INTO ONE TASK.** One task = one action. One file write, one command run, one config change. If a task requires writing 4 files, that's 4 tasks. If a test has setup + run + verify, that's 3 tasks. Small tasks are correct tasks — a task that copies one file IS a valid task. The agent repeatedly bundled 3-10 actions into single tasks despite the user correcting this 3 times (2026-03-23). The root cause was "merge if <3" rules in the task-builder skill, which have been removed. When decomposing: count the distinct actions, create that many task files. If it feels like "too many tasks," it's the right number.

---

| Topic | File | Lessons |
|-------|------|---------|
| Kernel Compliance | `kernel-compliance.md` | Hook bypass, quick anchor, dismissing work, words ≠ actions |
| Git & Branching | `git-and-branching.md` | Golden master, feature branches, branch strategy per repo type, repo reset |
| Infrastructure & Setup | `infrastructure-setup.md` | Playwright MCP setup, hook registration |
| Repo Topology | `repo-topology.md` | Kernel repo map, sync rules |
| Cycling Run 1 | `cycling-run.md` | Learn self-enforcement, complete gate, dual state, redundant specs, uncommitted output |
| Cycling Run 2 | `cycling-run-2.md` | Recreated existing files, CSS over role selectors, anchor missed violation, fix priorities |
| Cycling Run 3 | `cycling-run-3.md` | BI compliance blind spot, counter reset mechanism (use Write not Edit for anchor reset) |
| Domain Decomposition | `domain-decomposition.md` | 3 spec types (BUILD/WORKSPACE/OPERATE), decompose before research, anatomy mapping, factory orchestration, SDD connection |
| Meta-Spec Validation | `meta-spec-validation.md` | Gate-contract-driven validation, no validation skill, orchestrator reads gate-contract.md, builder never validates itself |
| Task Atomicity | `task-atomicity.md` | Never bundle actions, never merge "small" tasks, one action = one task file, user corrected 3x |
| Autonomous Cycling | `autonomous-cycling-lesson.md` | Never stop cycling, never skip HUMAN REQUIRED — spawn agent to do it, don't pause for user |
| Testing Completeness | `testing-completeness.md` | L1/L2/L3 required for every deliverable, plan tests in step 4 not step 6, simulate != Level 3 |
