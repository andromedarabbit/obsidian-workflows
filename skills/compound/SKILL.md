---
name: workflow-compound-reference
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다.
user-invocable: true
version: 0.1.0
created: 2026-03-02T14:58
updated: 2026-05-22T00:00
---

# COMPOUND Track Entry Point

`obsidian-workflows:ow:compound` executes `obsidian:write.compound.capture` in MVP to leave learning logs for iterative improvement.

## Future Extensions (Currently Unimplemented)

- `obsidian:write.compound.sync` (planned)

## Execution Order

1. Select target document (if not specified, use latest file from final_path).
2. Execute `obsidian:write.compound.capture`.
3. Briefly summarize policy/SOUL improvement candidates.

## Rules

- Keep capture lightweight and record-focused (close to noop skeleton).
- Avoid over-analysis in default mode; prioritize short, reusable capture notes.

## Usage

```
/obsidian-workflows:ow:compound file="path/to/completed.md"
/obsidian-workflows:ow:compound latest
/obsidian-workflows:ow:compound
```
