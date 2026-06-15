# Cutover Checklist

## Pre-cutover

- [ ] Confirm dedicated repo has canonical commands/skills/plugin metadata
- [ ] Confirm contracts docs exist (`docs/contracts/*`)
- [ ] Confirm runtime docs exist (`docs/runtime/*`)
- [ ] Snapshot vault runtime state files
- [ ] Prepare user-facing migration notice

## Cutover steps

- [ ] Point plugin source/install workflow to dedicated repo
- [ ] Apply updated local settings from `.claude/settings.local.json.example` <!-- 미반영: settings example은 생성되지 않음. 로컬 설정은 `.claude/settings.local.json`을 직접 사용 -->
- [ ] Verify command discovery from `commands`
- [ ] Execute smoke flows: plan passive, work draft, review

## Post-cutover validation window

- [ ] Monitor first session-start autorun <!-- 제거됨: session-start 자동 트리거는 이 저장소에 배선되지 않음. autorun은 명시 호출 전용 -->
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
- [ ] SessionStart autorun regression persists after one retry <!-- 제거됨: session-start 자동 트리거는 이 저장소에 배선되지 않음. autorun은 명시 호출 전용 -->
- [ ] Path safety mismatch across entrypoints
