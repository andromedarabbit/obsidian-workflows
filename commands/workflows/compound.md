---
name: workflows:compound
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다.
argument-hint: "[file=path] [latest]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-04T10:25
---

`obsidian-workflows:compound`는 MVP에서 `obsidian:write.compound.capture`를 실행해 반복 개선용 학습 로그를 남깁니다.

후속 확장(현재 미구현): `obsidian:write.compound.sync` (planned)

실행 순서:
1. 대상 문서를 선택합니다(명시 없으면 final_path 최신 파일).
2. `obsidian:write.compound.capture`를 실행합니다.
3. 정책/SOUL 개선 후보를 짧게 요약합니다.

규칙:
- 캡처는 경량 기록 중심(noop에 가까운 스켈레톤)으로 유지합니다.
