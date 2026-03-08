#!/usr/bin/env bash
# stop-hook.sh
# Claude Code Stop Hook — intercepts exit attempts to continue the Enqack loop.
# Receives hook JSON on stdin; outputs {"decision":"block","reason":...} to continue
# or exits 0 with no output to allow exit.
set -euo pipefail

# ─── Read hook input ──────────────────────────────────────────────────────────
HOOK_INPUT=$(cat)

# ─── Ensure we're in the project root (CWD is not guaranteed in hook context) ─
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "$CLAUDE_PROJECT_DIR"
fi

# ─── State file check ─────────────────────────────────────────────────────────
ENQACK_STATE_FILE=".claude/enqack-loop.local.md"

if [[ ! -f "$ENQACK_STATE_FILE" ]]; then
  # No active loop — allow exit
  exit 0
fi

# ─── Parse YAML frontmatter ───────────────────────────────────────────────────
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$ENQACK_STATE_FILE")

ITERATION=$(echo "$FRONTMATTER"       | grep '^iteration:'        | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER"  | grep '^max_iterations:'   | sed 's/max_iterations: *//')
STARTED_AT=$(echo "$FRONTMATTER"      | grep '^started_at:'       | sed 's/started_at: *//; s/^"//; s/"$//')
PROJECT_ROOT=$(echo "$FRONTMATTER"    | grep '^project_root:'     | sed 's/project_root: *//; s/^"//; s/"$//')

# Extract completion_promise and strip surrounding quotes
COMPLETION_PROMISE=$(echo "$FRONTMATTER" \
  | grep '^completion_promise:' \
  | sed 's/completion_promise: *//' \
  | sed 's/^"\(.*\)"$/\1/')

# ─── Session scope: only act on the session that started this loop ─────────────
STATE_SESSION=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' || true)
HOOK_SESSION=$(echo "$HOOK_INPUT"   | jq -r '.session_id // ""')
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# ─── Validate numeric fields ──────────────────────────────────────────────────
_abort_corrupt() {
  local problem="$1"
  echo "⚠️  Enqack loop: State file corrupted — $problem" >&2
  echo "   File: $ENQACK_STATE_FILE" >&2
  echo "   Run /enqack-loop again to start fresh." >&2
  rm "$ENQACK_STATE_FILE"
  exit 0
}

if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  _abort_corrupt "'iteration' is not a valid number (got: '$ITERATION')"
fi
if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  _abort_corrupt "'max_iterations' is not a valid number (got: '$MAX_ITERATIONS')"
fi

# ─── Logging helper ───────────────────────────────────────────────────────────
LOG_FILE="knowledge-vault/Logs/enqack-loop.log"
mkdir -p knowledge-vault/Logs

_log_event() {
  local event="$1"
  local iter="$2"
  local max_iter="${3:-$MAX_ITERATIONS}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local elapsed=0
  if [[ -n "$STARTED_AT" ]]; then
    local start_epoch end_epoch
    start_epoch=$(date -u -d "$STARTED_AT" +%s 2>/dev/null || echo 0)
    end_epoch=$(date -u -d "$now" +%s 2>/dev/null || echo 0)
    elapsed=$(( end_epoch - start_epoch ))
  fi
  local cp_json="null"
  if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
    cp_json="\"${COMPLETION_PROMISE}\""
  fi
  echo "{\"ts\":\"${now}\",\"event\":\"${event}\",\"iteration\":${iter},\"max_iterations\":${max_iter},\"elapsed_seconds\":${elapsed},\"completion_promise\":${cp_json}}" >> "$LOG_FILE"
}

# ─── Max iterations check ─────────────────────────────────────────────────────
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Enqack loop: Max iterations ($MAX_ITERATIONS) reached. Stopping."
  _log_event "max_iterations_reached" "$ITERATION" "$MAX_ITERATIONS"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

# ─── Read transcript ──────────────────────────────────────────────────────────
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Enqack loop: Transcript file not found: $TRANSCRIPT_PATH" >&2
  echo "   This is unusual and may indicate a Claude Code internal issue." >&2
  echo "   Stopping Enqack loop." >&2
  _log_event "transcript_missing" "$ITERATION"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

# ─── Extract last assistant output ───────────────────────────────────────────
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Enqack loop: No assistant messages found in transcript." >&2
  echo "   Stopping Enqack loop." >&2
  _log_event "no_assistant_messages" "$ITERATION"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

LAST_LINES=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 100)
if [[ -z "$LAST_LINES" ]]; then
  echo "⚠️  Enqack loop: Failed to extract assistant messages." >&2
  _log_event "extract_failed" "$ITERATION"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

set +e
LAST_OUTPUT=$(echo "$LAST_LINES" | jq -rs '
  map(.message.content[]? | select(.type == "text") | .text) | last // ""
' 2>&1)
JQ_EXIT=$?
set -e

if [[ $JQ_EXIT -ne 0 ]]; then
  echo "⚠️  Enqack loop: Failed to parse assistant message JSON." >&2
  echo "   Error: $LAST_OUTPUT" >&2
  _log_event "parse_failed" "$ITERATION"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

# ─── Check completion promise ─────────────────────────────────────────────────
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # Use Perl for multiline-safe extraction of <promise>...</promise>
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" \
    | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' \
    2>/dev/null || echo "")

  # Literal string comparison (= not ==) to avoid glob expansion on special chars
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "✅ Enqack loop: Completion promise detected → <promise>${COMPLETION_PROMISE}</promise>"
    _log_event "loop_complete" "$ITERATION"

    # ─── Agentic integration: Close run ───────────────────────────────────────
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
      python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/close_run.py" || true
      echo "TIP: Task complete. Run /enqack-finish to aggregate logs and prepare commit message." >&2
    fi

    rm "$ENQACK_STATE_FILE"
    exit 0
  fi
fi

# ─── Continue loop — increment iteration, build block response ────────────────
NEXT_ITERATION=$(( ITERATION + 1 ))

# Extract prompt body (everything after the second "---" line)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$ENQACK_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Enqack loop: No prompt text found in state file." >&2
  echo "   This usually means the state file was manually edited." >&2
  echo "   Stopping Enqack loop. Run /enqack-loop again to start fresh." >&2
  _log_event "empty_prompt" "$ITERATION"
  rm "$ENQACK_STATE_FILE"
  exit 0
fi

# Atomically update iteration counter
TEMP_FILE="${ENQACK_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$ENQACK_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$ENQACK_STATE_FILE"

_log_event "loop_continue" "$NEXT_ITERATION"

# ─── Agentic integration: Log iteration to vault & Refresh history ────────────
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/log_action.py" \
    --intent "enqack-loop" \
    --action "iteration_complete" \
    --scope "iteration-$ITERATION" \
    --result "ok" \
    --evidence "knowledge-vault/Logs/enqack-loop.log" 2>/dev/null || true

  python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/aggregate_history.py" 2>/dev/null || true
fi

# ─── Build system message ──────────────────────────────────────────────────────
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="🔄 Enqack iteration ${NEXT_ITERATION} of $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "∞"; fi) | Project: ${PROJECT_ROOT} | To stop: output <promise>${COMPLETION_PROMISE}</promise> (ONLY when TRUE — do not lie to exit!)"
else
  SYSTEM_MSG="🔄 Enqack iteration ${NEXT_ITERATION} of $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "∞"; fi) | Project: ${PROJECT_ROOT} | No completion promise — loop runs infinitely"
fi

# ─── Output block decision ────────────────────────────────────────────────────
# "decision":"block" prevents exit; "reason" is the prompt fed back to Claude.
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg    "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
