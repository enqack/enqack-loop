---
description: "Generate a Conventional Commit message from changes since the last commit"
allowed-tools: ["Bash(git diff HEAD:*)", "Bash(git log --oneline -5)"]
hide-from-slash-command-tool: "false"
---

# enqack-commit-message

Generate a Conventional Commit message from changes since the last commit.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Commit message format (normative)

Use **Conventional Commits**:

```
<type>(<scope>): <short summary>

<body>   # optional: why + what changed
<footer> # optional: Fixes #123, BREAKING CHANGE: ...
```

Allowed `type` values (preferred): `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`.

Rules:

- Summary line is imperative mood, \<= ~72 chars, no trailing period.
- `scope` is optional; use a short subsystem name if it clarifies impact.
- If change is breaking, include `!` after type/scope (e.g., `feat(api)!:`) and add `BREAKING CHANGE:` in footer.

## Link hygiene (normative)

### Allowed references

- **Repo-relative file paths**: prefer inline code (e.g. `tools/linters/rules.json`)
- **Public web links**: `https://…` only

### Forbidden references

- `file://…`
- `cci:`, `vscode:`, `idea:` deep-links
- Absolute local paths like `/home/...`, `/Users/...`, `C:\...`

### Sanitization rule

If a generated commit message includes forbidden links: replace with repo-relative paths in backticks, or remove the link entirely.

## Authority and safety (normative)

- The agent MUST NOT stage, commit, amend commits, push, rebase, or otherwise mutate Git history.
- The agent's output is limited to commit message candidates and formatting fixes.

## Steps

1. **Review diff since last commit** — read and summarize the workspace diff vs `HEAD`.
1. **Draft message content** — write the header first, add body only when needed.
1. **Propose 2–3 candidate commit messages** matching the format above.
1. **Sanitize references** — hard-check for forbidden patterns; fix any violations.
1. **Approval gate** — present the top candidate as the default; ask the user to approve or edit.
1. **Stop** — do not run any Git commands. The operator performs staging and committing.
