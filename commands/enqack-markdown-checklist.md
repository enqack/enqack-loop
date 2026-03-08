---
description: "Verify Markdown structure and quality"
allowed-tools: ["Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cvr/format_md.py:*)"]
hide-from-slash-command-tool: "false"
---

# enqack-markdown-checklist

Verify Markdown structure and quality across the repository.

## Precondition

- `knowledge-vault/Intent/project_intent.md` exists.

If precondition is not met:

- **FAIL CLOSED**
- Ask the operator: "What are you trying to produce in this repo?"
- Run `/enqack-establish-intent`.
- Do **not** continue until intent is established.

## Steps

1. **Format**

   - Run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cvr/format_md.py"`
   - If it fails with a missing dependency error, inform the user:
     - `mdformat`: `pip install mdformat`
     - `markdownlint-cli2`: `npm install -g markdownlint-cli2`

1. **Verify Structure**

   - [ ] Fenced code blocks have language identifiers?
   - [ ] Blank lines surround code blocks?
   - [ ] Lists use consistent indentation (2 spaces)?
   - [ ] No mixed bullets (`-` vs `*`)?
   - [ ] No hard-coded file links (`file://`)?

1. **Verify Links**

   - [ ] All internal links are repo-relative?
   - [ ] External links are valid (`https://`)?

1. **Commit**

   - Only commit after formatting passes cleanly.
