---
name: review
description: REVIEW 트랙 진입점. 정책/문체 품질 게이트를 수행합니다. 작성된 문서의 정책/문체 검증이 필요할 때 사용합니다.
version: 0.1.0
context: inline
mirrors: commands/ow-review.md
mirror_hash: 3c77acc1735098e9
language: korean
user-invocable: true
created: 2026-03-02T14:58
updated: 2026-07-07T00:00
---

# REVIEW Track Entry Point

> 미러 파일: 동작 정본은 `commands/ow-review.md`이며 이 파일은 그 미러입니다. 동작이 갈리면 커맨드를 정본으로 보고 이 파일을 맞춥니다. 동기화는 frontmatter `mirror_hash`로 강제됩니다(`tools/check-skill-sync.sh`).

`obsidian-workflows:ow-review` executes `write-review-policy` as the default quality gate in MVP.

## Security/Permission Principles

- This command operates in validation/reporting mode only and does not modify files.
- Uses read-only tools following the principle of least privilege.

## Execution Order

1. Confirm target file and policy.
2. Apply path safety rules to specified `file`:
   - Prohibit absolute paths
   - Prohibit `..`
   - After resolution, allow only vault root subdirectories
   - Prohibit symbolic link escapes outside root
3. Validate structure/length/required sections using `write-review-policy` rules.
4. Return PASS/FAIL checklist and modification points.

## Future Extensions (Currently Unimplemented)

- `write-review-voice` (planned)
- `write-review-final` (planned)

## Notes

- Currently prioritizes `write-review-policy` policy gate.

## Usage

```
/obsidian-workflows:ow-review file="path/to/document.md" policy=blog
/obsidian-workflows:ow-review file="노트/my-article.md"
```
