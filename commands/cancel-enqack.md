---
description: "Cancel active Enqack Loop"
allowed-tools: ["Bash(test -f .claude/enqack-loop.local.md:*)", "Bash(rm .claude/enqack-loop.local.md)", "Read(.claude/enqack-loop.local.md)"]
hide-from-slash-command-tool: "false"
---

# Cancel Enqack

To cancel the Enqack loop:

1. Check if `.claude/enqack-loop.local.md` exists using Bash: `test -f .claude/enqack-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Say "No active Enqack loop found."

3. **If EXISTS**:
   - Read `.claude/enqack-loop.local.md` to get the current `iteration:` value and `started_at:` value
   - Remove the file using Bash: `rm .claude/enqack-loop.local.md`
   - Report: "Cancelled Enqack loop (was at iteration N, started at STARTED_AT)" where N and STARTED_AT come from the state file
