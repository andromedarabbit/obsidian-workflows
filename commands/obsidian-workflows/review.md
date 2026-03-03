---
name: obsidian-workflows:review
description: REVIEW 트랙 진입점. 정책/문체 품질 게이트를 수행합니다.
argument-hint: file=path [policy=<policy-name>]
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T15:07
---

`obsidian-workflows:review`는 MVP에서 `obsidian:write.review.policy`를 기본 게이트로 실행합니다.

보안/권한 원칙:
- 이 명령은 검증/리포팅 전용으로 동작하며 파일을 수정하지 않습니다.
- 최소 권한 원칙에 따라 read-only 도구만 사용합니다.

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
