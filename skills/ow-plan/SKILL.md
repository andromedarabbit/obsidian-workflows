---
name: ow-plan
description: 'PLAN 트랙 진입점. 글쓰기 주제를 기획하거나 초안 작성 여부를 판단해 active/passive로 라우팅합니다. "블로그 아이디어 3개 제안", "이 주제로 쓸까", "최근 노트에서 쓸 거 있나"처럼 주제를 정하거나 초안 착수 여부를 결정할 때 사용합니다.'
version: 0.2.0
context: inline
language: korean
created: 2026-03-02T01:34
updated: 2026-08-06T00:00
---

# PLAN Track Entry Point

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

### Handoff Menus

각 분기 종료 시 텍스트 명령어 안내가 아닌 `AskUserQuestion` 4옵션 메뉴를 즉시 fire한다. Active/Passive 메뉴의 stem·옵션 라벨·옵션별 동작·Completion check 상세는 `references/handoff-menu.md`를 읽어 적용한다.

## Helper Script Path Resolution

Helper script는 `docs/contracts/helper-script-path.md`의 경로 규칙을 따른다(plugin/repo root 기준 절대 경로, vault cwd 상대 `src/...` 실행 금지, 해석 실패 시 추측 금지).

## Status/Output Rules

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: 분기 실행이 정상 완료됨
  - `SKIP`: passive 후보가 0건인 정상 empty case
  - `FAIL`: preflight/입력/실행 오류
- 실패 시 조용한 fallback 없이 즉시 종료합니다.
- passive는 proposal 생성까지만 수행하고 초안 자동 생성은 하지 않습니다.
- 사용자가 명령어를 직접 복사해 실행해야 하는 형태로 종료하지 않습니다.
