#!/bin/bash
# PreToolUse hook: enforce docs/contracts/path-safety.md's "reject absolute path input"
# check at runtime for the one thing that is uniquely this plugin's own action, instead
# of leaving it as command-body prose an executing agent could skip.
#
# Claude Code's PreToolUse hooks receive only the tool name and its input -- never which
# skill/command triggered the call -- so there is no way to scope this to "only while
# write-active is running." What IS unique to this plugin is invoking the `obsidian` CLI
# itself: no unrelated task in a normal session shells out to that binary. So this hook
# fires only on Bash commands that actually invoke `obsidian`, and only asks for
# confirmation when that invocation references an absolute path outside the current
# vault/project root. This is a confirmation gate, not a hard block -- a legitimate case
# (e.g. `obsidian create` against a path outside the vault) is a single explicit yes, not
# a dead end.
#
# Scope note: this does NOT cover write-active's `sources` field being read via the
# native Read tool (that path has no `obsidian` invocation to key off of, and Read is used
# for unrelated tasks constantly, so it can't be scoped to this plugin without a separate
# marker mechanism). See docs/contracts/path-safety.md for the tradeoff.

set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

[ "$tool_name" = "Bash" ] || exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')
[ -n "$command" ] || exit 0

# Only proceed if this Bash command actually invokes the `obsidian` binary as a command
# word (not merely a path/string that happens to contain "obsidian" as a substring).
echo "$command" | grep -qE '(^|[;&|]+[[:space:]]*)obsidian[[:space:]]' || exit 0

# Resolve the confinement root: Claude Code's project dir when set, else the hook's
# reported cwd. Nothing to compare against -- allow silently rather than guess.
root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ]; then
  root=$(echo "$input" | jq -r '.cwd // empty')
fi
[ -n "$root" ] || exit 0
root=$(cd "$root" 2>/dev/null && pwd -P) || exit 0

# Claude Code's own scratch/operational directories are not vault content -- flagging
# them would break routine tool use (scratchpad writes, its own settings/plugin cache).
is_allowlisted() {
  case "$1" in
    /tmp/claude-*|/private/tmp/claude-*|/var/folders/*|"$HOME"/.claude/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Normalize without requiring the path to exist (obsidian create's target often doesn't
# exist yet). python3's os.path.realpath handles this portably across macOS/Linux.
resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || printf '%s' "$1"
}

flag_path() {
  local path="$1"
  case "$path" in
    /*) ;;
    *) return 1 ;;  # not absolute, nothing to check
  esac
  is_allowlisted "$path" && return 1
  local resolved
  resolved=$(resolve_path "$path")
  case "$resolved" in
    "$root"/*|"$root") return 1 ;;  # inside the vault/project root -- fine
    *) return 0 ;;                  # absolute and outside root -- flag it
  esac
}

# Extract candidate path tokens by shell-tokenizing the command (so a relative path
# like Daily Notes/2026-07-28.md doesn't get mis-sliced into a fake "/2026-07-28.md"
# absolute path by a naive substring grep -- only a token, or a key=value token's value,
# that ITSELF starts with `/` counts).
candidates=$(python3 -c '
import shlex, sys
try:
    tokens = shlex.split(sys.argv[1])
except ValueError:
    tokens = sys.argv[1].split()
for tok in tokens:
    val = tok.split("=", 1)[1] if "=" in tok else tok
    if val.startswith("/"):
        print(val)
' "$command" 2>/dev/null || true)
while IFS= read -r cand; do
  [ -z "$cand" ] && continue
  if flag_path "$cand"; then
    reason="obsidian CLI 호출이 참조하는 절대 경로 '$cand'는 현재 볼트/프로젝트 루트('$root') 밖입니다. docs/contracts/path-safety.md의 경로 안전 원칙에 따라 확인이 필요합니다. 계속할까요?"
    printf '{"hookSpecificOutput": {"permissionDecision": "ask"}, "systemMessage": %s}' "$(printf '%s' "$reason" | jq -Rs .)" >&2
    exit 2
  fi
done <<<"$candidates"

exit 0
