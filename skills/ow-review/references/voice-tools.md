# Voice & External Tools (ow-review)

`ow-review`의 형태(문체) 층 상세: 외부 윤문/문법 도구 탐지 우선순위와 humanize 실행 게이트. 정책 게이트와 실행 순서 요약은 `SKILL.md` 본문에 두고, 이 파일은 문체 단계가 실제로 필요할 때만 읽는다(runtime-only detail).

## Voice & External Tools Detection

Fast mode가 아니고 `--skip voice`/`--skip external-tools`가 없을 때만, 정책 게이트 **이후에** 수행한다(의미 → 형태).

윤문 도구는 우선순위로 탐지하며 서로 보완적이다:

1. **im-not-ai humanize (최우선, 문체/윤문)** — AI 티·번역투·피동 남용 등 문체 흔적 진단/개선. `humanize`/`humanize-korean` 슬래시 스킬 또는 `humanize-korean` 스킬 가용 여부로 탐지.
2. **grammar-checker** — 맞춤법/문법/띄어쓰기(표기 오류).
3. **style-guide** — 용어/프로젝트 스타일 일관성.

grammar-checker/style-guide 실행은 `writing-config.md`의 `external_tools.auto_use`(`ask`(기본)/`true`/`false`)를 따른다. plugin/repo root나 도구/스킬 확인 불가 시 해당 탐지만 경고 후 건너뛰고 계속한다(fail-safe).

## Humanize Execution Gate

- 사용자가 윤문/재작성을 **명시 요청**했으면(`--humanize`, 또는 "AI 티 빼줘"·"사람처럼 다듬어줘"·"윤문해줘") 확인 없이 진행한다.
- 명시 요청이 없는데 문체 문제가 감지되면, `Skill`로 humanize를 부르기 전에 `AskUserQuestion`으로 확인한다. 거부 시 진단 리포트만 남기고 원본은 그대로 둔다.
- 진행 시 `Skill` 도구로 humanize 스킬을 `file` 경로에 즉시 호출하고, `final.md`의 before/after 요약을 리포트에 통합한다.
