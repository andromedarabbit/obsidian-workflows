# obsidian-workflows

[![Validate Commands](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/validate.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/validate.yml)
[![Lint](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/lint.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/lint.yml)
[![Generate Documentation](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/generate-docs.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/generate-docs.yml)

Obsidian writing workflows plugin for Claude Code.

## Purpose

This repository is the dedicated home for the plugin core:

- Claude command definitions (`commands/...`)
- Claude skill definitions (`.claude/skills/...`)
- Plugin metadata (`.claude-plugin/...`)
- Migration/runtime/contracts docs (`docs/...`)
- Validation infrastructure (`tools/`, `.github/workflows/`)

Vault content (notes, drafts, proposals, archives) stays in your Obsidian vault and is resolved via `writing-config.md` path contracts.

## Repository Layout

```text
.claude/
  commands/
  skills/
  state/
.claude-plugin/
config/
assets/
docs/
```

## Migration Goal

Move plugin implementation from vault-coupled layout into this dedicated repository while preserving:

- fail-fast behavior
- path safety contracts
- deterministic workflow routing
- runtime state continuity

See `docs/migration/` for checklists and rollout details.

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- Obsidian vault with writing workflow setup

### Install via Marketplace (Recommended)

```bash
/plugin marketplace add andromedarabbit/obsidian-workflows
/plugin install obsidian-workflows@andromedarabbit
```

### Install via npx skills

```bash
npx skills add git@github.com:kepano/obsidian-workflows.git
```

### Manual Installation

Add the contents of this repository to a `/.claude` folder in the root of your Obsidian vault (or whichever folder you're using with Claude Code).

```bash
cd /path/to/your/obsidian-vault
git clone https://github.com/kepano/obsidian-workflows.git .claude
```

See the [official Claude Skills documentation](https://code.claude.com/docs) for more details.

### Configuration

Configure vault paths in your Obsidian vault's `writing-config.md`:

```markdown
# Writing Configuration

source_paths:
  - /path/to/vault/sources

draft_path: /path/to/vault/drafts
final_path: /path/to/vault/finals
proposal_path: /path/to/vault/proposals
```

### Available Skills

- `/plan` - Plan writing workflow (active/passive modes)
- `/work` - Execute writing tasks (active/passive/draft/refine/route)
- `/review` - Review content quality (policy/style checks)
- `/compound` - Capture learning points from completed work

### Configuration Files

- `config/writing-config.example.md` - Example vault configuration
- `assets/SOUL.md` - Writing style template
- `assets/policy.md` - Channel-specific policies

## Development

### Prerequisites

- Node.js 20+ (for validation scripts)
- Python 3.8+ (for pre-commit hooks)
- Bash 3.2+ (for shell scripts)

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/kepano/obsidian-workflows.git
   cd obsidian-workflows
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Install pre-commit hooks** (optional but recommended):
   ```bash
   pip install pre-commit
   pre-commit install
   ```

### Validation

Run validators locally before committing:

```bash
# Shell validators
./tools/check-frontmatter.sh      # Check frontmatter fields
./tools/validate-command.sh       # Validate command structure
./tools/validate-hook-paths.sh    # Verify hook paths

# Node.js validators
npm run validate:commands         # Validate frontmatter
npm run validate:no-duplicates    # Check for duplicate names
npm run lint:frontmatter          # Lint YAML syntax
npm run lint:markdown             # Lint markdown files

# Run all validations
npm run validate:all
```

### Generate Documentation

Update the command index:

```bash
./tools/generate-index.sh
```

This generates `COMMANDS.md` from command frontmatter.

### Creating New Commands

Use the interactive command generator:

```bash
./template/create-command.sh
```

This will:
1. Prompt for command metadata
2. Validate name format and check for duplicates
3. Generate command file with proper frontmatter
4. Set correct permissions

### Pre-commit Hooks

Pre-commit hooks automatically run validation before commits:

- Check YAML syntax
- Fix trailing whitespace
- Validate command frontmatter
- Validate command structure
- Generate command index
- Fix shell script permissions

To run manually:

```bash
pre-commit run --all-files
```

### CI/CD

GitHub Actions workflows validate all changes:

- **Validate Commands** - Runs on PR and push to main
  - Validates frontmatter fields
  - Checks command structure
  - Verifies hook paths

- **Lint** - Runs on PR and push to main
  - Lints markdown files
  - Lints YAML files
  - Validates frontmatter YAML

- **Generate Documentation** - Runs on PR and push to main
  - Generates COMMANDS.md
  - Checks for uncommitted changes

## Documentation

- [Command Specification](docs/command-specification.md) - Command contract definition
- [Frontmatter Reference](docs/frontmatter-reference.md) - Field specifications and validation rules
- [Hook Patterns](docs/hook-patterns.md) - Best practices for hook scripts
- [Naming Conventions](docs/naming-conventions.md) - Naming standards for commands, files, and commits
- [Validation Guide](docs/validation-guide.md) - How to run validators and fix common issues

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run validation (`npm run validate:all`)
5. Commit your changes (`git commit -m 'feat: add new feature'`)
6. Push to the branch (`git push origin feature/my-feature`)
7. Open a Pull Request

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

Examples:
```
feat(commands): add obsidian:write.scan command
fix(validation): handle missing frontmatter gracefully
docs(hooks): add hook patterns documentation
```

## Core Principles

From [CLAUDE.md](CLAUDE.md):

1. **Fail fast over silent fallback** - Exit immediately on critical errors
2. **Enforce path safety consistently** - All hook paths must start with `commands/`
3. **Keep command discovery deterministic** - Single canonical source per command name
4. **Preserve PASS|SKIP|FAIL status semantics** - Consistent status reporting
5. **No absolute path assumptions** - Use relative paths in contracts
6. **No global runtime state dependencies** - Don't rely on `~/.claude/*` for correctness
7. **No duplicate command definitions** - Enforce unique command names
