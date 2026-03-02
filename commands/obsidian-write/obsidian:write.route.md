---
name: obsidian:write.route
description: 초안/최종본 경로 라우팅 및 이동/복사를 수행합니다.
argument-hint: file=path to=draft|final [mode=move|copy]
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:29
updated: 2026-03-02T17:04
---

동작:
1. `writing-config.md`에서 `draft_path`, `final_path`, `archive_path`, `archive_versioning`을 읽습니다.
2. `to` 대상 경로를 확정합니다.
3. 경로 안전 규칙(절대 경로 금지, `..` 금지, resolve 후 vault root 하위만 허용, 심볼릭 링크로 root 밖 탈출 금지)을 검증합니다.
4. `to=final`이고 `archive_versioning=true`인 경우:
   a. `final_path`에 동일 이름 파일이 있는지 확인
   b. 있으면 `archive_path/[topic]/` 디렉토리 생성
   c. 기존 파일을 `v{N}-{date}.md` 형식으로 백업 (버전 번호 자동 증가)
5. `mode=move|copy`로 파일을 라우팅합니다.

규칙:
- 대상 파일이 없으면 즉시 종료합니다.
- 경로 안전 규칙 위반 시 즉시 종료합니다.
- 기본 mode는 `move`입니다.
