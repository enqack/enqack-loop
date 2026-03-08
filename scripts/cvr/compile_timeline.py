#!/usr/bin/env python3
"""compile_timeline.py - Compile per-run Deep Thoughts notes from journals.

For each journal in knowledge-vault/Journal/, emits an individual
note to knowledge-vault/Deep Thoughts/<run-id>.md.

Run from the host project root (CLAUDE_PROJECT_DIR).
"""

import re
import sys
from pathlib import Path

# Resolve sibling paths.py regardless of install location or CWD
sys.path.insert(0, str(Path(__file__).resolve().parent))
import paths


def parse_journal_date(journal_path: Path) -> str:
    name = journal_path.stem
    match = re.search(r"(\d{4}-\d{2}-\d{2})", name)
    return match.group(1) if match else "unknown"


def make_deep_thought(run_id: str, date_str: str, journal_content: str) -> str:
    frontmatter = (
        "---\n"
        f"type: deep-thought\n"
        f"run_id: {run_id}\n"
        f"date: {date_str}\n"
        f'run: "[[Runs/{run_id}/implementation_plan]]"\n'
        f'journal: "[[Journal/{run_id}]]"\n'
        'tags: ["deep-thought"]\n'
        "---\n\n"
    )
    body = f"# Deep Thought: {run_id}\n\n{journal_content.strip()}\n"
    return frontmatter + body


def main():
    journal_dir = paths.JOURNAL_DIR
    deep_thoughts_dir = paths.DEEP_THOUGHTS_DIR

    if not journal_dir.exists():
        print(f"No journals found at {journal_dir}")
        return

    deep_thoughts_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for journal_path in sorted(journal_dir.glob("*.md")):
        run_id = journal_path.stem
        date_str = parse_journal_date(journal_path)
        content = journal_path.read_text(encoding="utf-8")

        out_path = deep_thoughts_dir / f"{run_id}.md"
        out_path.write_text(make_deep_thought(run_id, date_str, content), encoding="utf-8")
        print(f"  [ok] Deep Thought: {out_path.relative_to(Path.cwd())}")
        count += 1

    print(f"Deep Thoughts compiled: {count} notes.")


if __name__ == "__main__":
    main()
