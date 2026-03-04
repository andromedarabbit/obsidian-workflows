---
name: ow:compound
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다.
argument-hint: "[file=path] [latest]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-04T20:08
---

`obsidian-workflows:compound`는 MVP에서 `obsidian:write.compound.capture`를 실행해 반복 개선용 학습 로그를 남깁니다.

후속 확장(현재 미구현): `obsidian:write.compound.sync` (planned)

External Tools Detection:
1. 명령어 시작 시 `src/external-tools/keyword-detector.js`를 사용해 관련 도구를 탐지합니다.
2. `compound` 단계 키워드: humanizer, capture, learn, knowledge
3. 탐지된 도구가 있으면 `writing-config.md`의 `external_tools.auto_use` 설정을 확인합니다:
   - `ask`: AskUserQuestion으로 사용 여부 확인
   - `true`: 자동 사용 (질문 없이)
   - `false`: 건너뛰기
4. 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)

실행 순서:
1. 대상 문서를 선택합니다(명시 없으면 final_path 최신 파일).
2. `obsidian:write.compound.capture`를 실행합니다.
3. 정책/SOUL 개선 후보를 짧게 요약합니다.

규칙:
- 캡처는 경량 기록 중심(noop에 가까운 스켈레톤)으로 유지합니다.
