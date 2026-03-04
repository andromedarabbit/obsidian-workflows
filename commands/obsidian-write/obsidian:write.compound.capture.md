---
name: obsidian:write.compound.capture
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

외부 도구 활용 (External Tools Integration):
학습 포인트 캡처 완료 후, `writing-config.md`의 `auto_use_external_tools` 설정에 따라 외부 도구를 활용합니다.

1. **도구 감지**:
   - humanizer: AI 생성 텍스트를 자연스러운 인간 글쓰기로 변환

2. **활용 모드**:
   - `auto_use_external_tools: ask` (기본값): 도구 발견 시 사용 여부를 사용자에게 질문
   - `auto_use_external_tools: true`: 자동으로 활용 (질문 없이)
   - `auto_use_external_tools: false`: 사용하지 않음

3. **실행** (auto_use_external_tools=true 또는 사용자 승인 시):
   ```
   humanizer 적용 (있는 경우):
   - 캡처된 학습 포인트에 humanizer 실행
   - AI 생성 패턴을 자연스러운 인간 글쓰기로 변환
   ```

4. **출력 형식**:
   ```
   ✓ Learning points captured

   External tools applied:
   - humanizer: 2 AI patterns naturalized

   Compound workflow completed.
   ```

5. **Fail-safe 원칙**:
   - 외부 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행
