# Smoke Test: Plan Passive Flow

## Objective

Verify the passive plan flow is deterministic both when passive is explicit and when `--intent` is omitted.

## Steps

1. Ensure vault runtime profile is configured.
2. Run `/obsidian-workflows:plan --intent passive`.
3. Verify proposal output path and idea list rendering.
4. Run `/obsidian-workflows:plan` with omitted `--intent`.
5. Verify it follows the same passive branch behavior without showing an intent-selection prompt.

## Expected

- Explicit passive and omitted-intent runs both resolve to the passive branch.
- No intent-selection prompt appears when `--intent` is omitted.
- If `external_tools.auto_use: ask`, any prompt that appears is only for external-tool usage, not intent selection.
- Status is `PASS` or `SKIP` (empty candidate case).
- Next-step command is emitted in expected format.
- No silent fallback.
