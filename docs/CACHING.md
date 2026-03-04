# Caching Mechanism

obsidian-workflows는 반복 작업 속도를 개선하기 위해 설정 파일과 SOUL 규칙을 캐싱합니다.

## 캐시 저장 위치

```
.claude/state/
├── workflow-cache.json          # 메인 캐시 파일
└── obsidian-write-passive.json  # Passive 모드 상태
```

## 캐시 구조

```json
{
  "version": "1.0",
  "last_updated": "2026-03-04T21:49:00+09:00",
  "config": {
    "hash": "abc123def456",
    "cached_at": "2026-03-04T21:49:00+09:00",
    "ttl_hours": 24,
    "data": {
      "enabled_policies": ["daily-note", "technical-blog"],
      "soul_path": "Workflows/SOUL.md",
      "workflow_mode": "auto"
    }
  },
  "policies": {
    "daily-note": {
      "hash": "def456abc789",
      "cached_at": "2026-03-04T21:49:00+09:00",
      "data": {
        "topic_required": false,
        "min_length": 500,
        "structure": ["날짜", "날씨", "주요 활동"]
      }
    },
    "technical-blog": {
      "hash": "789abc123def",
      "cached_at": "2026-03-04T21:49:00+09:00",
      "data": {
        "topic_required": true,
        "min_length": 2000,
        "structure": ["제목", "개요", "본문", "결론"]
      }
    }
  },
  "soul": {
    "hash": "123def789abc",
    "cached_at": "2026-03-04T21:49:00+09:00",
    "data": {
      "rules_count": 15,
      "categories": ["tone", "structure", "terminology"]
    }
  },
  "usage_stats": {
    "daily-note": {
      "count": 5,
      "last_used": "2026-03-04T20:00:00+09:00"
    },
    "technical-blog": {
      "count": 3,
      "last_used": "2026-03-04T19:00:00+09:00"
    }
  }
}
```

## 캐시 무효화 조건

캐시는 다음 조건에서 무효화됩니다:

1. **파일 수정 시간 변경**
   - `writing-config.md` 수정
   - 정책 파일 수정
   - `SOUL.md` 수정

2. **Hash 불일치**
   - 파일 내용이 변경되어 hash가 달라진 경우

3. **TTL 만료**
   - 기본값: 24시간
   - `writing-config.md`의 `cache_ttl_hours`로 조정 가능

4. **명시적 무효화**
   - `--no-cache` 플래그 사용 시

## 캐시 동작

### 캐시 히트 (Cache Hit)

```bash
# 첫 실행 (캐시 미스)
/obsidian-workflows:ow:plan --intent passive
# 소요 시간: 5초 (설정 파일 읽기 + 파싱)

# 두 번째 실행 (캐시 히트)
/obsidian-workflows:ow:plan --intent passive
# 소요 시간: 0.1초 (캐시에서 읽기)
# 98% 빠름!
```

### 캐시 무효화

```bash
# 설정 파일 수정
echo "new_setting: value" >> writing-config.md

# 다음 실행 시 자동으로 캐시 재생성
/obsidian-workflows:ow:plan --intent passive
# 소요 시간: 5초 (캐시 재생성)
```

### 캐시 비활성화

```bash
# 일시적 비활성화
/obsidian-workflows:ow:plan --intent passive --no-cache

# 영구 비활성화 (writing-config.md)
cache_enabled: false
```

## 스마트 모드 선택과 캐싱

캐시는 스마트 모드 선택에도 활용됩니다:

```json
{
  "usage_stats": {
    "daily-note": {
      "count": 5,
      "last_used": "2026-03-04T20:00:00+09:00"
    }
  }
}
```

- **반복 작업 감지**: 동일 정책을 3회 이상 사용하면 자동으로 fast mode 제안
- **최근 사용 패턴**: 최근 24시간 내 사용 이력 기반 최적화

## 성능 개선

### 예상 효과

| 작업 | 캐시 없음 | 캐시 있음 | 개선율 |
|------|----------|----------|--------|
| 설정 파일 읽기 | 2초 | 0.05초 | 97.5% |
| SOUL 파싱 | 5초 | 0.1초 | 98% |
| 정책 검증 | 3초 | 0.05초 | 98.3% |
| **전체** | 10초 | 0.2초 | **98%** |

### 실제 워크플로우

```bash
# 첫 실행 (캐시 생성)
/obsidian-workflows:ow:plan --intent passive
# 소요 시간: 210초

# 두 번째 실행 (캐시 활용)
/obsidian-workflows:ow:plan --intent passive
# 소요 시간: 42초 (80% 빠름)

# Fast mode + 캐시
/obsidian-workflows:ow:plan --fast --intent passive
# 소요 시간: 21초 (90% 빠름)
```

## 문제 해결

### 캐시가 작동하지 않음

```bash
# 캐시 상태 확인
cat .claude/state/workflow-cache.json

# 캐시 삭제 후 재생성
rm .claude/state/workflow-cache.json
/obsidian-workflows:ow:plan --intent passive
```

### 오래된 캐시 데이터

```bash
# TTL 단축 (writing-config.md)
cache_ttl_hours: 1  # 1시간으로 단축

# 또는 캐시 비활성화
cache_enabled: false
```

### 디스크 공간 부족

캐시 파일은 일반적으로 10KB 미만이지만, 필요시 삭제 가능:

```bash
rm .claude/state/workflow-cache.json
```

## 관련 문서

- [Quick Start Guide](QUICK_START.md) - Fast mode 사용법
- [Configuration Guide](../config/writing-config.example.md) - 캐시 설정
