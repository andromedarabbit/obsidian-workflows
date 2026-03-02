---
name: work
description: This skill should be used when the user wants to execute writing work, asks for "obsidian-workflows:work", needs to draft or refine content, or wants to route to specific writing modes (active/passive/draft/refine). Use when user says "work", "write", "draft", "refine", "execute writing".
version: 0.1.0
created: 2026-03-02T14:58
updated: 2026-03-02T17:40
---

# WORK Track Entry Point

`obsidian-workflows:work` is the WORK track entry point. When `mode` is specified, it deterministically executes one of: active/passive/draft/refine/route.

## Mode Routing

### Without mode parameter:
- Immediately terminate with `FAIL` status.
- Instruct user to specify one of `active|passive|draft|refine|route`.

### With mode parameter:
- `mode=active` → Execute `/obsidian:write.active`
- `mode=passive` → Execute `/obsidian-workflows:plan --intent passive` (scan → propose)
- `mode=draft` → Execute `/obsidian:write.draft`
- `mode=refine` → Execute `/obsidian:write.refine`
- `mode=route` → Execute `/obsidian:write.route`

## Proposal Auto-Detection

When `mode=draft` and `proposal` parameter is not provided:

1. Read `proposal_path` from `writing-config.md`.
2. Scan for `.md` files in `proposal_path` directory.
3. Read frontmatter of each file to check `status` field.
4. Priority order:
   - Files with `status: in-progress` (most recent by `updated`)
   - Files with `status: pending` (most recent by `updated`)
   - Files without `status` field (most recent by `updated`)
   - Skip files with `status: completed`
5. Use `default_idea` from config (default: 1) if `idea` parameter not provided.
6. If `proposal_auto_select: true` in config, proceed without asking.
7. If `proposal_auto_select: false`, show detected proposal and ask for confirmation.

## Execution Rules

1. Validate mode parameter if provided.
2. If mode is invalid, immediately terminate with `FAIL` status.
3. Route to appropriate command based on mode.
4. Pass through all additional parameters (topic, policy, file, etc.).

## Status/Output Rules

- Output Context Card at start/end with: `command`, `mode`, `status`.
- Status meanings: `PASS|SKIP|FAIL` only.
  - `PASS`: Routing completed and target command executed
  - `SKIP`: `mode=passive` produced 0 scan candidates (normal empty case)
  - `FAIL`: Invalid mode or routing error
- On failure, terminate immediately without silent fallback.

## Usage

```
/obsidian-workflows:work mode=active topic="My Topic" policy=blog
/obsidian-workflows:work mode=draft proposal="path/to/proposal.md" idea=1
/obsidian-workflows:work mode=refine file="path/to/draft.md"
```
