# Step 2: Discover Repo Structure

Scan and list what exists:

```
SCAN:
├── [source_dir]/
│   ├── [reference_code]/    → Code pattern examples (if any)
│   ├── [core_modules]/      → Main logic
│   └── [utilities]/         → Helpers, config
├── .claude/
│   ├── skills/              → Workflow protocols
│   └── commands/            → Entry points (non-kernel)
├── [test_dir]/
│   ├── [test_config]        → Test setup (conftest.py, etc.)
│   └── [test_data]/         → Test fixtures, data
```

## Action

List all files found in each location.

## Output

Report file counts per directory.
