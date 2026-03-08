#!/usr/bin/env python3
"""add_note.py - Create a Cursed Knowledge or Deep Thought note.

Usage:
  python3 scripts/cvr/add_note.py --type cursed-knowledge --title "Never do X" [--run-id <run-id>] [--body "..."]
  python3 scripts/cvr/add_note.py --type deep-thought --title "On linting" [--run-id <run-id>] [--body "..."]

Run from the host project root (CLAUDE_PROJECT_DIR).
"""

import argparse
import re
import sys
from datetime import date
from pathlib import Path

# Resolve sibling paths.py regardless of install location or CWD
sys.path.insert(0, str(Path(__file__).resolve().parent))
import paths

NOTE_DIRS = {
    "cursed-knowledge": paths.CURSED_KNOWLEDGE_DIR,
    "deep-thought": paths.DEEP_THOUGHTS_DIR,
}


def slugify(title: str) -> str:
    slug = title.lower()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_]+", "-", slug)
    slug = slug.strip("-")
    return slug[:60]


def create_note(
    note_type: str,
    title: str,
    run_id: str = None,
    body: str = "",
) -> Path:
    if note_type not in NOTE_DIRS:
        raise ValueError(f"Unknown note type: {note_type!r}. Must be one of {list(NOTE_DIRS)}")

    note_dir = NOTE_DIRS[note_type]
    note_dir.mkdir(parents=True, exist_ok=True)

    today = date.today().isoformat()
    slug = slugify(title)
    filename = f"{today}-{slug}.md"
    out_path = note_dir / filename

    run_link = f'"[[Runs/{run_id}/implementation_plan]]"' if run_id else '""'

    frontmatter = (
        "---\n"
        f"type: {note_type}\n"
        f'title: "{title}"\n'
        f"date: {today}\n"
        f"run: {run_link}\n"
        f'tags: ["{note_type}"]\n'
        "---\n\n"
    )
    content = frontmatter + f"# {title}\n\n{body}\n"
    out_path.write_text(content, encoding="utf-8")
    print(f"Created {note_type} note: {out_path}")
    return out_path


def main():
    parser = argparse.ArgumentParser(description="Create a Cursed Knowledge or Deep Thought note.")
    parser.add_argument("--type", required=True, choices=["cursed-knowledge", "deep-thought"])
    parser.add_argument("--title", required=True)
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--body", default="", help="Optional initial body text")
    args = parser.parse_args()

    try:
        create_note(
            note_type=args.type,
            title=args.title,
            run_id=args.run_id,
            body=args.body,
        )
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
