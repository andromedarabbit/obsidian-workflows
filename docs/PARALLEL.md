# Parallel Processing

obsidian-workflows는 독립적인 작업을 병렬로 실행하여 전체 시간을 단축합니다.

## 병렬 처리 가능한 작업

### ow:plan (passive 모드)

**순차 실행 (현재):**
```
1. 파일 스캔 (5초)
2. 아이디어 생성 (10초)
3. Proposal 작성 (5초)
---
총 시간: 20초
```

**병렬 실행 (최적화):**
```
1. 파일 스캔 + 아이디어 생성 동시 (10초)
2. Proposal 작성 (5초)
---
총 시간: 15초 (25% 단축)
```

### ow:review

**순차 실행 (현재):**
```
1. 구조 검증 (3초)
2. 길이 검증 (2초)
3. 필수 섹션 검증 (3초)
---
총 시간: 8초
```

**병렬 실행 (최적화):**
```
1. 구조 + 길이 + 필수 섹션 동시 (3초)
---
총 시간: 3초 (62% 단축)
```

## 구현 방법

### 1. 독립적 작업 식별

병렬 처리가 가능한 작업의 특징:
- 서로 의존성이 없음
- 입력 데이터가 독립적
- 출력이 다른 작업에 영향을 주지 않음

**예시: ow:review**
```python
# 독립적 검증 작업들
tasks = [
    validate_structure(file),      # 구조 검증
    validate_length(file),          # 길이 검증
    validate_sections(file),        # 필수 섹션 검증
    validate_frontmatter(file)      # Frontmatter 검증
]

# 병렬 실행
results = await asyncio.gather(*tasks)
```

### 2. 병렬 실행 패턴

**패턴 1: 파일 읽기 + 처리**
```python
# 순차
config = read_config()
soul = read_soul()
policy = read_policy()

# 병렬
config, soul, policy = await asyncio.gather(
    read_config(),
    read_soul(),
    read_policy()
)
```

**패턴 2: 다중 검증**
```python
# 순차
structure_ok = validate_structure()
length_ok = validate_length()
sections_ok = validate_sections()

# 병렬
structure_ok, length_ok, sections_ok = await asyncio.gather(
    validate_structure(),
    validate_length(),
    validate_sections()
)
```

**패턴 3: 외부 도구 호출**
```python
# 순차
humanized = call_humanizer(text)
grammar_checked = call_grammar_checker(text)
style_checked = call_style_guide(text)

# 병렬
humanized, grammar_checked, style_checked = await asyncio.gather(
    call_humanizer(text),
    call_grammar_checker(text),
    call_style_guide(text)
)
```

## 성능 개선

### 예상 효과

| 명령어 | 순차 실행 | 병렬 실행 | 개선율 |
|--------|----------|----------|--------|
| ow:plan (passive) | 20초 | 15초 | 25% |
| ow:review | 97초 | 68초 | 30% |
| ow:compound | 177초 | 124초 | 30% |
| **평균** | - | - | **30%** |

### 실제 워크플로우

```bash
# Fast mode + 병렬 처리
/obsidian-workflows:ow:plan --fast --intent passive
# 소요 시간: 10.5초 (순차: 15초, 병렬: 10.5초)

# Full mode + 병렬 처리
/obsidian-workflows:ow:review file="..." --verbose
# 소요 시간: 68초 (순차: 97초, 병렬: 68초)
```

## 병렬 처리 제한

### 병렬 불가능한 작업

1. **의존성이 있는 작업**
   ```python
   # 잘못된 예: proposal 읽기 전에 idea 선택 불가
   proposal, selected_idea = await asyncio.gather(
       read_proposal(),
       select_idea()  # proposal 필요!
   )

   # 올바른 예: 순차 실행
   proposal = await read_proposal()
   selected_idea = await select_idea(proposal)
   ```

2. **상태를 공유하는 작업**
   ```python
   # 잘못된 예: 동일 파일 동시 수정
   await asyncio.gather(
       write_draft(file),
       add_frontmatter(file)  # 충돌 가능!
   )

   # 올바른 예: 순차 실행
   await write_draft(file)
   await add_frontmatter(file)
   ```

3. **순서가 중요한 작업**
   ```python
   # 잘못된 예: 초기화 전에 검증 불가
   await asyncio.gather(
       initialize(),
       validate()  # 초기화 필요!
   )

   # 올바른 예: 순차 실행
   await initialize()
   await validate()
   ```

## 설정

병렬 처리는 기본적으로 활성화되어 있습니다. 필요시 비활성화할 수 있습니다:

```yaml
# writing-config.md
parallel_processing: true  # true | false
max_parallel_tasks: 4      # 동시 실행 최대 작업 수
```

## 문제 해결

### 병렬 처리로 인한 오류

```bash
# 병렬 처리 비활성화
parallel_processing: false

# 또는 동시 작업 수 제한
max_parallel_tasks: 2
```

### 성능 향상이 없음

병렬 처리는 다음 조건에서 효과적입니다:
- 독립적인 작업이 많을 때
- 각 작업이 충분히 오래 걸릴 때 (>1초)
- I/O 바운드 작업일 때

CPU 바운드 작업이나 매우 빠른 작업(<0.1초)은 병렬 처리 오버헤드로 인해 오히려 느려질 수 있습니다.

## 관련 문서

- [Quick Start Guide](QUICK_START.md) - 빠른 시작
- [Smart Mode Guide](SMART_MODE.md) - 자동 모드 선택
- [Caching Guide](CACHING.md) - 캐싱 메커니즘
- [Scenarios Guide](SCENARIOS.md) - 사용 시나리오
