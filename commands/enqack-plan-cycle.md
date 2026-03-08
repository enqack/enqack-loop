---
description: "Orchestrate the full agentic development lifecycle: prepare → verify → plan → execute → review"
argument-hint: "[--auto-approve]"
allowed-tools: ["Read(knowledge-vault/**)", "Write(knowledge-vault/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-plan-cycle

Meta-skill that orchestrates the standard development lifecycle. Does not perform work directly; chains other skills to ensure safety, context, and institutional memory.

## Preconditions

- `knowledge-vault/Intent/project_intent.md` exists and reflects the repo's purpose.

## Inputs

- `auto_approve` (boolean, optional): Bypass manual plan approval. default: `false`.

## Workflow Sequence

### 1. Preparation

1. **`/enqack-prep-context`**

   - Loads `CLAUDE.md`, `AGENDA.md`, and respects `.agentsignore`.
   - Produces `knowledge-vault/Logs/context_manifest.md`.

1. **`/enqack-verify-agenda`**

   - Ensures `AGENDA.md` is classified and valid.
   - Prevents planning against completed or unknown items.

### 2. Planning

3. **`/enqack-plan-execution`**

   - Reads context and agenda.
   - Produces `knowledge-vault/Runs/<run-id>/implementation_plan.md`.

   **Approval Decision:**

   - IF `auto_approve` is `true`: **PROCEED** automatically to execution.
   - IF `auto_approve` is `false` (default): **STOP** and wait for operator approval of the plan.

### 3. Execution

4. **`/enqack-execute-plan`**

   - Executes the approved plan.
   - Runs verification (`tools/verify_all.sh` if present in host project).

### 4. Review

5. **`/enqack-post-verify`**

   - Reconciles `AGENDA.md` against reality.
   - Produces `knowledge-vault/Logs/post_verify_report.md`.

1. **`/enqack-post-execution-review`**

   - Captures lessons learned in `knowledge-vault/Lessons/lessons-learned.md`.
   - Closes the run.
