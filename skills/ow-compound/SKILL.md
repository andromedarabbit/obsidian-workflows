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

> 미러 파일: 동작 정본은 `commands/ow-compound.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

`obsidian-workflows:ow-compound` executes `write-compound-capture` in MVP to leave learning logs for iterative improvement.

## Future Extensions (Currently Unimplemented)

- `write-compound-sync` (planned)

## Execution Order

1. Select target document (if not specified, use latest file from final_path).
2. Execute `write-compound-capture`.
3. Briefly summarize policy/SOUL improvement candidates.

## Helper Script Path Resolution

Helper script는 현재 vault cwd 기준의 `src/...` 경로로 실행하지 않습니다.

1. 먼저 `obsidian-workflows` plugin/repo root를 해석합니다.
2. helper script를 사용할 때는 해석된 root 아래의 절대 경로로 실행합니다.
3. root를 해석할 수 없으면 vault cwd에서 추측하지 않습니다.
4. optional helper script 단계는 경고 후 건너뛰고, 본래 command의 fail-fast/fail-safe 정책을 따릅니다.

## Rules

- Keep capture lightweight and record-focused (close to noop skeleton).
- Avoid over-analysis in default mode; prioritize short, reusable capture notes.

## Usage

```
/obsidian-workflows:ow-compound file="path/to/completed.md"
/obsidian-workflows:ow-compound latest
/obsidian-workflows:ow-compound
```
