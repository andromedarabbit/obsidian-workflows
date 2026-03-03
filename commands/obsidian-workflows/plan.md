---
name: obsidian-workflows:plan
description: PLAN 트랙 진입점. 의도를 먼저 확인해 active handoff 또는 passive 제안을 수행합니다.
argument-hint: "[--intent active|passive] [topic=...] [policy=<policy-name>] [--window-days N] [--source path1,path2] [--verbose]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T17:38
---

`obsidian-workflows:plan`은 PLAN 트랙의 의도 선택형 엔트리포인트입니다.

주의:
- 이 명령은 로컬 플러그인 엔트리포인트입니다 (`/obsidian-workflows:plan`).
- `/compound-engineering:workflows:plan`은 다른 플러그인의 스킬이므로, 이 플러그인의 plan 분기를 실행하지 않습니다.

Scope Guard (repo-only):
- 구현/검증/출력은 vault root 하위 저장소 파일만 대상으로 합니다.
- `~/.claude/*` 같은 전역 런타임 상태를 해결책으로 사용하지 않습니다.

Preflight Gate (fail-fast):
- 초기화 대상 목록의 canonical source는 `commands/obsidian-write/obsidian:write.init.md`의 `초기화 대상` 섹션입니다.
1. 실행 시작 시 `obsidian:write.init`의 초기화 대상 파일 존재를 먼저 검증합니다.
   - `writing-config.md`
   - `Workflows/policy/writing-policy.blog.md`
   - `Workflows/policy/writing-policy.x-thread.md`
   - `Workflows/policy/writing-policy.weekly-review.md`
   - `Workflows/policy/writing-policy.newsletter.md`
   - `Workflows/SOUL.md`
   - `.claude/state/obsidian-write-passive.json`
2. 누락이 하나라도 있으면 즉시 `FAIL`로 종료합니다.
3. 종료 시 누락 파일 목록과 다음 액션(`/obsidian:write.init`)을 함께 출력합니다.
4. 자동 초기화는 수행하지 않습니다.

Intent Gate:
1. `--intent`가 없으면 사용자 의도를 먼저 확인합니다.
   - A) 이미 주제가 있다 (`active`)
   - B) 최근 변경을 스캔해 주제 제안을 받겠다 (`passive`)
2. `--intent=active`면 질문 없이 active 분기로 진행합니다.
3. `--intent=passive`면 질문 없이 passive 분기로 진행합니다.
4. `--intent` 값이 유효하지 않으면 즉시 `FAIL`로 종료합니다.

분기 실행 규칙:
- `active` 분기:
  1. `topic` 필수 여부를 확인합니다.
  2. `topic`이 없으면 즉시 종료합니다(fail-fast).
  3. 다음 실행 커맨드를 명시적으로 handoff합니다.
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
