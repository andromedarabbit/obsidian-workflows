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
# Acknowledged narrowing vs the pre-fix behavior: when the feeding command is a
# shell/script runner itself (`bash`/`sh`/`eval`/`source`/`.`), the heredoc
# body IS executed as shell commands, so an `obsidian ... /etc/x` line inside
# such a body is a real direct invocation. Pre-fix, bashlex's parse_error on
# quoted-delimiter heredocs accidentally prompted on that shape; after this
# strip it is no longer caught here. This is an accepted tradeoff under the
# hook's threat model (guard-absolute-path.sh:17 -- the agent is the caller,
# not an attacker; this layer is a backstop against accidental out-of-vault
# writes, and the command-level Required Checks in path-safety.md still
# apply), not a defense against adversarial command crafting.
#
# Best-effort: if anything is uncertain -- an internal error, an operator
# shape we don't recognize, or an unterminated heredoc we can't confidently
# close -- we return the command unchanged and let the caller parse the
# original, preserving the existing parse_error -> ask fallback.

# A heredoc redirection operator: `<<` or `<<-`, optional whitespace, an
# optional single-or-double quote around the delimiter, an identifier-like
# delimiter, and a matching closing quote. The delimiter is restricted to
# `[A-Za-z_][A-Za-z0-9_-]*` -- this covers virtually every real-world heredoc
# delimiter (EOF, PYEOF, END, ...). Exotic delimiters outside this set are
# left in place; the command then parses as-is (or hits parse_error -> ask if
# it genuinely has a heredoc), the safe fallback.
_HEREDOC_OP = re.compile(
    r"<<(?P<dash>-)?\s*(?P<q>['\"]?)(?P<delim>[A-Za-z_][A-Za-z0-9_-]*)(?P=q)"
)


def _find_heredoc_ops(line):
    """Find heredoc redirection operators in the UNQUOTED regions of one line.

    Returns a list of (start, end, tabstripped, delim) tuples, left to right.
    Operators inside single/double-quoted strings (e.g. ``echo "<< EOF"``) are
    skipped so a literal ``<<`` in an argument is not mistaken for a heredoc.
    """
    ops = []
    i, n = 0, len(line)
    in_single = in_double = False
    while i < n:
        c = line[i]
        if in_single:
            if c == "'":
                in_single = False
            i += 1
        elif in_double:
            if c == "\\" and i + 1 < n:  # escaped char inside double quotes
                i += 2
            else:
                if c == '"':
                    in_double = False
                i += 1
        elif c == "'":
            in_single = True
            i += 1
        elif c == '"':
            in_double = True
            i += 1
        elif c == "\\" and i + 1 < n:  # escaped char in unquoted text
            i += 2
        elif c == "#" and (i == 0 or not (line[i - 1].isalnum() or line[i - 1] == "_")):
            # Unquoted `#` at a word boundary starts a bash comment, so the rest
            # of the line carries no heredoc operators. Stop scanning this line
            # so a `<< DELIM` written inside a comment is never mistaken for a
            # real heredoc -- otherwise the lines after it (which can include a
            # genuine `obsidian ... /etc/x` invocation) would be silently
            # dropped as the comment's "body", a silent-pass regression.
            # Safe-bias: treat `#` as a comment whenever it is not clearly
            # mid-word. The worst case is leaving a real heredoc un-stripped,
            # which falls back to bashlex (parse_error -> ask), never a silent
            # allow; command-substitution nesting (`$( ... # ... )`) is a known
            # residual this best-effort scan does not track.
            break
        elif (
            c == "<"
            and i + 1 < n
            and line[i + 1] == "<"
            and (i == 0 or line[i - 1] != "<")
        ):
            # The trailing `line[i - 1] != "<"` guard avoids mis-reading bash's
            # here-string operator `<<<` as a heredoc `<<` matched against its
            # 2nd+3rd `<`, which would consume following lines as a phantom body.
            m = _HEREDOC_OP.match(line, i)
            if m:
                ops.append(
                    (m.start(), m.end(), m.group("dash") == "-", m.group("delim"))
                )
                i = m.end()
            else:
                i += 1
        else:
            i += 1
    return ops


def _remove_ops(line, ops):
    """Return ``line`` with each operator span in ``ops`` deleted."""
    parts = []
    prev = 0
    for start, end, _tab, _delim in ops:
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
            # Drop the operators from this line (they carry no obsidian/path
            # information), then consume each operator's body up to and
            # including its closing delimiter line.
            out.append(_remove_ops(line, ops))
            i += 1
            for _start, _end, tabstripped, delim in ops:
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
