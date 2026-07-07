---
name: compound
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다. 완성된 문서에서 학습 포인트를 축적해야 할 때 사용합니다.
version: 0.1.0
context: inline
mirrors: commands/ow/compound.md
mirror_hash: 3103bdcbf6d74b01
language: korean
user-invocable: true
created: 2026-03-02T14:58
updated: 2026-07-07T00:00
---

# COMPOUND Track Entry Point

> 미러 파일: 동작 정본은 `commands/ow/compound.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

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
