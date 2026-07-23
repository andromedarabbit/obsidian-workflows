---
name: ow-plan
description: PLAN 트랙 진입점. 자연어 작성 요청은 active로, 작성 지시 없는 빈 plan은 passive 제안으로 라우팅하고, 종료는 텍스트 명령어가 아니라 AskUserQuestion handoff로 처리합니다. 글쓰기 주제를 계획하거나 초안 작성 여부를 판단해야 할 때 사용합니다.
version: 0.2.0
context: inline
language: korean
created: 2026-03-02T01:34
updated: 2026-07-07T00:00
---

# PLAN Track Entry Point

> 미러 파일: 동작 정본은 `commands/ow-plan.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

## Intent Gate

1. `--intent=active`면 질문 없이 active 분기로 진행합니다.
2. `--intent=passive`면 질문 없이 passive 분기로 진행합니다.
3. `--intent`가 없고 free-form 작성 지시가 있으면 질문 없이 active 분기로 진행합니다.
   - free-form 작성 지시는 명령 인자에 자연어 topic과 즉시 작성 동사가 함께 있는 경우입니다.
   - 한국어 동사 예: `작성`, `작성하자`, `써`, `써줘`, `정리해줘`.
   - 영어 동사 예: `write`, `draft`, `compose`.
   - 예: `/obsidian-workflows:ow-plan 팀 스탠드업 문서를 작성` → `intent=active`, `topic="팀 스탠드업 문서"`.
4. `--intent`가 없고 free-form 작성 지시도 없으면 기본값으로 `passive`를 사용합니다.
5. `--intent` 값이 유효하지 않으면 즉시 `FAIL`로 종료합니다.

## Branch Execution Rules

### Active Branch

1. 선택 policy의 `topic_required` 계약을 먼저 적용합니다.
2. `topic_required: true`이고 `topic`이 없으면 즉시 종료합니다(fail-fast).
3. `topic_required: false` 정책(예: daily-note)은 `topic` 없이도 진행할 수 있습니다.
4. Fast mode가 아니면 필요한 리서치를 수행하고, Fast mode면 topic/policy 확정만 수행합니다.
5. 종료 시 텍스트 명령어를 안내하지 말고 `AskUserQuestion` 4옵션 handoff 메뉴를 표시합니다.

### Passive Branch

1. `writing-config.md`에서 `source_paths`, `exclude_paths`, `proposal_path`, `final_path`를 확인합니다.
2. `write-scan` 규칙으로 후보 파일을 수집합니다.
3. `write-propose` 규칙으로 아이디어 3~5개를 proposal note로 저장합니다.
4. 생성된 proposal 파일을 읽어 아이디어 제목, 핵심 논지, 추천 policy를 추출합니다.
5. proposal 요약 출력 후 텍스트 명령어를 안내하지 말고 `AskUserQuestion` 4옵션 handoff 메뉴를 표시합니다.

## Active Handoff Menu

Active 분기 종료 직후 `AskUserQuestion` 도구를 즉시 fire합니다. 메뉴를 텍스트로 설명하고 멈추면 완료가 아닙니다.

- stem: `Active plan 완료 (topic="<topic>", policy=<policy>). 다음에 무엇을 할까요?`
- options:
  1. `바로 실행` (recommended)
  2. `계획 다듬기`
  3. `다른 정책으로`
  4. `나중에`

옵션별 동작:

1. **바로 실행**
   - plan에서 받은 active 분기용 추가 인자(`--source`, `--window-days`, `--skip` 등)를 `extra_args`로 묶습니다.
   - `.claude/state/obsidian-write-active-handoff.json`을 `status: consumed`로 사전 기록합니다.
   - 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow-work`를 즉시 fire합니다. Claude Code에서는 `Skill` 도구를 사용합니다.
2. **계획 다듬기**
   - 사용자에게 다듬을 부분을 묻고 active 분기를 다시 실행합니다. 이후 이 메뉴를 다시 표시합니다.
3. **다른 정책으로**
   - enabled policy 후보를 제시하고 선택을 받아 active 분기를 다시 실행합니다. 이후 이 메뉴를 다시 표시합니다.
4. **나중에**
   - `.claude/state/obsidian-write-active-handoff.json`을 `status: pending`으로 저장하고 종료합니다. 이후 mode 없는 `obsidian-workflows:ow-work`가 이를 감지합니다.

Completion check:

1. `AskUserQuestion` 도구로 위 4옵션 메뉴를 fire합니다.
2. 사용자 선택을 수신합니다.
3. 선택에 따른 인라인 routing을 즉시 실행합니다.

## Passive Handoff Menu

Passive 분기 종료 직후 proposal 요약을 출력하고 `AskUserQuestion` 도구를 즉시 fire합니다. proposal만 만들고 텍스트 명령어를 안내하면 완료가 아닙니다.

- stem: `Passive proposal 생성 완료 (<N>개 아이디어). 다음에 무엇을 할까요?`
- options:
  1. `Idea 선택해서 draft` (recommended)
  2. `proposal 다듬기`
  3. `다른 정책으로`
  4. `나중에`

옵션별 동작:

1. **Idea 선택해서 draft**
   - 사용자에게 idea 번호를 묻고 proposal frontmatter의 `status`를 `in-progress`, `selected_idea`를 선택 번호로 갱신합니다.
   - 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow-work`를 즉시 fire합니다. Claude Code에서는 `Skill` 도구를 사용합니다.
2. **proposal 다듬기**
   - 아이디어 추가/교체 요청을 받아 propose를 다시 실행합니다. 이후 이 메뉴를 다시 표시합니다.
3. **다른 정책으로**
   - policy 후보를 제시하고 선택을 받아 propose를 다시 실행합니다. 이후 이 메뉴를 다시 표시합니다.
4. **나중에**
   - proposal frontmatter를 `status: pending`으로 유지하고 종료합니다.

Completion check:

1. proposal 요약 출력 후 `AskUserQuestion` 도구로 위 4옵션 메뉴를 fire합니다.
2. 사용자 선택을 수신합니다.
3. 선택에 따른 인라인 routing을 즉시 실행합니다.

## Helper Script Path Resolution

Helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.

1. 먼저 `obsidian-workflows` plugin/repo root를 해석합니다.
2. helper script를 사용할 때는 해석된 root 아래의 절대 경로로 실행합니다.
3. root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
4. optional helper script 단계는 경고 후 건너뛰고, 본래 command의 fail-fast/fail-safe 정책을 따릅니다.

## Status/Output Rules

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: 분기 실행이 정상 완료됨
  - `SKIP`: passive 후보가 0건인 정상 empty case
  - `FAIL`: preflight/입력/실행 오류
- 실패 시 조용한 fallback 없이 즉시 종료합니다.
- passive는 proposal 생성까지만 수행하고 초안 자동 생성은 하지 않습니다.
- 사용자가 명령어를 직접 복사해 실행해야 하는 형태로 종료하지 않습니다.
