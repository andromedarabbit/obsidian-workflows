# Path Safety Contract

## Policy

Apply the same path safety checks to every command that accepts user-provided file/path inputs.

## Required Checks

1. Reject absolute path input
2. Reject `..` parent traversal segments
3. Resolve normalized path and enforce vault-root confinement
4. Reject symlink escape outside vault root

These are command-level checks: every command listed under Coverage Scope must
apply all four to its own file/path arguments, with no per-field exceptions.
`write-active`'s `sources` follows this like any other path input — see
Coverage Scope.

## Runtime Enforcement (supplementary, not a replacement for the checks above)

`hooks/guard-absolute-path.sh` (registered via `hooks/hooks.json` as a
`PreToolUse` hook on `Bash`) adds a second, independent safety net for one
narrow case the checks above cannot reach by themselves: a Bash command that
invokes the `obsidian` CLI with an absolute path resolving outside the current
vault/project root. This exists because Claude Code's `PreToolUse` hooks
receive only the tool name and its input, never the invoking skill/command, so
there is no way to make a hook enforce the four Required Checks generally —
the hook can only key on the one thing that is uniquely this plugin's own: an
invocation of the `obsidian` binary. It does not substitute for a command
performing the Required Checks itself, and it does not extend to any other
tool call.

**This layer's semantics are deliberately different from the checks above: it
asks for confirmation, it does not reject.** The hook returns
`permissionDecision: ask`, not a denial — a human can approve and let the call
proceed with an absolute, out-of-vault path. This is intentional: the
Required Checks are the fail-fast contract commands must implement in their
own logic (no exceptions, no prompts); this hook is a best-effort, defense-in-
depth backstop for the one case where a command's own check might have been
skipped, and a confirmation prompt is more useful there than a silent
allow — the user actually using `obsidian create`/`read` mid-session is best
placed to judge whether that specific out-of-vault path is intentional. Do not
read "Runtime Enforcement" as satisfying Required Check 1 or the
FAIL-immediately requirement below for `Bash` calls; it is an additional,
softer gate layered on top, not an implementation of that requirement.

## Error Handling

- On any violation of the Required Checks (command-level, all commands under
  Coverage Scope): return `FAIL` immediately
- No fallback path rewriting
- Include actionable remediation message
- The runtime hook's confirmation prompt (see above) is a separate mechanism
  with its own semantics and does not change this section's FAIL requirement
  for command-level checks

## Coverage Scope

Must be consistent across:

- `write-scan`
- `write-draft`
- `write-refine`
- `write-review-policy`
- `write-route`
- `write-active` (including its `sources` field — no exception: absolute
  paths are rejected like any other input. To reference an external tool's
  data file, copy it into the vault first and pass the resulting relative
  path)
- `obsidian-workflows:ow-review`
- `obsidian-workflows:ow-policy`
- Any new command with file/path arguments
