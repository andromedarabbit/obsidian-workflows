# CLAUDE.md

This repository contains the **plugin core** for Obsidian writing workflows.

## Scope

- Keep this repository focused on command/skill/plugin contracts and migration/runtime docs.
- Do not mix user vault content into this repository.
- Runtime/user content paths must be resolved via configuration contracts, not hardcoded vault paths.

## Core Principles

- Fail fast over silent fallback.
- Enforce path safety consistently across all file/path inputs.
- Keep command discovery deterministic (single canonical source per command name).
- Preserve `PASS|SKIP|FAIL` status semantics across entrypoints.

## Structure

- `commands/`: command definitions (canonical source)
- `.claude/skills/`: skills and entrypoint guidance
- `.claude-plugin/`: plugin metadata
- `config/`: example configuration templates
- `assets/`: template assets (SOUL/policy)
- `docs/`: migration/contracts/runtime documentation
- `tools/`: validation scripts
- `.github/workflows/`: CI/CD automation

## Validation Infrastructure

This repository uses comprehensive validation to enforce quality gates:

### Local Validation

Run validators before committing:

```bash
# Shell validators
./tools/check-frontmatter.sh      # Validate frontmatter fields
./tools/validate-command.sh       # Validate command structure
./tools/validate-hook-paths.sh    # Verify hook paths

# Node.js validators
npm run validate:all              # Run all validations
```

### Pre-commit Hooks

Automatic validation on commit:

```bash
pip install pre-commit
pre-commit install
```

### CI/CD

GitHub Actions workflows validate all changes on PR and push to main.

See [Validation Guide](docs/validation-guide.md) for details.

## Guardrails

- No absolute path assumptions in command contracts.
- No dependency on global runtime state (`~/.claude/*`) for correctness.
- No duplicate command definitions with the same canonical `name`.
- All hook paths must start with `commands/`.

## Documentation

- [Command Specification](docs/command-specification.md) - Command contract definition
- [Frontmatter Reference](docs/frontmatter-reference.md) - Field specifications
- [Hook Patterns](docs/hook-patterns.md) - Best practices for hooks
- [Naming Conventions](docs/naming-conventions.md) - Naming standards
- [Validation Guide](docs/validation-guide.md) - Validation and troubleshooting
