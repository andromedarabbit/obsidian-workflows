# Security Test: Path Safety

## Objective

Ensure all file/path input entrypoints fail fast for unsafe inputs.

## Cases

- Absolute path input (e.g., `/tmp/file.md`)
- Parent traversal (`../outside.md`)
- Symlink escape outside vault root

## Entry Commands

- `/obsidian:write.scan`
- `/obsidian:write.draft`
- `/obsidian:write.refine`
- `/obsidian:write.route`
- `/obsidian-workflows:review`

## Expected

- Immediate `FAIL` for each unsafe case.
- Error message identifies violation category.
- No fallback behavior.
