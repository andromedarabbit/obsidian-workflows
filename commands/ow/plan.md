---
name: ow:plan
description: PLAN 트랙 진입점. 의도를 먼저 확인해 active handoff 또는 passive 제안을 수행합니다.
argument-hint: "[--intent active|passive] [topic=...] [policy=<policy-name>] [--window-days N] [--source path1,path2] [--verbose] [--fast] [--skip preflight,external-tools,research,context-card]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-04T22:00
---

`obsidian-workflows:plan`은 PLAN 트랙의 의도 선택형 엔트리포인트입니다.

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
  6. 다음 실행 커맨드를 명시적으로 handoff합니다.
     - `/obsidian-workflows:work mode=active topic="..." policy=...`
     - `/obsidian:write.active topic="..." policy=...`
- `passive` 분기:
  1. `writing-config.md`에서 `source_paths`, `exclude_paths`, `proposal_path`, `final_path`를 확인합니다.
  2. `obsidian:write.scan` 규칙으로 후보 파일을 수집합니다.
  3. `obsidian:write.propose` 규칙으로 아이디어 3~5개를 제안 노트로 저장합니다.
  4. **생성된 proposal 파일을 읽어서** 각 아이디어의 상세 내용을 추출합니다.
  5. 종료 시 출력:
     - `output_verbosity` 설정에 따라 형식 선택 (minimal/verbose)
     - `idea_detail_lines` 설정에 따라 아이디어 상세도 조정 (1/3/5줄)
     - proposal 파일에서 추출한 내용:
       - 제목 (항상 표시)
       - 핵심 논지 (idea_detail_lines >= 3)
       - 추천 policy (idea_detail_lines >= 3)
       - 근거 wikilink (idea_detail_lines >= 5, show_wikilinks=true)
     - 다음 단계: `/obsidian-workflows:work proposal="..." idea=N`

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

  Next: /obsidian-workflows:work proposal="..." idea=N
  ```

  **중요:** proposal 파일을 읽어서 각 아이디어의 "핵심 논지"와 "추천 policy"를 추출하여 표시합니다.
  `idea_detail_lines` 설정에 따라:
  - 1줄: 제목만
  - 3줄: 제목 + 핵심 논지 + 추천 policy (기본값)
  - 5줄: 제목 + 핵심 논지 + 근거 wikilink + 추천 policy
- `verbose`:
  ```
  [Context Card 전체]

  요청하신 Passive 분기로 실행 완료했습니다.

  - 생성된 proposal 파일: [경로]
  - 아이디어 목록:
    - Idea 1: [제목]
    ...

  다음 단계: /obsidian-workflows:work proposal="..." idea=N
  ```

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
