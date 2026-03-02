# Rollback Playbook

## Trigger Conditions

Initiate rollback if any of the following occur during validation window:

- Command discovery failure for canonical workflow entrypoints
- SessionStart autorun regression
- State parse/continuity failures
- Path safety bypass or inconsistent enforcement

## Rollback Procedure

1. Revert plugin source pointer to previous known-good location
2. Restore pre-cutover runtime state snapshots
3. Restore previous local settings/hook configuration
4. Re-run smoke checks on previous environment

## Smoke Checks After Rollback

- `/obsidian-workflows:plan --intent passive`
- `/obsidian-workflows:work mode=draft ...`
- `/obsidian-workflows:review ...`

## Communication

- Announce rollback start with reason
- Announce rollback complete with restored version
- Record incident notes and required fixes before next cutover attempt

## Recovery Criteria

- Legacy flow operates as before cutover
- No unresolved data/state corruption
- Clear owner and plan for remediation
