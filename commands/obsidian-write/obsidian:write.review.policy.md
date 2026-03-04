---
name: obsidian:write.review.policy
description: 정책 기반 품질 게이트. 채널별 구조/길이/섹션을 점검합니다.
argument-hint: file=path [policy=<policy-name>]
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-03T19:00
---

검증 항목(MVP):
- 필수 섹션 존재 여부
- 정책별 길이 제한 준수 여부
- 제목/서론/CTA 등 핵심 블록 충족 여부
- wikilink/참조 근거 포함 여부

출력 형식:
- `PASS` 또는 `FAIL`
- 체크리스트
- 수정 포인트(FAIL일 때만)

규칙:
- 실행 인자 이름은 `policy`를 사용합니다.
- 대상 파일 frontmatter 키는 `policy_type`를 사용합니다.
- policy 미지정 시 파일 frontmatter의 `policy_type`를 우선 사용합니다.
- 최종 policy는 `enabled_policies`에 포함되어야 하며 `policy_dir/writing-policy.<policy>.md`가 존재해야 합니다.
- `file` 경로는 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 강제합니다.
- `policy`와 `policy_type`이 모두 비어 있으면 즉시 종료합니다.
- 이 명령은 검증 리포트만 반환하며 파일을 수정하지 않습니다.
- 향후 auto-fix 기능이 추가되면 별도 명령(예: `obsidian:write.review.final`)로 권한을 분리합니다.

외부 도구 활용 (External Tools Integration):
정책 기반 리뷰 완료 후, `writing-config.md`의 `auto_use_external_tools` 설정에 따라 외부 도구를 활용합니다.

1. **도구 감지**:
   - grammar-checker: 맞춤법, 문법, 띄어쓰기 검사
   - style-guide: 프로젝트 스타일 가이드 준수 검사

2. **활용 모드**:
   - `auto_use_external_tools: ask` (기본값): 도구 발견 시 사용 여부를 사용자에게 질문
   - `auto_use_external_tools: true`: 자동으로 활용 (질문 없이)
   - `auto_use_external_tools: false`: 사용하지 않음

3. **실행 순서** (auto_use_external_tools=true 또는 사용자 승인 시):
   ```
   a. grammar-checker 실행 (있는 경우):
      - 맞춤법, 문법, 띄어쓰기 검사
      - 발견된 오류를 리포트에 추가

   b. style-guide 검사 (있는 경우):
      - 프로젝트 스타일 가이드 준수 여부 확인
      - 불일치 항목을 리포트에 추가
   ```

4. **출력 형식**:
   ```
   ✓ Policy review: PASS

   External tools results:
   - grammar-checker: 2 issues found
     • Line 15: "되" should be "돼"
     • Line 23: Missing space after comma
   - style-guide: 1 inconsistency found
     • Use "사용자" instead of "유저" (line 42)

   Next: /obsidian-workflows:oe:compound file="..."
   ```

5. **Fail-safe 원칙**:
   - 외부 도구 실행 실패 시 경고만 표시하고 리뷰 계속 진행
   - 도구 실행 결과는 원본 정책 리뷰 리포트에 통합
