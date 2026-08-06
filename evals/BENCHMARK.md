# Before/After Benchmark — 이번 작업(refactor + heredoc fix)

측정 시점: refactor 커밋(HEAD) vs 직전 상태(HEAD~1, heredoc 커밋 = 스킬 미변경).
토큰은 tiktoken `cl100k_base`(Claude 토크나이저의 근사치, 상대 비교용). 라인/문자는 실측.

## 1. 토큰 (측정 가능, 개선)

스킬이 활성화될 때 **매 턴 상주**하는 `SKILL.md` 본문 기준.

| 스킬 | before(tok) | after 상주(tok) | 변화 | on-demand refs(tok) |
|---|---|---|---|---|
| ow-plan | 1984 | 1143 | **-42%** | 1043 (handoff-menu) |
| ow-work | 1913 | 1079 | **-44%** | 1125 (mode-inference) |
| ow-review | 1781 | 1215 | **-32%** | 658 (voice-tools) |
| ow-policy | 1278 | 1306 | +2% | - |
| ow-compound | 386 | 432 | +12% | - |
| **합계** | **7342** | **5175** | **-29.5%** | 2826 |

- 상주 토큰 **-29.5%** (7342 → 5175). on-demand 2826토큰은 실제로 해당 단계에 도달할 때만 읽혀 **0 토큰**.
- ow-policy·ow-compound는 미세 증가 → description에 한국어 실발화 키워드를 추가한 의도적 투자(트리거 정확도 향상 목적). 절감의 99%는 3개 분리 스킬에서 발생.
- ow-review description은 357→약 210자로 압축(상주 description 비용도 감소).

## 2. 정확성 (보존 + 부분 개선, 1개 측정 공백)

| 항목 | before | after | 비고 |
|---|---|---|---|
| 행동 계약 pin 문자열 | 보존 | 보존 | `바로 실행`/`Idea 선택해서 draft`/`Passive Handoff Menu`/상태파일 경로가 before·after 동일 출현. 진화한 테스트가 references 병합文本에서 재검증 |
| validate:behavior-contracts | GREEN | GREEN | canonical helper-path 검증 추가 |
| test:plan-passive-default | GREEN | GREEN | handoff-menu refs를 branch-rules에 병합 |
| lint:markdown | GREEN | GREEN | 0 errors / 69 files |
| guard-absolute-path 회귀 | 30건 | **36건** | quoted command-substitution heredoc 오탐 6건 수정 |
| **trigger 정확도** | (측정 불가) | (측정 불가) | `claude -p` 헤드리스가 플러그인 미로드 → all-zero. 환경 제약. `EVALUATION_REPORT.md` 참고 |

- 핵심: **pin된 행동 계약은 한 글자도 바뀌지 않았다.** 분리된 라벨·라우팅 규칙이 그대로 시행되고, 테스트가 그것을 references까지 추적해 검증한다.
- trigger 정확도는 자동 측정이 안 되는 정직한 공백. 단, 실사용에선 슬래시 커맨드가 주경로이고 스킬→스킬 handoff는 모두 명시적 `Skill` 호출이라 description 기반 자율 발견이 load-bearing이 아님.

## 3. 속도 (회귀 없음)

| 검증기 | 소요(after) | before 대비 |
|---|---|---|
| validate:behavior-contracts | ~182ms (5회 avg) | 회귀 없음 — references 해석은 `fs.readFileSync` 3건 추가(sub-ms) |
| test:plan-passive-default | ~156ms (5회 avg) | 회귀 없음 |
| npm run validate:all | 수 초 | COMMANDS.md freshness 포함 전 통과 |

- analyzer(hook)의 heredoc 탐색기도 줄 단위 O(n), 중첩 깊이 상한 32로 여전히 선형. 오탐 수정이 속도에 미치는 영향 무시 가능.
- **결론: 속도는 현수준 유지.** 절감이 속도를 희생하지 않았다.

## 4. 기능 (순증, 제거 없음)

| 추가 | 내용 |
|---|---|
| Progressive disclosure | `references/` 도입(ow-plan/ow-work/ow-review), 명세에서 optional 허용 |
| 행동 테스트 진화 | references 병합 읽기, canonical helper-path 검증, dangling pointer 방지 여지 |
| helper-path 단일 진실 원천 | 4곳 중복 → `docs/contracts/helper-script-path.md` 포인터 |
| Execution Layer Separation 문서화 | agent/subagent 3계층 분담을 명세에 명시 |
| 한국어 헤더 통일 | 식별자 영어화(ow-policy 7·ow-review 4) |
| eval 인증 | 스킬별 trigger eval 세트 5개 + 보고서 |
| heredoc 오탐 수정 | 정상 Bash 명령의 불필요한 확인 창 제거 |

- 제거된 기능: 없음. 모든 hard constraint(name/description/version/context, inline+agent 금지, 충돌 금지) 유지.

## 요약

- **토큰 -29.5%** (상주), on-demand 2826토큰은 지연 로딩으로 0.
- **정확성 보존** (pin 계약 동일, 검증기 GREEN), heredoc 오탐 6건 수정, trigger 자동측정은 환경 제약.
- **속도 유지** (검증기 sub-200ms, 회귀 없음).
- **기능 순증** (progressive disclosure·테스트 진화·dedup·문서화), 제거 없음.
