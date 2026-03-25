---
name: obsidian:write.draft
description: 선택된 아이디어 기반으로 초안을 생성합니다.
argument-hint: proposal=path idea=ID [policy=<policy-name>] [soul=true|false]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-03T19:00
---

동작:
1. 제안 노트(`proposal`)에서 `idea`를 찾습니다.
2. Policy 결정 및 로드:
   - Policy frontmatter에서 `creation_engine` 필드 확인
3. 출력 경로 결정:
   - **Policy에 `creation_engine: obsidian-cli`가 있으면**:
     a. `writing-config.md`에서 `daily_notes_path` 읽기 (없으면 fail-fast)
     b. 오늘 날짜로 파일명 생성: `YYYY-MM-DD.md` (예: `2026-03-25.md`)
     c. 타겟 경로: `{daily_notes_path}/{YYYY-MM-DD}.md`
     d. 파일이 이미 존재하면: `target_heading` 섹션에 내용 추가 (section-edit)
     e. 파일이 없으면: 새 파일 생성
     f. Frontmatter에 `kind: section-edit-draft`, `target_file`, `target_heading` 포함
   - **그 외**: `draft_path`에 저장 (기존 동작)
4. `research_path/[topic]/`에서 관련 자료를 검색합니다 (있으면 참고).
5. 아이디어의 핵심 논지 + 근거 wikilink + 자료를 바탕으로 초안을 생성합니다.
6. 결정된 경로에 초안을 저장합니다.
7. soul=true면 SOUL 보이스를 적용합니다.
8. Proposal 상태를 `in-progress`로 업데이트하고 `draft_path`에 실제 저장 경로를 기록합니다.

규칙:
- 명시된 idea 하나만 생성합니다(다중 생성 금지).
- 아이디어를 찾지 못하면 즉시 종료합니다.
- policy 결정 순서: 명시 인자 > 제안 카드 추천 policy > `default_policy` > `enabled_policies` 첫 항목.
- 최종 policy는 `enabled_policies`에 포함되어야 하며, `policy_dir/writing-policy.<policy>.md`가 존재해야 합니다.
- policy 템플릿이 `creation_engine: obsidian-cli` / `template_engine: templater`를 요구하면 관련 설정이 누락된 경우 즉시 종료합니다.
- `creation_engine: obsidian-cli`인 경우 `daily_notes_path`가 설정되지 않았으면 즉시 종료합니다 (fail-fast).
- 파일명은 `writing-config.md`의 규칙을 우선 적용합니다.
- `proposal` 경로는 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 강제합니다.

외부 도구 활용 (External Tools Integration):
초안 생성 완료 후, `writing-config.md`의 `auto_use_external_tools` 설정에 따라 외부 도구를 활용합니다.

1. **도구 감지**:
   - humanizer: AI 생성 텍스트를 자연스러운 인간 글쓰기로 변환

2. **활용 모드**:
   - `auto_use_external_tools: ask` (기본값): 도구 발견 시 사용 여부를 사용자에게 질문
   - `auto_use_external_tools: true`: 자동으로 활용 (질문 없이)
   - `auto_use_external_tools: false`: 사용하지 않음

3. **실행** (auto_use_external_tools=true 또는 사용자 승인 시):
   ```
   humanizer 적용 (있는 경우):
   - 생성된 초안에 humanizer 실행
   - AI 생성 패턴을 자연스러운 인간 글쓰기로 변환
   ```

4. **출력 형식**:
   ```
   ✓ Draft created: [경로]

   External tools applied:
   - humanizer: 5 AI patterns naturalized

   Next: /obsidian-workflows:oe:refine file="..." policy=...
   ```

5. **Fail-safe 원칙**:
   - 외부 도구 실행 실패 시 경고만 표시하고 워크플로우 계속 진행
