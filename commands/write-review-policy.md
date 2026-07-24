---
name: write-review-policy
description: 정책 기반 품질 게이트. 채널별 구조/길이/섹션을 점검합니다.
argument-hint: file=path [policy=<policy-name>]
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-07-22T01:00
---

policy 스키마의 정본은 `docs/policy-specification.md`입니다. 검사하는 필드(`required_sections`/`target_length`/`cta_required`/`policy_type`)의 정의는 그 명세를 따릅니다.

검증 항목(MVP):
- 필수 섹션 존재 여부
- 정책별 길이 제한 준수 여부
- 제목/서론/CTA 등 핵심 블록 충족 여부
- wikilink/참조 근거 포함 여부

출력 형식:
- `PASS` 또는 `FAIL`
- 체크리스트
- 수정 포인트(FAIL일 때만)

규칙:
- 실행 인자 이름은 `policy`를 사용합니다.
- 대상 파일 frontmatter 키는 `policy_type`를 사용합니다.
- policy 미지정 시 파일 frontmatter의 `policy_type`를 우선 사용합니다.
- 최종 policy는 `enabled_policies`에 포함되어야 하며 `policy_dir/writing-policy.<policy>.md`가 존재해야 합니다.
- `file` 경로에 path safety(`docs/contracts/path-safety.md`)를 적용합니다.
- `policy`와 `policy_type`이 모두 비어 있으면 즉시 종료합니다.
- 이 명령은 검증 리포트만 반환하며 파일을 수정하지 않습니다.
- 향후 auto-fix 기능이 추가되면 별도 명령(예: `write-review-final`)로 권한을 분리합니다.

외부 도구 활용: 완료 후 `writing-config.md`의 `external_tools.auto_use`에 따라 grammar-checker → style-guide 순으로 적용합니다. 상세: `docs/contracts/external-tools-integration.md`.

출력에는 발견 항목을 도구별로 정리한 리포트(예: `grammar-checker: 2 issues found` + 라인별 상세, `style-guide: 1 inconsistency found` + 상세)와 `Next: /obsidian-workflows:ow-compound file="..."`를 포함합니다.
