---
name: ow-compound
description: COMPOUND 트랙 진입점. 완성본에서 학습 포인트를 축적합니다. 완성된 문서에서 학습 포인트를 축적해야 할 때 사용합니다.
version: 0.2.0
context: inline
language: korean
created: 2026-03-02T14:58
updated: 2026-07-07T00:00
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

Helper script는 항상 `obsidian-workflows` plugin/repo root 기준 절대 경로로 실행합니다 — 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다. root 해석 실패 시 추측하지 않고, optional 단계는 경고 후 건너뜁니다. 상세: `docs/contracts/helper-script-path.md`.

## Rules

- Keep capture lightweight and record-focused (close to noop skeleton).
- Avoid over-analysis in default mode; prioritize short, reusable capture notes.

## Usage

```
/obsidian-workflows:ow-compound file="path/to/completed.md"
/obsidian-workflows:ow-compound latest
/obsidian-workflows:ow-compound
```
