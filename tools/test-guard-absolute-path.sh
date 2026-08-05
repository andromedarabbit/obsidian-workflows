#!/usr/bin/env bash
# test-guard-absolute-path.sh - Exercise hooks/guard-absolute-path.sh against synthetic
# PreToolUse payloads. Feeds sample stdin JSON (as Claude Code itself would) and asserts
# on exit code and output shape. Regression coverage for the bypasses found in code
# review round 3 (SEC/REL/TEST/adversarial findings on this file), plus the real-usage
# false positive found after shipping (a piped `sed` argument mistaken for an obsidian
# path candidate) that motivated switching the analysis backend to bashlex.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT_DIR/hooks/guard-absolute-path.sh"

PASS=0
FAIL=0

# run <name> <expected_exit> <json> [expect_ask]
#   expect_ask=1  asserts stdout contains permissionDecision":"ask"
#   expect_ask=no asserts stdout has NO permissionDecision at all (the hook
#                 passed the command through -- the only stdout it ever emits
#                 is an ask JSON, so absence of permissionDecision means allow).
#   omitted/0     asserts nothing about stdout beyond the exit code.
run() {
  local name="$1" expected_exit="$2" json="$3" expect_ask="${4:-0}"
  local out err actual_exit
  set +e
  out=$(printf '%s' "$json" | CLAUDE_PROJECT_DIR="$ROOT_DIR" bash "$HOOK" 2>/tmp/tgap-stderr-$$)
  actual_exit=$?
  set -e
  err=$(cat "/tmp/tgap-stderr-$$" 2>/dev/null || true)
  rm -f "/tmp/tgap-stderr-$$"

  if [ "$actual_exit" != "$expected_exit" ]; then
    echo "FAIL: $name -- expected exit $expected_exit, got $actual_exit (stdout: $out / stderr: $err)"
    FAIL=$((FAIL + 1))
    return
  fi
  case "$expect_ask" in
    1)
      if ! printf '%s' "$out" | grep -q '"permissionDecision": *"ask"'; then
        echo "FAIL: $name -- expected stdout permissionDecision:ask, got: $out"
        FAIL=$((FAIL + 1))
        return
      fi
      ;;
    no)
      if printf '%s' "$out" | grep -q '"permissionDecision"'; then
        echo "FAIL: $name -- expected NO prompt (pass-through), got: $out"
        FAIL=$((FAIL + 1))
        return
      fi
      ;;
  esac
  echo "PASS: $name"
  PASS=$((PASS + 1))
}

# --- Baseline pass-through cases (exit 0, no ask) ---

run "non-Bash tool_name is ignored" 0 \
  '{"tool_name":"Read","tool_input":{"file_path":"/etc/passwd"}}'

run "Bash command without obsidian is ignored" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

run "obsidian create in-vault relative path is allowed" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian create path=\\\"Daily Notes/2026-07-28.md\\\"\"}}" no

run "obsidian create against an allowlisted scratch path is allowed" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/tmp/claude-501/scratch.md"}}' no

# --- Fix for finding #1: out-of-root path must ASK (stdout, exit 0), not hard-block ---

run "obsidian create against an out-of-root absolute path asks (not a hard block)" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/etc/passwd"}}' 1

# --- Fix for finding #3: detection must not be bypassable by quoting/subshell/substitution/keyword ---

run "command substitution invocation still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"x=$(obsidian create path=/etc/passwd)"}}' 1

run "full-path invocation still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"/usr/local/bin/obsidian create path=/etc/passwd"}}' 1

run "leading-whitespace invocation still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"  obsidian create path=/etc/passwd"}}' 1

run "quoted binary name still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"\"obsidian\" create path=/etc/passwd"}}' 1

run "subshell invocation still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"(obsidian create path=/etc/passwd)"}}' 1

run "shell-keyword-prefixed invocation still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"if true; then obsidian create path=/etc/passwd; fi"}}' 1

# --- Fix for finding #4: allowlist must not survive traversal out of an allowlisted prefix ---

run "traversal through an allowlisted prefix still triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/tmp/claude-501/../../etc/passwd"}}' 1

# --- Shell-expansion-prone tokens ($VAR, ~) are allowed, not flagged.
# Real usage overwhelmingly passes relative vault paths through variables (for-loop
# variables, config-derived paths, etc.). Flagging every variable reference as
# "unresolvable" makes the hook unusable. A variable that secretly holds an out-of-vault
# absolute path slips through -- accepted tradeoff (the agent is the caller, not an
# attacker).

run "dollar-prefixed token (shell variable) is allowed" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=$HOME/outside.md"}}' no

run "tilde-prefixed token is allowed" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=~/outside.md"}}' no

run "for-loop variable path is allowed" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"for p in Daily Notes/x.md; do obsidian create path=\"$p\"; done"}}' no

# --- Fix for finding #9: unparseable (unbalanced-quote) commands ask rather than mis-tokenizing ---

run "unbalanced quote in command triggers ask" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian create path=\\\"/etc/unclosed\"}}" 1

# --- Real-usage false positive: a piped command's unrelated argument must not be treated
# as an obsidian path candidate just because it starts with `/` and "obsidian" appears
# somewhere earlier in the same command string. ---

run "sed pattern argument after a pipe is not mistaken for an obsidian path" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian read path=\\\"Daily Notes/2026-07-29.md\\\" 2>&1 | sed -n '/Section A/,/Section B/p'\"}}" no

run "an out-of-root path in the obsidian segment of a pipeline still triggers ask" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian read path=/etc/passwd | sed -n '/x/p'\"}}" 1

# --- Heredoc false positive: a heredoc body that merely contains the substring
# "obsidian" (e.g. a `.obsidian/plugins/...` path) must NOT trigger a prompt when
# the `obsidian` CLI is not actually invoked. bashlex cannot parse quoted-delimiter
# heredocs (`<<'EOF'`), which previously turned every such command into
# parse_error -> ask. analyze_obsidian_command.py now strips heredoc operators
# and bodies before parsing, so the remaining command structure parses cleanly. ---

# Build multi-line heredoc commands with printf (avoids quoting/tab pitfalls),
# then wrap in a PreToolUse payload with jq so newlines are JSON-escaped properly.
HCMD_QUOTED=$(printf "python3 << 'EOF'\np = \".obsidian/plugins/x/data.json\"\nEOF\n")

run "quoted-heredoc body mentioning .obsidian but no obsidian CLI is allowed" 0 \
  "$(jq -nc --arg c "$HCMD_QUOTED" '{tool_name:"Bash",tool_input:{command:$c}}')" no

HCMD_UNQUOTED=$(printf "python3 << EOF\np = \".obsidian/plugins/x/data.json\"\nEOF\n")

run "unquoted-heredoc body mentioning .obsidian but no obsidian CLI is allowed" 0 \
  "$(jq -nc --arg c "$HCMD_UNQUOTED" '{tool_name:"Bash",tool_input:{command:$c}}')" no

HCMD_DASH=$(printf "python3 <<- 'EOF'\n\tp = \".obsidian/plugins/x/data.json\"\n\tEOF\n")

run "indented (<<-) heredoc body mentioning .obsidian but no obsidian CLI is allowed" 0 \
  "$(jq -nc --arg c "$HCMD_DASH" '{tool_name:"Bash",tool_input:{command:$c}}')" no

# Regression guard: a REAL obsidian invocation that also carries a heredoc must
# still be analyzed correctly -- the out-of-root path comes from the command
# word's own argument, not the stripped body, and must still prompt.
HCMD_OBSIDIAN=$(printf "obsidian create path=/etc/evil/x.md << 'EOF'\nignored body\nEOF\n")

run "obsidian invocation with an out-of-root path AND a heredoc still asks" 0 \
  "$(jq -nc --arg c "$HCMD_OBSIDIAN" '{tool_name:"Bash",tool_input:{command:$c}}')" 1

# --- Heredoc-stripper regressions found by code review (ce-code-review run
# 20260806-005749-45a71d34). These guard two bugs the strip preprocessor
# introduced and the safe fallback; they MUST stay green. ---

# comment-blindness (P1, was a silent-pass): a `<< EOF` written inside a bash
# comment must NOT be treated as a real heredoc, otherwise the genuine obsidian
# invocation on the next line is dropped as the comment's "body". The real
# out-of-root path must still be detected -> ask.
HCMD_COMMENT=$(printf 'obsidian read n.md # use << EOF to feed input\nobsidian create path=/etc/evil/x.md\nEOF')

run "a real obsidian out-of-root call after a comment containing << EOF still asks" 0 \
  "$(jq -nc --arg c "$HCMD_COMMENT" '{tool_name:"Bash",tool_input:{command:$c}}')" 1

# here-string `<<<` (P3, was a spurious ask): the here-string operator must not
# be mis-read as heredoc `<<`, even when a later bare line matches the word.
HCMD_HERESTR=$(printf 'obsidian read path=X.md <<< DONE\nDONE\necho done')

run "bash here-string (<<<) is not mistaken for a heredoc" 0 \
  "$(jq -nc --arg c "$HCMD_HERESTR" '{tool_name:"Bash",tool_input:{command:$c}}')" no

# unterminated heredoc -> safe fallback: the stripper returns the original
# command unchanged, bashlex then fails to parse it, and the hook asks. This
# guards that the best-effort fallback never silently allows.
HCMD_UNTERM=$(printf "obsidian read note.md << 'EOF'\nbody still going no close")

run "unterminated heredoc falls back to ask (never silent allow)" 0 \
  "$(jq -nc --arg c "$HCMD_UNTERM" '{tool_name:"Bash",tool_input:{command:$c}}')" 1

# post-heredoc command preserved: a real obsidian invocation that appears AFTER
# a closed heredoc must survive stripping and still be detected.
HCMD_POST=$(printf "cat << 'EOF'\nbody\nEOF\nobsidian create path=/etc/evil/x.md")

run "an obsidian out-of-root call after a closed heredoc still asks" 0 \
  "$(jq -nc --arg c "$HCMD_POST" '{tool_name:"Bash",tool_input:{command:$c}}')" 1

# --- Fix for finding #6/#7: missing dependency hard-blocks (deny) rather than silently allowing ---

MINIMAL_BIN_DIR=$(mktemp -d)
for tool in bash sh cat printf mktemp rm dirname basename env; do
  src=$(command -v "$tool" 2>/dev/null || true)
  [ -n "$src" ] && ln -sf "$src" "$MINIMAL_BIN_DIR/$tool"
done

set +e
out=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/etc/passwd"}}' \
  | CLAUDE_PROJECT_DIR="$ROOT_DIR" PATH="$MINIMAL_BIN_DIR" bash "$HOOK" 2>/tmp/tgap-stderr-nodeps-$$)
actual_exit=$?
set -e
err=$(cat "/tmp/tgap-stderr-nodeps-$$" 2>/dev/null || true)
rm -f "/tmp/tgap-stderr-nodeps-$$"
rm -rf "$MINIMAL_BIN_DIR"

if [ "$actual_exit" = "2" ]; then
  echo "PASS: missing jq/python3 hard-blocks (deny) instead of silently allowing"
  PASS=$((PASS + 1))
else
  echo "FAIL: missing jq/python3 -- expected exit 2 (deny), got $actual_exit (stderr: $err)"
  FAIL=$((FAIL + 1))
fi

# jq and python3 present, but `uv` (needed for the bashlex-based analysis) absent.
NO_UV_BIN_DIR=$(mktemp -d)
for tool in bash sh cat printf mktemp rm dirname basename env jq python3; do
  src=$(command -v "$tool" 2>/dev/null || true)
  [ -n "$src" ] && ln -sf "$src" "$NO_UV_BIN_DIR/$tool"
done

set +e
out=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/etc/passwd"}}' \
  | CLAUDE_PROJECT_DIR="$ROOT_DIR" PATH="$NO_UV_BIN_DIR" bash "$HOOK" 2>/tmp/tgap-stderr-nouv-$$)
actual_exit=$?
set -e
err=$(cat "/tmp/tgap-stderr-nouv-$$" 2>/dev/null || true)
rm -f "/tmp/tgap-stderr-nouv-$$"
rm -rf "$NO_UV_BIN_DIR"

if [ "$actual_exit" = "2" ]; then
  echo "PASS: missing uv hard-blocks (deny) instead of silently allowing"
  PASS=$((PASS + 1))
else
  echo "FAIL: missing uv -- expected exit 2 (deny), got $actual_exit (stderr: $err)"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "guard-absolute-path.sh: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
