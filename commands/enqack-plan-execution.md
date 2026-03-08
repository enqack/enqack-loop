---
description: "Produce an implementation plan from the verified agenda"
allowed-tools: ["Read(knowledge-vault/**)", "Write(knowledge-vault/Runs/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-plan-execution

Produce an implementation plan from the verified agenda.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists and reflects the repo's purpose.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Prerequisites (conditional)

Before drafting any plan, ensure context is loaded and agenda is verified:

1. **Context Manifest**:

   - Check if `knowledge-vault/Logs/context_manifest.md` exists.
   - If MISSING, run `/enqack-prep-context`.

1. **Agenda Verification**:

   - Check if `knowledge-vault/Logs/post_verify_report.md` exists and is fresher than the latest `AGENDA.md` edit (heuristic).
   - If in doubt, or if never run for this session, run `/enqack-verify-agenda`.

## Ignore semantics (normative)

`.gitignore` and `.agentsignore` are NOT permission systems. They MUST NOT be treated as a precondition failure or a panic.

- You MUST write planning artifacts under `knowledge-vault/Runs/<run-id>/` even if git ignores that directory.
- Do NOT ask the user to bypass ignore rules.

## Context load (normative)

Before drafting any plan, read:

- `knowledge-vault/Intent/project_intent.md`
- `CLAUDE.md`
- `AGENDA.md`

Use the intent to choose domain-appropriate planning:

- software: design + tests + build verification
- writing: outlines + milestones + editorial workflow
- research: hypotheses + methods + citations + reproducibility steps
- art: briefs + iterations + asset workflow
- mixed/unknown: minimal, conservative plan with explicit unknowns

## Run directory

All plan artifacts MUST be written under:

`knowledge-vault/Runs/<run-id>/`

## Outputs (normative paths)

- `knowledge-vault/Runs/<run-id>/implementation_plan.md`
- `knowledge-vault/Runs/<run-id>/implementation_plan.json`

Workspace root MUST NOT be used for plan artifacts.
