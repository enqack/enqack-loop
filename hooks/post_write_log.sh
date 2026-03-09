#!/usr/bin/env bash
# post_write_log.sh
# PostToolUse hook: log filesystem writes to the daily Activity ledger.
# Receives Claude Code hook JSON on stdin.
# Always exits 0 (non-blocking — logging must not interrupt tool use).
set -euo pipefail

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // ""')

# Nothing to log if no file path was extracted
if [[ -z "$file_path" ]]; then
  exit 0
fi

# Derive scope from directory; trim leading ./ if present
scope=$(dirname "$file_path")
scope="${scope#./}"
[[ "$scope" == "." ]] && scope="workspace"

# Map tool name to action verb
case "$tool_name" in
  Write)        action="file_written" ;;
  Edit)         action="file_edited" ;;
  NotebookEdit) action="notebook_edited" ;;
  *)            action="file_modified" ;;
esac

# Run log_action.py from the project root so relative vault paths resolve
# CWD is already the project root in hook context; guard against env var if set
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "${CLAUDE_PROJECT_DIR}"
fi

python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/log_action.py" \
  --intent  "filesystem-write" \
  --action  "$action" \
  --scope   "$scope" \
  --result  "ok" \
  --evidence "$file_path" \
  2>/dev/null || true  # suppress errors; never block on log failure

exit 0
