---
name: ow:review
description: REVIEW 트랙 진입점. 정책/문체 품질 게이트를 수행합니다.
argument-hint: file=path [policy=<policy-name>] [--fast]
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-04T21:49
---

`obsidian-workflows:review`는 MVP에서 `obsidian:write.review.policy`를 기본 게이트로 실행합니다.

보안/권한 원칙:
- 이 명령은 검증/리포팅 전용으로 동작하며 파일을 수정하지 않습니다.
- 최소 권한 원칙에 따라 read-only 도구만 사용합니다.

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

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 `src/external-tools/keyword-detector.js`를 사용해 관련 도구를 탐지합니다.
2. `review` 단계 키워드: grammar, style, checker, lint, review, quality
3. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
4. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

실행 순서:
1. 대상 파일과 policy를 확정합니다.
2. 지정된 `file` 경로에 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 적용합니다.
3. `obsidian:write.review.policy` 규칙으로 구조/길이/필수 섹션을 검증합니다.
4. PASS/FAIL 체크리스트와 수정 포인트를 반환합니다.

후속 확장(현재 미구현):
- `obsidian:write.review.voice` (planned)
- `obsidian:write.review.final` (planned)

메모:
- 현재는 `obsidian:write.review.policy` 정책 게이트를 우선 적용합니다.
