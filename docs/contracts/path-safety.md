# Path Safety Contract

## Policy

Apply the same path safety checks to every command that accepts user-provided file/path inputs.

## Required Checks

1. Reject absolute path input
2. Reject `..` parent traversal segments
3. Resolve normalized path and enforce vault-root confinement
4. Reject symlink escape outside vault root

## Error Handling

- On any violation: return `FAIL` immediately
- No fallback path rewriting
- Include actionable remediation message

## Coverage Scope

Must be consistent across:

- `obsidian:write.scan`
- `obsidian:write.draft`
- `obsidian:write.refine`
- `obsidian:write.route`
- `obsidian-workflows:review`
- Any new command with file/path arguments
