---
description: "Re-run agenda verification after execution and record reconciliation results"
allowed-tools: ["Read(AGENDA.md)", "Write(knowledge-vault/Logs/post_verify_report.md)"]
hide-from-slash-command-tool: "false"
---

# enqack-post-verify

Re-verify that `AGENDA.md` reflects reality after executing a plan.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Output requirements

Emit `knowledge-vault/Logs/post_verify_report.md` with the following **exact** section headings:

- `## Completed items`
- `## Items still open`
- `## Evidence`

## Rules

- Evidence pointers MUST be repo-relative paths (e.g. `knowledge-vault/Logs/test_results/...`).
- Evidence pointers MUST NOT be absolute paths and MUST NOT use `file://` URLs.
- Avoid truncation (`...`) in evidence pointers; they must be auditable.
