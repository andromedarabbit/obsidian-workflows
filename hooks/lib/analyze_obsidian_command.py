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
"""

import json
import sys

import bashlex
from bashlex.errors import ParsingError


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
