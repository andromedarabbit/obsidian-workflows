---
name: ow:compound
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다.
argument-hint: "[file=path] [latest] [--fast] [--skip external-tools,context-card]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
created: 2026-03-01T17:28
updated: 2026-03-04T22:00
---

`obsidian-workflows:ow:compound`는 MVP에서 `obsidian:write.compound.capture`를 실행해 반복 개선용 학습 로그를 남깁니다.

후속 확장(현재 미구현): `obsidian:write.compound.sync` (planned)

Selective Step Skipping (--skip):
- `--skip` 플래그로 특정 단계를 건너뛸 수 있습니다.
- 건너뛸 수 있는 단계:
  - `external-tools`: 외부 도구 탐지
  - `context-card`: Context Card 출력
- 프리셋 설정: `writing-config.md`의 `skip_steps.compound` 배열

Smart Mode Selection:
- `workflow_mode: auto`일 때 컨텍스트를 분석해서 자동으로 fast/full 모드를 선택합니다.
- Fast mode 자동 선택 조건:
  - 반복 학습 캡처 (동일 policy 3회 이상)
  - 파일 크기 < 2000자
- Full mode 자동 선택 조건:
  - 첫 학습 캡처
  - 복잡한 패턴 분석 필요
- 수동 override: `--fast` 플래그로 강제 fast mode

Fast Mode (--fast):
- `--fast` 플래그가 있으면 속도 최적화 모드로 실행합니다.
- Fast mode 동작:
  - 패턴 식별만 수행 (상세 분석 생략)
  - SOUL 개선 제안 3개 → 1개로 축소
  - External tools 탐지 비활성화
  - Context Card 출력 최소화
- Fast mode는 빠른 학습 캡처가 필요할 때 사용합니다.

Helper Script Path Resolution:
- helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.
- helper script를 쓸 때는 먼저 `obsidian-workflows` plugin/repo root를 해석하고, 해석된 root 아래의 절대 경로로 실행합니다.
- root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
- optional helper script 단계는 경고 후 건너뛰고, 본래 단계의 fail-safe 정책을 따릅니다.

External Tools Detection:
- **Fast mode가 아닐 때만** 외부 도구를 탐지합니다.
1. 명령어 시작 시 helper script path resolution 규칙에 따라 plugin/repo root를 먼저 해석합니다.
2. root가 해석되고 external tool detector가 존재할 때만 절대 경로로 실행해 관련 도구를 탐지합니다. 현재 vault cwd 기준의 `src/...` 경로를 추측해 실행하지 않습니다.
3. `compound` 단계 키워드: humanizer, capture, learn, knowledge
4. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
5. root 또는 detector를 확인할 수 없으면 외부 도구 탐지만 경고 후 건너뛰고 워크플로우 계속 진행 (fail-safe)
6. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
- **Fast mode일 때**: 외부 도구 탐지를 건너뜁니다.

실행 순서:
1. 대상 문서를 선택합니다(명시 없으면 final_path 최신 파일).
2. `obsidian:write.compound.capture`를 실행합니다.
3. 정책/SOUL 개선 후보를 짧게 요약합니다.

규칙:
- 캡처는 경량 기록 중심(noop에 가까운 스켈레톤)으로 유지합니다.
