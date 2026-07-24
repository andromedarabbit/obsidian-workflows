---
name: write-compound-capture
description: 완성본에서 학습 포인트를 캡처해 누적합니다(MVP 스켈레톤).
argument-hint: file=path [append=true]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-01T18:20
---

목표:
- 잘 된 패턴/아쉬운 점/재사용 가능한 문장 전략을 간단히 기록합니다.

기본 동작:
1. 대상 최종본을 읽습니다.
2. 아래 3가지를 3~5줄로 요약합니다.
   - 잘 된 점
   - 개선할 점
   - 다음 정책/SOUL 업데이트 후보
3. `proposal_path` 또는 전용 compound 노트에 append합니다.

메모:
- MVP에서는 저장 포맷만 고정하고 자동 정책 갱신은 수행하지 않습니다.

외부 도구 활용: 완료 후 `writing-config.md`의 `external_tools.auto_use`에 따라 humanizer를 적용합니다. 상세: `docs/contracts/external-tools-integration.md`.

출력에는 적용된 도구 요약(예: `humanizer: 2 AI patterns naturalized`)과 `Compound workflow completed.`를 포함합니다.
