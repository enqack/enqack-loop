---
description: "Execute an approved implementation plan, collect evidence, and summarize results"
allowed-tools: ["Bash(tools/verify_all.sh:*)", "Write(knowledge-vault/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-execute-plan

Execute an approved implementation plan, collect evidence, and summarize results.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists and reflects the repo's purpose.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Ignore semantics (normative)

`.gitignore` and `.agentsignore` are NOT permission systems. They MUST NOT be treated as a precondition failure or a panic.

- Do NOT ask the user to bypass ignore rules.
- Ignore rules only affect what gets committed or included in agent context, not what can be created on disk.

## Verification (recommended default)

If `tools/verify_all.sh` exists in the host project, run it to:

- validate template baseline + intent
- execute lints
- run project tests via `tools/test.sh` (language-agnostic hook)
- capture outputs under `knowledge-vault/Logs/*.log` and `knowledge-vault/Logs/test_results/`

## After completion (normative)

The agent MUST NOT consider `enqack-execute-plan` finished until the feedback loop is closed.

1. **Agenda Reconciliation**:

   - Run `/enqack-post-verify`.
   - This generates `knowledge-vault/Logs/post_verify_report.md`.

1. **Institutional Memory**:

   - Run `/enqack-post-execution-review`.
   - This ensures lessons are captured in `knowledge-vault/Lessons/lessons-learned.md`.
