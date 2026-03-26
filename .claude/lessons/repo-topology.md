# Repo Topology & Sync

Kernel repo map and sync rules.

---

## Kernel Repo Topology — Sync Reference

When kernel files change, ALL repos with kernel copies must be synced.

| Repo | Local Path | GitHub | Role |
|------|-----------|--------|------|
| **isagawa-kernel** | `D:\my_ai_projects\isagawa-kernel` | `isagawa-co/isagawa-kernel` (public) | **Canonical source** — all kernel changes start or land here |
| **cognitive-agent** | `D:\my_ai_projects\project_test_repos\cognitive-agent` | `isagawa-co/cognitive-agent` (private) | Vanilla kernel + autonomous cycling. Testing ground. |
| **sr_dev_test** | `D:\my_ai_projects\project_test_repos\sr_dev_test` | — | Dev workspace. Has kernel commands for governance. |
| **platform-playwright** | `D:\my_ai_projects\project_test_repos\platform-playwright` | `isagawa-qa/platform-playwright` | v1 domain spec (prescriptive). QA test automation. |
| **vibe-coder-spec** | `D:\my_ai_projects\project_test_repos\vibe-coder-spec` | `isagawa-co/vibe-coder-spec` (private) | v2 domain spec (generative). Vibe coding. |
| **platform** | — | `isagawa-qa/platform` (public) | Python/Selenium QA platform. Live, customer-facing. Kernel sync AFTER autonomy testing. |

**Kernel files that must stay in sync:**
- `.claude/commands/kernel/` — all command .md files
- `.claude/hooks/` — universal-gate-enforcer.py, test-failure-detector.py
- `.claude/skills/kernel-domain-setup/` — SKILL.md + references/
- `.claude/skills/autonomous-cycling/` — SKILL.md + workflow.md
- `.claude/settings.local.json` — hook registration
- `CLAUDE.md` — kernel governance rules

**Sync rule:** Change in canonical (isagawa-kernel) → copy to all other repos that carry kernel files.
