---
description: "Toggle MAINTENANCE mode for the agent (operator-controlled)"
argument-hint: "[on|off|toggle] [--reason TEXT]"
allowed-tools: ["Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/log_action.py:*)", "Write(knowledge-vault/Logs/agent_mode.json)", "Write(knowledge-vault/Activity/**)"]
hide-from-slash-command-tool: "false"
---

# enqack-toggle-maintenance-mode

Operator-controlled switch that marks the agent as being in **MAINTENANCE mode** (or not).

This is a **state toggle only**. It does not stage/commit/push anything, and it does not modify plugin code by itself.

## Inputs

- `state` (string, optional): one of `on`, `off`, `toggle`. default: `toggle`.
- `reason` (string, optional): short human note explaining why maintenance is being enabled.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Alert the operator that intent must be established before toggling maintenance mode.
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Normative behavior

### State file

Maintain exactly one state file: `knowledge-vault/Logs/agent_mode.json`

Schema:

```json
{
  "mode": "maintenance | normal",
  "timestamp": "ISO-8601",
  "reason": "string (optional)"
}
```

### Transition rules

- If `state: on`: write the state file with `"mode": "maintenance"`, then log:

  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/log_action.py" \
    --intent toggle_maintenance_mode --action toggle \
    --scope agent_mode --result ok \
    --evidence knowledge-vault/Logs/agent_mode.json
  ```

- If `state: off`: write the state file with `"mode": "normal"`, then log action.
- If `state: toggle`: if current mode is `maintenance`, switch to `normal`; otherwise switch to `maintenance`. Log action in both cases.

### Continuous notification requirement

While `"mode": "maintenance"` is active, the agent MUST prepend the following banner to **every** response until the mode is set back to `normal`:

> **MAINTENANCE MODE ENABLED** — Runtime modifications may be in progress. Operator intent required for any risky actions.

## Steps

1. Read current `knowledge-vault/Logs/agent_mode.json` if it exists; otherwise assume `"normal"`.
1. Apply Transition rules, writing the updated state file.
1. Echo the new mode + timestamp + reason (if provided) to the operator.
1. Stop.
