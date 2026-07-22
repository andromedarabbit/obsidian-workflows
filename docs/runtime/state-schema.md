# Runtime State Schema

## Files

- `.claude/state/obsidian-write-passive.json`
- `.claude/state/obsidian-write-scan-latest.json`
- `.claude/state/obsidian-write-active-handoff.json`

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

## Active handoff state fields

`.claude/state/obsidian-write-active-handoff.json` records a pending active-mode plan that has been deferred to a later `/obsidian-workflows:ow-work` invocation. It is the active-branch counterpart to passive-branch proposal files.

- `schema_version`
- `created_at` — ISO 8601 with timezone offset
- `source` — originating skill (e.g., `ow-plan`)
- `target_mode` — always `active` for this file
- `topic` — string, may be empty when policy's `topic_required: false`
- `policy` — policy name
- `extra_args` — object; pass-through args for downstream `write-active`
- `status` — `pending` | `consumed`

Status transitions:

- `pending`: handoff saved by `ow-plan`, awaiting `ow-work`
- `consumed`: `ow-work` has read the file and started execution; the file persists with `consumed` until the next plan handoff overwrites it

Concurrency: this file is a single-slot store, not a queue. When `ow-plan` saves a new handoff while a previous `pending` handoff has not been consumed, the file is overwritten — latest wins, the earlier handoff is permanently lost. Callers needing a queue of pending plans should manage their own ordering at a higher layer.

## Constraints

- Keep JSON schema stable and additive where possible
- Preserve backward compatibility for known keys
- Fail fast on malformed state file parse

## Git and lifecycle policy

- `.claude/state/obsidian-write-passive.json` is runtime state for passive/autorun orchestration.
- `.claude/state/obsidian-write-active-handoff.json` is runtime state for active-mode plan handoffs.
- Both are gitignored and should not be committed as content.
- The committed contract surface is command/policy/template docs, not runtime state snapshots.
