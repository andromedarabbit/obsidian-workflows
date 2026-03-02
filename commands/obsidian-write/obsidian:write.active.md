---
name: obsidian:write.active
description: Active 모드. 사용자 입력(topic/sources/policy)으로 즉시 초안을 생성합니다.
argument-hint: topic=... [policy=<policy-name>] [sources=[[노트A]],[[노트B]]] [soul=false]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-02T17:38
---

입력:
- `topic` (필수)
- `policy` (기본: blog, 커스텀 정책 허용)
- `sources` (선택, wikilink/경로 목록)
- `soul` (기본 true)

정책 해석 규칙:
- 기본 제공 정책(`blog`, `x-thread`, `weekly-review`, `newsletter`)은 즉시 사용 가능합니다.
- 커스텀 정책은 `policy_dir/writing-policy.<policy>.md` 파일이 존재하면 사용 가능합니다.
- 지정한 policy 파일이 없으면 즉시 종료합니다.

실행:
1. `writing-config.md` 로드
2. 선택한 policy 템플릿 로드 (`policy_dir/writing-policy.<policy>.md`)
3. `soul_path` 로드 (soul=true일 때)
4. policy 형식에 맞는 초안을 생성하고 `draft_path`에 저장
5. soul=true이면 보이스 리라이트를 적용

출력:
- 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)
- 생성 파일 경로
- 적용 policy / soul 적용 여부
- 보강 필요 TODO(있을 경우)

실패 정책:
- topic 누락, policy 미존재, draft_path 미설정이면 즉시 종료합니다.
