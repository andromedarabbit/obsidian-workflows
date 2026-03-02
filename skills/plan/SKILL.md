---
name: plan
description: This skill should be used when the user wants to plan writing content, asks for "obsidian-workflows:plan", wants to start a writing workflow, or needs to choose between active writing (known topic) or passive discovery (scan for ideas). Use when user says "plan", "start writing", "writing workflow", "obsidian plan".
version: 0.1.0
created: 2026-03-02T01:34
updated: 2026-03-02T01:34
---

# PLAN Track Entry Point

`obsidian-workflows:plan` is the intent-selection entry point for the PLAN track.

## Important Notes

- This is a local plugin entry point (`/obsidian-workflows:plan`).
- `/compound-engineering:workflows:plan` is a different plugin skill and will not execute this plugin's plan flow.

## Scope Guard (repo-only)

- Implementation/validation/output targets only vault root repository files.
- Do not use `~/.claude/*` global runtime state as a solution.

## Preflight Gate (fail-fast)

The canonical source for initialization targets is the `초기화 대상` section in `commands/obsidian-write/obsidian:write.init.md`.

1. At execution start, verify existence of `obsidian:write.init` initialization target files:
   - `writing-config.md`
   - `Workflows/policy/writing-policy.blog.md`
   - `Workflows/policy/writing-policy.x-thread.md`
   - `Workflows/policy/writing-policy.weekly-review.md`
   - `Workflows/policy/writing-policy.newsletter.md`
   - `Workflows/SOUL.md`
   - `.claude/state/obsidian-write-passive.json`
2. If any are missing, immediately terminate with `FAIL` status.
3. At termination, output missing file list and next action (`/obsidian:write.init`).
4. Do not perform automatic initialization.

## Intent Gate

1. If `--intent` is not provided, first confirm user intent:
   - A) Already have a topic (`active`)
   - B) Want to scan recent changes for topic suggestions (`passive`)
2. If `--intent=active`, proceed to active branch without questions.
3. If `--intent=passive`, proceed to passive branch without questions.
4. If `--intent` value is invalid, immediately terminate with `FAIL` status.

## Branch Execution Rules

### Active Branch:
1. Check if `topic` is required.
2. If `topic` is missing, immediately terminate (fail-fast).
3. Explicitly handoff to next execution command:
   - `/obsidian-workflows:work mode=active topic="..." policy=...`
   - `/obsidian:write.active topic="..." policy=...`

### Passive Branch:
1. Check `source_paths`, `exclude_paths`, `proposal_path`, `final_path` from `writing-config.md`.
2. Collect candidate files using `obsidian:write.scan` rules.
3. Save 3-5 ideas as proposal notes using `obsidian:write.propose` rules.
4. Proposal frontmatter must include:
   - `status: pending` (initial state)
   - `selected_idea: null`
   - `draft_path: null`
5. At termination, output:
   - Generated proposal file path
   - List of idea titles (Idea 1: [title], Idea 2: [title], ...)
   - Next step: `/obsidian-workflows:work proposal="..." idea=N`
   - Note: User should review ideas and choose which one to develop

## Status/Output Rules

- Read output settings from `writing-config.md`:
  - `output_verbosity`: minimal | standard | verbose (default: minimal)
  - `show_context_card`: Show Context Card (default: false)
  - `idea_detail_lines`: Detail lines per idea 1-5 (default: 3)
  - `show_wikilinks`: Show reference wikilinks (default: true)
- `--verbose` flag overrides `output_verbosity` to `verbose`.
- Context Card only shown when `show_context_card: true` or `--verbose` flag present.
- Status meanings: `PASS|SKIP|FAIL` only.
  - `PASS`: Branch execution completed normally
  - `SKIP`: Normal empty case with 0 passive candidates
  - `FAIL`: preflight/input/execution error
- On failure, terminate immediately without silent fallback.
- Passive only performs proposal note creation, not automatic draft generation.

Output format by verbosity:
- `minimal`:
  ```
  ✓ Passive proposal created: [path]

  [N] ideas generated. Review and select one:

    1. [title1]
    2. [title2]
    ...

  Next: /obsidian-workflows:work proposal="..." idea=N
  ```
- `verbose`:
  ```
  [Full Context Card]

  요청하신 Passive 분기로 실행 완료했습니다.

  - 생성된 proposal 파일: [path]
  - 아이디어 목록:
    - Idea 1: [title]
    ...

  다음 단계: /obsidian-workflows:work proposal="..." idea=N
  ```

## Usage

```
/obsidian-workflows:plan
/obsidian-workflows:plan --intent active topic="My Topic" policy=blog
/obsidian-workflows:plan --intent passive --window-days 7
/obsidian-workflows:plan --intent passive --verbose
```
