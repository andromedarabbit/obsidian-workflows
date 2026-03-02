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

- Run session-start autorun once
- Run `/obsidian-workflows:plan --intent passive`
- Confirm status semantics (`PASS|SKIP|FAIL`) unchanged

## Rollback Trigger

If state continuity fails (e.g., guard regression, parse errors), restore snapshot and revert to previous runtime profile.
