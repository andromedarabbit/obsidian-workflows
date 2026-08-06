# Path Safety Contract

## Policy

Apply the same path safety checks to every command that accepts user-provided file/path inputs.

## Required Checks

1. Accept an absolute path only if it resolves inside the vault root; rewrite it to a vault-relative path and continue with checks 2–4. Reject absolute paths that resolve outside the vault (or when the vault root cannot be determined)
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

**When the hook cannot verify safety at all, it hard-blocks instead of
guessing.** A missing dependency (`jq`, `python3`, or `uv`), an unresolvable
vault root, or a command it cannot parse as valid bash gives the hook no
basis for a meaningful yes/no question, so those cases are a hard deny
(`exit 2`), not a silent allow and not an `ask`. Only a *specific*,
successfully-identified out-of-vault path gets the softer `ask` treatment.
See `hooks/guard-absolute-path.sh`'s own comments and
`tools/test-guard-absolute-path.sh` for the exact cases covered — the first
version of this hook got the `ask` mechanics wrong (`exit 2` is always a hard
block in Claude Code regardless of any JSON attached to it; `ask` requires
JSON on stdout with `exit 0`) and had several detection bypasses, all fixed
and regression-tested in the version this file describes.

**Command analysis uses `bashlex`, not a hand-rolled parser.** An earlier
version approximated bash grammar with `shlex` plus manual token scanning,
which correctly closed the round-3 bypasses but introduced a new false
positive in real use: it scanned every token across an *entire* piped
command, so a `sed`/`grep`/etc. argument after a `|` that happened to start
with `/` (e.g. a sed address pattern) was flagged as an obsidian path
candidate even though it belonged to a completely different command in the
pipeline. `hooks/lib/analyze_obsidian_command.py` now parses the command with
`bashlex` (a real port of bash's own parser) and only extracts path
candidates from the command node(s) that actually invoke `obsidian` — correct
across pipelines, subshells, and `if`/`while`/etc. compounds. It runs via
`uv run`, which resolves and caches the `bashlex` dependency automatically
(no separate `pip install` step); `uv`'s absence is therefore also a hard
deny, alongside `jq` and `python3`.

**Heredoc commands are preprocessed before parsing.** bashlex cannot parse
quoted-delimiter heredocs (`<< 'EOF'`), which previously turned any command
containing one into a `parse_error` → `ask` — a false positive whenever the
body merely mentioned "obsidian" (e.g. a `.obsidian/plugins/...` path). The
analyzer now strips heredoc redirection operators and their bodies before
parsing, so only the command structure reaches bashlex. Ordinary single- and
double-quoted strings remain opaque, but an unescaped command substitution
(`$()`) inside double quotes opens a nested shell-syntax context; this lets
commands such as `"$(cat <<'EOF' ... EOF)"` strip their real heredoc without
mistaking a literal `"cat <<'EOF'"` or escaped `\$(` for shell syntax.

A heredoc body is normally stdin data for another command, not a shell command
word the hook keys on. The exception is a heredoc fed to a shell/script runner
(`bash`/`sh`/`eval`/`source`/`.`), whose body is executable shell source. The
analyzer identifies the feeder in its local command-substitution context and
preserves the original command whenever that feeder is a shell runner. The
quoted heredoc then follows the conservative `parse_error` → `ask` path rather
than being stripped into a silent allow. Ambiguous delimiters, unterminated
heredocs, and uncertain nesting likewise preserve the original command.

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
- `write-active` (including its `sources` field — no exception: an absolute
  path is rewritten to vault-relative when it resolves inside the vault,
  rejected when outside. For a file that lives outside the vault entirely,
  copy it into the vault first and pass the resulting relative path)
- `obsidian-workflows:ow-review`
- `obsidian-workflows:ow-policy`
- Any new command with file/path arguments
