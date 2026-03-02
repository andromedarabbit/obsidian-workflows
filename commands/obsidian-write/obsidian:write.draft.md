---
name: obsidian:write.draft
description: 선택된 아이디어 기반으로 초안을 생성합니다.
argument-hint: proposal=path idea=ID [policy=<policy-name>] [soul=true|false]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-02T17:34
---

동작:
1. 제안 노트(`proposal`)에서 `idea`를 찾습니다.
2. `research_path/[topic]/`에서 관련 자료를 검색합니다 (있으면 참고).
3. 아이디어의 핵심 논지 + 근거 wikilink + 자료를 바탕으로 초안을 생성합니다.
4. 선택된 policy 포맷으로 `draft_path`에 저장합니다.
5. soul=true면 SOUL 보이스를 적용합니다.

규칙:
- 명시된 idea 하나만 생성합니다(다중 생성 금지).
- 아이디어를 찾지 못하면 즉시 종료합니다.
- policy가 지정되면 `policy_dir/writing-policy.<policy>.md` 존재 여부를 검증하고, 없으면 즉시 종료합니다.
- policy를 생략하면 제안 카드의 추천 policy를 사용합니다.
- 파일명은 `writing-config.md`의 규칙을 우선 적용합니다.
- `proposal` 경로는 절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지 규칙을 강제합니다.
