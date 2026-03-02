---
name: obsidian:write.init
description: 글쓰기 워크플로우 초기화. 설정/정책/SOUL 템플릿 존재 여부를 점검하고 생성합니다.
argument-hint: "[--force]"
allowed-tools: Read, Write, Edit, Glob, Grep
created: 2026-03-01T17:28
updated: 2026-03-02T17:38
---

초기화 대상:
- `writing-config.md`
- `Workflows/policy/writing-policy.blog.md`
- `Workflows/policy/writing-policy.x-thread.md`
- `Workflows/policy/writing-policy.weekly-review.md`
- `Workflows/policy/writing-policy.newsletter.md`
- `Workflows/SOUL.md`
- `.claude/state/obsidian-write-passive.json`

동작 규칙:
- 기본은 누락 파일만 생성합니다.
- `--force`가 있으면 대상 템플릿을 재생성(덮어쓰기)할 수 있습니다.
- 완료 후 생성/유지/실패 목록을 표로 출력합니다.
- 실패 시 즉시 종료하며 조용한 fallback을 사용하지 않습니다.
