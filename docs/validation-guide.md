# Validation Guide

How to run validators locally and in CI, interpret errors, and fix common issues.

## Overview

The obsidian-workflows repository uses multiple validation layers to ensure command quality:

1. **Shell-based validators** - Fast, portable validation scripts
2. **Node.js validators** - Advanced parsing and analysis
3. **Pre-commit hooks** - Automatic validation before commits
4. **GitHub Actions** - CI/CD validation on pull requests

## Local Validation

### Recommended entrypoints

Use the root `Makefile` as the main discovery and execution interface:

```bash
make help
make validate-fast
make validate-ci
```

- `make validate-fast` runs the quick local path for command/frontmatter/hook-path checks.
- `make validate-ci` runs the PR-ready path that mirrors the main locally reproducible CI checks.

### Quick Validation

Run the fast local validation path:

```bash
make validate-fast
```

This currently runs:

```bash
./tools/check-frontmatter.sh
./tools/validate-command.sh
./tools/validate-hook-paths.sh
```

### Individual Validators

#### Frontmatter Validation

Checks required fields, formats, and duplicate names:

```bash
./tools/check-frontmatter.sh
```

**What it checks**:
- Required fields present (name, description, argument-hint, allowed-tools, created, updated)
- Date formats (ISO 8601)
- Name format (kebab-case)
- Duplicate command names

#### Structure Validation

Validates command structure and path safety:

```bash
./tools/validate-command.sh
```

**What it checks**:
- Path safety (no absolute paths, no `~/.claude/*`)
- Status semantics (PASS|SKIP|FAIL usage)
- Hook script permissions
- ShellCheck validation (if available)

#### Hook Path Validation

Verifies hook paths start with `commands/`:

```bash
./tools/validate-hook-paths.sh
```

**What it checks**:
- Hook paths start with `commands/`
- Referenced files exist

#### Generate Index

Creates COMMANDS.md from frontmatter:

```bash
./tools/generate-index.sh
```

**Output**: `COMMANDS.md` with categorized command list

### PR-ready Validation

Run the CI-parity local validation path before opening a PR:

```bash
make validate-ci
```

This path covers:

- fast shell validators
- command frontmatter validation
- duplicate and namespace validation
- frontmatter YAML lint
- markdown lint
- `COMMANDS.md` freshness
- workflow YAML syntax validation

### Node.js Validators

Markdown lint config source of truth:

- Rule config (`MDxxx`) is managed in `.markdownlint.json`.
- `.markdownlint-cli2.jsonc` is used only for CLI2 runner options like `globs` and `ignores`.

Install dependencies first:

```bash
npm install
```

Then run validators:

```bash
# Validate command frontmatter
npm run validate:commands

# Check duplicate command names + command/skill collisions + legacy command layout
npm run validate:no-duplicates

# Lint frontmatter YAML
npm run lint:frontmatter

# Lint markdown
npm run lint:markdown

# Fast local path
npm run validate:fast

# Workflow YAML syntax validation
npm run validate:workflows

# COMMANDS.md freshness validation
npm run validate:generated

# Run the CI-parity path
npm run validate:ci
```

## Pre-commit Hooks

### Setup

Install pre-commit hooks:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks
pre-commit install
```

### Usage

Hooks run automatically on `git commit`:

```bash
git add commands/my-command.md
git commit -m "Add new command"
# Hooks run automatically
```

Run manually on all files:

```bash
pre-commit run --all-files
```

Run specific hook:

```bash
pre-commit run check-command-frontmatter
```

### Configured Hooks

- `check-yaml` - Validate YAML syntax (excluding `.github/workflows/`; use `make validate-workflows` for local workflow checks when workflow files change)
- `end-of-file-fixer` - Ensure files end with newline
- `trailing-whitespace` - Remove trailing whitespace
- `check-merge-conflict` - Detect merge conflict markers
- `generate-commands-index` - Update COMMANDS.md
- `check-command-frontmatter` - Validate frontmatter
- `validate-command` - Validate structure
- `fix-shell-permissions` - Ensure .sh files are executable

## CI/CD Validation

### GitHub Actions Workflows

Three workflows validate commands on pull requests:

#### 1. Validate Commands (`.github/workflows/validate.yml`)

Runs on: PR and push to main

Jobs:
- `validate-frontmatter` - Check frontmatter fields
- `validate-structure` - Check command structure
- `validate-hook-paths` - Check hook paths

#### 2. Lint (`.github/workflows/lint.yml`)

Runs on: PR and push to main

Jobs:
- `markdown-lint` - Lint markdown files via `tools/validate-markdown.sh`
- `yaml-lint` - Lint YAML files
- `frontmatter-lint` - Lint frontmatter YAML via `tools/lint-frontmatter.sh`
- `workflow-syntax` - Validate workflow YAML syntax via `tools/validate-workflows.sh`

#### 3. Generate Documentation (`.github/workflows/generate-docs.yml`)

Runs on: PR and push to main

Jobs:
- `generate-indices` - Validate `COMMANDS.md` freshness via `tools/validate-generated.sh`

### Viewing CI Results

1. Go to your PR on GitHub
2. Scroll to "Checks" section
3. Click on failed check to see details
4. Download artifacts for detailed error logs

## Common Errors and Fixes

### Missing Required Field

**Error**:
```
ERROR: commands/my-command.md - Missing required field: name
```

**Fix**: Add the missing field to frontmatter:
```yaml
---
name: my-command
description: My command description
argument-hint: [args]
allowed-tools: Read, Write
created: 2026-03-02T19:00
updated: 2026-03-02T19:00
---
```

### Invalid Date Format

**Error**:
```
ERROR: commands/my-command.md - created '2026-03-01' is not valid ISO 8601 format
```

**Fix**: Include time component:
```yaml
created: 2026-03-01T14:30
```

### Invalid Name Format

**Error**:
```
WARNING: commands/my-command.md - name 'My_Command' should be kebab-case
```

**Fix**: Use kebab-case:
```yaml
name: my-command
```

### Duplicate Command Name

**Error**:
```
ERROR: Duplicate command name 'work' found in:
  - commands/work.md
  - commands/obsidian-workflows/work.md
```

**Fix**: Keep one canonical command file only. Do not define the same `name` twice.

### Legacy Command Root (Double Namespace Risk)

**Error**:
```
ERROR: Legacy command root 'commands/obsidian-workflows/' detected at commands/obsidian-workflows/work.md
  Move file under 'commands/' directly (e.g., 'commands/plan.md') to avoid double namespace discovery.
```

**Fix**: Move entrypoints to canonical root:
- `commands/plan.md`
- `commands/work.md`
- `commands/review.md`
- `commands/compound.md`

and remove `commands/obsidian-workflows/*.md`.

### Path Safety Violation

**Error**:
```
ERROR: commands/my-command.md - Contains reference to global runtime state (~/.claude/*)
```

**Fix**: Use repository-relative paths:
```markdown
# Bad
~/.claude/state/app.json

# Good
.claude/state/app.json
```

### Missing Hook Permissions

**Error**:
```
WARNING: commands/hooks/my-hook.sh - Missing execute permission
```

**Fix**: Add execute permission:
```bash
chmod +x commands/hooks/my-hook.sh
```

### ShellCheck Issues

**Error**:
```
WARNING: commands/hooks/my-hook.sh - ShellCheck found issues
```

**Fix**: Run ShellCheck to see specific issues:
```bash
shellcheck commands/hooks/my-hook.sh
```

### Workflow YAML Syntax Error

**Fix**: Run the local workflow validator:
```bash
make validate-workflows
```

If it fails, correct the YAML syntax in `.github/workflows/*.yml` and rerun the target.

### COMMANDS.md Out of Date

**Error**:
```
ERROR: COMMANDS.md is out of date. Run 'tools/generate-index.sh' and commit the changes.
```

**Fix**: Regenerate and commit:
```bash
./tools/generate-index.sh
git add COMMANDS.md
git commit -m "Update COMMANDS.md"
```

## Debugging Validation Issues

### Verbose Output

Run validators with bash tracing:

```bash
bash -x ./tools/check-frontmatter.sh
```

### Check Specific File

Test validation on a single file:

```bash
# Extract frontmatter
awk '/^---$/{if(++c==2)exit;next}c==1' commands/my-command.md

# Check with Node.js
node -e "
const matter = require('gray-matter');
const fs = require('fs');
const content = fs.readFileSync('commands/my-command.md', 'utf8');
console.log(matter(content).data);
"
```

### Validate YAML Syntax

```bash
# Using Python
python3 -c "import yaml; yaml.safe_load(open('commands/my-command.md').read().split('---')[1])"

# Using Node.js
node -e "const yaml = require('js-yaml'); console.log(yaml.load(require('fs').readFileSync('commands/my-command.md', 'utf8').split('---')[1]))"
```

## Best Practices

1. **Run the fast path before committing**
   ```bash
   make validate-fast && git commit
   ```

2. **Use pre-commit hooks** - Automatic validation
   ```bash
   pre-commit install
   ```

3. **Fix issues immediately** - Don't let validation errors accumulate

4. **Run the PR-ready path before creating a PR**
   ```bash
   make validate-ci
   ```

5. **Keep COMMANDS.md updated** - Use the generated-file validator after command changes
   ```bash
   make validate-generated
   ```

## References

- [Command Specification](./command-specification.md)
- [Frontmatter Reference](./frontmatter-reference.md)
- [Hook Patterns](./hook-patterns.md)
