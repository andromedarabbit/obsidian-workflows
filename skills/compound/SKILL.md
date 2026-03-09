---
name: workflow-compound-reference
description: Internal reference for the COMPOUND track contract. Not user-invocable; command entrypoint is /obsidian-workflows:compound.
user-invocable: false
version: 0.1.0
created: 2026-03-02T14:58
updated: 2026-03-04T22:20
---

# COMPOUND Track Entry Point

`obsidian-workflows:compound` executes `obsidian:write.compound.capture` in MVP to leave learning logs for iterative improvement.

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
/obsidian-workflows:compound file="path/to/completed.md"
/obsidian-workflows:compound latest
/obsidian-workflows:compound
```
