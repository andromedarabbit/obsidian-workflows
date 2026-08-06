# ow-policy field collection (runtime detail)

이 파일은 `ow-policy`가 대화형으로 필드를 수집하고 policy 파일을 생성할 때 익히는 런타임 디테일이다. policy 스키마의 정본은 `docs/policy-specification.md`이다 — 이 파일은 정본을 반복하지 않고, "어떤 필드를 어떤 순서로, 어떤 조건으로 묻고 생성하는지"에만 집중한다.

## 수집 순서

인자로 값이 주어진 항목은 질문을 건너뛴다. `AskUserQuestion`으로 핵심을 하나씩 묻는다.

1. **policy 이름** → `policy_type` + 파일명 suffix. `^[a-z0-9-]+$` 검증. 대상 파일이 이미 있으면 기본은 `FAIL`, `--overwrite` 또는 명시 확인 시에만 진행.
2. **필수 채널 필드**: `output_type`, `target_length`(자유 입력, 단위는 채널마다 다름), `required_sections`(목록), `cta_required`(bool).
3. **선택적 채널 필드**는 맥락에 맞을 때만 제안한다. 후보:
   - 톤/주제: `reference_style`, `line_style`, `topic_required`
   - 소스 관련: `source_strategy` / `source_path_key` / `missing_source_behavior` / `recent_candidates_limit`
   - 생성 엔진: `creation_engine` / `template_engine` / `template_key`
4. 본문 `Goal` / `Structure` / `Style`(또는 `Constraints`)는 답변을 근거로 초안하고 사용자가 검토한다.

각 필드의 스키마(타입·허용값)는 `docs/policy-specification.md`를 따른다.

## 파일 생성 포맷

`assets/Workflows/policy/writing-policy.{blog,daily-note}.md` 포맷을 few-shot 기준으로 삼는다.

1. frontmatter: `created`/`updated`(ISO), `policy_type`, `output_type`, `target_length`, `required_sections`, `cta_required` + 수집한 선택 필드.
2. 본문: `# <Title> Policy`, `## Goal`, `## Structure`, `## Style` | `## Constraints`.
3. `policy_dir/writing-policy.<policy>.md`에 Write.

`write-review-policy`가 읽는 필드(`required_sections`·`target_length`·`cta_required`)가 well-formed여야 한다 — SKILL.md의 Self-Validation 단계가 이를 확인한다.
