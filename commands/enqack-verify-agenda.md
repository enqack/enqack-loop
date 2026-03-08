---
description: "Verify agenda items and classify their completion status"
allowed-tools: ["Read(AGENDA.md)", "Read(knowledge-vault/Intent/project_intent.md)"]
hide-from-slash-command-tool: "false"
---

# enqack-verify-agenda

Verify agenda items and classify their completion status before planning.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Classification

Agenda items MUST be classified as one of:

- `finished`
- `in-progress`
- `blocked`
- `not-started`
- `unknown`

## Rules

- `finished` items MUST include evidence pointers (repo-relative paths only).
- `unknown` items are defects and MUST specify what evidence would resolve them.

## Planning rule

Items marked `finished` MUST NOT appear in `implementation_plan.*` unless explicitly reopened under a new hypothesis ID (or marked regression-only).
