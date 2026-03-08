# enqack-loop

A custom [Claude Code](https://claude.ai/code) plugin implementing the **Enqack Loop** — a self-referential iterative agent loop based on Geoffrey Huntley's "Ralph Wiggum technique."

> The Enqack loop is a Bash loop: a `while true` that repeatedly feeds an AI agent a prompt file, allowing it to iteratively improve until done.

This plugin does it **inside your current Claude Code session** via a Stop hook — no external shell loop required.

---

## How It Works

```
You run ONCE:
  /enqack-loop "Build a REST API" --completion-promise "DONE" --max-iterations 20

Claude Code automatically:
  1. Works on the task
  2. Tries to exit
  3. Stop hook (hooks/stop-hook.sh) intercepts → {"decision":"block","reason":<prompt>}
  4. Same prompt fed back to Claude
  5. Claude sees its previous file changes + git history
  6. Repeat until <promise>DONE</promise> output OR max iterations reached
```

State lives in `.claude/enqack-loop.local.md` (auto-added to `.gitignore`, never committed).
Each iteration is appended to `knowledge-vault/Logs/enqack-loop.log` (NDJSON).

---

## Customizations vs. Official Plugin

| Feature | Official | This Plugin |
|---------|----------|-------------|
| `--dry-run` flag | ❌ | ✅ Preview state file without activating |
| Iteration logging | ❌ | ✅ NDJSON → `knowledge-vault/Logs/enqack-loop.log` |
| Elapsed time tracking | ❌ | ✅ `elapsed_seconds` in each log entry |
| Auto-.gitignore | ❌ | ✅ State file auto-excluded |
| Project root in system msg | ❌ | ✅ Situational awareness across iterations |
| `started_at` in state | ❌ | ✅ Timestamped start for observability |

---

## Installation

Install into any Claude Code project by adding it to your plugin path:

```bash
# Option 1: Symlink into project plugins dir
mkdir -p /your/project/.claude/plugins
ln -s /home/sysop/Projects/enqack-loop \
      /your/project/.claude/plugins/enqack-loop

# Option 2: Global user plugin (if Claude Code supports it)
mkdir -p ~/.claude/plugins
ln -s /home/sysop/Projects/enqack-loop \
      ~/.claude/plugins/enqack-loop
```

Claude Code must be configured to use the Stop hook. Add to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/enqack-loop/hooks/stop-hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/enqack-loop/hooks/post_write_log.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

The `Stop` hook runs the iterative loop. The `PostToolUse` hook (`post_write_log.sh`) is optional but recommended — it logs every file write to the daily activity ledger in `knowledge-vault/Activity/`.

---

## Commands

### `/enqack-loop`

Start an Enqack loop in the current session.

```
/enqack-loop "PROMPT" [--max-iterations N] [--completion-promise "TEXT"] [--dry-run]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--max-iterations N` | 0 (unlimited) | Stop after N iterations |
| `--completion-promise TEXT` | none | Exact phrase Claude must output to stop |
| `--dry-run` | false | Preview state file without activating |

**Examples:**

```bash
# Run up to 20 iterations, stop when Claude outputs <promise>DONE</promise>
/enqack-loop "Build a REST API for todos. CRUD, validation, tests." \
  --completion-promise "DONE" \
  --max-iterations 20

# Infinite loop, no completion signal (use /cancel-enqack to stop)
/enqack-loop "Continuously improve the code quality"

# Preview only
/enqack-loop "Fix all lint errors" --max-iterations 10 --dry-run
```

### `/cancel-enqack`

Cancel an active Enqack loop (removes the state file).

```
/cancel-enqack
```

---

## Agentic Development Lifecycle Commands

This plugin bundles a full agentic development lifecycle as slash commands. Each command is a structured protocol document that Claude follows.

### Lifecycle Flow

```
/enqack-start
  └─ /enqack-establish-intent   (if project_intent.md missing)
  └─ /enqack-prep-context       (if context_manifest.md missing)
  └─ /enqack-plan-cycle
       ├─ /enqack-prep-context
       ├─ /enqack-verify-agenda
       ├─ /enqack-plan-execution  → approval gate →
       ├─ /enqack-execute-plan
       ├─ /enqack-post-verify
       └─ /enqack-post-execution-review

/enqack-finish
  ├─ /enqack-post-verify
  ├─ /enqack-post-execution-review
  ├─ /enqack-commit-message
  └─ /enqack-markdown-checklist
```

### Command Reference

| Command | Description |
|---------|-------------|
| `/enqack-start` | Entry point — ensures intent + context, hands off to plan-cycle |
| `/enqack-finish` | Closing sequence — verify, review, commit message, format |
| `/enqack-plan-cycle` | Full lifecycle orchestrator |
| `/enqack-establish-intent` | Write `knowledge-vault/Intent/project_intent.md` |
| `/enqack-prep-context` | Load context + produce `context_manifest.md` |
| `/enqack-verify-agenda` | Classify all `AGENDA.md` items before planning |
| `/enqack-plan-execution` | Produce `implementation_plan.md` + `.json` |
| `/enqack-execute-plan` | Execute approved plan + run `verify_all.sh` |
| `/enqack-post-verify` | Reconcile `AGENDA.md` → `post_verify_report.md` |
| `/enqack-post-execution-review` | Extract lessons + seal run via `close_run.py` |
| `/enqack-commit-message` | Propose Conventional Commit messages |
| `/enqack-markdown-checklist` | Format + lint all Markdown files |
| `/enqack-toggle-maintenance-mode` | Toggle agent maintenance mode |

---

## CVR Python Runtime

The plugin ships a Python runtime in `scripts/cvr/` that powers the agentic development commands.

### Scripts

| Script | Purpose |
|--------|---------|
| `paths.py` | Canonical vault path constants (single source of truth) |
| `log_action.py` | Append a row to the daily `knowledge-vault/Activity/YYYY-MM-DD.md` ledger |
| `generate_context_manifest.py` | Produce `knowledge-vault/Logs/context_manifest.md` |
| `close_run.py` | Seal a run: extract lessons, write journal, write `closure.json` |
| `journal.py` | Generate a narrative "Deep Thoughts" journal entry from run artifacts |
| `format_md.py` | Format + lint all `.md` files (`mdformat` + `markdownlint-cli2`) |
| `add_note.py` | Create a Cursed Knowledge or Deep Thought note |
| `aggregate_history.py` | Build `history.ndjson` from all runs |
| `compile_timeline.py` | Compile per-run Deep Thoughts from journals |

### Python Dependencies

The CVR runtime requires **Python 3** in `PATH`. All scripts run from the host project's working directory.

| Dependency | Required by | Install |
|------------|-------------|----------|
| `mdformat` | `format_md.py` | `pip install mdformat` |
| `markdownlint-cli2` | `format_md.py` | `npm install -g markdownlint-cli2` |

`format_md.py` degrades gracefully: it will warn and exit with an error if dependencies are missing, but it will never crash other commands that don't call it.

---

## Knowledge Vault Structure

All structured output from agentic development commands lands in `knowledge-vault/` inside the **host project**:

```
your-project/
  knowledge-vault/
    Intent/
      project_intent.md        # domain + milestones
    Runs/
      2026-03-08-14-00-00/     # one dir per run
        implementation_plan.md
        implementation_plan.json
        walkthrough.md
        post_verify_report.md
        closure.json
    Logs/
      context_manifest.md
      post_verify_report.md
      agent_mode.json
    Activity/
      2026-03-08.md            # daily write ledger (PostToolUse hook)
    Lessons/
      lessons-learned.md
    Journal/
      2026-03-08-14-00-00.md  # narrative per run
    History/
      history.ndjson
      history.md
```

Add `knowledge-vault/` to your project's `.gitignore` if you don't want to commit vault artifacts.

## State File Format

`.claude/enqack-loop.local.md` uses markdown with YAML frontmatter:

```markdown
---
active: true
iteration: 3
session_id: abc123
max_iterations: 20
completion_promise: "DONE"
started_at: "2026-03-08T12:00:00Z"
project_root: "/your/project"
---

Your original prompt text lives here.
```

---

## Log Format

`knowledge-vault/Logs/enqack-loop.log` (NDJSON, one entry per line):

```jsonl
{"ts":"2026-03-08T12:00:00Z","event":"loop_start","iteration":1,"max_iterations":20,"elapsed_seconds":0,"completion_promise":"DONE","session_id":"abc123","project_root":"/project"}
{"ts":"2026-03-08T12:01:15Z","event":"loop_continue","iteration":2,"max_iterations":20,"elapsed_seconds":75,"completion_promise":"DONE"}
{"ts":"2026-03-08T12:02:30Z","event":"loop_complete","iteration":3,"max_iterations":20,"elapsed_seconds":150,"completion_promise":"DONE"}
```

**Events:** `loop_start` · `loop_continue` · `loop_complete` · `max_iterations_reached` · `transcript_missing` · `no_assistant_messages` · `extract_failed` · `parse_failed` · `empty_prompt`

---

## Prompt Writing Best Practices

### ✅ Clear completion criteria

```
Build a REST API for todos. Requirements:
- CRUD endpoints (GET/POST/PUT/DELETE)
- Input validation on all endpoints
- Tests with >80% coverage
- README with API docs
Output <promise>DONE</promise> when ALL requirements are met.
```

### ✅ Escape hatches for stuck states

```
/enqack-loop "Implement feature X" --max-iterations 15

# Also include in prompt:
# "After 12 iterations with no progress: document what's blocking,
#  list what was attempted, then output <promise>BLOCKED</promise>"
```

### ✅ TDD self-correction

```
Implement feature X using TDD:
1. Write failing tests
2. Implement feature
3. Run tests — if any fail, debug and fix
4. Refactor if needed
5. Repeat until all green
6. Output <promise>ALL TESTS PASSING</promise>
```

---

## Philosophy

1. **Iteration > Perfection** — Don't aim for perfect on the first try. Let the loop refine the work.
2. **Failures Are Data** — Each iteration's output informs the next.
3. **Operator Skill Matters** — Success depends on writing good prompts, not just having a good model.
4. **Persistence Wins** — The loop handles retry logic automatically.

---

## License

Apache 2.0 — same as the [official Anthropic enqack-loop plugin](https://github.com/anthropics/claude-plugins-official).
