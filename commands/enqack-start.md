---
description: "Start a new agentic development session or work cycle"
argument-hint: "[--auto-approve]"
allowed-tools: ["Read(knowledge-vault/Intent/project_intent.md)", "Read(knowledge-vault/Logs/context_manifest.md)", "Write(knowledge-vault/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-start

User-friendly entry point for the agentic development cycle.

Ensures foundational artifacts exist (`project_intent.md`, context manifest) then hands off to `plan-cycle`.

## Inputs

- `auto_approve` (boolean, optional): If true, skips the plan approval gate. default: `false`.

> **Warning:** Setting `auto_approve: true` removes the human-in-the-loop safety check. Use only for routine tasks or trusted automated loops.

## Workflow

1. **Check Intent**

   - Check if `knowledge-vault/Intent/project_intent.md` exists.
   - If MISSING, run `/enqack-establish-intent`.

1. **Ensure Context Prepared**

   - Check if `knowledge-vault/Logs/context_manifest.md` exists.
   - If MISSING, run `/enqack-prep-context`.
   - If PRESENT, do not re-run (treat as already prepared for this session).

1. **Hand off to Cycle**

   - Run `/enqack-plan-cycle` with the `auto_approve` argument.
