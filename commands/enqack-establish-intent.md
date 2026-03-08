---
description: "Establish project intent before any planning or execution"
allowed-tools: ["Write(knowledge-vault/Intent/project_intent.md)"]
hide-from-slash-command-tool: "false"
---

# enqack-establish-intent

Prevent premature domain assumptions. Before any planning or execution, establish what this repository is for.

## Instructions

1. Ask the user a single neutral question:

   "What are you trying to produce in this repo (software, book, research notes, something else), and what does 'done' look like for the first milestone?"

1. Write `knowledge-vault/Intent/project_intent.md` with the result using the schema below.

1. If the user refuses or is unsure, set `primary_domain: unknown` and proceed with minimal, non-domain-specific planning only.

## Schema (required)

`knowledge-vault/Intent/project_intent.md` MUST contain YAML frontmatter with:

- `primary_domain`: one of `software`, `writing`, `research`, `art`, `mixed`, `unknown`
- `deliverable`: short description of the end product
- `first_milestone_done`: definition of done for the first milestone
- `constraints`: list of constraints
- `non_goals`: list of non-goals
- `preferred_tools`: list of tools/skills the user prefers (optional)

## Notes

- Do not introduce language-specific scaffolding unless `primary_domain: software` AND the user wants it.
- For non-software domains, prefer doc-first workflows (outlines, drafts, experiments, citations, etc.).
