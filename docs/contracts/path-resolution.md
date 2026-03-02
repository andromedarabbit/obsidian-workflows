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

## Guardrails

- No absolute path assumptions in command contracts
- Missing required path config should fail fast
- Keep path parsing deterministic and side-effect free
