---
name: ow:plan
description: PLAN 트랙 진입점. 의도를 먼저 확인해 active handoff 또는 passive 제안을 수행합니다.
argument-hint: "[--intent active|passive] [topic=...] [policy=<policy-name>] [--window-days N] [--source path1,path2] [--verbose] [--fast] [--skip preflight,external-tools,research,context-card]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-05-23T00:00
---

`obsidian-workflows:plan`은 PLAN 트랙의 의도 선택형 엔트리포인트입니다.

> **Critical contract — Plan 종료 출력**
>
> Active/Passive 두 분기 모두, plan 종료의 출력은 **항상 `AskUserQuestion` 4-옵션 메뉴여야 합니다**. 텍스트 명령어 안내로 종료하면 명세 위반입니다.
>
> 이 skill에서 흔히 발생하는 실패 모드:
> - AI가 plan 분기를 실행한 뒤 "다음 단계: `/obsidian-workflows:work mode=active topic="..." policy=...`" 같은 텍스트 안내를 출력하고 멈추는 것.
> - 사용자에게 명령어를 복붙시키는 워크플로우는 **폐기되었습니다**. 이 형태로 종료하면 명세 위반입니다.
>
> 올바른 종료:
> 1. `AskUserQuestion` 도구를 fire하여 4-옵션 메뉴를 표시
> 2. 사용자 선택을 수신
> 3. 선택에 따른 인라인 routing을 즉시 실행 (메뉴를 띄우고 멈추는 것은 완료가 아닙니다)
>
> 자세한 옵션 정의, 동작, completion check, negative/positive example은 아래 "Active Handoff Menu" / "Passive Handoff Menu" 절을 참조하세요. **이 두 절은 non-optional load입니다 — 분기 종료 단계에 도달하면 반드시 읽어야 합니다.**

주의:
- 이 명령은 로컬 플러그인 엔트리포인트입니다 (`/obsidian-workflows:plan`).
- `/compound-engineering:workflows:plan`은 다른 플러그인의 스킬이므로, 이 플러그인의 plan 분기를 실행하지 않습니다.

Scope Guard (repo-only):
- 구현/검증/출력은 vault root 하위 저장소 파일만 대상으로 합니다.
- `~/.claude/*` 같은 전역 런타임 상태를 해결책으로 사용하지 않습니다.

Selective Step Skipping (--skip):
- `--skip` 플래그로 특정 단계를 건너뛸 수 있습니다.
- 건너뛸 수 있는 단계:
  - `preflight`: 초기화 검증 (파일 존재 확인만 수행)
  - `external-tools`: 외부 도구 탐지
  - `research`: 리서치 (active 모드에서 WebSearchPrime)
  - `context-card`: Context Card 출력
- 여러 단계를 쉼표로 구분해서 지정: `--skip preflight,external-tools`
- 프리셋 설정: `writing-config.md`의 `skip_steps.plan` 배열

Smart Mode Selection:
- `workflow_mode: auto`일 때 컨텍스트를 분석해서 자동으로 fast/full 모드를 선택합니다.
- Fast mode 자동 선택 조건:
  - Proposal 파일이 이미 존재하고 idea가 선택됨
  - 동일 policy를 최근 24시간 내 3회 이상 사용 (캐시의 usage_stats 확인)
  - 파일 크기 < 1000자
- Full mode 자동 선택 조건:
  - 첫 실행 (writing-config.md 없음)
  - 새로운 policy 추가
  - 복잡한 주제 (키워드: architecture, design, system, complex, research)
  - Topic이 20단어 이상
  - `--verbose` 플래그
- 수동 override: `--fast` 플래그로 강제 fast mode

Fast Mode (--fast):
- `--fast` 플래그가 있으면 속도 최적화 모드로 실행합니다.
- Fast mode 동작:
  - Preflight 검증 간소화 (파일 존재 확인만, 초기화 건너뛰기)
  - External tools 탐지 비활성화
  - Active 모드: 리서치 단계 생략 (WebSearchPrime 건너뛰기)
  - Passive 모드: 아이디어 생성만 수행 (상세 분석 생략)
  - Context Card 출력 최소화
- Fast mode는 단순 작업에 최적화되어 있으며, 복잡한 주제나 첫 실행 시에는 권장하지 않습니다.

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

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 `src/external-tools/keyword_detector.py`를 사용해 관련 도구를 탐지합니다.
2. `plan` 단계 키워드: canvas, visual, graph, mind-map, plan
3. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
4. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

Intent Gate:
1. `--intent`가 없으면 기본값으로 `passive`를 사용합니다.
2. `--intent=active`면 질문 없이 active 분기로 진행합니다.
3. `--intent=passive`면 질문 없이 passive 분기로 진행합니다.
4. `--intent` 값이 유효하지 않으면 즉시 `FAIL`로 종료합니다.

분기 실행 규칙:
- `active` 분기:
  1. 선택 policy의 `topic_required` 계약을 우선 적용합니다.
  2. `topic_required: true`이고 `topic`이 없으면 즉시 종료합니다(fail-fast).
  3. `topic_required: false` 정책(예: daily-note)은 `topic` 없이도 진행할 수 있습니다.
  4. **Fast mode가 아닐 때**: WebSearchPrime으로 리서치를 수행합니다.
  5. **Fast mode일 때**: 리서치를 건너뛰고 topic/policy 확정만 수행합니다.
  6. **STOP. 종료 시 반드시 `AskUserQuestion` 도구를 fire하여 4-옵션 Handoff 메뉴를 표시합니다.**
     - **금지**: "다음 단계:", "또는 직접:", "/obsidian-workflows:work mode=...", "/obsidian:write.active ..." 등 텍스트 명령어 안내. 사용자가 명령어를 복붙하는 워크플로우는 폐기되었습니다.
     - 메뉴 옵션, 동작, completion check는 아래 "Active Handoff Menu" 절 참조. **이 절을 읽지 않고 분기를 완료하지 마세요 (non-optional load).**
- `passive` 분기:
  1. `writing-config.md`에서 `source_paths`, `exclude_paths`, `proposal_path`, `final_path`를 확인합니다.
  2. `obsidian:write.scan` 규칙으로 후보 파일을 수집합니다.
     - 성능: `src/scan-recent-files.sh` 스크립트 사용 권장 (git log보다 훨씬 빠름)
  3. `obsidian:write.propose` 규칙으로 아이디어 3~5개를 제안 노트로 저장합니다.
  4. **생성된 proposal 파일을 읽어서** 각 아이디어의 상세 내용을 추출합니다.
  5. proposal 요약 출력 후 **STOP. 반드시 `AskUserQuestion` 도구를 fire하여 4-옵션 Handoff 메뉴를 표시합니다.**
     - **금지**: "Next: /obsidian-workflows:work proposal=...", "다음 단계:" 등 텍스트 명령어 안내. 메뉴 fire 없이 종료하면 명세 위반입니다.
     - 메뉴 옵션, 동작, completion check는 아래 "Passive Handoff Menu" 절 참조. **non-optional load.**
     - 요약 출력 세부:
       - `output_verbosity` 설정에 따라 형식 선택 (minimal/verbose)
       - `idea_detail_lines` 설정에 따라 아이디어 상세도 조정 (1/3/5줄)
       - proposal 파일에서 추출한 내용:
         - 제목 (항상 표시)
         - 핵심 논지 (idea_detail_lines >= 3)
         - 추천 policy (idea_detail_lines >= 3)
         - 근거 wikilink (idea_detail_lines >= 5, show_wikilinks=true)

Active Handoff Menu (active 분기 종료 직후):
- **`AskUserQuestion` 도구를 즉시 fire하여 메뉴를 표시하세요. 텍스트 명령어 안내로 종료하는 것은 명세 위반입니다.**
- 흔한 실패 모드 (이렇게 종료하지 마세요):
  ```
  ❌ "다음 단계 (work 단계에서 초안 즉시 생성):
       /obsidian-workflows:work mode=active topic="..." policy=daily-note
     또는 직접:
       /obsidian:write.active topic="..." policy=daily-note"
  ```
  사용자에게 명령어를 복붙시키는 워크플로우는 폐기되었습니다. AI가 학습된 default로 위 패턴에 빠지기 쉬우니, 명세를 따라 메뉴를 fire하세요.
- 올바른 종료:
  ```
  ✓ AskUserQuestion 도구 호출 → 4-옵션 메뉴 표시 → 사용자 선택 수신 → 옵션별 인라인 routing 실행
  ```
- AskUserQuestion 호출 시 정확한 question stem과 option label을 사용합니다 (AI가 임의로 변형하지 않음):
  - stem: `"Active plan 완료 (topic="<topic>", policy=<policy>). 다음에 무엇을 할까요?"`
  - options (정확한 label):
    1. `"바로 실행"` (recommended)
    2. `"계획 다듬기"`
    3. `"다른 정책으로"`
    4. `"나중에"`
- 옵션 2(계획 다듬기)와 옵션 3(다른 정책으로)은 옵션 1(바로 실행) 또는 옵션 4(나중에)가 선택될 때까지 메뉴를 반복합니다. 즉 두 옵션이 루프의 종료 조건입니다.
- `AskUserQuestion` 스키마가 미리 로드되지 않았으면 `ToolSearch`에 `select:AskUserQuestion`을 먼저 호출해 로드한 뒤 fire합니다. 스키마 로드가 번거롭다는 이유로 텍스트 안내로 fallback하지 마세요 — 학습된 default 패턴에 빠지는 가장 흔한 경로입니다.
- 메뉴 옵션(4지선다):
  1. **바로 실행** — 이 plan으로 draft 작성
     - 동작:
       1. plan 단계에서 사용자가 넘긴 active 분기용 추가 인자(`--source`, `--window-days`, `--skip` 등)를 `extra_args` dict로 묶습니다. 이 키 집합은 옵션 4("나중에")가 상태 파일에 저장하는 `extra_args`와 동일합니다.
       2. `.claude/state/obsidian-write-active-handoff.json`을 `status: consumed`로 *사전에* 기록합니다. 이는 `mode=active`로 work를 호출하면 work의 자동 추론(step #2)이 적용되지 않아 상태 파일을 읽지 않으므로, 다음 세션에서 같은 handoff가 자동 재실행되지 않게 하기 위함입니다.
       3. 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow:work`를 **즉시 fire하세요** (Claude Code에서는 `Skill` 도구, Codex에서는 동일하게 `Skill`, Gemini/Pi는 해당 플랫폼의 primitive). 사용자에게 "이제 `/work`를 입력하세요"라고 안내하지 마세요 — 이 세션에서 곧바로 호출합니다. 인자: `mode=active, topic="<plan의 topic>", policy="<plan의 policy>", **extra_args`.
  2. **계획 다듬기** — topic / 소스 범위 / policy 한 번 더 정제
     - 동작: 사용자에게 어떤 부분을 다듬을지(`topic` 구체화, 소스 범위 조정, policy 변경 등) 후속 질문한 뒤, 답변을 반영해 active 분기를 재실행합니다. 재실행 후 다시 본 메뉴를 출력합니다.
  3. **다른 정책으로** — policy 변경 후 plan 재실행
     - 동작: 사용자에게 사용할 policy 후보(현재 enabled_policies)를 제시하고 선택을 받아 active 분기를 재실행합니다. 재실행 후 다시 본 메뉴를 출력합니다.
  4. **나중에** — handoff 상태만 저장하고 종료
     - 동작: `.claude/state/obsidian-write-active-handoff.json`을 아래 스키마로 저장하고 종료합니다(`status: pending`). 이후 `/obsidian-workflows:work`가 mode 없이 호출되면 이 파일을 자동 감지해 active 모드로 진행합니다.
- Active handoff 상태 파일 스키마는 `docs/runtime/state-schema.md`의 "Active handoff state fields" 절을 참조합니다.
- **Completion check** — active 분기는 다음 3가지가 모두 완료되어야 끝납니다.
  1. `AskUserQuestion` 도구로 위 4-옵션 메뉴를 fire함
  2. 사용자 선택을 수신함
  3. 선택에 따른 인라인 routing을 즉시 실행함 (옵션 1: work skill fire + 상태 파일 consumed; 옵션 2: 후속 질문 후 분기 재실행; 옵션 3: policy 선택 후 분기 재실행; 옵션 4: 상태 파일 pending 저장 후 종료)
- 다음은 모두 **완료가 아닙니다 — 명세 위반입니다**:
  - 메뉴를 띄우고 멈추는 것
  - 사용자 선택을 수신한 뒤 안내문("이제 work를 호출하시겠어요?", "/work mode=active …")으로 끝내는 것
  - 옵션 1을 선택받았는데 Skill 도구로 fire하지 않고 텍스트로 명령어를 안내하는 것
  - AskUserQuestion 스키마 미로드를 이유로 메뉴를 fire하지 않고 텍스트 안내로 fallback하는 것

Passive Handoff Menu (passive 분기 종료 직후):
- proposal 요약을 먼저 출력(아래 출력 형식 참조)한 다음, **`AskUserQuestion` 도구를 즉시 fire하여 메뉴를 표시하세요. 텍스트 명령어 안내로 종료하는 것은 명세 위반입니다.**
- 흔한 실패 모드 (이렇게 종료하지 마세요):
  ```
  ❌ "Next: /obsidian-workflows:work proposal="..." idea=N"
  ❌ "다음 단계: 위 idea 중 하나를 선택하려면 /work proposal=... idea=N 실행하세요"
  ```
- 올바른 종료:
  ```
  ✓ proposal 요약 출력 → AskUserQuestion 도구 호출 → 4-옵션 메뉴 표시 → 사용자 선택 수신 → 옵션별 인라인 routing 실행
  ```
- AskUserQuestion 호출 시 정확한 question stem과 option label을 사용합니다:
  - stem: `"Passive proposal 생성 완료 (<N>개 아이디어). 다음에 무엇을 할까요?"`
  - options (정확한 label):
    1. `"Idea 선택해서 draft"` (recommended)
    2. `"proposal 다듬기"`
    3. `"다른 정책으로"`
    4. `"나중에"`
- 옵션 2(proposal 다듬기)와 옵션 3(다른 정책으로)은 옵션 1(Idea 선택해서 draft) 또는 옵션 4(나중에)가 선택될 때까지 메뉴를 반복합니다. 즉 두 옵션이 루프의 종료 조건입니다.
- `AskUserQuestion` 스키마가 미리 로드되지 않았으면 `ToolSearch`에 `select:AskUserQuestion`을 먼저 호출해 로드한 뒤 fire합니다.
- 메뉴 옵션(4지선다):
  1. **Idea 선택해서 draft** — 1~N 중 선택
     - 동작:
       1. 사용자에게 idea 번호를 묻고(또는 stem에서 바로 받음) proposal frontmatter의 `status`를 `in-progress`, `selected_idea`를 선택된 번호로 갱신합니다.
       2. 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow:work`를 **즉시 fire하세요** (Claude Code의 `Skill` 도구). 사용자에게 "이제 `/work proposal=... idea=N`을 입력하세요"라고 안내하지 마세요 — 이 세션에서 곧바로 호출합니다. 인자: `mode=draft, proposal="<proposal 파일 경로>", idea=N`.
  2. **proposal 다듬기** — 아이디어 추가/교체
     - 동작: 사용자에게 어떤 아이디어를 빼거나 추가할지 후속 질문한 뒤, 답변을 반영해 propose를 재실행합니다. 재실행 후 다시 본 메뉴를 출력합니다.
  3. **다른 정책으로** — proposal 재생성
     - 동작: 사용자에게 policy 후보를 제시하고 선택을 받아 propose를 재실행합니다. 재실행 후 다시 본 메뉴를 출력합니다.
  4. **나중에** — proposal만 저장하고 종료
     - 동작: proposal frontmatter는 `status: pending` 그대로 유지하고 종료합니다. 이후 `/obsidian-workflows:work`가 호출되면 기존 "Proposal 자동 감지" 흐름으로 이어집니다.
- **Completion check** — passive 분기는 다음 3가지가 모두 완료되어야 끝납니다.
  1. proposal 요약 출력 후 `AskUserQuestion` 도구로 위 4-옵션 메뉴를 fire함
  2. 사용자 선택을 수신함
  3. 선택에 따른 인라인 routing을 즉시 실행함 (옵션 1: proposal frontmatter 갱신 + work skill fire; 옵션 2: 후속 질문 후 propose 재실행; 옵션 3: policy 선택 후 propose 재실행; 옵션 4: proposal pending 유지하고 종료)
- 다음은 모두 **완료가 아닙니다 — 명세 위반입니다**:
  - proposal 요약만 출력하고 메뉴 fire 없이 종료하는 것
  - 메뉴를 띄우고 사용자 선택을 수신한 뒤 안내문으로 끝내는 것
  - 옵션 1이 선택됐는데 Skill 도구로 fire하지 않고 텍스트로 명령어를 안내하는 것

Pipeline / 자동 환경 예외:
- `/obsidian:write.autorun` 같은 hook 기반 자동 실행에서는 Handoff 메뉴를 skip합니다. 자동 환경에는 동기적으로 답할 사용자가 없으므로 메뉴 fire가 의미 없습니다.
- 자동 환경의 default 동작:
  - Active 분기: 옵션 4 "나중에" 동등 — handoff 상태 파일을 `status: pending`으로 저장하고 종료. 다음 인터랙티브 세션의 `/ow:work`가 자동 감지.
  - Passive 분기: 옵션 4 "나중에" 동등 — proposal을 `status: pending`으로 저장하고 종료.
- 메뉴 fire와 인라인 routing은 사용자가 동기적으로 응답 가능한 대화 컨텍스트에서만 수행합니다.

상태/출력 규칙:
- `writing-config.md`에서 출력 설정을 읽습니다:
  - `output_verbosity`: minimal | standard | verbose (기본: minimal)
  - `show_context_card`: Context Card 표시 여부 (기본: false)
  - `idea_detail_lines`: 아이디어당 세부 정보 줄 수 1-5 (기본: 3)
  - `show_wikilinks`: 근거 wikilink 표시 여부 (기본: true)
- `--verbose` 플래그가 있으면 `output_verbosity`를 `verbose`로 override합니다.
- Context Card는 `show_context_card: true` 또는 `--verbose` 플래그가 있을 때만 출력합니다.
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: 분기 실행이 정상 완료됨
  - `SKIP`: passive 후보가 0건인 정상 empty case
  - `FAIL`: preflight/입력/실행 오류
- 실패 시 조용한 fallback 없이 즉시 종료합니다.
- passive는 제안 노트 생성까지만 수행하고 초안 자동 생성은 하지 않습니다.

출력 형식 (output_verbosity별):
- `minimal`:
  ```
  ✓ Passive proposal created: [경로]

  [N] ideas generated. Review and select one:

    1. [제목]
       [핵심 논지 1줄]
       [추천 policy]

    2. [제목]
       [핵심 논지 1줄]
       [추천 policy]
    ...
  ```

  **중요:** proposal 파일을 읽어서 각 아이디어의 "핵심 논지"와 "추천 policy"를 추출하여 표시합니다.
  `idea_detail_lines` 설정에 따라:
  - 1줄: 제목만
  - 3줄: 제목 + 핵심 논지 + 추천 policy (기본값)
  - 5줄: 제목 + 핵심 논지 + 근거 wikilink + 추천 policy

  요약 출력 직후 위 "Passive Handoff Menu"의 4지선다를 `AskUserQuestion`으로 제시합니다(텍스트 명령어 출력 금지 규칙은 메뉴 정의 참조).
- `verbose`:
  ```
  [Context Card 전체]

  요청하신 Passive 분기로 실행 완료했습니다.

  - 생성된 proposal 파일: [경로]
  - 아이디어 목록:
    - Idea 1: [제목]
    ...
  ```

  verbose 모드에서도 요약 출력 직후 "Passive Handoff Menu"의 4지선다를 제시합니다(텍스트 명령어 출력 금지 규칙은 메뉴 정의 참조).

Proposal 파일 frontmatter 스펙:
```yaml
---
created: 2026-03-02T06:22:30+00:00
kind: passive-proposal
anchor: 2026-03-01T14:41:24.806686+00:00
idea_count: 4
updated: 2026-03-02T15:22
status: pending  # pending | in-progress | completed
selected_idea: null  # 선택된 idea 번호 (1-based)
draft_path: null  # 생성된 초안 경로
---
```

상태 전이:
- `pending`: proposal 생성 직후 (plan 단계)
- `in-progress`: work 단계에서 idea 선택 후
- `completed`: 초안 완성 및 final 경로 이동 후
