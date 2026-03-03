# Path Resolution Contract

## Intent

All runtime paths are resolved through vault-side configuration, not hardcoded repository absolute paths.

## Configuration Source

- Operational source: vault `writing-config.md`
- Repository side: `config/writing-config.example.md` as reference template

## Resolution Order

1. Explicit per-path value (`policy_dir`, `soul_path`, `proposal_path`, etc.)
2. Derived default from `workflow_base_path`

## Required Runtime Paths

- `policy_dir`
- `soul_path`
- `research_path`
- `draft_path`
- `archive_path`
- `final_path`
- `proposal_path`

## Policy-driven path keys (optional but required by selected policy)

When a selected policy template requires specific runtime keys, those keys become required at execution time.

Examples:
- `daily_notes_path` (used when `source_strategy: previous-note`)
- `daily_note_template` (used when `template_engine: templater`)

The command layer must fail fast if a policy-required path key is missing.

## Guardrails

- No absolute path assumptions in command contracts
- Missing required path config should fail fast
- Keep path parsing deterministic and side-effect free
