# Smoke Test: Plan Passive Flow

## Objective

Verify `/obsidian-workflows:plan --intent passive` runs scan -> propose and returns deterministic next-step output.

## Steps

1. Ensure vault runtime profile is configured.
2. Run `/obsidian-workflows:plan --intent passive`.
3. Verify proposal output path and idea list rendering.

## Expected

- Status is `PASS` or `SKIP` (empty candidate case).
- Next-step command is emitted in expected format.
- No silent fallback.
