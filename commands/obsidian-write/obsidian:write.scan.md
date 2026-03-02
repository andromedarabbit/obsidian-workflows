---
name: obsidian:write.scan
description: Passive 스캔. 기준 시점 이후 변경 파일을 source_paths에서 수집합니다.
argument-hint: "[--since ISO_DATE] [--window-days N] [--source path1,path2]"
allowed-tools: Read, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T17:34
---

입력/설정:
- `writing-config.md` frontmatter를 읽습니다.
- 기본 기준 시점(anchor)은 `final_path` 내 최신 파일 시각입니다.
- final_path가 비어 있으면 `today - passive_window_days`를 anchor로 사용합니다.
- `--since`가 있으면 anchor를 강제 override합니다.

스캔 규칙:
1. `source_paths`(다중 경로)에서 Markdown 파일을 찾습니다.
2. `exclude_paths`와 숨김/시스템 경로(`.obsidian`, `.git`, `.trash`)를 제외합니다.
3. `research_path`는 자동으로 제외됩니다 (자료는 주제 제안 대상 아님).
3. 경로 안전 규칙을 적용합니다.
   - 절대 경로 입력 금지
   - `..` 세그먼트 포함 경로 금지
   - 정규화(resolve) 후 vault root 하위 경로만 허용
   - 심볼릭 링크를 통해 vault root 밖으로 벗어나는 경로 금지
4. mtime > anchor 인 파일만 후보로 수집합니다.
5. 결과를 구조화해 반환합니다:
   - `anchor`
   - `scanned_paths`
   - `candidate_count`
   - `candidates[]` (path, modified_at)

실패 정책:
- 설정 파일 또는 source_paths가 유효하지 않으면 즉시 종료합니다.
- 경로 안전 규칙 위반 시 즉시 종료합니다.
- 빈 결과는 실패가 아니라 정상 결과(후속 propose에서 "제안 없음")로 처리합니다.
