---
name: ow-compound
description: 'COMPOUND 트랙 진입점. 완성된 글에서 학습 포인트·반복 패턴·재사용 가능한 문장 전략을 캡처해 SOUL/policy 개선 후보로 누적합니다.'
when_to_use: '"학습 포인트 뽑아줘", "이 글에서 배운 거 정리해줘", "SOUL에 반영하자"처럼 완성본에서 배운 점을 정리할 때 사용합니다.'
version: 0.3.0
context: inline
language: korean
created: 2026-03-02T14:58
updated: 2026-08-06T00:00
---

# COMPOUND Track Entry Point

`obsidian-workflows:ow-compound` executes `write-compound-capture` in MVP to leave learning logs for iterative improvement.

## Future Extensions (Currently Unimplemented)

- `write-compound-sync` (planned)

## Execution Order

1. Select target document (if not specified, use latest file from final_path).
2. Execute `write-compound-capture`.
3. Briefly summarize policy/SOUL improvement candidates.

## Helper Script Path Resolution

Helper script는 `docs/contracts/helper-script-path.md`의 경로 규칙을 따른다(plugin/repo root 기준 절대 경로, vault cwd 상대 `src/...` 실행 금지, 해석 실패 시 추측 금지).

## Rules

- Keep capture lightweight and record-focused (close to noop skeleton).
- Avoid over-analysis in default mode; prioritize short, reusable capture notes.

## Usage

```
/obsidian-workflows:ow-compound file="path/to/completed.md"
/obsidian-workflows:ow-compound latest
/obsidian-workflows:ow-compound
```
