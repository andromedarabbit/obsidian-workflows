# Recovery Test: Rollback

## Objective

Validate rollback restores previous working flow if cutover regressions occur.

## Steps

1. Simulate cutover failure condition.
2. Execute rollback playbook steps.
3. Re-run workflow smoke commands.

## Expected

- Legacy flow returns to known-good behavior.
- State continuity restored from snapshot.
- Validation commands succeed within one session.
