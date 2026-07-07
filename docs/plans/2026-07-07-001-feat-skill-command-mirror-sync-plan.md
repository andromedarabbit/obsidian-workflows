---
date: 2026-07-07
type: feat
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
product_contract_source: ce-plan-bootstrap
execution: code
origin: docs/ideation/2026-06-16-skill-authoring-compliance-ideation.html
---

# feat: SKILL↔command 미러 드리프트 해시 동기 검사

## Summary

각 `skills/<name>/SKILL.md`는 짝이 되는 `commands/ow/<name>.md`의 행위를 손으로 미러링한다. `docs/skill-specification.md`는 이 관계를 명시하고 command를 단일 정본으로 규정하지만, **동기화는 순수 산문 규칙("편집할 때 유념하라")으로만 강제**된다. 이 미러는 이미 한 번 갈라져 실제 회귀를 냈다(`docs/solutions/logic-errors/ow-plan-passive-default-regression.md`). 이 계획은 SKILL frontmatter에 짝 command **본문의 콘텐츠 해시**를 기록하고, command가 바뀌었는데 해시가 갱신되지 않으면 pre-commit·CI가 실패하게 만들어 드리프트를 자동 검출한다.

핵심 성격은 **강제 재확인(forcing function)**이다: command 본문이 바뀌면 저자는 반드시 SKILL.md를 다시 보고 해시를 재생성해야 커밋이 통과한다. 이는 "커맨드만 고치고 skill을 빼먹는" 정확한 회귀 패턴을 차단한다.

## Problem Frame

- **문제:** SKILL.md와 짝 command의 동기화가 사람 규율에만 의존한다. command 행위가 바뀌어도 SKILL.md가 안 따라오면 아무 신호가 없다 — 이미 겪은 무증상 회귀.
- **왜 지금:** 세션 재검토 결과 skills 계층의 다른 갭(name↔dir, frontmatter 필드, MOC 오염, 검증 사각지대, 분기 미문서화)은 모두 해소됐고, 미러 드리프트 방어가 유일하게 남은 실질 문제다.
- **범위 경계:** 이 계획은 *검출*만 자동화한다. command→SKILL을 자동 생성하지 않으며(스펙이 방금 확정한 "손으로 쓰는 미러" 모델과 상충), command 동작을 바꾸지 않는다.

## Requirements

- **R1** — SKILL frontmatter가 짝 command 경로(`mirrors`)와 그 본문 해시(`mirror_hash`)를 기록한다.
- **R2** — 검증기가 각 skill에 대해 짝 command 본문의 현재 해시를 계산해 기록된 `mirror_hash`와 비교하고, 불일치 시 `FAIL`(exit 2)로 어느 skill이 stale인지와 갱신 방법을 출력한다.
- **R3** — 정당한 동기화 후 저자가 해시를 재생성하는 값싼 경로(`--fix` 또는 갱신 헬퍼)를 제공한다.
- **R4** — 검사가 pre-commit과 CI(`validate.yml`)에 배선되어, skill 또는 command 어느 쪽이 바뀌든 발동한다.
- **R5** — 4개 skill 전부 `mirrors`/`mirror_hash`로 백필되고, 미러 선언이 4개에 일관되게 적용된다(현재 plan/work만 본문 선언).
- **R6** — `check-skill-frontmatter.sh`가 신규 필수 필드(`mirrors`, `mirror_hash`)를 인지한다.
- **R7**(부수) — 한국어 콘텐츠 lint(em-dash·외래어 표기법) stance를 스펙의 Diverged/Not Applicable에 명시해 "채택 안 함"인지 "미착수"인지 모호함을 없앤다.

**Product Contract preservation:** 신규 계획(bootstrap) — 상위 요구사항 문서 없음. ideation 문서(`docs/ideation/2026-06-16-...html`) Idea 3을 근거로 삼는다.

---

## Key Technical Decisions

- **KTD1 — 해시 대상은 command "본문"(frontmatter 이후 전체).** command frontmatter의 `created`/`updated` 타임스탬프는 자주 바뀌므로 전체 파일 해시는 오탐을 낸다. 행위 정본은 본문(`commands/ow/plan.md` 기준 8번째 줄 종료 delimiter 이후)이므로 본문만 해시한다. command의 인터페이스 필드(`description`/`argument-hint`)는 이미 `check-frontmatter.sh`가 독립 검증하므로 이 검사 범위 밖. *대안(향후):* 인터페이스 필드까지 포함하려면 본문 + `description` + `argument-hint`를 정규화해 해시(타임스탬프 제외).
- **KTD2 — 알고리즘·정규화.** `shasum -a 256`(macOS/Linux 공통) 또는 `sha256sum` 폴백. 해시 전 후행 공백/최종 개행을 정규화(`pre-commit`의 end-of-file-fixer와 충돌 방지). 짧은 표기를 위해 앞 16 hex만 기록해도 충돌 위험은 무시 가능.
- **KTD3 — 쉘 검증기 + 기존 헬퍼 재사용.** `tools/lib/frontmatter.sh`의 `extract_field()`로 `mirrors`/`mirror_hash`를 읽는다. Node가 아니라 쉘로 구현해 기존 `check-*.sh` 계열과 일관.
- **KTD4 — pre-commit `files` 글롭은 양쪽을 포함.** `^(skills/.*/SKILL\.md|commands/ow/.*\.md)$` — command만 바뀌어도 훅이 발동해야 하므로. 훅은 인자를 무시하고 4개 쌍 전부를 결정적으로 검사한다.
- **KTD5 — 미러 선언은 frontmatter `mirrors:` 필드를 정본으로.** 본문 산문 선언(현재 plan/work만)은 중복이므로, frontmatter 필드를 4개 공통 정본으로 삼고 본문 선언은 한 줄로 통일하거나 제거한다.

---

## Implementation Units

### U1. 미러-싱크 frontmatter 계약 정의 (스펙)

- **Goal:** `mirrors`/`mirror_hash` 필드와 해시 규칙(KTD1·KTD2)을 스펙에 규정해 단일 정본화한다.
- **Requirements:** R1
- **Dependencies:** 없음
- **Files:** `docs/skill-specification.md` (수정), `docs/frontmatter-reference.md` (수정 — skill 필드 표에 추가 시)
- **Approach:** Frontmatter Contract에 `mirrors`(string, 짝 command 경로)와 `mirror_hash`(string, KTD1 규칙으로 계산한 command 본문 해시)를 필수 필드로 추가. "Skill Body Conventions" 절에 해시가 *강제 재확인* 수단임을 명시하고, 검출만 하며 의미 동등성은 보증하지 않는다는 한계를 적는다. Example Skill frontmatter도 갱신.
- **Patterns to follow:** 기존 Frontmatter Contract 필드 기술 스타일(`name`/`description`/`context` 항목).
- **Test scenarios:** `Test expectation: none -- 문서 변경(동작 없음).` 단, U6 검증기가 이 계약을 강제하므로 계약-검증기 정합은 U6에서 검사.
- **Verification:** 스펙에 두 필드와 해시 규칙·한계가 문서화되어 있고 Example가 실제 SKILL.md와 일치.

### U2. `mirror_hash` 계산·갱신 헬퍼

- **Goal:** command 본문 해시를 계산하고 SKILL.md의 `mirror_hash`를 갱신하는 값싼 경로(R3).
- **Requirements:** R3
- **Dependencies:** U1
- **Files:** `tools/lib/mirror-hash.sh` (신규 — 공유 해시 함수), `tools/update-skill-hash.sh` (신규 — 갱신 CLI), `tools/lib/frontmatter.sh` (참조)
- **Approach:** `mirror-hash.sh`는 command 경로를 받아 본문(frontmatter 종료 delimiter 이후)을 추출·정규화·해시하는 순수 함수를 export(검증기와 갱신기가 공유). `update-skill-hash.sh [<name>...]`는 대상 skill(기본 4개 전부)의 `mirrors` 필드를 읽어 짝 command 해시를 계산하고 SKILL.md의 `mirror_hash`를 in-place 치환. `set -euo pipefail`, fail-fast.
- **Execution note:** 해시 함수는 U6 검증기와 공유되므로 먼저 `mirror-hash.sh`의 계산이 결정적임을 증명하는 테스트를 작성.
- **Patterns to follow:** `tools/lib/frontmatter.sh`의 함수 스타일; `tools/check-frontmatter.sh`의 색상/exit 관례.
- **Test scenarios:**
  - 동일 command 본문에 대해 해시가 결정적(2회 호출 동일).
  - frontmatter의 `updated:` 타임스탬프만 바뀐 command → 해시 불변(본문만 해시 확인).
  - command 본문 1글자 변경 → 해시 변화.
  - `update-skill-hash.sh plan`이 `skills/plan/SKILL.md`의 `mirror_hash`만 갱신하고 다른 필드·본문 불변.
  - 존재하지 않는 짝 command → fail-fast로 명확한 에러.
- **Verification:** `update-skill-hash.sh` 실행 후 4개 SKILL.md의 `mirror_hash`가 짝 command 본문과 일치하고, 재실행 시 변경 없음(멱등).

### U3. `check-skill-sync.sh` 검증기

- **Goal:** 기록된 `mirror_hash`와 짝 command 본문의 현재 해시를 비교해 드리프트를 검출(R2).
- **Requirements:** R2
- **Dependencies:** U2
- **Files:** `tools/check-skill-sync.sh` (신규), `tools/lib/mirror-hash.sh` (재사용)
- **Approach:** 모든 `skills/*/SKILL.md`를 순회하며 `mirrors`·`mirror_hash`를 추출, `mirror-hash.sh`로 짝 command 본문 해시를 계산해 비교. 불일치 시 `ERROR`로 skill명·짝 경로·`tools/update-skill-hash.sh <name>`로 갱신하라는 지침을 출력하고 exit 2. 인자 무시(pre-commit이 부분 파일을 넘겨도 항상 4쌍 전수 검사, KTD4). `mirrors` 필드 누락 skill도 실패(계약 위반).
- **Patterns to follow:** `tools/check-skill-frontmatter.sh`의 순회·색상·`Checked N / All checks passed!` 출력 관례.
- **Test scenarios:**
  - 4개 모두 동기 상태 → PASS(exit 0).
  - 한 command 본문을 바꾸고 해시 미갱신 → 해당 skill FAIL(exit 2), 메시지에 skill명·갱신 명령 포함.
  - `mirror_hash` 필드 누락 skill → FAIL.
  - `mirrors`가 존재하지 않는 command를 가리킴 → FAIL(명확한 사유).
  - command frontmatter 타임스탬프만 변경 → PASS(본문 해시 불변, 오탐 없음).
- **Verification:** 의도적으로 command를 편집해 검사를 빨간불로 만들고, `update-skill-hash.sh`로 초록불 복구되는 왕복이 성립.

### U4. 4개 SKILL.md 백필 + 미러 선언 통일

- **Goal:** 4개 skill에 `mirrors`/`mirror_hash`를 채우고 미러 선언을 일관화(R5).
- **Requirements:** R5
- **Dependencies:** U2
- **Files:** `skills/plan/SKILL.md`, `skills/work/SKILL.md`, `skills/review/SKILL.md`, `skills/compound/SKILL.md`
- **Approach:** 각 SKILL frontmatter에 `mirrors: commands/ow/<name>.md` 추가 후 `tools/update-skill-hash.sh`로 `mirror_hash` 생성. 본문 미러 선언: frontmatter `mirrors`가 정본이 되므로(KTD5), plan/work의 기존 산문 선언을 4개 공통의 한 줄 형식으로 통일하거나 제거해 review/compound와 일관되게 맞춘다.
- **Patterns to follow:** 기존 SKILL frontmatter 필드 순서·형식.
- **Test scenarios:** `Test expectation: none -- 콘텐츠/메타데이터 변경(동작 없음).` 정합은 U3·U6 검증기가 커버.
- **Verification:** `check-skill-sync.sh` PASS; 4개 skill의 미러 선언 방식이 동일.

### U5. pre-commit·CI 배선

- **Goal:** 동기 검사를 게이트로 승격(R4).
- **Requirements:** R4
- **Dependencies:** U3, U4
- **Files:** `.pre-commit-config.yaml`, `.github/workflows/validate.yml`
- **Approach:** pre-commit에 로컬 `language: script` 훅 `check-skill-sync` 추가, `files: '^(skills/.*/SKILL\.md|commands/ow/.*\.md)$'`(KTD4)로 양쪽 변경에 발동. `validate.yml`의 frontmatter 잡에 `bash tools/check-skill-sync.sh` 단계 추가(기존 `check-skill-frontmatter.sh` 옆). 게이트 도입은 U4 백필 완료 후 같은 변경 묶음에 포함해 도입 즉시 빨간불이 안 나게 한다(gate-ordering).
- **Patterns to follow:** `.pre-commit-config.yaml`의 기존 `check-skill-frontmatter` 훅 블록(35–40행); `validate.yml`의 `check-skill-frontmatter.sh` 스텝(33–34행).
- **Test scenarios:**
  - `Covers R4.` pre-commit에서 command만 스테이징하고 skill 미갱신 → 훅 실패로 커밋 차단.
  - skill·command를 동기 상태로 함께 스테이징 → 훅 통과.
  - CI에서 `check-skill-sync.sh`가 frontmatter 잡의 일부로 실행됨을 워크플로 파싱으로 확인.
- **Verification:** `pre-commit run check-skill-sync --all-files` 통과; 드리프트 주입 시 pre-commit·CI 모두 실패.

### U6. `check-skill-frontmatter.sh`에 신규 필드 인지 + 한국어 lint stance 문서화

- **Goal:** 신규 필수 필드 인지(R6) + 한국어 콘텐츠 lint stance 명시(R7).
- **Requirements:** R6, R7
- **Dependencies:** U1
- **Files:** `tools/check-skill-frontmatter.sh`, `docs/skill-specification.md`
- **Approach:** (R6) `check-skill-frontmatter.sh`의 `REQUIRED_FIELDS`에 `mirrors`·`mirror_hash` 추가(unknown 필드를 거부하지 않으므로 회귀 없음, 필수화만). `mirrors`는 `commands/ow/<name>.md` 형태 형식 검사, `mirror_hash`는 16+ hex 형식 검사. (R7) 스펙의 "Relationship to oh-my-skills" Diverged/Not Applicable에 한국어 콘텐츠 lint(em-dash 금지·외래어 표기법·용어집) 항목을 추가해 "현재 미강제 — 향후 lint 후보" 또는 "N/A" 중 하나로 stance를 못박는다.
- **Patterns to follow:** `check-skill-frontmatter.sh`의 `REQUIRED_FIELDS` 배열·`case` 필드 검증; 스펙의 Diverged 항목 서술 스타일.
- **Test scenarios:**
  - `mirrors` 누락 SKILL.md → `check-skill-frontmatter.sh` FAIL.
  - `mirror_hash`가 hex 형식이 아님 → FAIL.
  - 4개 정상 skill → PASS.
  - `Test expectation: 스펙 stance 편집은 동작 없음` — R7 부분은 문서만.
- **Verification:** `check-skill-frontmatter.sh` 4개 PASS; 필드 누락 시 FAIL; 스펙에 한국어 lint stance가 한 항목으로 존재.

---

## Verification Contract

- `bash tools/check-skill-sync.sh` → 4개 PASS, 드리프트 주입 시 exit 2.
- `bash tools/check-skill-frontmatter.sh` → 4개 PASS(신규 필드 포함).
- `bash tools/update-skill-hash.sh` → 멱등(재실행 시 변경 없음).
- `npm run validate:all` → 그린.
- `pre-commit run --all-files` → 그린; command 단독 편집으로 드리프트 주입 시 `check-skill-sync` 실패.
- 왕복 증명: command 본문 편집 → 검사 빨간불 → SKILL.md 갱신 + `update-skill-hash` → 초록불.

## Definition of Done

- R1–R7 충족.
- 4개 SKILL.md가 `mirrors`/`mirror_hash` 보유, 미러 선언 일관.
- `check-skill-sync.sh`가 pre-commit·CI 게이트에 배선되어 초기 도입 커밋이 그린.
- 스펙에 해시 계약·한계·한국어 lint stance 문서화.
- 전체 검증 스위트 그린.

---

## Risks & Dependencies

- **R-A: 해시는 재확인을 강제할 뿐 의미 동등성을 증명하지 않는다.** 저자가 해시를 재생성하며 SKILL.md를 *실제로* 올바르게 맞췄는지는 보증하지 못한다. 이는 설계상 한계(forcing function)로, 스펙에 명시(U1). 완화: command 편집 시 검사가 반드시 저자의 눈을 SKILL.md로 되돌린다는 점이 순수 산문 규칙보다 강함.
- **R-B: 해시 대상 선택(본문 only)이 인터페이스 드리프트를 놓칠 수 있다.** command `description`/`argument-hint` 변경은 이 검사에 안 걸린다(KTD1). 완화: 그 필드는 `check-frontmatter.sh`가 독립 검증; 필요 시 KTD1 대안으로 확장.
- **R-C: pre-commit `files` 글롭 오설정 시 command 편집에 훅이 안 뜰 수 있다.** 완화: U5 테스트가 "command 단독 편집 → 훅 발동"을 명시 검사.
- **의존:** `shasum`/`sha256sum` 가용(macOS·Linux CI 러너 기본 제공). `tools/lib/frontmatter.sh` 헬퍼.

## Sources & Research

- `docs/ideation/2026-06-16-skill-authoring-compliance-ideation.html` — Idea 3(미러 해소) 근거.
- `docs/skill-specification.md` — "Skill Body Conventions"가 미러 관계와 드리프트 위험을 이미 규정(강제는 산문뿐).
- `docs/solutions/logic-errors/ow-plan-passive-default-regression.md` — 미러 드리프트가 낸 실제 회귀 선례.
- 재사용 인프라(세션 내 확인): `tools/lib/frontmatter.sh`(`extract_field`), `tools/check-skill-frontmatter.sh`(unknown 필드 미거부), `.pre-commit-config.yaml`(로컬 script 훅), `.github/workflows/validate.yml`(frontmatter 잡).
