# Handoff Menus (ow-plan)

`ow-plan`의 각 분기가 끝날 때 사용자에게 보여주는 `AskUserQuestion` 4옵션 메뉴의 상세 명세. 분기 요약·라우팅 규칙은 `SKILL.md` 본문에 두고, 이 파일은 메뉴를 실제로 띄워야 하는 순간에만 읽는다(runtime-only detail).

## Active Handoff Menu

Active 분기 종료 직후 `AskUserQuestion` 도구를 즉시 fire한다. 메뉴를 텍스트로 설명하고 멈추면 완료가 아니다.

- stem: `Active plan 완료 (topic="<topic>", policy=<policy>). 다음에 무엇을 할까요?`
- options:
  1. `바로 실행` (recommended)
  2. `계획 다듬기`
  3. `다른 정책으로`
  4. `나중에`

옵션별 동작:

1. **바로 실행**
   - plan에서 받은 active 분기용 추가 인자(`--source`, `--window-days`, `--skip` 등)를 `extra_args`로 묶는다.
   - `.claude/state/obsidian-write-active-handoff.json`을 `status: consumed`로 사전 기록한다.
   - 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow-work`를 즉시 fire한다. Claude Code에서는 `Skill` 도구를 사용한다.
2. **계획 다듬기**
   - 사용자에게 다듬을 부분을 묻고 active 분기를 다시 실행한다. 이후 이 메뉴를 다시 표시한다.
3. **다른 정책으로**
   - enabled policy 후보를 제시하고 선택을 받아 active 분기를 다시 실행한다. 이후 이 메뉴를 다시 표시한다.
4. **나중에**
   - `.claude/state/obsidian-write-active-handoff.json`을 `status: pending`으로 저장하고 종료한다. 이후 mode 없는 `obsidian-workflows:ow-work`가 이를 감지한다.

Completion check:

1. `AskUserQuestion` 도구로 위 4옵션 메뉴를 fire한다.
2. 사용자 선택을 수신한다.
3. 선택에 따른 인라인 routing을 즉시 실행한다.

## Passive Handoff Menu

Passive 분기 종료 직후 proposal 요약을 출력하고 `AskUserQuestion` 도구를 즉시 fire한다. proposal만 만들고 텍스트 명령어를 안내하면 완료가 아니다.

- stem: `Passive proposal 생성 완료 (<N>개 아이디어). 다음에 무엇을 할까요?`
- options:
  1. `Idea 선택해서 draft` (recommended)
  2. `proposal 다듬기`
  3. `다른 정책으로`
  4. `나중에`

옵션별 동작:

1. **Idea 선택해서 draft**
   - 사용자에게 idea 번호를 묻고 proposal frontmatter의 `status`를 `in-progress`, `selected_idea`를 선택 번호로 갱신한다.
   - 플랫폼의 skill-invocation primitive로 `obsidian-workflows:ow-work`를 즉시 fire한다. Claude Code에서는 `Skill` 도구를 사용한다.
2. **proposal 다듬기**
   - 아이디어 추가/교체 요청을 받아 propose를 다시 실행한다. 이후 이 메뉴를 다시 표시한다.
3. **다른 정책으로**
   - policy 후보를 제시하고 선택을 받아 propose를 다시 실행한다. 이후 이 메뉴를 다시 표시한다.
4. **나중에**
   - proposal frontmatter를 `status: pending`으로 유지하고 종료한다.

Completion check: Active Handoff Menu의 Completion check와 동일한 절차(`AskUserQuestion` fire → 선택 수신 → 인라인 routing)를 따른다.
