---
name: ow-policy
description: 새 writing policy를 대화형으로 생성하고 확인 후 writing-config.md에 등록합니다. 새 채널/글 유형의 policy를 만들거나 추가해야 할 때 사용합니다.
version: 0.2.0
context: inline
language: korean
created: 2026-07-22T00:00
updated: 2026-07-22T01:00
---

# POLICY Track Entry Point

> 미러 파일: 동작 정본은 `commands/ow-policy.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

`obsidian-workflows:ow-policy`는 대화형 문답으로 새 writing policy 파일을 생성하고, 사용자 확인을 받아 vault의 `writing-config.md`에 등록합니다. 생성된 policy는 `write-review-policy` 게이트가 그대로 검증할 수 있는 형태여야 합니다.

policy 스키마의 정본은 `docs/policy-specification.md`입니다. 생성하는 frontmatter/본문 구조는 이 명세를 따릅니다.

## 보안/권한 원칙

- 이 스킬은 파일을 생성/수정합니다(read-only 아님): 새 policy 파일 Write와 `writing-config.md` Edit.
- 모든 경로 입력과 쓰기 대상에 path safety를 강제합니다: 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지.
- config 편집은 사용자의 명시적 확인 없이는 수행하지 않습니다.

## Preflight (경로 해석)

1. `docs/contracts/path-resolution.md` 계약에 따라 plugin/repo root와 vault-local `writing-config.md`를 해석·로드합니다.
2. `policy_dir`가 없으면 조용한 fallback 없이 즉시 `FAIL`.
3. policy 파일 경로는 항상 `policy_dir/writing-policy.<policy>.md`로 조합합니다.

## 대화형 수집

인자로 값이 주어진 항목은 질문을 건너뜁니다. `AskUserQuestion`으로 핵심을 하나씩 묻습니다.

1. **policy 이름** → `policy_type` + 파일명 suffix. `^[a-z0-9-]+$` 검증. 대상 파일이 이미 있으면 기본은 `FAIL`, `--overwrite` 또는 명시 확인 시에만 진행.
2. **output_type**, **target_length**(자유 입력, 단위는 채널마다 다름), **required_sections**(목록), **cta_required**(bool).
3. **선택적 채널 필드**는 맥락에 맞을 때만 제안: `reference_style`, `line_style`, `topic_required`, `source_strategy`/`source_path_key`/`missing_source_behavior`/`recent_candidates_limit`, `creation_engine`/`template_engine`/`template_key`.
4. 본문 `Goal`/`Structure`/`Style`(또는 `Constraints`)는 답변을 근거로 초안하고 사용자가 검토합니다.

## 파일 생성

`assets/Workflows/policy/writing-policy.{blog,daily-note}.md` 포맷을 few-shot 기준으로 삼습니다.

1. frontmatter: `created`/`updated`(ISO), `policy_type`, `output_type`, `target_length`, `required_sections`, `cta_required`, + 선택 필드.
2. 본문: `# <Title> Policy`, `## Goal`, `## Structure`, `## Style`|`## Constraints`.
3. `policy_dir/writing-policy.<policy>.md`에 Write.

## 자체 검증

`write-review-policy`가 읽는 필드(`required_sections`·`target_length`·`cta_required`)가 well-formed인지, 본문 섹션 헤더가 `required_sections`와 정합하는지 확인합니다. 어긋나면 `FAIL`.

## config 등록 (확인 후 쓰기)

`AskUserQuestion`으로 등록 여부를 확인합니다. 수락 시 vault `writing-config.md`를 Edit:

- `enabled_policies`에 `<policy>` 추가
- (선택) `default_policy` 갱신, `proposal_policy_allowlist`에 추가
- `filename_rule.<policy>` 추가(패턴 질문, 기본 `{{date}}-{{slug}}`)

거부 시 편집을 건너뛰고 수동 등록 안내(fail-safe). policy 파일 생성 자체는 유지됩니다.

## 상태/출력 규칙

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
