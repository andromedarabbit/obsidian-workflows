# Security Test: Path Safety

## Objective

Ensure all file/path input entrypoints fail fast for unsafe inputs.

## Cases

- Absolute path input (e.g., `/tmp/file.md`)
- Parent traversal (`../outside.md`)
- Symlink escape outside vault root

## Entry Commands

- `/write-scan`
- `/write-draft`
- `/write-refine`
- `/write-route`
- `/obsidian-workflows:ow-review`

## Expected

- Immediate `FAIL` for each unsafe case.
- Error message identifies violation category.
- No fallback behavior.
