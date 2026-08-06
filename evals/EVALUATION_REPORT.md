# Skill Description Trigger Eval — Report

## 목적

`skills/ow-*` 5개 스킬의 description이 Anthropic 권고(3인칭, what+when, 실사용자 발화 키워드,
제외 조건 명시)에 맞게 다듬어진 뒤, 트리거 정확도(과다/과소 트리거 없음)를 검증한다.

## Eval 세트

스킬별 should-trigger / near-miss 쿼리 세트를 `evals/<skill>-eval.json` 에 둔다. 각 세트는
사용자가 실제로 할 법한 구체적 발화와, 같은 키워드를 공유하지만 다른 스킬/도구로 가야 하는
near-miss 케이스를 섞는다(near-miss가 분별력의 핵심).

- `ow-review-eval.json` — 8건. near-miss: "AI 티만 빼줘"(정책 없는 윤문 → ow-review 제외,
  humanize-korean으로), "맞춤법만 교정"(제외), "새 policy 만들어줘"(ow-policy), "PR 코드 리뷰"(제외).
- `ow-plan-eval.json` — 7건. near-miss: "맞춤법 검사"(ow-review), "새 policy 만들어줘"(ow-policy),
  "학습 포인트 정리"(ow-compound).
- `ow-work-eval.json` — 6건. near-miss: "블로그 아이디어 제안"(ow-plan), "발행 전 정책 점검"(ow-review).
- `ow-policy-eval.json` — 6건. near-miss: "기존 policy 수정"(ow-policy는 신규 생성 전용이라 제외),
  "초안 정책 검증"(ow-review), "맞춤법 검사".
- `ow-compound-eval.json` — 5건. near-miss: "새 글 써줘"(ow-plan active), "초안 리뷰"(ow-review).

## 자동 측정 시도 (run_eval.py)

skill-creator의 `scripts/run_eval.py` 로 ow-review 세트에 대한 baseline 측정을 시도했다
(python3.13 + `claude -p` 서브프로세스, runs-per-query=1, 8 workers).

결과: **모든 쿼리 trigger_rate 0.0**. should_trigger=true 4건이 전부 실패(트리거 0), should_trigger=false
4건은 우연히 "통과". 원인은 `claude -p` 헤드리스 컨텍스트가 obsidian-workflows 플러그인을 로드하지 않아
스킬이 available_skills에 노출되지 않기 때문이다. 따라서 이 환경에서 자동 trigger eval은 의미 있는
신호를 내지 못하며, `run_loop.py` 최적화 루프(스킬당 ~300회 모델 호출)를 돌려도 동일한 all-zero 결과로
귀결된다.

재시도 조건: 플러그인이 활성화된 대화형 세션, 또는 `claude -p` 가 프로젝트 플러그인을 로드하는 환경에서
`run_eval.py --eval-set evals/<skill>-eval.json --skill-path skills/<skill> --runs-per-query 3` 로
baseline을 잴 수 있다. 이 eval 세트는 그때까지 regression spec으로 보존한다.

## 수동 near-miss 분석

자동 측정이 불가한 대신, 각 description의 "제외" 절과 키워드 배치가 near-miss를 어떻게 분리하는지
정성 점검했다. 근거는 각 스킬의 현재 description 본문.

- **ow-review** — "맞춤법만 교정 · policy 신규 생성 · 코드 리뷰 · 새 글 작성 · 정책 없이 문장만 윤문"
  을 명시적으로 제외한다. 따라서 "AI 티만 빼줘"·"맞춤법만 교정해줘"·"PR 코드 리뷰해줘"는 ow-review가
  아닌 humanize-korean/직접 처리/코드 리뷰 도구로 가야 하고, description이 그 방향으로 분리한다.
- **ow-policy** — "기존 policy 수정이나 맞춤법 검사는 제외입니다"로 명시. "기존 blog policy 수정해줘"는
  ow-policy가 아니라 수동 편집/ow-review 경로로 향한다.
- **ow-plan / ow-work / ow-compound** — 각각 "주제 기획/초안 착수 여부", "작성 트랙 즉시 실행",
  "완성본에서 학습 포인트 정리"로 what을 분리했고, ow-work·ow-compound description은 서로와 ow-plan과
  키워드가 겹치지 않아 혼동 가능성이 낮다.

## 결론

- description 5개 전부 구조적 검증 통과(codepoint ≤1024, 트리거 문구 유지, 3인칭, what+when).
  `tools/check-skill-frontmatter.sh`, `validate:behavior-contracts`, `test:plan-passive-default`,
  `lint:markdown` 모두 GREEN.
- 자동 trigger 최적화는 환경 제약(헤드리스 플러그인 미로드)으로 보류. eval 세트는 위 재시도 조건이
  갖춰지면 바로 사용할 수 있도록 보존한다.
- 실사용에서 스킬 호출은 슬래시 커맨드(`/obsidian-workflows:ow-*`)가 주 경로이고, 스킬→스킬 handoff는
  모두 명시적 `Skill` 도구 호출(이름 지정)이라 description 기반 자율 발견이 load-bearing 경로가
  아니라는 점이 자동 최적화의 우선순위를 낮추는 추가 근거다(`docs/skill-specification.md` 의
  Diverged 섹션 및 Execution Layer Separation 참고).
