---
name: ow-policy
description: '새 writing policy 파일을 대화형으로 생성해 writing-config.md에 등록합니다.'
when_to_use: '"새 채널 policy 만들어줘", "linkedin 정책 추가", "writing-config에 채널 등록"처럼 새 채널이나 글 유형의 policy를 만들거나 추가할 때 사용합니다. 기존 policy 수정이나 맞춤법 검사는 제외입니다.'
version: 0.3.0
context: inline
language: korean
created: 2026-07-22T00:00
updated: 2026-08-06T00:00
---

# POLICY Track Entry Point

`obsidian-workflows:ow-policy`는 대화형 문답으로 새 writing policy 파일을 생성하고, 사용자 확인을 받아 vault의 `writing-config.md`에 등록합니다. 생성된 policy는 `write-review-policy` 게이트가 그대로 검증할 수 있는 형태여야 합니다.

policy 스키마의 정본은 `docs/policy-specification.md`입니다. 생성하는 frontmatter/본문 구조는 이 명세를 따릅니다.

## Security & Permissions

- 이 스킬은 파일을 생성/수정합니다(read-only 아님): 새 policy 파일 Write와 `writing-config.md` Edit.
- 모든 경로 입력과 쓰기 대상에 path safety(`docs/contracts/path-safety.md`)를 강제합니다.
- config 편집은 사용자의 명시적 확인 없이는 수행하지 않습니다.

## Preflight (Path Resolution)

1. `docs/contracts/path-resolution.md` 계약에 따라 plugin/repo root와 vault-local `writing-config.md`를 해석·로드합니다.
2. `policy_dir`가 없으면 조용한 fallback 없이 즉시 `FAIL`.
3. policy 파일 경로는 항상 `policy_dir/writing-policy.<policy>.md`로 조합합니다.

## Interactive Collection & File Generation

필드 수집 순서, 선택 필드 후보, 파일 생성 포맷은 `references/policy-fields.md`를 읽어 적용한다. policy 스키마의 정본은 `docs/policy-specification.md`이고, `assets/Workflows/policy/writing-policy.{blog,daily-note}.md`를 few-shot 기준으로 삼는다.

## Self-Validation

`write-review-policy`가 읽는 필드(`required_sections`·`target_length`·`cta_required`)가 well-formed인지, 본문 섹션 헤더가 `required_sections`와 정합하는지 확인합니다. 어긋나면 `FAIL`.

## Config Registration (Confirm Before Write)

`AskUserQuestion`으로 등록 여부를 확인합니다. 수락 시 vault `writing-config.md`를 Edit:

- `enabled_policies`에 `<policy>` 추가
- (선택) `default_policy` 갱신, `proposal_policy_allowlist`에 추가
- `filename_rule.<policy>` 추가(패턴 질문, 기본 `{{date}}-{{slug}}`)

거부 시 편집을 건너뛰고 수동 등록 안내(fail-safe). policy 파일 생성 자체는 유지됩니다.

## Status/Output Rules

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: policy 파일 생성 정상 완료(등록은 선택).
  - `SKIP`: 대상이 이미 존재하고 덮어쓰지 않은 정상 종료.
  - `FAIL`: preflight/입력/자체 검증 오류.
- 실패 시 조용한 fallback 없이 즉시 종료합니다.
- 종료 시 요약과 다음 단계를 안내합니다(예: 이 policy로 초안을 작성하려면 `obsidian-workflows:ow-plan`을 policy와 함께 사용).

## Usage

```
/obsidian-workflows:ow-policy
/obsidian-workflows:ow-policy policy=linkedin output_type=linkedin-post
/obsidian-workflows:ow-policy policy=newsletter --register
```
