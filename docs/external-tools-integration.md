# External Tool Detector

이 유틸리티는 설치된 외부 도구(skills, MCP 서버)를 감지하고 활용 가능 여부를 확인합니다.

## 지원 도구

### 1. humanizer
- **용도**: AI 생성 텍스트를 자연스러운 인간 글쓰기로 변환
- **활용 단계**: draft, refine, compound
- **감지 방법**: skill 목록에서 `humanizer` 존재 확인

### 2. grammar-checker
- **용도**: 맞춤법, 문법, 띄어쓰기, 구두점 검사
- **활용 단계**: refine, review
- **감지 방법**: skill 목록에서 `grammar-checker` 존재 확인

### 3. style-guide
- **용도**: 프로젝트 스타일 가이드 준수 검사
- **활용 단계**: refine, review
- **감지 방법**: skill 목록에서 `style-guide` 존재 확인

## 감지 로직

```bash
# 설치된 skills 목록 조회
claude skill list --json | jq -r '.skills[].name'

# 특정 도구 존재 확인
if claude skill list --json | jq -r '.skills[].name' | grep -q "^humanizer$"; then
    echo "humanizer available"
fi
```

## 설정 기반 동작

`writing-config.md`의 `auto_use_external_tools` 설정에 따라 동작:

- `ask` (기본값): 도구 발견 시 사용 여부를 사용자에게 질문
- `true`: 자동으로 활용 (질문 없이)
- `false`: 사용하지 않음

## 통합 예시

### draft 단계에서 humanizer 활용

```markdown
1. 초안 생성 완료
2. humanizer 도구 감지
3. auto_use_external_tools 설정 확인
   - ask: "초안에 humanizer를 적용하시겠습니까? (AI 생성 텍스트를 자연스럽게 변환)"
   - true: 자동 적용
   - false: 건너뛰기
4. 적용 시: `/humanizer [draft-file-path]` 실행
```

### review 단계에서 grammar-checker 활용

```markdown
1. 정책 기반 리뷰 완료
2. grammar-checker 도구 감지
3. auto_use_external_tools 설정 확인
4. 적용 시: `/grammar-checker [file-path]` 실행
5. 검사 결과를 리뷰 리포트에 통합
```

## 도구 호출 규칙

- 도구 실행은 항상 `/skill-name [args]` 형태로 호출
- 실행 결과는 원본 워크플로우 출력에 통합
- 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행 (fail-safe)
