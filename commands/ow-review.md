---
name: ow-review
description: REVIEW 트랙 진입점. 정책/문체 품질 게이트를 수행합니다.
argument-hint: file=path [policy=<policy-name>] [--fast] [--skip external-tools,context-card]
allowed-tools: Read, Glob, Grep, AskUserQuestion
created: 2026-03-01T17:28
updated: 2026-03-04T22:00
---

`obsidian-workflows:ow-review`는 MVP에서 `write-review-policy`를 기본 게이트로 실행합니다.

보안/권한 원칙:
- 이 명령은 검증/리포팅 전용으로 동작하며 파일을 수정하지 않습니다.
- 최소 권한 원칙에 따라 read-only 도구만 사용합니다.

Selective Step Skipping (--skip):
- `--skip` 플래그로 특정 단계를 건너뛸 수 있습니다.
- 건너뛸 수 있는 단계:
  - `external-tools`: 외부 도구 탐지
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
  - External tools 탐지 비활성화
  - Context Card 출력 최소화
- Fast mode는 빠른 검증이 필요할 때 사용합니다.

Helper Script Path Resolution:
- helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.
- helper script를 쓸 때는 먼저 `obsidian-workflows` plugin/repo root를 해석하고, 해석된 root 아래의 절대 경로로 실행합니다.
- root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
- optional helper script 단계는 경고 후 건너뛰고, 본래 단계의 fail-safe 정책을 따릅니다.

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 helper script path resolution 규칙에 따라 plugin/repo root를 먼저 해석합니다.
2. root가 해석되고 external tool detector가 존재할 때만 절대 경로로 실행해 관련 도구를 탐지합니다. 현재 vault cwd 기준의 `src/...` 경로를 추측해 실행하지 않습니다.
3. `review` 단계 키워드: grammar, style, checker, lint, review, quality
4. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
5. root 또는 detector를 확인할 수 없으면 외부 도구 탐지만 경고 후 건너뛰고 워크플로우 계속 진행 (fail-safe)
6. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

실행 순서:
1. 대상 파일과 policy를 확정합니다.
2. 지정된 `file` 경로에 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 적용합니다.
3. `write-review-policy` 규칙으로 구조/길이/필수 섹션을 검증합니다.
4. PASS/FAIL 체크리스트와 수정 포인트를 반환합니다.

후속 확장(현재 미구현):
- `write-review-voice` (planned)
- `write-review-final` (planned)

메모:
- 현재는 `write-review-policy` 정책 게이트를 우선 적용합니다.
