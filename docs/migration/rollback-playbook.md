# Rollback Playbook

## Trigger Conditions

Initiate rollback if any of the following occur during validation window:

- Command discovery failure for canonical workflow entrypoints
- SessionStart autorun regression <!-- 제거됨: session-start 자동 트리거는 이 저장소에 배선되지 않음. autorun은 명시 호출 전용 -->
- State parse/continuity failures
- Path safety bypass or inconsistent enforcement

## Rollback Procedure

1. Revert plugin source pointer to previous known-good location
2. Restore pre-cutover runtime state snapshots
3. Restore previous local settings/hook configuration
4. Re-run smoke checks on previous environment

## Smoke Checks After Rollback

- `/obsidian-workflows:ow:plan --intent passive`
- `/obsidian-workflows:ow:work mode=draft ...`
- `/obsidian-workflows:ow:review ...`

## Communication

- Announce rollback start with reason
- Announce rollback complete with restored version
- Record incident notes and required fixes before next cutover attempt

## Recovery Criteria

- Legacy flow operates as before cutover
- No unresolved data/state corruption
- Clear owner and plan for remediation
