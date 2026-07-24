# Helper Script Path Resolution Contract

## Policy

Any command/skill that shells out to a helper script never runs it relative to
the current vault working directory. Vault cwd is user content, not the
plugin's own file tree, so a `src/...`-relative path is wrong by construction.

## Required Behavior

1. Resolve the `obsidian-workflows` plugin/repo root first.
2. Run the helper script from an absolute path under that resolved root.
3. If the root cannot be resolved, do not guess from vault cwd.
4. When the helper script step is optional, warn and skip on resolution
   failure, then continue under the calling command's own fail-fast/fail-safe
   policy.

## Coverage Scope

Must be consistent across:

- `skills/ow-plan/SKILL.md`
- `skills/ow-work/SKILL.md`
- `skills/ow-compound/SKILL.md`
- `skills/ow-review/SKILL.md`
- `commands/write-scan.md`
- Any new command/skill that shells out to a helper script
