# Repository Structure

This document describes the organization and purpose of directories and files in the obsidian-workflows repository.

## Directory Layout

```text
obsidian-workflows/
├── .claude/                    # Claude Code local/runtime files
│   ├── settings.local.json    # Local settings (not committed)
│   └── state/                 # Runtime state (not committed)
├── .claude-plugin/            # Plugin metadata
├── .github/                   # GitHub configuration
│   └── workflows/             # CI/CD workflows
├── assets/                    # Template assets
│   ├── SOUL.md               # Writing style template
│   └── policy.md             # Channel-specific policies
├── commands/                   # Command definitions (canonical source)
├── config/                    # Configuration templates
│   └── writing-config.example.md
├── docs/                      # Documentation
│   ├── command-specification.md
│   ├── frontmatter-reference.md
│   ├── hook-patterns.md
│   ├── naming-conventions.md
│   ├── policy-specification.md
│   ├── repository-structure.md (this file)
│   ├── skill-specification.md
│   └── validation-guide.md
├── skills/                     # Skill definitions (canonical source)
├── tools/                     # Validation and utility scripts
│   ├── check-frontmatter.sh
│   ├── check-skill-frontmatter.sh
│   ├── validate-command.sh
│   ├── validate-hook-paths.sh
│   └── generate-index.sh
├── template/                  # Code generation templates
│   └── create-command.sh
├── CLAUDE.md                  # Project instructions for Claude
├── CONTRIBUTING.md            # Contribution guidelines
├── README.md                  # User-facing documentation
└── package.json              # Node.js dependencies and scripts
```

## Directory Purposes

### `.claude/`
Claude Code local/runtime files. Commands and skills live at the top-level `commands/` and `skills/` directories, not under `.claude/` — see those entries below.

- **`settings.local.json`**: Local Claude Code settings (not committed to git).
- **`state/`**: Runtime state directory (not committed to git). Used for temporary workflow state.

### `commands/`
Canonical source for command definitions. Each command is a markdown file with frontmatter and implementation details. See [Command Specification](./command-specification.md).

### `skills/`
Canonical source for skill definitions. Each skill is a `SKILL.md` file under `skills/<name>/`. See [Skill Specification](./skill-specification.md).

### `.claude-plugin/`
Plugin metadata for Claude Code plugin system. Contains plugin manifest and configuration.

### `.github/workflows/`
CI/CD automation using GitHub Actions:
- `validate.yml`: Validates command structure and frontmatter
- `lint.yml`: Lints markdown and YAML files
- `generate-docs.yml`: Generates command index documentation

### `assets/`
Template assets used by the writing workflows:
- **`SOUL.md`**: Writing style guide template
- **`policy.md`**: Channel-specific content policies

### `config/`
Configuration file templates:
- **`writing-config.example.md`**: Example vault configuration showing required path contracts

### `docs/`
Comprehensive documentation for developers and contributors:
- **`command-specification.md`**: Command contract definition
- **`frontmatter-reference.md`**: Field specifications and validation rules (commands)
- **`skill-specification.md`**: Skill contract definition
- **`hook-patterns.md`**: Best practices for hook scripts
- **`naming-conventions.md`**: Naming standards for commands, skills, files, and commits
- **`policy-specification.md`**: Writing policy schema (frontmatter fields, body structure, config registration) — the SSOT for policies
- **`repository-structure.md`**: This file
- **`validation-guide.md`**: How to run validators and fix common issues

### `tools/`
Validation and utility scripts:
- **`check-frontmatter.sh`**: Validates frontmatter fields in commands
- **`check-skill-frontmatter.sh`**: Validates frontmatter fields in skills
- **`validate-command.sh`**: Validates command structure and contracts
- **`validate-hook-paths.sh`**: Verifies hook paths follow safety rules
- **`generate-index.sh`**: Generates COMMANDS.md from command frontmatter

### `template/`
Code generation templates:
- **`create-command.sh`**: Interactive command generator

## Path Contracts

### Command Discovery
Commands are discovered from the canonical source: `commands/`

Each command file must:
- Be a markdown file with valid frontmatter
- Have a unique `name` field
- Follow naming conventions
- Have hook paths starting with `commands/`

### Vault Content Paths
User vault content (notes, drafts, proposals) is NOT stored in this repository. Paths are resolved via `writing-config.md` in the user's Obsidian vault:

```markdown
# Writing Configuration

source_paths:
  - /path/to/vault/sources

draft_path: /path/to/vault/drafts
final_path: /path/to/vault/finals
proposal_path: /path/to/vault/proposals
```

### No Absolute Paths
All internal paths use relative references. No hardcoded absolute paths in command contracts or scripts.

### No Global State Dependencies
Commands do not rely on `~/.claude/*` for correctness. All required state is passed explicitly or resolved via configuration contracts.

## File Organization Conventions

### Command Files
- Location: `commands/`
- Format: Markdown with YAML frontmatter
- Naming: `category:action.md` (e.g., `write-scan.md`)

### Skill Files
- Location: `skills/<name>/SKILL.md`
- Format: Markdown with YAML frontmatter (see [Skill Specification](./skill-specification.md))
- Naming: `<name>` MUST equal the skill's directory name (e.g., `skills/plan/SKILL.md` has `name: plan`)

### Documentation Files
- Location: `docs/`
- Format: Markdown
- Naming: Kebab-case (e.g., `command-specification.md`)

### Script Files
- Location: `tools/` or `template/`
- Format: Shell scripts (`.sh`)
- Permissions: Executable (`chmod +x`)

## Migration Notes

This repository structure supports migration from vault-coupled layout to dedicated plugin repository while preserving:

- Fail-fast behavior
- Path safety contracts
- Deterministic workflow routing
- Runtime state continuity

See `docs/migration/` for detailed migration checklists and rollout plans.
