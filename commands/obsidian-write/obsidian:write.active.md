---
name: obsidian:write.active
description: Active 모드. 사용자 입력(topic/sources/policy)으로 즉시 초안을 생성합니다.
argument-hint: topic=... [policy=<policy-name>] [sources=[[노트A]],[[노트B]]] [soul=false]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-03T19:00
---

입력:
- `topic` (기본 필수, 단 선택 policy의 `topic_required: false`면 생략 가능)
- `policy` (선택)
- `sources` (선택, wikilink/경로 목록)
- `soul` (기본 true)

정책 해석 규칙(설정 기반):
1. `writing-config.md`에서 `enabled_policies`, `default_policy`, `policy_dir`를 읽습니다.
2. `policy` 결정 순서:
   - 명시 인자 `policy`
   - `default_policy`
   - `enabled_policies`의 첫 항목
3. 최종 policy는 반드시 `enabled_policies`에 포함되어야 합니다.
4. policy 템플릿(`policy_dir/writing-policy.<policy>.md`)이 없으면 즉시 종료합니다.
5. 정책 enum은 하드코딩하지 않습니다. 새 policy 추가는 설정+템플릿으로 처리합니다.

정책별 동작 계약:
- policy 템플릿 frontmatter의 실행 메타데이터를 해석합니다.
  - 예: `topic_required`, `source_strategy`, `missing_source_behavior`, `recent_candidates_limit`, `creation_engine`, `template_engine`
- `source_strategy: previous-note`인 경우:
  1. policy/config에 지정된 소스 경로(예: `daily_notes_path`)에서 직전 노트를 찾습니다.
  2. 직전 노트가 없고 `missing_source_behavior: skip-and-prompt-recent`면 `SKIP`으로 종료합니다.
  3. 종료 시 최근 파일 최대 N개(`recent_candidates_limit`, 기본 5)를 제시하고 사용자 선택을 요청합니다.
  4. 최근 파일도 없으면 그 사실을 명시하고 다음 액션을 사용자에게 묻습니다.
- `creation_engine: obsidian-cli`와 `template_engine: templater`가 요구되면 해당 설정 누락 시 즉시 종료합니다.

실행:
1. `writing-config.md` 로드
2. policy 결정 및 policy 템플릿 로드
3. policy 메타데이터 기반 입력/소스 검증
4. `soul_path` 로드 (soul=true일 때)
5. policy 형식에 맞는 초안을 생성하고 `draft_path`에 저장
6. policy가 `creation_engine: obsidian-cli`를 요구하면 Obsidian CLI 경로로 생성
7. soul=true이면 보이스 리라이트를 적용

출력:
- 공통 Context Card(`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`, `policy_type`, `soul`, `status`)
- 생성 파일 경로
- 적용 policy / soul 적용 여부
- 보강 필요 TODO(있을 경우)

실패 정책:
- 필수 입력/설정(`enabled_policies`, policy 템플릿, `draft_path` 등) 누락 시 즉시 종료합니다.
- 조용한 fallback 없이 fail-fast로 동작합니다.
