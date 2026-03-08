#!/usr/bin/env python3
"""format_md.py - Format and lint Markdown files.

Usage:
  python3 scripts/cvr/format_md.py          # Format (rewrite) all .md files
  python3 scripts/cvr/format_md.py --check  # Check formatting (exit 1 if changed)

Dependencies (soft):
  - mdformat (Python): pip install mdformat
  - markdownlint-cli2 (Node.js): npm install -g markdownlint-cli2

Run from the host project root (CLAUDE_PROJECT_DIR).
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List

# Resolve sibling paths.py regardless of install location or CWD
sys.path.insert(0, str(Path(__file__).resolve().parent))
import paths

try:
    import mdformat  # noqa: F401
    HAS_MDFORMAT = True
except ImportError:
    HAS_MDFORMAT = False


def find_markdown_files(root: Path) -> List[Path]:
    """Find all .md files, skipping common noise directories."""
    md_files = []
    for root_dir, dirs, files in os.walk(root):
        for skip in (".git", ".venv", "node_modules", "vendor", "scenarios"):
            if skip in dirs:
                dirs.remove(skip)
        for f in files:
            if f.endswith(".md"):
                md_files.append(Path(root_dir) / f)
    return md_files


def run_markdownlint(check_only: bool) -> int:
    """Run markdownlint-cli2 if available."""
    cmd = ["markdownlint-cli2", "**/*.md", "#node_modules", "#vendor", "#scenarios"]

    if shutil.which("markdownlint-cli2"):
        final_cmd = cmd
    elif shutil.which("nix-shell"):
        print("==> Bridging markdownlint-cli2 via nix-shell...", file=sys.stderr)
        inner = " ".join(cmd)
        final_cmd = ["nix-shell", "-p", "markdownlint-cli2", "--run", inner]
    else:
        print("WARNING: markdownlint-cli2 not found — skipping lint step.", file=sys.stderr)
        return 0

    print("==> Running markdownlint-cli2...")
    try:
        subprocess.run(final_cmd, check=True)
        return 0
    except subprocess.CalledProcessError:
        return 1


def main() -> int:
    if not HAS_MDFORMAT:
        print(
            "ERROR: mdformat not installed. Run: pip install mdformat",
            file=sys.stderr,
        )
        return 1

    check_mode = "--check" in sys.argv

    repo_root = Path.cwd()
    files = [str(f.relative_to(repo_root)) for f in find_markdown_files(repo_root)]

    if not files:
        print("No markdown files found.")
        return 0

    print(f"==> Running mdformat ({'check' if check_mode else 'write'}) on {len(files)} files...")

    base_cmd = [sys.executable, "-m", "mdformat"]
    if check_mode:
        base_cmd.append("--check")

    cmd = base_cmd + files

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        print("FAIL: mdformat found issues.")
        return 1

    return run_markdownlint(check_mode)


if __name__ == "__main__":
    sys.exit(main())
