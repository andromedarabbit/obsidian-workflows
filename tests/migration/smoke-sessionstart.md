# Smoke Test: SessionStart Autorun

## Objective

Verify SessionStart hook triggers `/obsidian:write.autorun --trigger session-start` in the migrated plugin setup.

## Steps

1. Apply `.claude/settings.local.json.example` as local settings.
2. Start a fresh Claude Code session.
3. Confirm autorun command invocation (log or state change).

## Expected

- Hook executes once per session.
- No crash if command returns non-zero.
- Runtime state updated or skip recorded consistently.
