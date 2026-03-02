---
name: obsidian:write.autorun
description: 일일 자동 제안 실행. SessionStart 훅에서 호출되는 Passive 오케스트레이터입니다.
argument-hint: "[--trigger session-start]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-01T23:40
---

목표:
- 하루 1회만 `scan -> propose`를 자동 실행합니다.
- 자동 실행 결과는 제안 노트까지만 생성합니다.
- 이 명령은 non-interactive `passive` 전용입니다(질문 분기 없음).

상태 파일:
- `.claude/state/obsidian-write-passive.json`
- 주요 필드: `last_propose_run_at`, `last_status`, `last_proposal_note`

락/중복 방지:
1. `.claude/state/obsidian-write-passive.lock`으로 동시 실행을 차단합니다.
2. `last_propose_run_at` 날짜가 오늘과 같으면 `SKIP`합니다.

실행 순서:
1. `writing-config.md` 로드
2. 기준 시점 계산 (`final_path` 최신 파일 또는 window fallback)
3. `obsidian:write.scan` 수행
4. `obsidian:write.propose` 수행
5. 상태 파일 업데이트

실패 정책:
- 시작/종료 시 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)를 출력합니다.
- 실패 시에도 가능한 범위에서 동일 키로 Context Card를 남깁니다.
- 실패 시 원인을 상태 파일에 기록하고 즉시 종료합니다.
- 조용한 fallback 없이 fail-fast로 동작합니다.

역할 경계:
- `obsidian-workflows:plan`은 의도 확인형(질문 가능) 진입점입니다.
- `obsidian:write.autorun`은 훅 기반 자동 실행에서만 사용하는 deterministic passive 오케스트레이터입니다.
