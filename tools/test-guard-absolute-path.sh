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
#   expect_ask=1 asserts stdout contains permissionDecision":"ask"
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
  if [ "$expect_ask" = "1" ]; then
    if ! printf '%s' "$out" | grep -q '"permissionDecision": *"ask"'; then
      echo "FAIL: $name -- expected stdout permissionDecision:ask, got: $out"
      FAIL=$((FAIL + 1))
      return
    fi
  fi
  echo "PASS: $name"
  PASS=$((PASS + 1))
}

# --- Baseline pass-through cases (exit 0, no ask) ---

run "non-Bash tool_name is ignored" 0 \
  '{"tool_name":"Read","tool_input":{"file_path":"/etc/passwd"}}'

run "Bash command without obsidian is ignored" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"git status"}}'

run "obsidian create in-vault relative path is allowed" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian create path=\\\"Daily Notes/2026-07-28.md\\\"\"}}"

run "obsidian create against an allowlisted scratch path is allowed" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=/tmp/claude-501/scratch.md"}}'

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

# --- Fix for finding #5: shell-expansion-prone tokens ask rather than being silently dropped ---

run "dollar-prefixed token (shell expansion) triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=$HOME/outside.md"}}' 1

run "tilde-prefixed token triggers ask" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"obsidian create path=~/outside.md"}}' 1

# --- Fix for finding #9: unparseable (unbalanced-quote) commands ask rather than mis-tokenizing ---

run "unbalanced quote in command triggers ask" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian create path=\\\"/etc/unclosed\"}}" 1

# --- Real-usage false positive: a piped command's unrelated argument must not be treated
# as an obsidian path candidate just because it starts with `/` and "obsidian" appears
# somewhere earlier in the same command string. ---

run "sed pattern argument after a pipe is not mistaken for an obsidian path" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian read path=\\\"Daily Notes/2026-07-29.md\\\" 2>&1 | sed -n '/Section A/,/Section B/p'\"}}"

run "an out-of-root path in the obsidian segment of a pipeline still triggers ask" 0 \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"obsidian read path=/etc/passwd | sed -n '/x/p'\"}}" 1

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
