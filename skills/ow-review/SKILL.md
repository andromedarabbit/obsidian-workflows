---
name: ow-review
description: '발행 직전 초안을 채널 정책 게이트(구조·길이·필수 섹션)와 문체 리뷰(AI 티·번역투 진단, 필요 시 사람처럼 다듬기)로 한 번에 검증합니다. "발행 전 최종 점검", "정책 통과하는지 봐줘", "AI 티 빼줘", "초안 리뷰해줘"처럼 정책과 문체를 함께 점검할 때 사용합니다. 맞춤법만 교정, policy 신규 생성, 코드 리뷰, 새 글 작성, 정책 없이 문장만 윤문하는 건 제외입니다.'
version: 0.3.0
context: inline
language: korean
created: 2026-03-02T14:58
updated: 2026-08-06T00:00
---

# REVIEW Track Entry Point

`obsidian-workflows:ow-review`는 두 단계로 검증합니다: (1) `write-review-policy` 정책 게이트로 구조·길이·필수 섹션을 점검(의미 층), (2) 문체·윤문 단계에서 AI 티·번역투를 진단하고 필요 시 윤문(형태 층). 정책 게이트가 섹션을 바꾸면 앞선 윤문이 무효화되므로 구조를 먼저 확정합니다.

## Security & Permissions

- 자체 검사(정책 게이트·탐지·리포팅)는 파일을 수정하지 않고 read-only 도구만 씁니다.
- 윤문 재작성은 직접 하지 않고 `Skill` 도구로 humanize 스킬에 위임합니다. humanize는 결과를 자체 워크스페이스(`_workspace/{date}/final.md`)에 씁니다.
- 재작성은 사용자가 명시 요청했을 때만 자동 진행하고, 아니면 실행 전 `AskUserQuestion`으로 확인합니다(read-only 기본 보존).

## Helper Script Path Resolution

Helper script는 `docs/contracts/helper-script-path.md`의 경로 규칙을 따른다(plugin/repo root 기준 절대 경로, vault cwd 상대 `src/...` 실행 금지, 해석 실패 시 추측 금지).

## Voice & External Tools

정책 게이트 통과 후(Fast/skip이 아니면) 문체·윤문 단계를 수행한다. im-not-ai humanize를 최우선으로 탐지하고, grammar-checker·style-guide는 `writing-config.md`의 `external_tools.auto_use`를 따른다. 도구 탐지 우선순위와 humanize 실행 게이트(명시 요청 vs 확인 후 진행)의 상세는 `references/voice-tools.md`를 읽어 적용한다.

## Execution Order

1. 대상 파일과 policy를 확정합니다.
2. `file` 경로에 path safety(`docs/contracts/path-safety.md`)를 적용합니다.
3. `write-review-policy` 규칙으로 구조/길이/필수 섹션을 검증합니다(의미 층).
4. (fast/skip이 아니면) Voice/윤문 & External Tools 단계를 수행합니다(형태 층): 문체 진단, 필요 시 확인 후 humanize 위임.
5. PASS/FAIL 체크리스트, 수정 포인트, 윤문 요약(수행 시)을 반환합니다.

## Status/Output Rules

- 상태 의미는 `PASS|SKIP|FAIL`로만 사용합니다: `PASS`(정책 게이트 통과), `SKIP`(대상/도구 없음), `FAIL`(위반/입력·경로 오류).
- 종료 시 다음 단계 안내(예: `obsidian-workflows:ow-compound`).

## Future Extensions

- 문체(voice) 리뷰는 별도 `write-review-voice` 대신 이 단계의 im-not-ai humanize 위임으로 제공합니다.
- `write-review-final`(정책 위반 자동 수정, planned) — 자동 수정은 read-only 리뷰와 권한을 분리해 별도 명령으로 둡니다.

## Usage

```
/obsidian-workflows:ow-review file="path/to/document.md" policy=blog
/obsidian-workflows:ow-review file="노트/my-article.md" --humanize
```
