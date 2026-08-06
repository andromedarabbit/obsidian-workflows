# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "bashlex",
# ]
# ///
"""Analyze a single Bash command string for guard-absolute-path.sh.

Uses bashlex (a real port of bash's own parser) instead of a hand-rolled
shlex/regex approximation, so pipelines, subshells, and command substitution
are understood the way bash itself understands them -- an earlier shlex-based
version scanned every token across an entire piped command indiscriminately,
which flagged an unrelated `sed` pattern argument (e.g. `obsidian read ... |
sed -n '/pattern/p'`) as if it were an obsidian path argument.

Run via `uv run` (see the "script" header above) so the `bashlex` dependency
is resolved/cached automatically without requiring a system-wide pip install.

Output: one JSON object on stdout.
  {"status": "parse_error"}
  {"status": "ok", "invokes_obsidian": bool,
   "absolute_candidates": [...], "unresolvable_candidates": [...]}

A "parse_error" means the command is not valid/supported bash syntax as far
as bashlex is concerned -- ambiguous enough that the caller should ask for
confirmation rather than silently proceeding. Any exception other than a
recognized bashlex parsing error is left to propagate (non-zero exit), which
the caller treats as "cannot verify at all" -> hard deny, distinct from a
merely-unparseable command.

Heredoc handling: bashlex cannot parse quoted-delimiter heredocs
(`<< 'EOF' ... EOF`, including `<<- 'EOF'`) -- it raises ParsingError on
them, even when the body is empty. (Unquoted delimiters parse fine.) That
turned any command containing such a heredoc into a `parse_error`, so a
harmless `python3 << 'EOF' ...` whose body merely mentions the word
"obsidian" (e.g. a `.obsidian/plugins/...` path) hit the hook's spurious
ask. `strip_heredoc_bodies()` (see below) removes heredoc redirection
operators and their bodies before parsing, so bashlex only sees the command
structure. This is safe by design -- see that function's docstring.
"""

import json
import re
import sys

import bashlex
from bashlex.errors import ParsingError


# --- Heredoc body stripping (preprocessing for bashlex) ---------------------
#
# Why: bashlex rejects quoted-delimiter heredocs (`<< 'EOF'` / `<<- 'EOF'`)
# with ParsingError -- even an empty body. A command that contains such a
# heredoc therefore became a `parse_error`, which the hook treats as "ask".
# The result was a false positive: any `python3 << 'EOF' ...` whose body
# happened to contain the substring "obsidian" (very common -- e.g. a
# `.obsidian/plugins/...` config path) prompted for confirmation even though
# the `obsidian` CLI was never invoked.
#
# What we do: before handing the command to bashlex, remove every heredoc
# redirection operator AND the body that follows it, leaving only the command
# structure (`python3 << 'EOF'\nBODY\nEOF` -> `python3`). The operator itself
# must be removed (not just the body) because bashlex rejects even empty
# quoted-delimiter heredocs.
#
# Why this is safe (scope): guard-absolute-path.sh keys on a *direct shell
# invocation of the `obsidian` binary* -- see its header comment and
# docs/contracts/path-safety.md's "Runtime Enforcement" section. A heredoc
# body is stdin for some other command (python/cat/...), never a shell
# command word this hook could key on. Whether the `obsidian` CLI is invoked
# *inside* that body via a subprocess is therefore out of scope for this hook
# by design, so dropping the body cannot hide a case the hook was meant to
# catch. (Stripping the body also cannot drop a path the `obsidian` CLI itself
# references: those paths are arguments on the command word's own line, which
# is preserved.)
#
# Shell-runner exception: when the feeding command is itself a shell/script
# runner (`bash`/`sh`/`eval`/`source`/`.`), the heredoc body IS executable shell
# source. In that case we preserve the original command instead of stripping
# it, so quoted-heredoc parsing takes the conservative parse_error -> ask path.
# This applies inside command substitutions too: in `echo "$(bash <<'EOF' ...)"`
# the feeder is the nested `bash`, not the outer `echo`.
#
# Best-effort: if anything is uncertain -- an internal error, an operator
# shape we don't recognize, or an unterminated heredoc we can't confidently
# close -- we return the command unchanged and let the caller parse the
# original, preserving the existing parse_error -> ask fallback.

# A heredoc redirection operator: `<<` or `<<-`, optional whitespace, an
# optional single-or-double quote around the delimiter, an identifier-like
# delimiter, and a matching closing quote. The delimiter is restricted to
# `[A-Za-z_][A-Za-z0-9_-]*` -- this covers virtually every real-world heredoc
# delimiter (EOF, PYEOF, END, ...). A `<<` whose delimiter is NOT cleanly
# terminated by whitespace / a shell metachar / end-of-line (e.g. `<<true.foo`,
# where the real bash delimiter is the dotted `true.foo` but this regex would
# capture only the `true` prefix) is treated as ambiguous and aborts stripping
# for the whole command via _HeredocAmbiguous -> the caller parses the original
# (parse_error -> ask), never a silent allow.
_HEREDOC_OP = re.compile(
    r"<<(?P<dash>-)?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_-]*)(?P=q)"
)

# Characters that may legitimately follow a heredoc delimiter on the same line
# (end of line, more redirections, a pipe, a comment, ...). If the character
# right after a matched delimiter is anything else, the real delimiter is
# longer/different than the identifier we captured -> ambiguous -> bail.
_HEREDOC_DELIM_TERMINATORS = " \t|&;<>#"

# Raised internally to signal "this command has a heredoc shape we cannot
# confidently strip" (ambiguous delimiter, etc.). strip_heredoc_bodies's
# existing broad except catches it and returns the original command.
class _HeredocAmbiguous(Exception):
    pass

# Commands whose heredoc body is executed as shell (so an `obsidian ...` line
# inside the body IS a real direct invocation). We cannot analyze the body as
# data the way we can for python/cat/..., so for these we preserve the original
# command (-> the quoted-heredoc parse_error -> ask behavior) instead of
# stripping. Covers the common direct forms; `env bash`, `xargs -0 bash`, etc.
# are accepted residuals (documented).
_SHELL_RUNNERS = {
    "bash", "sh", "dash", "rbash", "zsh", "ksh", "ash",
    "eval", "source", ".", "exec",
}


def _text_feeds_shell_runner(command_text):
    """True if the first command word of `command_text` is a shell runner."""
    stripped = command_text.strip()
    if not stripped:
        return False
    first = stripped.split()[0].strip("'\"")
    first = first.rsplit("/", 1)[-1]  # /bin/bash -> bash
    return first in _SHELL_RUNNERS


def _find_heredoc_ops(line):
    """Find heredoc operators in shell syntax regions of one physical line.

    Ordinary quoted text stays opaque, but an unescaped ``$(`` inside double
    quotes opens a nested shell-syntax context. Each result is
    ``(start, end, tabstripped, delim, feeds_shell_runner)``. Source offsets
    always refer to the original line so `_remove_ops()` can rewrite it safely.
    """
    ops = []
    n = len(line)

    def scan_double(i, depth):
        while i < n:
            c = line[i]
            if c == "\\" and i + 1 < n:
                i += 2
                continue
            if c == '"':
                return i + 1, True
            if c == "$" and i + 1 < n and line[i + 1] == "(":
                # `$((...))` is arithmetic expansion, not command substitution.
                # It remains opaque like the surrounding double-quoted text.
                if i + 2 < n and line[i + 2] == "(":
                    i += 3
                    continue
                i, closed = scan_shell(i + 2, True, depth + 1)
                if not closed:
                    return i, False
                continue
            i += 1
        return i, False

    def scan_shell(i, stop_on_rparen, depth):
        if depth > 32:
            raise _HeredocAmbiguous()

        command_start = i
        while i < n:
            c = line[i]
            if c == "\\" and i + 1 < n:
                i += 2
                continue
            if c == "'":
                end = line.find("'", i + 1)
                if end < 0:
                    return n, False
                i = end + 1
                continue
            if c == '"':
                i, closed = scan_double(i + 1, depth)
                if not closed:
                    return i, False
                continue
            if c == "$" and i + 1 < n and line[i + 1] == "(":
                if i + 2 < n and line[i + 2] == "(":
                    i += 3
                    continue
                i, closed = scan_shell(i + 2, True, depth + 1)
                if not closed:
                    return i, False
                continue
            if c == ")" and stop_on_rparen:
                return i + 1, True
            if c == "#" and (i == 0 or line[i - 1] in " \t;|&()<>"):
                # An unquoted `#` at a shell word boundary starts a comment.
                # Ignoring the remainder prevents comment text such as
                # `# use << EOF` from consuming later real commands.
                return n, not stop_on_rparen
            if c in ";|&":
                command_start = i + 1
                i += 1
                continue
            if (
                c == "<"
                and i + 1 < n
                and line[i + 1] == "<"
                and (i == 0 or line[i - 1] != "<")
            ):
                # The previous-character guard avoids matching the second and
                # third `<` of Bash's here-string operator `<<<`.
                m = _HEREDOC_OP.match(line, i)
                if not m:
                    i += 1
                    continue
                if m.end() < n and line[m.end()] not in _HEREDOC_DELIM_TERMINATORS:
                    # The real delimiter continues beyond the identifier prefix
                    # we captured (for example `<<true.foo`). Rewriting against
                    # the wrong delimiter could silently drop a later command.
                    raise _HeredocAmbiguous()
                feeder = line[command_start:m.start()]
                ops.append(
                    (
                        m.start(),
                        m.end(),
                        m.group("dash") == "-",
                        m.group("delim"),
                        _text_feeds_shell_runner(feeder),
                    )
                )
                i = m.end()
                continue
            i += 1
        return i, not stop_on_rparen

    scan_shell(0, False, 0)
    return ops


def _remove_ops(line, ops):
    """Return ``line`` with each operator span in ``ops`` deleted."""
    parts = []
    prev = 0
    for start, end, _tab, _delim, _feeds_shell_runner in ops:
        parts.append(line[prev:start])
        prev = end
    parts.append(line[prev:])
    return "".join(parts)


def strip_heredoc_bodies(command):
    """Best-effort removal of heredoc operators + bodies (see note above).

    Returns the rewritten command, or ``command`` unchanged when the command
    has an unterminated heredoc or anything unexpected happens -- so the
    caller falls back to parsing the original (and the existing
    parse_error -> ask behavior if it is genuinely bad).
    """
    try:
        lines = command.split("\n")
        out = []
        i, n = 0, len(lines)
        while i < n:
            line = lines[i]
            ops = _find_heredoc_ops(line)
            if not ops:
                out.append(line)
                i += 1
                continue
            # If the heredoc feeds a shell/script runner (bash/sh/eval/...),
            # its body is executed as shell -- an `obsidian ...` line inside it
            # is a real direct invocation we would hide by stripping. We cannot
            # analyze that body as data, so preserve the ORIGINAL command: the
            # caller parses it as-is, restoring the quoted-heredoc parse_error
            # -> ask backstop. (Tradeoff: a `.obsidian/...` path in a
            # shell-runner heredoc body prompts again -- accepted, because the
            # alternative is a silent allow of an in-body obsidian call.)
            if any(feeds_shell_runner for *_, feeds_shell_runner in ops):
                return command
            # Drop the operators from this line (they carry no obsidian/path
            # information), then consume each operator's body up to and
            # including its closing delimiter line.
            out.append(_remove_ops(line, ops))
            i += 1
            for _start, _end, tabstripped, delim, _feeds_shell_runner in ops:
                closed = False
                while i < n:
                    cand = lines[i]
                    cmp = cand.lstrip("\t") if tabstripped else cand
                    cmp = cmp.rstrip("\r")
                    if cmp == delim:
                        i += 1  # closing delimiter line -- drop it
                        closed = True
                        break
                    i += 1  # body line -- drop it
                if not closed:
                    # Unterminated heredoc: cannot confidently rewrite this
                    # command. Leave it untouched so the caller parses the
                    # original (parse_error -> ask if it really is malformed).
                    return command
        return "\n".join(out)
    except Exception:
        return command


def collect_commands(node, out, seen):
    if node is None or id(node) in seen:
        return
    seen.add(id(node))
    if getattr(node, "kind", None) == "command":
        out.append(node)
    for child in getattr(node, "parts", None) or []:
        collect_commands(child, out, seen)
    # CompoundNode (subshells, if/for/while/case, ...) nests its children
    # under `.list` instead of `.parts`.
    for child in getattr(node, "list", None) or []:
        collect_commands(child, out, seen)
    # command/process-substitution nodes nest their inner command under a
    # singular `.command` attribute rather than `.parts`.
    collect_commands(getattr(node, "command", None), out, seen)


def analyze(command):
    # Strip heredoc operators + bodies first: bashlex cannot parse
    # quoted-delimiter heredocs, which would otherwise turn any command
    # containing one (very commonly: a `.obsidian/...` path in the body) into
    # a spurious parse_error. Best-effort -- returns the original command
    # unchanged when it can't confidently rewrite (see strip_heredoc_bodies).
    command = strip_heredoc_bodies(command)
    trees = bashlex.parse(command)

    commands = []
    seen = set()
    for tree in trees:
        collect_commands(tree, commands, seen)

    invokes_obsidian = False
    absolute_candidates = []
    unresolvable_candidates = []

    for cmd in commands:
        words = [p for p in (cmd.parts or []) if getattr(p, "kind", None) == "word"]
        if not words:
            continue

        first = words[0]
        if first.parts:
            # Command word itself contains an expansion (e.g. `$(echo obsidian)
            # create ...`) -- can't statically tell what it resolves to. Treat
            # as a possible obsidian invocation only if "obsidian" literally
            # appears in its raw source text; otherwise there's nothing to
            # anchor on and it's almost certainly an unrelated command.
            if "obsidian" not in first.word:
                continue
        else:
            # .word is already bash-dequoted for a part-less (no-expansion)
            # word node -- no further shlex/quote processing needed or wanted.
            if first.word.rsplit("/", 1)[-1] != "obsidian":
                continue

        invokes_obsidian = True

        for w in words[1:]:
            if w.parts:
                # Contains an expansion (parameter, tilde, command
                # substitution, etc.) -- can't statically resolve whether it
                # becomes an absolute path. Ask rather than silently drop it.
                unresolvable_candidates.append(w.word)
                continue
            val = w.word
            if "=" in val:
                val = val.split("=", 1)[1]
            if val.startswith("/"):
                absolute_candidates.append(val)
            elif val.startswith("$") or val.startswith("~") or "$(" in val or "`" in val:
                unresolvable_candidates.append(val)

    return {
        "status": "ok",
        "invokes_obsidian": invokes_obsidian,
        "absolute_candidates": absolute_candidates,
        "unresolvable_candidates": unresolvable_candidates,
    }


def main():
    command = sys.argv[1]
    try:
        result = analyze(command)
    except ParsingError:
        result = {"status": "parse_error"}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
