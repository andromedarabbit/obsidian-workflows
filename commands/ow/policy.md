---
name: ow:policy
description: 새 writing policy를 대화형으로 생성하고 확인 후 writing-config.md에 등록합니다.
argument-hint: "[policy=<name>] [output_type=<type>] [--register] [--overwrite]"
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
created: 2026-07-22T00:00
updated: 2026-07-22T01:00
---

`obsidian-workflows:ow:policy`는 대화형 문답으로 새 writing policy 파일을 생성하고, 사용자 확인을 받아 vault의 `writing-config.md`에 등록합니다.

생성된 policy는 `obsidian:write.review.policy` 게이트가 그대로 검증할 수 있는 형태여야 합니다. 즉 이 커맨드가 쓰는 frontmatter 필드는 review.policy가 읽는 필드(`required_sections`, `target_length`, `cta_required`, `policy_type`)와 정합해야 합니다.

policy 스키마의 정본은 `docs/policy-specification.md`입니다. 생성하는 frontmatter/본문 구조는 이 명세를 따릅니다.

## 보안/권한 원칙

- 이 커맨드는 파일을 생성/수정합니다(read-only 아님). 새 policy 파일 Write와 `writing-config.md` Edit 두 곳에서 쓰기가 발생합니다.
- 모든 경로 입력과 쓰기 대상에 path safety를 강제합니다: 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지.
- config 편집은 사용자의 명시적 확인 없이는 수행하지 않습니다.

## Preflight (경로 해석)

1. `docs/contracts/path-resolution.md` 계약에 따라 `obsidian-workflows` plugin/repo root와 vault-local `writing-config.md`를 해석·로드합니다.
2. config에서 `policy_dir`를 확인합니다. `policy_dir`가 없으면 조용한 fallback 없이 즉시 `FAIL`로 종료합니다.
3. policy 파일 경로는 항상 `policy_dir/writing-policy.<policy>.md`로 조합합니다. policy enum을 하드코딩하지 않습니다.

## 대화형 수집

인자로 값이 이미 주어진 항목은 해당 질문을 건너뜁니다. `AskUserQuestion`으로 한 번에 핵심 하나씩 묻습니다.

1. **policy 이름** → `policy_type`이자 파일명 suffix가 됩니다. `^[a-z0-9-]+$`로 검증하고, 어긋나면 `FAIL`.
   - `policy_dir/writing-policy.<policy>.md`가 이미 존재하면 기본은 `FAIL`로 중단합니다. `--overwrite` 인자 또는 명시적 덮어쓰기 확인이 있을 때만 진행합니다.
2. **output_type** (예: `blog-post`, `x-thread`, `daily-note`, `linkedin-post`).
3. **target_length** — 단위는 채널마다 다릅니다. 자유 입력을 받습니다(예: `1200-1800 words`, `8-15 posts`, `300-800 words`).
4. **required_sections** — 필수 섹션 목록.
5. **cta_required** — boolean.
6. **선택적 채널 필드** — 맥락에 맞을 때만 제안합니다: `reference_style`, `line_style`, `topic_required`, `source_strategy`/`source_path_key`/`missing_source_behavior`/`recent_candidates_limit`, `creation_engine`/`template_engine`/`template_key`. 예시는 `assets/Workflows/policy/writing-policy.daily-note.md`를 참고합니다.
7. **본문 초안** — `Goal`/`Structure`/`Style`(또는 `Constraints`) 섹션 내용을 답변을 근거로 초안하고 사용자가 검토합니다.

## 파일 생성

`assets/Workflows/policy/writing-policy.blog.md`, `writing-policy.daily-note.md` 포맷을 few-shot 기준으로 삼습니다.

1. frontmatter: `created`/`updated`(ISO 8601), `policy_type`(=policy 이름), `output_type`, `target_length`, `required_sections`, `cta_required`, 그리고 수집된 선택 필드.
2. 본문: `# <Title> Policy`, `## Goal`, `## Structure`, `## Style` 또는 `## Constraints`.
3. `policy_dir/writing-policy.<policy>.md`에 Write합니다.

## 자체 검증

파일을 쓴 뒤, `obsidian:write.review.policy`가 읽는 필드가 well-formed인지 점검합니다.

- `required_sections`가 비어 있지 않은 목록인지, `target_length`가 값이 있는지, `cta_required`가 boolean인지 확인합니다.
- 본문 섹션 헤더가 `required_sections`와 정합하는지 확인합니다.
- 어긋나면 `FAIL`로 보고합니다(생성된 policy가 review 게이트에서 검증 불가한 상태로 남지 않게 합니다).

## config 등록 (확인 후 쓰기)

`AskUserQuestion`으로 등록 여부를 확인합니다. `--register` 인자가 있으면 등록 의사로 간주하되, 실제 편집 전에 변경 요약을 보여줍니다.

수락 시 vault `writing-config.md`를 Edit합니다:

- `enabled_policies`에 `<policy>`를 추가합니다.
- (선택) `default_policy`를 갱신하고, `proposal_policy_allowlist`에 추가합니다.
- `filename_rule.<policy>`를 추가합니다(패턴을 묻고, 기본값은 `{{date}}-{{slug}}`).

거부 시 config 편집을 건너뛰고 수동 등록 방법을 안내합니다(fail-safe). policy 파일 생성 자체는 유지됩니다.

## 상태/출력 규칙

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다.
  - `PASS`: policy 파일 생성이 정상 완료됨(등록은 사용자 선택에 따름).
  - `SKIP`: 생성 대상이 이미 존재하고 덮어쓰기를 하지 않은 정상 종료.
  - `FAIL`: preflight/입력/자체 검증 오류.
- 실패 시 조용한 fallback 없이 즉시 종료합니다.
- 종료 시 요약과 다음 단계를 안내합니다(예: 이 policy로 초안을 작성하려면 `obsidian-workflows:ow:plan`을 policy와 함께 사용).

## Usage

```
/obsidian-workflows:ow:policy
/obsidian-workflows:ow:policy policy=linkedin output_type=linkedin-post
/obsidian-workflows:ow:policy policy=newsletter --register
```
