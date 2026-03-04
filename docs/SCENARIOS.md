# Usage Scenarios

obsidian-workflows를 다양한 상황에서 효과적으로 사용하는 방법을 안내합니다.

## 시나리오 1: 빠른 프로토타이핑

**상황:** 아이디어를 빠르게 초안으로 만들어야 함 (5분 이내)

**목표:**
- 속도 최우선
- 검증 최소화
- 빠른 피드백

**워크플로우:**

```bash
# 1. Fast mode로 아이디어 제안
/obsidian-workflows:ow:plan --fast --intent passive

# 2. 첫 번째 아이디어로 빠른 초안
/obsidian-workflows:ow:work --fast mode=draft idea=1

# 3. 간단한 검토
/obsidian-workflows:ow:review --fast file="Workflows/Drafts/my-draft.md"
```

**최적화 팁:**
- `--skip preflight,external-tools` 추가로 더 빠르게
- `workflow_mode: fast`로 설정하면 플래그 생략 가능
- 캐시 활성화로 반복 작업 시 80% 빠름

**예상 시간:** 4분 (일반 모드: 7분)

---

## 시나리오 2: 팀 협업

**상황:** 팀 표준을 준수하는 문서 작성

**목표:**
- 정책 준수 필수
- 일관된 출력 형식
- 상세한 검증

**워크플로우:**

```bash
# 1. Full mode로 리서치 포함 계획
/obsidian-workflows:ow:plan --intent active topic="..." policy=technical-blog

# 2. 정책 준수 초안 작성
/obsidian-workflows:ow:work mode=active topic="..." policy=technical-blog

# 3. 상세 검토
/obsidian-workflows:ow:review file="..." --verbose

# 4. 수정 후 재검토
/obsidian-workflows:ow:work mode=refine file="..."
/obsidian-workflows:ow:review file="..."

# 5. 학습 캡처
/obsidian-workflows:ow:compound file="Workflows/Final/..."
```

**최적화 팁:**
- `workflow_mode: auto`로 설정하면 자동으로 적절한 모드 선택
- 외부 도구 활성화 (humanizer, grammar-checker, style-guide)
- `output_verbosity: verbose`로 상세 출력

**예상 시간:** 15분 (리서치 포함)

---

## 시나리오 3: 장기 프로젝트

**상황:** 여러 문서를 일관되게 작성하고 패턴 학습

**목표:**
- 일관성 유지
- SOUL 학습 활성화
- 장기적 개선

**워크플로우:**

```bash
# 1. 첫 문서 (Full mode)
/obsidian-workflows:ow:plan --intent active topic="Part 1: ..."
/obsidian-workflows:ow:work mode=active topic="Part 1: ..."
/obsidian-workflows:ow:review file="..."
/obsidian-workflows:ow:compound file="..."

# 2. 두 번째 문서 (Auto mode - 자동으로 Fast 선택)
/obsidian-workflows:ow:plan --intent active topic="Part 2: ..."
# 자동으로 fast mode 선택 (반복 작업 감지)
/obsidian-workflows:ow:work mode=active topic="Part 2: ..."
/obsidian-workflows:ow:review file="..."
/obsidian-workflows:ow:compound file="..."

# 3. 세 번째 문서 (캐시 활용으로 더 빠름)
/obsidian-workflows:ow:plan --intent active topic="Part 3: ..."
# 캐시 히트로 80% 빠름
```

**최적화 팁:**
- `workflow_mode: auto` + `cache_enabled: true`
- 정기적으로 SOUL 개선 제안 검토
- `compound` 단계를 빠뜨리지 말 것

**예상 시간:**
- 첫 문서: 15분
- 두 번째: 8분 (auto mode)
- 세 번째: 4분 (캐시 + auto mode)

---

## 시나리오 4: 일일 노트 작성

**상황:** 매일 반복되는 노트 작성

**목표:**
- 최소 시간 소요
- 일관된 형식
- 자동화

**워크플로우:**

```bash
# 설정 (한 번만)
# writing-config.md
workflow_mode: auto
cache_enabled: true
skip_steps:
  work: [external-tools, context-card]

# 매일 실행
/obsidian-workflows:ow:work mode=active policy=daily-note
# 자동으로 fast mode + 캐시 활용
# 소요 시간: 30초
```

**최적화 팁:**
- `proposal_auto_select: true`로 자동 선택
- `skip_steps`로 불필요한 단계 제거
- SessionStart 훅으로 자동 실행 가능

**예상 시간:** 30초 (첫 실행: 2분)

---

## 시나리오 5: 복잡한 기술 문서

**상황:** 심층 리서치가 필요한 기술 문서

**목표:**
- 정확한 정보
- 상세한 분석
- 외부 도구 활용

**워크플로우:**

```bash
# 1. 리서치 중심 계획
/obsidian-workflows:ow:plan --intent active \
  topic="Distributed system architecture patterns" \
  --verbose

# 2. 외부 도구 활용 초안
/obsidian-workflows:ow:work mode=active \
  topic="..." \
  policy=technical-blog

# 3. 상세 검토 (외부 도구 포함)
/obsidian-workflows:ow:review file="..." --verbose

# 4. 정제 (humanizer + grammar-checker)
/obsidian-workflows:ow:work mode=refine file="..."

# 5. 최종 검토
/obsidian-workflows:ow:review file="..."

# 6. 학습 캡처
/obsidian-workflows:ow:compound file="..."
```

**최적화 팁:**
- `external_tools.auto_use: true`로 자동 활용
- `--verbose` 플래그로 상세 출력
- WebSearchPrime으로 최신 정보 수집

**예상 시간:** 20분 (리서치 포함)

---

## 시나리오 6: 블로그 시리즈

**상황:** 연관된 여러 블로그 포스트 작성

**목표:**
- 일관된 톤앤매너
- 시리즈 연결성
- 효율적 작성

**워크플로우:**

```bash
# 1. 시리즈 계획 (한 번만)
/obsidian-workflows:ow:plan --intent active \
  topic="Series: Kubernetes Deep Dive - Part 1" \
  policy=technical-blog

# 2. 첫 포스트 작성 (Full mode)
/obsidian-workflows:ow:work mode=active topic="..." policy=technical-blog
/obsidian-workflows:ow:review file="..."
/obsidian-workflows:ow:compound file="..."

# 3. 두 번째 포스트 (Fast mode - 자동 선택)
/obsidian-workflows:ow:plan --intent active \
  topic="Series: Kubernetes Deep Dive - Part 2"
# 자동으로 fast mode (반복 작업 + 캐시)
/obsidian-workflows:ow:work mode=active topic="..." policy=technical-blog
/obsidian-workflows:ow:review file="..."
/obsidian-workflows:ow:compound file="..."

# 4. 나머지 포스트들 (더 빠름)
# 캐시 + auto mode로 각 포스트 5분 이내
```

**최적화 팁:**
- 첫 포스트에서 SOUL 패턴 확립
- `workflow_mode: auto`로 자동 최적화
- 시리즈 전체에 동일한 policy 사용

**예상 시간:**
- 첫 포스트: 15분
- 나머지: 각 5분

---

## 시나리오 비교

| 시나리오 | 모드 | 시간 | 검증 수준 | 외부 도구 | 캐싱 |
|---------|------|------|----------|----------|------|
| 빠른 프로토타이핑 | Fast | 4분 | 최소 | 비활성 | ✓ |
| 팀 협업 | Full | 15분 | 최대 | 활성 | ✓ |
| 장기 프로젝트 | Auto | 4-15분 | 중간 | 활성 | ✓ |
| 일일 노트 | Auto | 30초 | 최소 | 비활성 | ✓ |
| 복잡한 기술 문서 | Full | 20분 | 최대 | 활성 | ✓ |
| 블로그 시리즈 | Auto | 5-15분 | 중간 | 활성 | ✓ |

---

## 설정 프리셋

### 프리셋 1: 속도 우선

```yaml
workflow_mode: fast
cache_enabled: true
cache_ttl_hours: 24
skip_steps:
  plan: [external-tools, context-card]
  work: [external-tools, validation, context-card]
  review: [external-tools, context-card]
  compound: [external-tools, context-card]
external_tools:
  detection: disabled
output_verbosity: minimal
show_context_card: false
```

### 프리셋 2: 품질 우선

```yaml
workflow_mode: full
cache_enabled: true
cache_ttl_hours: 24
skip_steps:
  plan: []
  work: []
  review: []
  compound: []
external_tools:
  detection: auto
  auto_use: true
output_verbosity: verbose
show_context_card: true
```

### 프리셋 3: 균형형 (권장)

```yaml
workflow_mode: auto
cache_enabled: true
cache_ttl_hours: 24
skip_steps:
  plan: []
  work: []
  review: []
  compound: []
external_tools:
  detection: auto
  auto_use: ask
output_verbosity: minimal
show_context_card: false
auto_mode_rules:
  - condition: "proposal exists and idea selected"
    mode: fast
  - condition: "first time or complex topic"
    mode: full
  - condition: "review after draft"
    mode: fast
  - condition: "repeated task (same policy 3+ times)"
    mode: fast
```

---

## 문제 해결

### 너무 느림

```bash
# 1. Fast mode 강제
/obsidian-workflows:ow:plan --fast --intent passive

# 2. 단계 건너뛰기
/obsidian-workflows:ow:plan --skip preflight,external-tools --intent passive

# 3. 설정 변경
workflow_mode: fast
skip_steps:
  plan: [external-tools, context-card]
```

### 품질이 낮음

```bash
# 1. Full mode 강제
/obsidian-workflows:ow:plan --verbose --intent active

# 2. 외부 도구 활성화
external_tools:
  auto_use: true

# 3. 상세 출력
output_verbosity: verbose
```

### 반복 작업인데 최적화 안 됨

```bash
# 1. 캐시 확인
cat .claude/state/workflow-cache.json

# 2. Auto mode 규칙 조정
auto_mode_rules:
  - condition: "repeated task (same policy 2+ times)"  # 3+ → 2+
    mode: fast

# 3. 캐시 활성화 확인
cache_enabled: true
```

---

## 관련 문서

- [Quick Start Guide](QUICK_START.md) - 빠른 시작
- [Smart Mode Guide](SMART_MODE.md) - 자동 모드 선택
- [Caching Guide](CACHING.md) - 캐싱 메커니즘
- [Configuration Guide](../config/writing-config.example.md) - 설정 옵션
