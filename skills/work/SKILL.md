---
name: workflow-work-reference
description: WORK 트랙 진입점. mode를 명시하거나 파일/상태 신호에서 자동 추론해 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다.
user-invocable: true
version: 0.1.0
created: 2026-03-02T14:58
updated: 2026-06-15T00:00
---

# WORK Track Entry Point

`obsidian-workflows:ow:work`는 WORK 트랙 엔트리포인트입니다. 이 문서는 `commands/ow/work.md`의 mirror입니다. 동작이 갈리면 `commands/ow/work.md`를 canonical source로 보고 이 파일을 맞춥니다.

## Mode Routing

### With mode parameter

`mode`가 지정되면 추가 질문 없이 해당 경로를 실행합니다.

- `mode=active` → `obsidian:write.active`
- `mode=passive` → `obsidian-workflows:ow:plan --intent passive` equivalent (scan → propose)
- `mode=draft` → `obsidian:write.draft`
- `mode=refine` → `obsidian:write.refine`
- `mode=route` → `obsidian:write.route`

### Without mode parameter

파일 기반 신호를 대화 문맥보다 우선합니다.

1. `proposal` 또는 `idea` 인자가 있으면 `mode=draft`.
2. `.claude/state/obsidian-write-active-handoff.json`이 존재하고 `status: pending`이면 active handoff로 처리합니다.
   - 파일에서 `topic`, `policy`, `extra_args`를 로드합니다.
   - 하위 명령 실행 전에 즉시 `status: consumed`로 전이합니다. 전이에 실패하면 fail-fast로 종료합니다.
   - 로드한 인자로 `obsidian:write.active`를 실행합니다.
3. `proposal_path` 디렉터리에서 pending/in-progress proposal이 감지되면 `mode=draft`.
4. 직전 PLAN 대화 문맥이 passive proposal 생성을 가리키면 `mode=draft`.
5. 직전 PLAN 대화 문맥이 active handoff를 가리키면 `mode=active`.
6. 그래도 불명확하면 사용자에게 질문합니다.

## Active Handoff from PLAN

`obsidian-workflows:ow:plan`의 active handoff는 사용자가 명령어를 복사해 실행하는 흐름이 아닙니다.

- 사용자가 PLAN 메뉴에서 `바로 실행`을 선택하면 PLAN이 상태 파일을 `consumed`로 사전 기록한 뒤 `Skill` 도구로 `obsidian-workflows:ow:work`를 즉시 fire합니다.
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

## Status/Output Rules

- Status meanings are `PASS|SKIP|FAIL` only.
  - `PASS`: Routing completed and target command executed
  - `SKIP`: `mode=passive` produced 0 scan candidates (normal empty case)
  - `FAIL`: Invalid mode or routing error
- On failure, terminate immediately without silent fallback.
