---
name: review
description: This skill should be used when the user wants to review writing quality, asks for "obsidian-workflows:review", needs policy/style quality gate checks, or wants to validate content against writing policies. Use when user says "review", "check quality", "validate", "quality gate".
version: 0.1.0
created: 2026-03-02T14:58
updated: 2026-03-02T14:58
---

# REVIEW Track Entry Point

`obsidian-workflows:review` executes `obsidian:write.review.policy` as the default quality gate in MVP.

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
/obsidian-workflows:review file="path/to/document.md" policy=blog
/obsidian-workflows:review file="노트/my-article.md"
```
