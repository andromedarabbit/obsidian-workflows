---
name: obsidian:write.refine
description: 기존 초안을 SOUL 규칙으로 리라이트/정제합니다.
argument-hint: file=path [soul=true|false] [policy=<policy-name>]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-03T19:00
---

실행:
1. 대상 초안 파일을 읽습니다.
2. `soul_path`를 로드합니다.
3. soul=true면 보이스/톤/리듬 규칙으로 리라이트합니다.
4. policy가 지정되면 해당 구조 규칙도 함께 정렬합니다.
5. 결과를 같은 파일에 반영하거나 `-refined` 파일로 저장합니다.

기본 정책:
- soul_enforced=true 환경에서는 soul=false 요청이 있더라도 명시 override 여부를 확인합니다.
- policy가 지정되면 `enabled_policies` 포함 여부와 `policy_dir/writing-policy.<policy>.md` 존재 여부를 함께 검증하고, 하나라도 실패하면 즉시 종료합니다.
- `file` 경로는 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 강제합니다.
- 리라이트 후 변경 요약(핵심 수정 3가지)을 제공합니다.

외부 도구 활용 (External Tools Integration):
리라이트 완료 후, `writing-config.md`의 `auto_use_external_tools` 설정에 따라 외부 도구를 활용합니다.

1. **도구 감지**:
   - humanizer: AI 생성 텍스트를 자연스러운 인간 글쓰기로 변환
   - grammar-checker: 맞춤법, 문법, 띄어쓰기 검사
   - style-guide: 프로젝트 스타일 가이드 준수 검사

2. **활용 모드**:
   - `auto_use_external_tools: ask` (기본값): 도구 발견 시 사용 여부를 사용자에게 질문
   - `auto_use_external_tools: true`: 자동으로 활용 (질문 없이)
   - `auto_use_external_tools: false`: 사용하지 않음

3. **실행 순서** (auto_use_external_tools=true 또는 사용자 승인 시):
   ```
   a. humanizer 적용 (있는 경우):
      - 리라이트된 파일에 humanizer 실행
      - AI 생성 패턴을 자연스러운 인간 글쓰기로 변환

   b. grammar-checker 실행 (있는 경우):
      - 맞춤법, 문법, 띄어쓰기 검사
      - 발견된 오류를 자동 수정 또는 제안

   c. style-guide 검사 (있는 경우):
      - 프로젝트 스타일 가이드 준수 여부 확인
      - 불일치 항목 리포트
   ```

4. **출력 형식**:
   ```
   ✓ Refine completed

   External tools applied:
   - humanizer: 3 AI patterns naturalized
   - grammar-checker: 2 errors fixed
   - style-guide: All checks passed

   Next: /obsidian-workflows:oe:review file="..." policy=...
   ```

5. **Fail-safe 원칙**:
   - 외부 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행
   - 도구 실행 결과는 원본 리라이트 출력에 통합
