# Mode Inference (ow-work)

`mode` 파라미터가 없을 때 `ow-work`가 작성 트랙을 자동으로 추론하는 규칙과, 신호가 부족해 사용자에게 모드를 물어야 할 때의 `AskUserQuestion` 형식. 분기 요약은 `SKILL.md` 본문에 두고, 이 파일은 추론이 실제로 필요한 순간에만 읽는다(runtime-only detail).

## Without mode parameter

이번 턴의 명시적 요청 > 관련된 PLAN 문맥·handoff > 대기 proposal 순으로 우선한다. 오래된 상태 파일만으로 이번 요청의 대상이나 모드를 바꾸지 않는다.

1. `proposal` 또는 `idea` 인자, 또는 초안·제안·윤문·라우팅을 명확히 요청한 표현이 있으면 해당 모드를 선택한다.
2. 이번 턴에 대상과 행동이 명확하고 즉시 반영을 요청하면 `mode=active`로 선택한다. 예: "최근 7일 음성노트를 처리해", "오늘 노트에 반영해줘". 초안·제안·검토를 요청했거나 PLAN에서 넘긴 작업을 명시적으로 이어받는 경우에는 이 규칙을 적용하지 않는다.
3. 이번 턴이 PLAN에서 넘긴 작업을 이어받거나 대상을 특정하지 않은 호출이면 관련 PLAN 문맥과 pending active handoff를 확인한다. 관련 없는 새 요청이 있으면 handoff를 소비하지 않는다.
   - 관련 pending handoff는 파일에서 `topic`, `policy`, `extra_args`를 로드한다.
   - 하위 명령 실행 전에 즉시 `status: consumed`로 전이한다. 전이에 실패하면 fail-fast로 종료한다.
   - 로드한 인자로 `write-active`를 실행한다.
   - handoff가 없으면 직전 PLAN의 passive proposal 생성은 `draft`, active handoff는 `active`로 연결한다.
4. 대상이 지정되지 않은 호출이고 `proposal_path`에 pending/in-progress proposal이 있으면 `mode=draft`로 선택한다. 별도 주제의 명시적 요청에는 적용하지 않는다.
5. 위 규칙으로도 불명확하면 사용자에게 질문한다 (형식은 아래 "Mode 질문 형식").

## Mode 질문 형식

위 자동 추론의 5번이 발동할 때(신호가 정말로 부족한 경우):

- 이 지점은 규칙 1~4가 명시적 요청과 관련된 상태를 확인한 뒤에만 도달하는 예외 경로다. 과거 장문 설명으로 질문을 대신해 새던 결함이 있었으므로, ow-plan의 handoff 메뉴와 동일한 강도(반드시 `AskUserQuestion`을 fire)로 명시한다.
- **STOP.** 반드시 `AskUserQuestion` 도구를 fire하여 선택지를 제시한다. 장문 설명으로 질문을 대신하는 것은 명세 위반이다.
- `AskUserQuestion` 스키마가 미리 로드되지 않았으면 `ToolSearch`에 `select:AskUserQuestion`을 먼저 호출해 로드한다.
- Question stem: 이번 턴 요청·인자에서 topic을 특정할 수 있으면 `"{topic}을(를) 어떤 모드로 진행할까요?"`를, 특정할 수 없으면 `"이 작업을 어떤 모드로 진행할까요?"`를 쓴다. (규칙 3 handoff 경로는 이 질문 지점에 도달하지 않으므로 topic 출처를 handoff로 한정하지 않는다.)
- 옵션(라벨은 그대로): `active`(지금 바로 반영) / `draft`(초안 먼저) / `passive`(제안만) / `refine`(문체 다듬기). `route`는 메뉴에 넣지 않는다 — `AskUserQuestion`의 "Other"로 흡수.
- 사용자 선택을 받으면 즉시 해당 mode 경로를 실행한다.
