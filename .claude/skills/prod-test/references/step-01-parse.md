# Step 1: Parse Input + Discover Repo

Understand what we're testing before setting anything up.

## Process

1. **Parse the source repo path** from the command argument.

2. **Verify the source repo exists:**
   ```bash
   test -d [source_repo_path]
   ```

3. **Discover repo structure:**
   - List top-level files and directories
   - Check for `framework/` or `src/` (deliverable code)
   - Check for `.claude/skills/` (domain spec)
   - Check for `requirements.txt` or `package.json` (dependencies)
   - Check for existing `_test/` directory (prior test artifacts)

4. **Identify the domain spec:**
   - Read `.claude/skills/*/SKILL.md` — find the domain name
   - If no domain spec exists: STOP, report error — prod-test requires a domain spec

5. **Identify test infrastructure needs:**

   | Found in repo | Infra needed |
   |---------------|-------------|
   | SSH interface / network code | Docker container with service |
   | Web UI / browser tests | Docker + browser service |
   | CLI tool / library | None — runs locally |
   | API client | Mock server or Docker service |

6. **Determine paths:**
   - `master_path`: `[source_repo_parent]/[source_name]-master`
   - `test_path`: `[source_repo_parent]/[source_name]-test`

## Output

```
PROD-TEST: Parse complete

Source: [source_repo_path]
Domain spec: [skill name] at .claude/skills/[dir]/
Code: [framework/ | src/ | etc.]
Dependencies: [requirements.txt | package.json | none]
Infra needed: [Docker + SSH | Docker + browser | none]
Master path: [master_path]
Test path: [test_path]

Proceeding to master assembly.
```
