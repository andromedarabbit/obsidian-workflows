# Error Message Contract

## Status Enum

Use only:

- `PASS`
- `SKIP`
- `FAIL`

## Rules

- `PASS`: normal success completion
- `SKIP`: normal empty/non-actionable case (e.g., passive scan 0 candidates)
- `FAIL`: invalid input, preflight failure, or execution error

## Message Style

- State the failure reason plainly
- Include next action command where relevant
- Avoid silent fallback

## Required Examples

- Missing init prerequisites:
  - show missing files list
  - next action: `/obsidian:write.init`
- Invalid mode:
  - show allowed values: `active|passive|draft|refine|route`
- Path safety violation:
  - identify rejected path category (`absolute`, `..`, `symlink escape`)
