---
name: review
description: REVIEW 트랙 진입점. 정책/문체 품질 게이트를 수행합니다. 작성된 문서의 정책/문체 검증이 필요할 때 사용합니다.
version: 0.1.0
context: inline
language: korean
user-invocable: true
created: 2026-03-02T14:58
updated: 2026-07-07T00:00
---

# REVIEW Track Entry Point

`obsidian-workflows:ow:review` executes `obsidian:write.review.policy` as the default quality gate in MVP.

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
3. Validate structure/length/required sections using `obsidian:write.review.policy` rules.
4. Return PASS/FAIL checklist and modification points.

## Future Extensions (Currently Unimplemented)

- `obsidian:write.review.voice` (planned)
- `obsidian:write.review.final` (planned)

## Notes

- Currently prioritizes `obsidian:write.review.policy` policy gate.

## Usage

```
/obsidian-workflows:ow:review file="path/to/document.md" policy=blog
/obsidian-workflows:ow:review file="노트/my-article.md"
```
