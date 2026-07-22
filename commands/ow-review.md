---
name: ow-review
description: '게시·발행 직전의 초안을 정책 검증과 문체 리뷰까지 한 번에 통과시키고 싶을 때 사용합니다. Obsidian vault 초안(블로그·뉴스레터·스레드·데일리 노트)이나 writing-config policy로 검증할 draft가 대상입니다. 채널 정책 게이트(구조·길이·필수 섹션 검증)에 이어 문체·윤문 점검(AI 티·번역투 진단, 필요 시 사람처럼 다듬기)까지 한 번에 수행합니다. 정책 검증하고 문체까지, 발행 전 최종 점검, 리뷰하고 AI 티 있으면 다듬어줘 같은 요청에 적합합니다. 제외 — 맞춤법·오탈자만 교정, policy 신규 생성, 코드·PR 리뷰, 새 글 작성, 정책 검증 없이 문장만 윤문(AI 티만 빼줘)하려는 요청.'
argument-hint: file=path [policy=<policy-name>] [--fast] [--humanize] [--skip external-tools,voice,context-card]
allowed-tools: Read, Glob, Grep, AskUserQuestion, Skill
created: 2026-03-01T17:28
updated: 2026-07-22T02:00
---

`obsidian-workflows:ow-review`는 두 단계로 품질을 검증합니다: (1) `write-review-policy` 정책 게이트로 구조·길이·필수 섹션을 점검하고(의미 층), (2) 문체·윤문 단계에서 AI 티·번역투를 진단하고 필요 시 윤문합니다(형태 층).

의미 → 형태 순서를 지키는 이유: 정책 게이트가 섹션을 재배치하거나 내용을 바꾸면 앞서 한 윤문이 무효가 됩니다. 그래서 구조/의미를 먼저 확정하고 윤문(형태 다듬기)은 마지막에 둡니다.

보안/권한 원칙:
- 이 명령의 자체 검사(정책 게이트·탐지·리포팅)는 파일을 수정하지 않습니다. read-only 도구만 사용합니다.
- 윤문 재작성은 이 명령이 직접 하지 않고 `Skill` 도구로 humanize 스킬에 위임합니다. humanize는 결과를 자체 워크스페이스(`_workspace/{date}/final.md`)에 쓰므로 원본을 즉석에서 덮어쓰지 않습니다.
- 재작성(윤문)은 사용자가 명시적으로 요청했을 때만 자동 진행하고, 그렇지 않으면 실행 전에 `AskUserQuestion`으로 확인합니다(read-only 기본값 보존).

Selective Step Skipping (--skip):
- `--skip` 플래그로 특정 단계를 건너뛸 수 있습니다.
- 건너뛸 수 있는 단계:
  - `external-tools`: grammar-checker/style-guide 탐지
  - `voice`: 문체·윤문(humanize) 단계
  - `context-card`: Context Card 출력
- 프리셋 설정: `writing-config.md`의 `skip_steps.review` 배열

Smart Mode Selection:
- `workflow_mode: auto`일 때 컨텍스트를 분석해서 자동으로 fast/full 모드를 선택합니다.
- Fast mode 자동 선택 조건:
  - 초안 작성 후 리뷰 (Drafts 디렉토리의 파일)
  - 동일 policy를 최근 24시간 내 3회 이상 사용
  - 파일 크기 < 1000자
- Full mode 자동 선택 조건:
  - 첫 리뷰 (정책 검증 필요)
  - `--verbose` 플래그
- 수동 override: `--fast` 플래그로 강제 fast mode

Fast Mode (--fast):
- `--fast` 플래그가 있으면 속도 최적화 모드로 실행합니다.
- Fast mode 동작:
  - 필수 섹션 검증만 수행
  - 상세 체크리스트 생략
  - PASS/FAIL만 반환 (상세 수정 제안 생략)
  - 문체·윤문 단계와 외부 도구 탐지 비활성화
  - Context Card 출력 최소화
- Fast mode는 빠른 검증이 필요할 때 사용합니다.

Helper Script Path Resolution:
- helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.
- helper script를 쓸 때는 먼저 `obsidian-workflows` plugin/repo root를 해석하고, 해석된 root 아래의 절대 경로로 실행합니다.
- root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
- optional helper script 단계는 경고 후 건너뛰고, 본래 단계의 fail-safe 정책을 따릅니다.

Voice/윤문 & External Tools Detection:
- **Fast mode가 아니고 `--skip voice`/`--skip external-tools`가 없을 때만** 실행합니다. 정책 게이트 이후에 수행합니다(의미 → 형태 순서).
- 윤문 도구 탐지는 **우선순위**를 둡니다. 서로 배타적이지 않고 보완적입니다:
  1. **im-not-ai humanize (최우선, 문체/윤문)** — AI 티·번역투·기계적 병렬·피동 남용 등 문체 흔적을 진단/개선하는 사내 표준 도구. 탐지 방법: `humanize`/`humanize-korean` 슬래시 스킬 또는 `humanize-korean` 스킬이 사용 가능한지 확인.
  2. **grammar-checker (맞춤법/문법/띄어쓰기)** — 문체가 아닌 표기 오류.
  3. **style-guide (용어/프로젝트 스타일)** — 용어 일관성 등.
- 탐지 후 동작:
  1. humanize가 사용 가능하면 문체·윤문의 1순위 도구로 삼습니다. grammar-checker/style-guide는 함께(또는 humanize가 없을 때 대체로) 표기·용어 리포트를 채웁니다.
  2. grammar-checker/style-guide 실행 여부는 `writing-config.md`의 `external_tools.auto_use`(`ask`(기본)/`true`/`false`)를 따릅니다.
  3. plugin/repo root나 도구/스킬을 확인할 수 없으면 해당 탐지만 경고 후 건너뛰고 워크플로우를 계속합니다(fail-safe). 도구 실행 실패도 경고 후 계속(fail-safe).

윤문(humanize) 실행 게이트:
- 사용자가 윤문/재작성을 **명시적으로 요청**했으면(`--humanize` 플래그, 또는 "AI 티 빼줘"·"사람처럼 다듬어줘"·"윤문해줘" 같은 지시) 확인 없이 진행합니다.
- 명시 요청이 없는데 문체 문제가 감지되면, `Skill` 도구로 humanize를 부르기 전에 `AskUserQuestion`으로 확인합니다(예: "AI 티/번역투가 보입니다. 지금 im-not-ai humanize로 윤문할까요?"). 사용자가 거부하면 진단 리포트만 남기고 원본은 그대로 둡니다.
- 진행 시 `Skill` 도구로 humanize 스킬을 `file` 경로에 대해 즉시 호출합니다. 결과 `final.md`의 before/after 요약과 워크스페이스 경로를 리뷰 리포트에 통합합니다.

실행 순서:
1. 대상 파일과 policy를 확정합니다.
2. 지정된 `file` 경로에 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 적용합니다.
3. `write-review-policy` 규칙으로 구조/길이/필수 섹션을 검증합니다(의미 층).
4. (fast/skip이 아니면) Voice/윤문 & External Tools 단계를 수행합니다(형태 층): 문체 진단, 필요 시 확인 후 humanize 위임.
5. PASS/FAIL 체크리스트, 수정 포인트, 윤문 요약(수행 시)을 반환합니다.

출력/상태 규칙:
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: 정책 게이트 통과(윤문은 사용자 선택에 따름).
  - `SKIP`: 검증 대상/도구가 없어 정상적으로 건너뛴 경우.
  - `FAIL`: 정책 게이트 위반 또는 입력/경로 오류.
- 종료 시 다음 단계를 안내합니다(예: `obsidian-workflows:ow-compound`로 학습 적립).

후속 확장:
- 문체(voice) 리뷰는 별도 `write-review-voice` 명령을 만드는 대신 이 단계에서 im-not-ai humanize 위임으로 제공합니다.
- `write-review-final` (정책 위반 자동 수정, planned) — 자동 수정은 read-only 리뷰와 권한을 분리해 별도 명령으로 둡니다.

메모:
- 정책 게이트(`write-review-policy`)가 항상 먼저이고, 윤문은 그 뒤 형태 단계입니다.
