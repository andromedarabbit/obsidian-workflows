---
name: obsidian:write.review.policy
description: 정책 기반 품질 게이트. 채널별 구조/길이/섹션을 점검합니다.
argument-hint: file=path [policy=<policy-name>]
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-02T17:38
---

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
- policy가 지정되면 `policy_dir/writing-policy.<policy>.md` 존재 여부를 검증하고, 없으면 즉시 종료합니다.
- `file` 경로는 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 강제합니다.
- `policy`와 `policy_type`이 모두 비어 있으면 즉시 종료합니다.
- 이 명령은 검증 리포트만 반환하며 파일을 수정하지 않습니다.
- 향후 auto-fix 기능이 추가되면 별도 명령(예: `obsidian:write.review.final`)로 권한을 분리합니다.
