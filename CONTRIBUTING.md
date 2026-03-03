# Contributing to obsidian-workflows

Thank you for your interest in contributing to obsidian-workflows! This guide will help you set up your development environment and understand our contribution workflow.

## Development Prerequisites

- Node.js 20+ (for validation scripts)
- Python 3.8+ (for pre-commit hooks)
- Bash 3.2+ (for shell scripts)
- Git

## Setup

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/obsidian-workflows.git
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

## Validation Workflow

Run validators locally before committing to ensure your changes meet quality standards:

### Shell Validators

```bash
./tools/check-frontmatter.sh      # Check frontmatter fields
./tools/validate-command.sh       # Validate command structure
./tools/validate-hook-paths.sh    # Verify hook paths
```

### Node.js Validators

```bash
npm run validate:commands         # Validate frontmatter
npm run validate:no-duplicates    # Check for duplicate names
npm run lint:frontmatter          # Lint YAML syntax
npm run lint:markdown             # Lint markdown files
```

### Run All Validations

```bash
npm run validate:all
```

## Creating New Commands

Use the interactive command generator to create new commands with proper structure:

```bash
./template/create-command.sh
```

This will:
1. Prompt for command metadata
2. Validate name format and check for duplicates
3. Generate command file with proper frontmatter
4. Set correct permissions

## Pre-commit Hooks

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

## Generate Documentation

Update the command index after adding or modifying commands:

```bash
./tools/generate-index.sh
```

This generates `COMMANDS.md` from command frontmatter.

## CI/CD

GitHub Actions workflows validate all changes on PR and push to main:

### Validate Commands Workflow
- Validates frontmatter fields
- Checks command structure
- Verifies hook paths

### Lint Workflow
- Lints markdown files
- Lints YAML files
- Validates frontmatter YAML

### Generate Documentation Workflow
- Generates COMMANDS.md
- Checks for uncommitted changes

All workflows must pass before merging.

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

### Examples

```
feat(commands): add obsidian:write.scan command
fix(validation): handle missing frontmatter gracefully
docs(hooks): add hook patterns documentation
chore(deps): update dependencies
ci(workflows): add validation workflow
```

## Pull Request Process

1. **Fork the repository** and create a feature branch:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** following the coding standards

3. **Run validation**:
   ```bash
   npm run validate:all
   ```

4. **Commit your changes** with conventional commit messages:
   ```bash
   git commit -m 'feat: add new feature'
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/my-feature
   ```

6. **Open a Pull Request** against the `main` branch

7. **Address review feedback** if requested

## Coding Standards

### Command Structure

- All commands must have valid frontmatter
- Hook paths must start with `commands/`
- Command names must be unique
- Follow naming conventions in [docs/naming-conventions.md](docs/naming-conventions.md)

### Path Safety

- Use relative paths in contracts
- No absolute path assumptions
- All file/path inputs must be validated

### Error Handling

- Fail fast over silent fallback
- Exit immediately on critical errors
- Preserve `PASS|SKIP|FAIL` status semantics

### Documentation

- Update relevant documentation when adding features
- Keep examples up to date
- Document breaking changes clearly

## Core Principles

From [CLAUDE.md](CLAUDE.md):

1. **Fail fast over silent fallback** - Exit immediately on critical errors
2. **Enforce path safety consistently** - All hook paths must start with `commands/`
3. **Keep command discovery deterministic** - Single canonical source per command name
4. **Preserve PASS|SKIP|FAIL status semantics** - Consistent status reporting
5. **No absolute path assumptions** - Use relative paths in contracts
6. **No global runtime state dependencies** - Don't rely on `~/.claude/*` for correctness
7. **No duplicate command definitions** - Enforce unique command names

## Getting Help

- Check existing [documentation](docs/)
- Review [validation guide](docs/validation-guide.md) for common issues
- Open an issue for questions or problems
- Join discussions in pull requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
