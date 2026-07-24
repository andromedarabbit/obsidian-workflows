---
name: write-refine
description: 기존 초안을 SOUL 규칙으로 리라이트/정제합니다.
argument-hint: file=path [soul=true|false] [policy=<policy-name>]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-03T19:00
---

실행:
1. 대상 초안 파일을 읽습니다.
2. `soul_path`를 로드합니다.
3. soul=true면 보이스/톤/리듬 규칙으로 리라이트합니다.
4. policy가 지정되면 해당 구조 규칙도 함께 정렬합니다.
5. 결과를 같은 파일에 반영하거나 `-refined` 파일로 저장합니다.

기본 정책:
- soul_enforced=true 환경에서는 soul=false 요청이 있더라도 명시 override 여부를 확인합니다.
- policy가 지정되면 `enabled_policies` 포함 여부와 `policy_dir/writing-policy.<policy>.md` 존재 여부를 함께 검증하고, 하나라도 실패하면 즉시 종료합니다.
- `file` 경로에 path safety(`docs/contracts/path-safety.md`)를 적용합니다.
- 리라이트 후 변경 요약(핵심 수정 3가지)을 제공합니다.

외부 도구 활용: 완료 후 `writing-config.md`의 `external_tools.auto_use`에 따라 humanizer → grammar-checker → style-guide 순으로 적용합니다. 상세: `docs/contracts/external-tools-integration.md`.

출력에는 적용된 도구 요약(예: `humanizer: 3 AI patterns naturalized`, `grammar-checker: 2 errors fixed`, `style-guide: All checks passed`)과 `Next: /obsidian-workflows:ow-review file="..." policy=...`를 포함합니다.
