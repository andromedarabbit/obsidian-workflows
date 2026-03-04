---
name: ow:work
description: WORK 트랙 진입점. mode 지정 시 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다.
argument-hint: mode=<active|passive|draft|refine|route> [args...] [--fast] [--skip preflight,external-tools,validation,context-card]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-04T22:00
---

`obsidian-workflows:work`는 `obsidian:write.*` 실행 명령으로 라우팅하는 WORK 트랙 엔트리포인트입니다.

주의:
- 로컬 워크플로우는 `/obsidian-workflows:*`를 사용합니다.
- `/compound-engineering:workflows:*`는 다른 플러그인 스킬입니다.

Scope Guard (repo-only):
- 실행 대상은 vault root 하위 저장소 파일로 제한합니다.
- `~/.claude/*` 같은 전역 런타임 상태를 해결책으로 사용하지 않습니다.

Selective Step Skipping (--skip):
- `--skip` 플래그로 특정 단계를 건너뛸 수 있습니다.
- 건너뛸 수 있는 단계:
  - `preflight`: 초기화 검증
  - `external-tools`: 외부 도구 탐지
  - `validation`: 입력 검증 (proposal/policy 검증)
  - `context-card`: Context Card 출력
- 여러 단계를 쉼표로 구분: `--skip preflight,validation`
- 프리셋 설정: `writing-config.md`의 `skip_steps.work` 배열

Smart Mode Selection:
- `workflow_mode: auto`일 때 컨텍스트를 분석해서 자동으로 fast/full 모드를 선택합니다.
- Fast mode 자동 선택 조건:
  - Proposal 파일이 이미 존재하고 idea가 선택됨
  - 동일 policy를 최근 24시간 내 3회 이상 사용
  - Draft 모드에서 proposal이 이미 검증됨
- Full mode 자동 선택 조건:
  - 첫 실행 (초기화 필요)
  - Active 모드에서 복잡한 주제
  - `--verbose` 플래그
- 수동 override: `--fast` 플래그로 강제 fast mode

Fast Mode (--fast):
- `--fast` 플래그가 있으면 속도 최적화 모드로 실행합니다.
- Fast mode 동작:
  - Preflight 검증 간소화 (파일 존재 확인만)
  - External tools 탐지 비활성화
  - Draft 모드: Proposal 파일 읽기만 (검증 생략)
  - Refine 모드: SOUL 규칙 간소화 적용
  - Wikilinks 생성 생략
  - Context Card 출력 최소화
- Fast mode는 단순 작업에 최적화되어 있습니다.

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 `src/external-tools/keyword-detector.js`를 사용해 관련 도구를 탐지합니다.
2. 모드별 키워드:
   - `active`: markdown, obsidian, humanizer, write, draft, template
   - `draft`: markdown, obsidian, humanizer, write, draft, template
   - `refine`: humanizer, grammar, style, polish, edit, rewrite
3. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
4. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

Preflight Gate (fail-fast):
- 초기화 대상 목록의 canonical source는 `commands/obsidian-write/obsidian:write.init.md`의 `초기화 대상(코어)`/`초기화 대상(동적 정책)` 섹션입니다.
- **Fast mode가 아닐 때만** 전체 검증을 수행합니다:
1. 실행 시작 시 코어 대상 파일 존재를 먼저 검증합니다.
   - `writing-config.md`
   - `Workflows/SOUL.md`
   - `.claude/state/obsidian-write-passive.json`
2. `writing-config.md`에서 `enabled_policies`, `policy_dir`를 읽고 각 policy에 대해 `policy_dir/writing-policy.<policy>.md` 존재를 검증합니다.
3. 누락 파일이 있으면 `/obsidian:write.init`를 먼저 실행해 초기화 프로세스를 시작합니다.
4. 초기화 후 동일한 코어/동적 정책 대상을 재검증합니다.
5. 여전히 누락이 남아있으면 `FAIL`로 종료하고 누락 목록을 출력합니다.
- **Fast mode일 때**: `writing-config.md` 존재만 확인하고 즉시 진행합니다.

모드 매핑(mode 지정 시 질문 없는 deterministic 실행):
- `mode=active` -> `obsidian:write.active` (policy의 `source_strategy`/`missing_source_behavior` 계약을 따름; 예: daily-note에서 직전 노트가 없으면 `SKIP` + 최근 파일 후보 제시)
- `mode=passive` -> `obsidian-workflows:plan --intent passive` (`scan -> propose`)
- `mode=draft` -> `obsidian:write.draft`
- `mode=refine` -> `obsidian:write.refine`
- `mode=route` -> `obsidian:write.route`

Proposal 자동 감지 (mode=draft이고 proposal 미지정 시):
1. `writing-config.md`에서 `proposal_path` 읽기
2. `proposal_path` 디렉토리의 `.md` 파일 스캔
3. 각 파일의 frontmatter에서 `status` 필드 확인
4. 우선순위:
   - `status: in-progress` (최신순)
   - `status: pending` (최신순)
   - `status` 필드 없음 (최신순)
   - `status: completed`는 제외
5. `idea` 미지정 시 config의 `default_idea` 사용 (기본값: 1)
6. `proposal_auto_select: true`면 자동 진행
7. `proposal_auto_select: false`면 감지된 proposal 표시 후 확인 요청

실행 규칙:
- 시작/종료 시 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)를 출력합니다.
- `mode`가 없으면 즉시 `FAIL`로 종료하고 `active|passive|draft|refine|route` 중 하나를 지정하도록 안내합니다.
- `mode`가 지정되면 추가 질문 없이 해당 경로를 실행합니다.
- 하위 명령의 입력 스키마를 그대로 따릅니다.
- 실패 시 조용한 fallback 없이 즉시 종료하고 원인/해결 액션을 반환합니다.

상태/출력 규칙:
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
- `mode=passive`의 empty candidate는 오류가 아니라 `SKIP`입니다.
