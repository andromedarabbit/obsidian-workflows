# Smoke Test: Plan Passive Flow

## Objective

Verify the passive plan flow is deterministic both when passive is explicit and when `--intent` is omitted.

## Steps

1. Ensure vault runtime profile is configured.
2. Run `/obsidian-workflows:ow:plan --intent passive`.
3. Verify proposal output path and idea list rendering.
4. Run `/obsidian-workflows:ow:plan` with omitted `--intent` and no free-form writing request.
5. Verify it follows the same passive branch behavior without showing an intent-selection prompt.
6. Run `/obsidian-workflows:ow:plan 팀스탠드업을 작성하자`.
7. Verify the free-form writing request routes to the active branch without showing an intent-selection prompt.

## Expected

- Explicit passive and blank omitted-intent runs both resolve to the passive branch.
- Omitted-intent free-form writing requests resolve to the active branch.
- No intent-selection prompt appears when `--intent` is omitted.
- If `external_tools.auto_use: ask`, any prompt that appears is only for external-tool usage, not intent selection.
- Passive status is `PASS` or `SKIP` (empty candidate case).
- Handoff is presented through the expected 4-option menu, not a next-step command string.
- No silent fallback.
