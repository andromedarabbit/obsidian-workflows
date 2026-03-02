---
name: obsidian:write.propose
description: Passive 제안 생성. 스캔 결과를 아이디어 카드(3~5개)로 제안 노트에 저장합니다.
argument-hint: "[--from-scan] [--ideas N] [--draft idea-id]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T17:35
---

동작:
1. `obsidian:write.scan`의 최신 결과를 입력으로 사용합니다.
2. scan 결과가 없으면 오류가 아니라 `SKIP`으로 즉시 종료하고, 아래 다음 액션을 안내합니다.
   - `/obsidian-workflows:plan` 실행 후 B(주제 제안 받기) 선택
   - `/obsidian-workflows:plan --intent passive --window-days 7` (필요 시 window/source 조정)
   - `writing-config.md`의 `source_paths`/`exclude_paths` 점검
3. 후보 파일을 주제별로 묶어 아이디어 3~5개를 생성합니다.
4. `proposal_path`에 제안 노트를 생성합니다.

아이디어 카드 형식(각 항목 필수):
- 제목
- 핵심 논지(1~2문장)
- 근거 wikilink 목록
- 추천 policy (`blog|x-thread|weekly-review|newsletter`)

기본 원칙:
- 시작/종료 시 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)를 출력합니다.
- 실패 시에도 가능한 범위에서 동일 키로 Context Card를 남깁니다.
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다(빈 scan 결과는 `SKIP`).
- 기본값은 제안 노트 생성까지만 수행합니다.
- `--draft`로 명시된 아이디어만 `obsidian:write.draft` 흐름으로 이어갈 수 있습니다.
- 자동 실행에서도 제안 노트까지만 생성합니다.
