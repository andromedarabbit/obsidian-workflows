---
name: ow-work
description: 'WORK 트랙 진입점. mode를 명시하거나 파일·상태 신호에서 active/passive/draft/refine/route 중 하나를 추론해 바로 실행합니다.'
when_to_use: '"draft로 써줘", "이 proposal 진행해줘", "mode 정해줘", "refine 한 번 더"처럼 작성 트랙을 즉시 실행할 때 사용합니다.'
version: 0.3.0
context: inline
language: korean
created: 2026-03-02T14:58
updated: 2026-08-06T00:00
---

# WORK Track Entry Point

## Mode Routing

### With mode parameter

`mode`가 지정되면 추가 질문 없이 해당 경로를 실행합니다.

- `mode=active` → `write-active`
- `mode=passive` → `obsidian-workflows:ow-plan --intent passive` equivalent (scan → propose)
- `mode=draft` → `write-draft`
- `mode=refine` → `write-refine`
- `mode=route` → `write-route`

### Without mode parameter

`mode`가 없으면 파일 기반 신호 > PLAN 대화 문맥 > 이번 턴 지시 순으로 우선해 active/passive/draft/refine 중 하나를 추론한다. pending active handoff 상태 파일(`.claude/state/obsidian-write-active-handoff.json`)이 있으면 이를 소비해 `write-active`로 즉시 연결한다. 추론 7단계와 신호 부족 시 `AskUserQuestion` 모드 질문 형식의 상세는 `references/mode-inference.md`를 읽어 적용한다.

## Active Handoff from PLAN

`obsidian-workflows:ow-plan`의 active handoff는 사용자가 명령어를 복사해 실행하는 흐름이 아닙니다.

- 사용자가 PLAN 메뉴에서 `바로 실행`을 선택하면 PLAN이 상태 파일을 `consumed`로 사전 기록한 뒤 `Skill` 도구로 `obsidian-workflows:ow-work`를 즉시 fire합니다.
- 사용자가 PLAN 메뉴에서 `나중에`를 선택하면 PLAN이 `.claude/state/obsidian-write-active-handoff.json`을 `status: pending`으로 저장합니다. 이후 mode 없이 WORK가 호출되면 위 자동 추론 #2가 이 상태를 소비합니다.
- WORK는 pending 상태를 소비한 뒤 active 실행이 실패하더라도 같은 handoff를 다음 호출에서 무한 재실행하지 않도록 해야 합니다.

## Proposal Auto-Detection

When `mode=draft` and `proposal` parameter is not provided:

1. Read `proposal_path` from `writing-config.md`.
2. Scan for Markdown files in `proposal_path`.
3. Read frontmatter of each file and check `status`.
4. Priority order:
   - `status: in-progress` (newest first)
   - `status: pending` (newest first)
   - missing `status` field (newest first)
   - skip `status: completed`
5. Use `default_idea` from config when `idea` is not provided.
6. If `proposal_auto_select: true`, proceed without asking.
7. If `proposal_auto_select: false`, show the detected proposal and ask for confirmation.

## Execution Rules

1. Validate `mode` if provided.
2. If `mode` is invalid, immediately terminate with `FAIL`.
3. If `mode` is missing, infer mode with the file-first rules above.
4. Route to the appropriate command based on mode.
5. Pass through all additional parameters (`topic`, `policy`, `file`, `proposal`, `idea`, etc.).
6. Do not end by telling the user to copy and run another slash command. If routing can be performed in the current session, use the platform skill-invocation primitive.

## Helper Script Path Resolution

Helper script는 `docs/contracts/helper-script-path.md`의 경로 규칙을 따른다(plugin/repo root 기준 절대 경로, vault cwd 상대 `src/...` 실행 금지, 해석 실패 시 추측 금지).

## Status/Output Rules

- Status meanings are `PASS|SKIP|FAIL` only.
  - `PASS`: Routing completed and target command executed
  - `SKIP`: `mode=passive` produced 0 scan candidates (normal empty case)
  - `FAIL`: Invalid mode or routing error
- On failure, terminate immediately without silent fallback.
