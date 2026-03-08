#!/usr/bin/env python3
"""
log_action.py - Append an event to the daily Activity note.

Usage:
  python3 scripts/cvr/log_action.py --intent <intent> --action <action> \
    [--scope <scope>] [--result <result>] [--evidence <file>...]

Each call appends one table row to knowledge-vault/Activity/YYYY-MM-DD.md.

Run from the host project root (CLAUDE_PROJECT_DIR).
"""

import argparse
import datetime
import json
import os
import sys
from pathlib import Path

# Resolve sibling paths.py regardless of install location or CWD
sys.path.insert(0, str(Path(__file__).resolve().parent))
import paths

MODE_FILE = paths.AGENT_MODE_FILE
ACTIVITY_DIR = paths.ACTIVITY_DIR

FRONTMATTER_TEMPLATE = """\
---
type: activity
date: {date}
tags: ["activity", "daily"]
---

| Time | Actor | Intent | Scope | Action | Result |
|------|-------|--------|-------|--------|--------|
"""


def get_current_mode() -> str:
    try:
        if MODE_FILE.exists():
            data = json.loads(MODE_FILE.read_text())
            return data.get("mode", "normal")
    except Exception:
        pass
    return "normal"


def get_actor() -> str:
    return os.environ.get("USER", os.environ.get("USERNAME", "unknown"))


def append_entry(
    intent: str,
    action: str,
    scope: str = "workspace",
    result: str = "ok",
    evidence=None,
    metadata=None,
) -> None:
    now = datetime.datetime.now(datetime.timezone.utc)
    today = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M")

    ACTIVITY_DIR.mkdir(parents=True, exist_ok=True)
    daily_note = ACTIVITY_DIR / f"{today}.md"

    if not daily_note.exists():
        daily_note.write_text(
            FRONTMATTER_TEMPLATE.format(date=today), encoding="utf-8"
        )

    row = (
        f"| {time_str} | {get_actor()} | {intent} "
        f"| {scope} | {action} | {result} |\n"
    )
    with open(daily_note, "a", encoding="utf-8") as f:
        f.write(row)

    print(f"Logged '{action}' for '{intent}' to {daily_note}")


def main():
    parser = argparse.ArgumentParser(description="Log an action to the daily activity note.")
    parser.add_argument("--intent", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--scope", default="workspace")
    parser.add_argument("--result", default="ok")
    parser.add_argument("--evidence", nargs="*")
    parser.add_argument("--metadata")

    args = parser.parse_args()
    try:
        append_entry(
            intent=args.intent,
            action=args.action,
            scope=args.scope,
            result=args.result,
            evidence=args.evidence,
            metadata=args.metadata,
        )
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
