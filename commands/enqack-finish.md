---
description: "Unified finishing sequence: verify → review → commit message"
allowed-tools: ["Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/format_md.py:*)"]
hide-from-slash-command-tool: "false"
---

# enqack-finish

Unified entry point for closing a development cycle. Ensures the repository is verified, history is aggregated, and a commit message is prepared.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Workflow

1. **Verify Results**

   - Run `/enqack-post-verify` to reconcile `AGENDA.md` and generate the final report.

1. **Seal History**

   - Run `/enqack-post-execution-review` to aggregate the run into permanent history and extract lessons learned.

1. **Prepare Handoff**

   - Run `/enqack-commit-message` to generate candidate Conventional Commit messages.

1. **Format Documentation**

   - Run `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/format_md.py` to ensure all artifacts and history files are perfectly formatted.
