# Git & Branching Lessons

Branch strategy, commit practices, and repo reset procedures.

---

## 2026-02-25 Branch Strategy — Main = Golden Master
- **Main branch** is the golden master — vanilla repo used to reset for testing.
- **Feature branches** are for new features added AFTER testing confirms main works.
- Infrastructure fixes (MCP config, step files, commands) commit to **main**.
- New capabilities after testing use **feature branches** off main.

## 2026-03-03 Agent Committed to Canonical Master Instead of Feature Branch
- **Issue:** Agent committed new kernel features directly to `master` on isagawa-kernel.
- **Root Cause:** Applied "main = golden master for infrastructure" lesson too broadly. That was for workspace/testing repos, not the canonical open-source kernel.
- **Fix:** New kernel features go on a feature branch in isagawa-kernel. Only merge to main after testing. Direct commits to main are for hotfixes only.
- **Anti-Pattern:** NEVER commit new features directly to main/master on the canonical kernel repo.

## 2026-03-03 Branch Naming Convention
- All repos use `main` (not `master`) — both local and GitHub.
- Feature branches: `feature/[name]` (kebab-case, describes **what** not **when**).
- If a repo still uses `master`, rename it to `main`.

## 2026-03-03 Branch Strategy Per Repo Type

| Repo Type | Strategy |
|-----------|----------|
| **Workspace** (sr_dev_test) | Main only. No feature branches — sessions span multiple topics. |
| **Canonical kernel** (isagawa-kernel) | Feature branches → PR to main after testing. |
| **Product repos** (cognitive-agent, platform-playwright) | Feature branches for new capabilities. |

## 2026-03-03 Repo Reset — Full Clean Reset Procedure
- **Issue:** When resetting cognitive-agent for a fresh test, agent manually deleted files one-by-one instead of resetting to `origin/main`. Then even after `git reset --hard`, gitignored artifacts like `node_modules/` survived — leaving a dirty local that didn't match remote.
- **Root Cause:** `git reset --hard` only resets tracked files. Gitignored files (node_modules, build output, .claude/state, etc.) are invisible to it. Agent didn't account for this.
- **Fix:** Full reset is TWO commands, not one:
  ```bash
  git fetch origin
  git reset --hard origin/main   # Reset tracked files to remote
  git clean -fdx                 # Remove ALL untracked + ignored files
  ```
  Then create feature branch and cherry-pick/rebase commits to keep.
- **Anti-Pattern:** NEVER manually delete files to "reset" a repo. NEVER assume `git reset --hard` alone is sufficient — it leaves gitignored artifacts.
- **Rule:** The remote is the source of truth for clean state. Local = disposable. `reset --hard` + `clean -fdx` = true match with remote.

## 2026-03-18 Check Branch Before Push — Don't Assume Main
- **Issue:** `git push` failed with "no upstream branch" because README commit was made on `feature/hook-workspace-relative-paths` instead of `main`. Had to cherry-pick to main.
- **Root Cause:** Didn't check current branch before committing. Assumed we were on main.
- **Fix:** Always run `git branch --show-current` before committing cross-repo changes. If on wrong branch, checkout main first.
- **Anti-Pattern:** NEVER commit + push without verifying you're on the intended branch — especially when working across multiple repos in one session.
