---
description: "Load and verify workspace context at the start of a session"
allowed-tools: ["Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/generate_context_manifest.py:*)", "Read(.agentsignore)", "Read(CLAUDE.md)", "Read(AGENDA.md)"]
hide-from-slash-command-tool: "false"
---

# enqack-prep-context

Load and verify required workspace context before any planning or execution.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If the precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Operating Rules

- No code or configuration modifications are permitted.
- Artifact writes permitted **only** under `knowledge-vault/**` as specified.
- Runs in audit-only mode.

## Purpose

Load and verify required workspace context before any planning or execution:

- `CLAUDE.md` (mandatory)
- `AGENDA.md` (mandatory)
- Relevant files under `docs/` if present and not ignored

If any mandatory context file is missing, **fail closed**.

## Agent Ignore

- MUST respect `.agentsignore` when selecting additional files to read.
- If `.agentsignore` is missing, unreadable, or malformed, **fail closed**.

## Required Actions

1. Read all mandatory context files.
1. Read additional context files subject to `.agentsignore` and any read-scope budget.
1. Extract and internalize all enforceable constraints defined in `CLAUDE.md`.

## Output: context_manifest.md

Emit `knowledge-vault/Logs/context_manifest.md` by running:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/generate_context_manifest.py"
```

Manual creation or editing of this file is prohibited.

### Required Fields

- Timestamp (ISO-8601, UTC)
- Operating mode
- Agent ignore file used
- Files read as context (repo-relative paths)
- Files skipped due to `.agentsignore` (if detectable)
- **Constraints acknowledged**: concise list of enforceable rules extracted from `CLAUDE.md`

## Prohibitions

- No code changes
- No configuration changes
- No partial artifacts
- No speculative continuation beyond context loading
