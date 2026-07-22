# State Migration Checklist

## Objective

Preserve passive/scan continuity when moving plugin runtime from vault-coupled layout to dedicated plugin repo contracts.

## Checklist

- [ ] Snapshot existing state files before cutover
- [ ] Validate JSON parse and required keys
- [ ] Inject `schema_version` when missing
- [ ] Carry forward timestamps/anchors without mutation
- [ ] Verify first post-cutover passive run preserves daily guard behavior
- [ ] Verify scan output still honors configured `exclude_paths`

## Validation Commands (manual)

- Run session-start autorun once <!-- 제거됨: session-start 자동 트리거는 이 저장소에 배선되지 않음. autorun은 명시 호출 전용 -->
- Run `/obsidian-workflows:ow-plan --intent passive`
- Confirm status semantics (`PASS|SKIP|FAIL`) unchanged

## Rollback Trigger

If state continuity fails (e.g., guard regression, parse errors), restore snapshot and revert to previous runtime profile.
