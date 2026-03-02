---
name: work
description: WORK 트랙 진입점. mode 지정 시 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다.
argument-hint: mode=<active|passive|draft|refine|route> [args...]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T17:38
---

`obsidian-workflows:work`는 `obsidian:write.*` 실행 명령으로 라우팅하는 WORK 트랙 엔트리포인트입니다.

주의:
- 로컬 워크플로우는 `/obsidian-workflows:*`를 사용합니다.
- `/compound-engineering:workflows:*`는 다른 플러그인 스킬입니다.

Scope Guard (repo-only):
- 실행 대상은 vault root 하위 저장소 파일로 제한합니다.
- `~/.claude/*` 같은 전역 런타임 상태를 해결책으로 사용하지 않습니다.

Preflight Gate (fail-fast):
- 초기화 대상 목록의 canonical source는 `.claude/commands/obsidian:write.init.md`의 `초기화 대상` 섹션입니다.
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

모드 매핑(mode 지정 시 질문 없는 deterministic 실행):
- `mode=active` -> `obsidian:write.active`
- `mode=passive` -> `obsidian-workflows:plan --intent passive` (`scan -> propose`)
- `mode=draft` -> `obsidian:write.draft`
- `mode=refine` -> `obsidian:write.refine`
- `mode=route` -> `obsidian:write.route`

Proposal 자동 감지 (mode=draft이고 proposal 미지정 시):
1. `writing-config.md`에서 `proposal_path` 읽기
2. `proposal_path` 디렉토리의 `.md` 파일 스캔
3. 각 파일의 frontmatter에서 `status` 필드 확인
4. 우선순위:
   - `status: in-progress` (최신순)
   - `status: pending` (최신순)
   - `status` 필드 없음 (최신순)
   - `status: completed`는 제외
5. `idea` 미지정 시 config의 `default_idea` 사용 (기본값: 1)
6. `proposal_auto_select: true`면 자동 진행
7. `proposal_auto_select: false`면 감지된 proposal 표시 후 확인 요청

실행 규칙:
- 시작/종료 시 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)를 출력합니다.
- `mode`가 없으면 즉시 `FAIL`로 종료하고 `active|passive|draft|refine|route` 중 하나를 지정하도록 안내합니다.
- `mode`가 지정되면 추가 질문 없이 해당 경로를 실행합니다.
- 하위 명령의 입력 스키마를 그대로 따릅니다.
- 실패 시 조용한 fallback 없이 즉시 종료하고 원인/해결 액션을 반환합니다.

상태/출력 규칙:
- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
- `mode=passive`의 empty candidate는 오류가 아니라 `SKIP`입니다.
