# Mode Inference (ow-work)

`mode` 파라미터가 없을 때 `ow-work`가 작성 트랙을 자동으로 추론하는 규칙과, 신호가 부족해 사용자에게 모드를 물어야 할 때의 `AskUserQuestion` 형식. 분기 요약은 `SKILL.md` 본문에 두고, 이 파일은 추론이 실제로 필요한 순간에만 읽는다(runtime-only detail).

## Without mode parameter

파일 기반 신호 > PLAN 대화 문맥 신호 > 이번 턴 지시 신호 순으로 우선한다.

1. `proposal` 또는 `idea` 인자가 있으면 `mode=draft`.
2. `.claude/state/obsidian-write-active-handoff.json`이 존재하고 `status: pending`이면 active handoff로 처리한다.
   - 파일에서 `topic`, `policy`, `extra_args`를 로드한다.
   - 하위 명령 실행 전에 즉시 `status: consumed`로 전이한다. 전이에 실패하면 fail-fast로 종료한다.
   - 로드한 인자로 `write-active`를 실행한다.
3. `proposal_path` 디렉터리에서 pending/in-progress proposal이 감지되면 `mode=draft`.
4. 직전 PLAN 대화 문맥이 passive proposal 생성을 가리키면 `mode=draft`.
5. 직전 PLAN 대화 문맥이 active handoff를 가리키면 `mode=active`.
6. 이번 턴 지시 자체가 모호하지 않은 직접 작성 명령이면 `mode=active`로 간주한다:
   - 명령형으로 즉시 반영을 요청한다 (예: "~작성하자", "~해줘", "~를 오늘 노트에 반영해줘").
   - 초안/제안/검토를 시사하는 표현이 전혀 없다 (예: "초안으로", "제안만", "검토 후", "draft로", "먼저 보여줘").

   두 조건 중 하나라도 불확실하면 이 규칙을 적용하지 않고 다음 단계로 넘어간다.
7. 위 규칙으로도 불명확하면 사용자에게 질문한다 (형식은 아래 "Mode 질문 형식").

## Mode 질문 형식

위 자동 추론의 7번이 발동할 때(신호가 정말로 부족한 경우):

- 이 지점은 규칙 6이 직접 지시를 걸러낸 뒤에만 도달하는 예외 경로다. 과거 장문 설명으로 질문을 대신해 새던 결함이 있었으므로, ow-plan의 handoff 메뉴와 동일한 강도(반드시 `AskUserQuestion`을 fire)로 명시한다.
- **STOP.** 반드시 `AskUserQuestion` 도구를 fire하여 선택지를 제시한다. 장문 설명으로 질문을 대신하는 것은 명세 위반이다.
- `AskUserQuestion` 스키마가 미리 로드되지 않았으면 `ToolSearch`에 `select:AskUserQuestion`을 먼저 호출해 로드한다.
- Question stem: 이번 턴 요청·인자에서 topic을 특정할 수 있으면 `"{topic}을(를) 어떤 모드로 진행할까요?"`를, 특정할 수 없으면 `"이 작업을 어떤 모드로 진행할까요?"`를 쓴다. (규칙 2 handoff 경로는 이 질문 지점에 도달하지 않으므로 topic 출처를 handoff로 한정하지 않는다.)
- 옵션(라벨은 그대로): `active`(지금 바로 반영) / `draft`(초안 먼저) / `passive`(제안만) / `refine`(문체 다듬기). `route`는 메뉴에 넣지 않는다 — `AskUserQuestion`의 "Other"로 흡수.
- 사용자 선택을 받으면 즉시 해당 mode 경로를 실행한다.
