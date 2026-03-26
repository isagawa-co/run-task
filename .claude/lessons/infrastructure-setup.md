# Infrastructure & Setup Lessons

MCP configuration, hook registration, and tooling setup.

---

## 2026-02-25 Playwright MCP Setup — Complete Reference

- **Issue:** Playwright MCP server didn't show in `/mcp` list. Agent fell back to WebFetch and guessed selectors.
- **Root Cause:** MCP config was at `.claude/mcp.json` (wrong). Must be `.mcp.json` at **project root**.

### Correct Setup (all 3 required)

**1. Install:** `npm install @playwright/mcp@latest`

**2. `.mcp.json` at PROJECT ROOT:**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

**3. `.claude/settings.local.json`:**
```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["playwright"]
}
```

### Working Reference (platform-playwright)

The platform-playwright repo is the known-good reference for Playwright MCP config. When in doubt, match its setup exactly:
- `.mcp.json` at project root (plain `npx`, no `cmd /c` wrapper)
- `@playwright/mcp` as a dependency in `package.json`
- `settings.local.json` with BOTH `enableAllProjectMcpServers` AND `enabledMcpjsonServers`
- Restart Claude Code after any MCP config change

### cognitive-agent Fix (2026-03-03)

- **Issue:** Playwright MCP not loading in cognitive-agent.
- **Root Cause (3 problems):**
  1. `.mcp.json` was at `.claude/mcp.json` instead of project root
  2. `@playwright/mcp` package was not installed (no `package.json`)
  3. `settings.local.json` was missing `enableAllProjectMcpServers` and `enabledMcpjsonServers`
- **Fix:** Moved config to root, installed package, added both settings keys. Matched platform-playwright exactly.
- **Lesson:** When MCP doesn't work, check ALL THREE: file location, package installed, settings keys present. Missing any one of the three = broken.

### Anti-Patterns
- NEVER put MCP config at `.claude/mcp.json` — must be `.mcp.json` at project root
- NEVER use `cmd /c` wrapper in MCP command — plain `npx` works on all platforms
- NEVER fall back to WebFetch if MCP tools aren't available — STOP and report
- NEVER guess selectors without live page inspection
- NEVER assume MCP works without restart — config loads at Claude Code startup only

## 2026-02-26 Domain-Setup Skipped Hook Registration in settings.local.json
- **Issue:** Domain-setup created hook files but never registered them in `settings.local.json`. Hooks were dead code.
- **Root Cause:** Step 5 conflated "hook code is universal" with "hook runs automatically." Registration is required.
- **Fix:** Updated step-05 and step-09 to require explicit hook registration with exact JSON template and MERGE rule.
- **Anti-Pattern:** NEVER assume hook files run automatically. Registration in `settings.local.json` is required.
- **Design Rule:** Conceptual docs explain what/why, implementation docs provide templates/how.
