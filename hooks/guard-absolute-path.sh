#!/bin/bash
# PreToolUse hook: enforce docs/contracts/path-safety.md's "reject absolute path input"
# check at runtime for the one thing that is uniquely this plugin's own action, instead
# of leaving it as command-body prose an executing agent could skip.
#
# Claude Code's PreToolUse hooks receive only the tool name and its input -- never which
# skill/command triggered the call -- so there is no way to scope this to "only while
# write-active is running." What IS unique to this plugin is invoking the `obsidian` CLI
# itself: no unrelated task in a normal session shells out to that binary.
#
# Design principle (v2, after a security review found multiple bypasses in v1): fail
# toward blocking or asking, never toward silent allow.
#   - `deny`: a hard PreToolUse block (exit 2). Used when this hook cannot verify safety
#     at all (missing dependency, unresolvable root, unparseable command) -- there is no
#     meaningful question to ask, so the safe default is to stop, not to guess.
#   - `ask`: a soft confirmation (Claude Code only honors `permissionDecision` via JSON on
#     STDOUT with exit 0 -- exit 2 is always a hard block and any JSON attached to it is
#     ignored, regardless of stream). Used when a specific absolute, out-of-vault path (or
#     something that could resolve to one) was actually detected -- a human can approve.
#
# Command analysis (v3): a v2 hand-rolled shlex-token-scan approximation of bash grammar
# flagged an unrelated `sed` pattern argument in a piped command (`obsidian read ... | sed
# -n '/pattern/p'`) as an obsidian path candidate, because it scanned every token across
# the whole command string with no awareness of which pipe segment actually invoked
# `obsidian`. `hooks/lib/analyze_obsidian_command.py` replaces that scan with `bashlex`, a
# real port of bash's own parser, run via `uv run` (see that script's PEP 723 header --
# `uv` resolves/caches the `bashlex` dependency automatically, no system-wide pip install
# needed). This correctly scopes candidate extraction to the command node(s) that actually
# invoke `obsidian`, across pipelines, subshells, `if`/`while`/etc. compounds, and command
# substitution alike.
#
# Scope note: this does NOT cover write-active's `sources` field being read via the
# native Read tool (that path has no `obsidian` invocation to key off of, and Read is used
# for unrelated tasks constantly, so it can't be scoped to this plugin without a separate
# marker mechanism). See docs/contracts/path-safety.md for the tradeoff.

set -euo pipefail

# Local dev-time kill switch: `touch` this file to disable the hook immediately (each
# invocation re-reads this script fresh, so no session reload is needed), `rm` it to
# re-enable. Never commit this file -- it's a local escape hatch, not shipped behavior.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/.disabled" ] && exit 0

deny() {
  echo "guard-absolute-path: $1" >&2
  exit 2
}

ask() {
  printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": %s}}\n' \
    "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

command -v jq >/dev/null 2>&1 || deny "jq가 없어 경로 안전 확인을 할 수 없습니다."
command -v python3 >/dev/null 2>&1 || deny "python3가 없어 경로 안전 확인을 할 수 없습니다."
command -v uv >/dev/null 2>&1 || deny "uv가 없어 경로 안전 확인을 할 수 없습니다(bashlex 기반 명령어 분석에 필요)."

input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty') || deny "tool_name을 읽지 못했습니다."

[ "$tool_name" = "Bash" ] || exit 0

command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty') || deny "command를 읽지 못했습니다."
[ -n "$command" ] || exit 0

case "$command" in
  *obsidian*) ;;
  *) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$root" ]; then
  root=$(printf '%s' "$input" | jq -r '.cwd // empty') || deny "cwd를 읽지 못했습니다."
fi
[ -n "$root" ] || deny "볼트/프로젝트 루트를 확인할 수 없어 경로 안전 확인이 불가능합니다."
root=$(cd "$root" 2>/dev/null && pwd -P) || deny "루트 경로 '$root'를 확인할 수 없습니다."

# Claude Code's own scratch/operational directories are not vault content -- flagging
# them would break routine tool use (scratchpad writes, its own settings/plugin cache).
# Deliberately narrow (checked against resolved paths only, below) rather than the wider
# /var/folders/* glob a prior version used, which exempted arbitrary macOS temp paths.
is_allowlisted() {
  case "$1" in
    /tmp/claude-*|/private/tmp/claude-*|"$HOME"/.claude/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Normalize without requiring the path to exist (obsidian create's target often doesn't
# exist yet). python3's os.path.realpath handles this portably across macOS/Linux.
resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null
}

flag_path() {
  local path="$1" resolved
  case "$path" in
    /*) ;;
    *) return 1 ;;  # not absolute, nothing to check
  esac
  resolved=$(resolve_path "$path") || deny "경로 '$path'를 정규화하지 못했습니다."
  # Allowlist check runs on the RESOLVED path -- checking the raw candidate let a
  # traversal like /tmp/claude-x/../../etc/evil match the prefix before confinement
  # ever ran.
  is_allowlisted "$resolved" && return 1
  case "$resolved" in
    "$root"/*|"$root") return 1 ;;  # inside the vault/project root -- fine
    *) return 0 ;;                  # absolute and outside root -- flag it
  esac
}

# Analyze the command with a real bash parser (see header comment) rather than a
# hand-rolled approximation. `uv run` resolves/caches the `bashlex` dependency on first
# use. `--quiet` suppresses uv's own resolver/install chatter from stdout.
analysis=$(uv run --quiet "$SCRIPT_DIR/lib/analyze_obsidian_command.py" "$command") \
  || deny "명령어를 분석하지 못했습니다(uv/bashlex 실행 실패)."

status=$(printf '%s' "$analysis" | jq -r '.status // empty') || deny "분석 결과를 읽지 못했습니다."

if [ "$status" = "parse_error" ]; then
  ask "obsidian CLI 호출이 포함된 명령어를 유효한 bash 구문으로 파싱할 수 없습니다. 절대 경로 여부를 확인할 수 없어 확인이 필요합니다. 계속할까요?"
fi
[ "$status" = "ok" ] || deny "명령어 분석 결과를 이해할 수 없습니다: $analysis"

invokes_obsidian=$(printf '%s' "$analysis" | jq -r '.invokes_obsidian') || deny "분석 결과를 읽지 못했습니다."
[ "$invokes_obsidian" = "true" ] || exit 0

while IFS= read -r cand; do
  [ -z "$cand" ] && continue
  if flag_path "$cand"; then
    ask "obsidian CLI 호출이 참조하는 절대 경로 '$cand'는 현재 볼트/프로젝트 루트('$root') 밖입니다. docs/contracts/path-safety.md의 경로 안전 원칙에 따라 확인이 필요합니다. 계속할까요?"
  fi
done < <(printf '%s' "$analysis" | jq -r '.absolute_candidates[]')

while IFS= read -r cand; do
  [ -z "$cand" ] && continue
  ask "obsidian CLI 호출의 인자 '$cand'는 셸 확장(변수/틸드/커맨드 치환) 후에만 절대 경로가 될 수 있어 정적으로 안전을 확인할 수 없습니다. 확인이 필요합니다. 계속할까요?"
done < <(printf '%s' "$analysis" | jq -r '.unresolvable_candidates[]')

exit 0
