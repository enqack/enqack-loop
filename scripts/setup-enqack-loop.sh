#!/usr/bin/env bash
# setup-enqack-loop.sh
# Creates the state file that activates the in-session Enqack loop.
# Usage: setup-enqack-loop.sh PROMPT [--max-iterations N] [--completion-promise TEXT] [--dry-run]
set -euo pipefail

# ─── Parse arguments ─────────────────────────────────────────────────────────
PROMPT_PARTS=()
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat <<'HELP_EOF'
enqack Loop - Iterative self-referential Claude Code agent loop

USAGE:
  /enqack-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Task description (multiple words without quotes are fine)

OPTIONS:
  --max-iterations <n>           Stop after N iterations (0 = unlimited, default: 0)
  --completion-promise '<text>'  Exact phrase that signals completion (use quotes for multi-word)
  --dry-run                      Preview the state file without activating the loop
  -h, --help                     Show this help message

DESCRIPTION:
  Activates a stop hook that intercepts Claude's exit attempts and feeds the
  SAME PROMPT back as input. Claude sees its own previous file changes and git
  history, enabling self-correction across iterations.

  To signal completion, Claude must output: <promise>YOUR_PHRASE</promise>

  Iteration state is stored in .claude/enqack-loop.local.md
  (automatically added to .gitignore).

  Each iteration is logged to knowledge-vault/Logs/enqack-loop.log.

EXAMPLES:
  /enqack-loop Build a REST API for todos --completion-promise 'DONE' --max-iterations 20
  /enqack-loop Fix the failing tests --max-iterations 10
  /enqack-loop Refactor the cache layer   # runs forever
  /enqack-loop --dry-run "Check what the state file looks like" --max-iterations 5

STOPPING:
  • Automatic: --max-iterations reached or --completion-promise detected
  • Manual:    /cancel-enqack

MONITORING:
  head -10 .claude/enqack-loop.local.md   # current state
  tail -f knowledge-vault/Logs/enqack-loop.log       # live iteration log
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Examples: --max-iterations 10   --max-iterations 0  (unlimited)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: --max-iterations must be a non-negative integer, got: $2" >&2
        echo "   Examples: 10, 50, 0 (unlimited)" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --completion-promise requires a text argument" >&2
        echo "   Examples: --completion-promise 'DONE'   --completion-promise 'All tests passing'" >&2
        echo "   Note: multi-word promises must be quoted." >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# ─── Validate ─────────────────────────────────────────────────────────────────
PROMPT="${PROMPT_PARTS[*]:-}"

if [[ -z "$PROMPT" ]]; then
  echo "❌ Error: No prompt provided." >&2
  echo "" >&2
  echo "   The Enqack loop needs a task description to work on." >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /enqack-loop Build a REST API for todos" >&2
  echo "     /enqack-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /enqack-loop --completion-promise 'DONE' Refactor code" >&2
  echo "" >&2
  echo "   For all options: /enqack-loop --help" >&2
  exit 1
fi

# ─── Prepare YAML values ──────────────────────────────────────────────────────
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"${COMPLETION_PROMISE}\""
else
  COMPLETION_PROMISE_YAML="null"
fi

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PROJECT_ROOT="$(pwd)"

# ─── Build state file content ─────────────────────────────────────────────────
STATE_CONTENT="---
active: true
iteration: 1
session_id: ${SESSION_ID}
max_iterations: ${MAX_ITERATIONS}
completion_promise: ${COMPLETION_PROMISE_YAML}
started_at: \"${STARTED_AT}\"
project_root: \"${PROJECT_ROOT}\"
---

${PROMPT}"

# ─── Dry run ──────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  echo "🔍 DRY RUN — state file preview (not written):"
  echo ""
  echo "File: .claude/enqack-loop.local.md"
  echo "──────────────────────────────────────────────"
  echo "$STATE_CONTENT"
  echo "──────────────────────────────────────────────"
  echo ""
  echo "  Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "unlimited"; fi)"
  echo "  Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "\"${COMPLETION_PROMISE}\""; else echo "none"; fi)"
  echo ""
  echo "Run without --dry-run to activate the loop."
  exit 0
fi

# ─── Write state file ─────────────────────────────────────────────────────────
ENQACK_STATE_FILE=".claude/enqack-loop.local.md"
mkdir -p .claude

# Write atomically via temp file
TEMP_FILE="${ENQACK_STATE_FILE}.tmp.$$"
echo "$STATE_CONTENT" > "$TEMP_FILE"
mv "$TEMP_FILE" "$ENQACK_STATE_FILE"

# ─── Ensure .gitignore covers state file ──────────────────────────────────────
GITIGNORE=".gitignore"
GITIGNORE_ENTRY="enqack-loop.local.md"
if [[ ! -f "$GITIGNORE" ]] || ! grep -qF "$GITIGNORE_ENTRY" "$GITIGNORE" 2>/dev/null; then
  echo "" >> "$GITIGNORE"
  echo "# Enqack Loop state (session-local, never commit)" >> "$GITIGNORE"
  echo "$GITIGNORE_ENTRY" >> "$GITIGNORE"
fi

# ─── Ensure log directory exists ──────────────────────────────────────────────
mkdir -p knowledge-vault/Logs
LOG_FILE="knowledge-vault/Logs/enqack-loop.log"
echo "{\"ts\":\"${STARTED_AT}\",\"event\":\"loop_start\",\"iteration\":1,\"max_iterations\":${MAX_ITERATIONS},\"completion_promise\":${COMPLETION_PROMISE_YAML},\"session_id\":\"${SESSION_ID}\",\"project_root\":\"${PROJECT_ROOT}\"}" >> "$LOG_FILE"

# ─── Agentic integration: Check for project intent ───────────────────────────
if [[ ! -f "knowledge-vault/Intent/project_intent.md" ]] && [[ "$DRY_RUN" == "false" ]]; then
  echo ""
  echo "💡 TIP: Project intent not established. Consider running /enqack-start"
  echo "   first to define goals and prepare context manifest."
  echo ""
fi

# ─── Activation banner ────────────────────────────────────────────────────────
cat <<EOF
🔄 Enqack loop activated in this session!

  Iteration:          1
  Max iterations:     $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo "$MAX_ITERATIONS"; else echo "unlimited"; fi)
  Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE} (ONLY output when TRUE - do not lie!)"; else echo "none (runs forever)"; fi)
  Started at:         ${STARTED_AT}
  Log:                ${PROJECT_ROOT}/${LOG_FILE}
  State file:         ${PROJECT_ROOT}/${ENQACK_STATE_FILE}

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous file changes in place, creating a
self-referential loop where you iteratively improve on the same task.

⚠️  WARNING: This loop cannot be stopped manually without /cancel-enqack.
    It runs infinitely unless --max-iterations or --completion-promise is set.

Monitor:  head -10 .claude/enqack-loop.local.md
Log:      tail -f knowledge-vault/Logs/enqack-loop.log

🔄
EOF

echo ""
echo "$PROMPT"

# ─── Completion promise briefing ─────────────────────────────────────────────
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "CRITICAL - Enqack Loop Completion Promise"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>${COMPLETION_PROMISE}</promise>"
  echo ""
  echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
  echo "  ✓ Use <promise> XML tags EXACTLY as shown above"
  echo "  ✓ The statement MUST be completely and unequivocally TRUE"
  echo "  ✓ Do NOT output false statements to exit the loop"
  echo "  ✓ Do NOT lie even if you think you should exit"
  echo ""
  echo "IMPORTANT - Do not circumvent the loop:"
  echo "  Even if you believe you're stuck, the task is impossible,"
  echo "  or you've been running too long — you MUST NOT output a"
  echo "  false promise. The loop continues until the promise is"
  echo "  GENUINELY TRUE. Trust the process."
  echo "═══════════════════════════════════════════════════════════"
fi
