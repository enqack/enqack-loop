---
description: "Capture institutional memory from an executed plan"
allowed-tools: ["Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/close_run.py:*)", "Write(knowledge-vault/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-post-execution-review

Capture institutional memory from an executed plan. Aggregates lessons learned and seals the run.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Inputs

- `knowledge-vault/Runs/<run-id>/walkthrough.md`
- `knowledge-vault/Logs/post_verify_report.md` (preferred)
- Evidence under `knowledge-vault/`

## Actions

1. Write `knowledge-vault/Runs/<run-id>/walkthrough.md` if not already present (summary of what changed and why).

1. Close the run by running:

   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/close_run.py"
   ```

   This script:
   - Extracts lessons from `walkthrough.md`
   - Appends them to `knowledge-vault/Lessons/lessons-learned.md`
   - Generates a journal entry in `knowledge-vault/Journal/`
   - Writes `closure.json` to seal the run

## Rules

- Entries MUST include evidence pointers (repo-relative paths).
- Do NOT add an entry if there is no evidence.
