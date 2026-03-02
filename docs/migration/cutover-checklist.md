# Cutover Checklist

## Pre-cutover

- [ ] Confirm dedicated repo has canonical commands/skills/plugin metadata
- [ ] Confirm contracts docs exist (`docs/contracts/*`)
- [ ] Confirm runtime docs exist (`docs/runtime/*`)
- [ ] Snapshot vault runtime state files
- [ ] Prepare user-facing migration notice

## Cutover steps

- [ ] Point plugin source/install workflow to dedicated repo
- [ ] Apply updated local settings from `.claude/settings.local.json.example`
- [ ] Verify command discovery from `.claude/commands`
- [ ] Execute smoke flows: plan passive, work draft, review

## Post-cutover validation window

- [ ] Monitor first session-start autorun
- [ ] Validate status output contracts
- [ ] Validate path safety failures are fail-fast

## Exit criteria (Go/No-Go)

### Go

- [ ] No command discovery regressions
- [ ] No state continuity regressions
- [ ] No namespace confusion incidents in validation window
- [ ] Smoke scenarios under `tests/migration/*.md` all pass

### No-Go / Hold

- [ ] Any fail-fast contract regression detected
- [ ] SessionStart autorun regression persists after one retry
- [ ] Path safety mismatch across entrypoints
