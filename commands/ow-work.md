---
name: ow-work
description: WORK 트랙 진입점. mode를 명시하거나 문맥에서 자동 추론해 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다.
argument-hint: "[mode=<active|passive|draft|refine|route>] [args...] [--fast] [--skip preflight,external-tools,validation,context-card]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Skill
created: 2026-03-01T17:28
updated: 2026-05-22T00:00
---

`obsidian-workflows:ow-work`는 `write-*` 실행 명령으로 라우팅하는 WORK 트랙 엔트리포인트입니다.

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

Helper Script Path Resolution:
- helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.
- helper script를 쓸 때는 먼저 `obsidian-workflows` plugin/repo root를 해석하고, 해석된 root 아래의 절대 경로로 실행합니다.
- root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
- optional helper script 단계는 경고 후 건너뛰고, 본래 단계의 fail-safe 정책을 따릅니다.

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 helper script path resolution 규칙에 따라 plugin/repo root를 먼저 해석합니다.
2. root가 해석되고 external tool detector가 존재할 때만 절대 경로로 실행해 관련 도구를 탐지합니다. 현재 vault cwd 기준의 `src/...` 경로를 추측해 실행하지 않습니다.
3. 모드별 키워드:
   - `active`: markdown, obsidian, humanizer, write, draft, template
   - `draft`: markdown, obsidian, humanizer, write, draft, template
   - `refine`: humanizer, grammar, style, polish, edit, rewrite
4. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
5. root 또는 detector를 확인할 수 없으면 외부 도구 탐지만 경고 후 건너뛰고 워크플로우 계속 진행 (fail-safe)
6. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

Preflight Gate (fail-fast):
- 초기화 대상 목록의 canonical source는 `commands/write-init.md`의 `초기화 대상(코어)`/`초기화 대상(동적 정책)` 섹션입니다.
- **Fast mode가 아닐 때만** 전체 검증을 수행합니다:
1. 실행 시작 시 코어 대상 파일 존재를 먼저 검증합니다.
   - `writing-config.md`
   - `Workflows/SOUL.md`
   - `.claude/state/obsidian-write-passive.json`
2. `writing-config.md`에서 `enabled_policies`, `policy_dir`를 읽고 각 policy에 대해 `policy_dir/writing-policy.<policy>.md` 존재를 검증합니다.
3. 누락 파일이 있으면 `/write-init`를 먼저 실행해 초기화 프로세스를 시작합니다.
4. 초기화 후 동일한 코어/동적 정책 대상을 재검증합니다.
5. 여전히 누락이 남아있으면 `FAIL`로 종료하고 누락 목록을 출력합니다.
- **Fast mode일 때**: `writing-config.md` 존재만 확인하고 즉시 진행합니다.

모드 매핑(mode 지정 시 질문 없는 deterministic 실행):
- `mode=active` -> `write-active` (policy의 `source_strategy`/`missing_source_behavior` 계약을 따름; 예: daily-note에서 직전 노트가 없으면 `SKIP` + 최근 파일 후보 제시)
- `mode=passive` -> `obsidian-workflows:ow-plan --intent passive` (`scan -> propose`)
- `mode=draft` -> `write-draft`
- `mode=refine` -> `write-refine`
- `mode=route` -> `write-route`

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
- `mode`가 지정되면 추가 질문 없이 해당 경로를 실행합니다.
- `mode`가 없으면 아래 순서로 자동 추론합니다(파일 기반 신호 > PLAN 대화 문맥 신호 > 이번 턴 지시 신호 순으로 우선):
  1. `proposal` 또는 `idea` 인자가 있으면 `mode=draft` (변경 없음).
  2. **Active handoff 상태 파일 확인**: `.claude/state/obsidian-write-active-handoff.json`이 존재하고 `status: pending`이면 다음 순서로 진행합니다.
     1. 파일에서 `topic`, `policy`, `extra_args`를 로드합니다.
     2. **하위 명령(`write-active`) 실행 *전에* 즉시 `status: consumed`로 전이합니다.** 전이 실패 시 fail-fast로 종료합니다. 이 순서를 지키지 않으면 active 실행이 실패할 때 상태 파일이 `pending` 그대로 남아 같은 handoff가 다음 호출에서 자동으로 다시 잡혀 무한 재실행이 발생합니다.
     3. 로드한 인자로 하위 명령(`write-active`)을 실행합니다.
     - 스키마는 `docs/runtime/state-schema.md`의 "Active handoff state fields" 절을 참조합니다.
  3. `proposal_path` 디렉토리 스캔에서 pending/in-progress proposal이 감지되면 `mode=draft` (아래 "Proposal 자동 감지" 절과 동일한 규칙을 적용).
  4. 직전 PLAN 대화 문맥이 passive proposal 생성 완료를 가리키면 `mode=draft` (대화 문맥 fallback).
  5. 직전 PLAN 대화 문맥이 active handoff를 가리키면 `mode=active` (대화 문맥 fallback).
  6. **이번 턴 지시 자체가 모호하지 않은 직접 작성 명령이면 `mode=active`로 간주합니다.** 다음 두 조건을 모두 만족해야 합니다.
     - 명령형으로 즉시 반영을 요청한다 (예: "~작성하자", "~해줘", "~를 오늘 노트에 반영해줘").
     - 초안/제안/검토를 시사하는 표현이 전혀 없다 (예: "초안으로", "제안만", "검토 후", "draft로", "먼저 보여줘").
     두 조건 중 하나라도 불확실하면 이 규칙을 적용하지 않고 다음 단계로 넘어갑니다.
  7. 위 규칙으로도 불명확하면 사용자에게 질문합니다 (형식은 아래 "Mode 질문 형식" 절을 참조).
- 하위 명령의 입력 스키마를 그대로 따릅니다.
- 실패 시 조용한 fallback 없이 즉시 종료하고 원인/해결 액션을 반환합니다.
- 사용자가 명령어를 복사해 실행하는 흐름이 아닙니다. 현재 세션에서 routing을 수행할 수 있으면 플랫폼의 skill-invocation primitive를 사용합니다.

Mode 질문 형식:
- 이 지점은 새 규칙 6이 이미 "모호하지 않은 직접 지시"를 걸러낸 뒤에만 도달하는 예외 경로다 — 즉 여기 남는 건 정말로 신호가 부족한 경우뿐이다. 이번 버그의 실제 증상이 바로 이 지점에서 구조화된 질문 대신 장문 설명 프로즈("mode=active로 실행하시겠습니까? 아니면 다른 모드(draft...")로 새어나간 것이었다. 그래서 이 지점만큼은 `ow-plan.md`와 동일한 강도로 못박는다:
- **STOP.** 반드시 `AskUserQuestion` 도구를 fire하여 선택지를 제시합니다. 장문 설명 문단으로 질문을 대신하는 것은 명세 위반입니다.
- `AskUserQuestion` 스키마가 미리 로드되지 않았으면 `ToolSearch`에 `select:AskUserQuestion`을 먼저 호출해 로드한 뒤 fire합니다. 스키마 로드가 번거롭다는 이유로 텍스트 안내로 fallback하지 마세요 — 학습된 default 패턴에 빠지는 가장 흔한 경로입니다.
- Question stem: 이번 턴 요청·인자에서 topic을 특정할 수 있으면 `"{topic}을(를) 어떤 모드로 진행할까요?"`를, 특정할 수 없으면 `"이 작업을 어떤 모드로 진행할까요?"`를 쓴다. (규칙 2의 handoff 경로는 `topic` 로드 후 곧장 active를 실행하거나 fail-fast로 종료하므로 이 질문 지점에는 도달하지 않는다 — topic 출처를 handoff로 한정하지 말 것.)
- 옵션(최대 4개, 라벨은 아래 그대로 사용): `active`(지금 바로 대상 문서에 반영) / `draft`(초안을 먼저 만들어 검토 후 반영) / `passive`(소스를 스캔해 제안만 생성) / `refine`(기존 문서의 문체만 다듬기). `route`는 이 메뉴에 넣지 않는다 — `AskUserQuestion`은 항상 "Other" 자유 입력을 제공하므로, 흔치 않은 `route` 케이스는 거기로 흡수한다.
- 사용자 선택을 받으면 별도 확인 없이 즉시 해당 mode 경로를 실행합니다.

상태/출력 규칙:
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
- `mode=passive`의 empty candidate는 오류가 아니라 `SKIP`입니다.
