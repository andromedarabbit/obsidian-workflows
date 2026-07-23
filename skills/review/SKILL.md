---
name: review
description: '게시·발행 직전의 초안을 정책 검증과 문체 리뷰까지 한 번에 통과시키고 싶을 때 사용합니다. Obsidian vault 초안(블로그·뉴스레터·스레드·데일리 노트)이나 writing-config policy로 검증할 draft가 대상입니다. 채널 정책 게이트(구조·길이·필수 섹션 검증)에 이어 문체·윤문 점검(AI 티·번역투 진단, 필요 시 사람처럼 다듬기)까지 한 번에 수행합니다. 정책 검증하고 문체까지, 발행 전 최종 점검, 리뷰하고 AI 티 있으면 다듬어줘 같은 요청에 적합합니다. 제외 — 맞춤법·오탈자만 교정, policy 신규 생성, 코드·PR 리뷰, 새 글 작성, 정책 검증 없이 문장만 윤문(AI 티만 빼줘)하려는 요청.'
version: 0.2.0
context: inline
mirrors: commands/ow-review.md
mirror_hash: ce48b2dabb6c5a15
language: korean
ce_platforms: []
created: 2026-03-02T14:58
updated: 2026-07-22T02:00
---

# REVIEW Track Entry Point

> 미러 파일: 동작 정본은 `commands/ow-review.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

`obsidian-workflows:ow-review`는 두 단계로 검증합니다: (1) `write-review-policy` 정책 게이트로 구조·길이·필수 섹션을 점검(의미 층), (2) 문체·윤문 단계에서 AI 티·번역투를 진단하고 필요 시 윤문(형태 층).

의미 → 형태 순서를 지키는 이유: 정책 게이트가 섹션을 재배치/변경하면 앞선 윤문이 무효가 되므로, 구조/의미를 먼저 확정하고 윤문은 마지막에 둡니다.

## 보안/권한 원칙

- 자체 검사(정책 게이트·탐지·리포팅)는 파일을 수정하지 않고 read-only 도구만 씁니다.
- 윤문 재작성은 직접 하지 않고 `Skill` 도구로 humanize 스킬에 위임합니다. humanize는 결과를 자체 워크스페이스(`_workspace/{date}/final.md`)에 씁니다.
- 재작성은 사용자가 명시 요청했을 때만 자동 진행하고, 아니면 실행 전 `AskUserQuestion`으로 확인합니다(read-only 기본 보존).

## Helper Script Path Resolution

- helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.
- 먼저 `obsidian-workflows` plugin/repo root를 해석하고, 해석된 root 아래 절대 경로로 실행합니다.
- root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
- optional helper script 단계는 경고 후 건너뛰고 fail-safe 정책을 따릅니다.

## Voice/윤문 & External Tools Detection

Fast mode가 아니고 `--skip voice`/`--skip external-tools`가 없을 때만, 정책 게이트 **이후에** 수행합니다(의미 → 형태).

윤문 도구는 우선순위로 탐지하며 서로 보완적입니다:

1. **im-not-ai humanize (최우선, 문체/윤문)** — AI 티·번역투·피동 남용 등 문체 흔적 진단/개선. `humanize`/`humanize-korean` 슬래시 스킬 또는 `humanize-korean` 스킬 가용 여부로 탐지.
2. **grammar-checker** — 맞춤법/문법/띄어쓰기(표기 오류).
3. **style-guide** — 용어/프로젝트 스타일 일관성.

grammar-checker/style-guide 실행은 `writing-config.md`의 `external_tools.auto_use`(`ask`(기본)/`true`/`false`)를 따릅니다. plugin/repo root나 도구/스킬 확인 불가 시 해당 탐지만 경고 후 건너뛰고 계속합니다(fail-safe).

## 윤문(humanize) 실행 게이트

- 사용자가 윤문/재작성을 **명시 요청**했으면(`--humanize`, 또는 "AI 티 빼줘"·"사람처럼 다듬어줘"·"윤문해줘") 확인 없이 진행합니다.
- 명시 요청이 없는데 문체 문제가 감지되면, `Skill`로 humanize를 부르기 전에 `AskUserQuestion`으로 확인합니다. 거부 시 진단 리포트만 남기고 원본은 그대로 둡니다.
- 진행 시 `Skill` 도구로 humanize 스킬을 `file` 경로에 즉시 호출하고, `final.md`의 before/after 요약을 리포트에 통합합니다.

## 실행 순서

1. 대상 파일과 policy를 확정합니다.
2. `file` 경로에 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크 탈출 금지를 적용합니다.
3. `write-review-policy` 규칙으로 구조/길이/필수 섹션을 검증합니다(의미 층).
4. (fast/skip이 아니면) Voice/윤문 & External Tools 단계를 수행합니다(형태 층): 문체 진단, 필요 시 확인 후 humanize 위임.
5. PASS/FAIL 체크리스트, 수정 포인트, 윤문 요약(수행 시)을 반환합니다.

## 상태/출력 규칙

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다: `PASS`(정책 게이트 통과), `SKIP`(대상/도구 없음), `FAIL`(위반/입력·경로 오류).
- 종료 시 다음 단계 안내(예: `obsidian-workflows:ow-compound`).

## 후속 확장

- 문체(voice) 리뷰는 별도 `write-review-voice` 대신 이 단계의 im-not-ai humanize 위임으로 제공합니다.
- `write-review-final`(정책 위반 자동 수정, planned) — 자동 수정은 read-only 리뷰와 권한을 분리해 별도 명령으로 둡니다.

## Usage

```
/obsidian-workflows:ow-review file="path/to/document.md" policy=blog
/obsidian-workflows:ow-review file="노트/my-article.md" --humanize
```
