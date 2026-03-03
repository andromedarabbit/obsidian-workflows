# Runtime State Schema

## Files

- `.claude/state/obsidian-write-passive.json`
- `.claude/state/obsidian-write-scan-latest.json`

## Versioning

Include `schema_version` key for forward-compatible migrations.

## Passive state fields

- `schema_version`
- `last_propose_run_at`
- `last_scan_window_start`
- `last_scan_window_end`
- `last_proposal_note`
- `last_status`
- `last_message`

## Scan-latest state fields

- `schema_version`
- `command`
- `anchor`
- `scanned_paths`
- `exclude_paths`
- `candidate_count`
- `candidates`
- `timestamp`

## Constraints

- Keep JSON schema stable and additive where possible
- Preserve backward compatibility for known keys
- Fail fast on malformed state file parse

## Git and lifecycle policy

- `.claude/state/obsidian-write-passive.json` is runtime state for passive/autorun orchestration.
- It is gitignored and should not be committed as content.
- The committed contract surface is command/policy/template docs, not runtime state snapshots.
