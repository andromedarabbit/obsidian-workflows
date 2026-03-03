---
name: obsidian:write.init
description: 글쓰기 워크플로우 초기화. 설정/정책/SOUL 템플릿 존재 여부를 점검하고 생성합니다.
argument-hint: "[--force]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-03T19:00
---

초기화 대상(코어):
- `writing-config.md`
- `Workflows/SOUL.md`
- `.claude/state/obsidian-write-passive.json`

초기화 대상(동적 정책):
- `writing-config.md`의 `enabled_policies`를 읽어 각 정책에 대해 아래 파일을 검증합니다.
  - `policy_dir/writing-policy.<policy>.md`
- 예: `enabled_policies: [daily-note, weekly-note]`면
  - `policy_dir/writing-policy.daily-note.md`
  - `policy_dir/writing-policy.weekly-note.md`

동작 규칙:
- 기본은 누락 파일만 생성합니다.
- `--force`가 있으면 대상 템플릿을 재생성(덮어쓰기)할 수 있습니다.
- 완료 후 생성/유지/실패 목록을 표로 출력합니다.
- 실패 시 즉시 종료하며 조용한 fallback을 사용하지 않습니다.
