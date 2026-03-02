# Naming Conventions

Consistent naming conventions for commands, files, and git commits in obsidian-workflows.

## Command Names

### Format

Command names MUST follow kebab-case with optional namespace prefix:

```
^[a-z0-9]+([:-][a-z0-9]+)*(\.[a-z0-9]+)*$
```

### Patterns

**Simple names** (preferred for top-level commands):
```
work
plan
review
compound
```

**Namespaced names** (for related command groups):
```
obsidian:write.active
obsidian:write.draft
obsidian:write.refine
obsidian-workflows:work
```

### Guidelines

1. **Be descriptive**: Name should indicate what the command does
2. **Be concise**: Prefer shorter names when clear
3. **Use namespaces**: Group related commands with `:` or `-`
4. **Avoid abbreviations**: Unless widely understood (e.g., `init`, `config`)
5. **Use verbs**: For action commands (e.g., `scan`, `generate`, `validate`)

### Examples

✅ **Good**:
- `work` - Clear, concise
- `obsidian:write.active` - Well-namespaced
- `validate-frontmatter` - Descriptive
- `generate-index` - Action-oriented

❌ **Bad**:
- `Work` - Capital letters not allowed
- `my_command` - Underscores not allowed
- `cmd` - Too abbreviated
- `do-stuff` - Not descriptive

## File Names

### Command Files

Command definition files follow the pattern:

```
commands/<namespace>/<name>.md
```

**Examples**:
```
commands/obsidian:write.active.md
commands/obsidian-workflows/work.md
commands/obsidian-workflows/plan.md
```

### Hook Scripts

Hook scripts follow the pattern:

```
commands/<namespace>/hooks/<name>.sh
```

**Examples**:
```
commands/obsidian-workflows/hooks/scan.sh
commands/obsidian-workflows/hooks/validate.sh
```

### Documentation Files

Documentation files use kebab-case:

```
docs/command-specification.md
docs/frontmatter-reference.md
docs/hook-patterns.md
docs/naming-conventions.md
```

### Tool Scripts

Tool scripts use kebab-case:

```
tools/check-frontmatter.sh
tools/validate-command.sh
tools/generate-index.sh
```

## Git Conventions

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

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

### Scopes

Common scopes for this repository:

- `commands`: Command definitions
- `validation`: Validation scripts
- `docs`: Documentation
- `ci`: GitHub Actions workflows
- `tools`: Tool scripts
- `hooks`: Pre-commit hooks

### Examples

✅ **Good**:
```
feat(commands): add obsidian:write.scan command
fix(validation): handle missing frontmatter gracefully
docs(hooks): add hook patterns documentation
chore(ci): update GitHub Actions to v4
refactor(tools): simplify frontmatter extraction
```

❌ **Bad**:
```
Added new command
Fixed bug
Update docs
WIP
asdf
```

### Commit Message Guidelines

1. **Use imperative mood**: "add" not "added" or "adds"
2. **Be specific**: Describe what changed and why
3. **Keep first line under 72 characters**
4. **Add body for complex changes**: Explain motivation and context
5. **Reference issues**: Use "Fixes #123" or "Closes #456"

### Multi-line Example

```
feat(commands): add passive workflow automation

Implements automatic proposal generation based on file changes.
The scan command monitors source_paths and generates proposals
when new content is detected.

- Add obsidian:write.scan command
- Add obsidian:write.propose command
- Update work command to support passive mode

Closes #42
```

## Branch Names

### Format

```
<type>/<short-description>
```

### Types

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Code refactoring
- `chore/` - Maintenance

### Examples

✅ **Good**:
```
feature/add-validation-scripts
fix/frontmatter-parsing
docs/update-command-spec
refactor/simplify-hook-paths
chore/update-dependencies
```

❌ **Bad**:
```
my-branch
test
fix
new-feature-123
```

## Version Numbers

If using semantic versioning for commands:

### Format

```
MAJOR.MINOR.PATCH
```

### Rules

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Examples

```
1.0.0 - Initial release
1.1.0 - Add new optional parameter
1.1.1 - Fix validation bug
2.0.0 - Breaking: change required parameters
```

## Directory Structure

Standard directory naming:

```
.claude/
├── commands/          # Command definitions
├── skills/            # Skills (if applicable)
└── state/             # Runtime state

.github/
└── workflows/         # GitHub Actions

docs/                  # Documentation
tools/                 # Validation scripts
scripts/               # Node.js scripts
template/              # Command templates
tests/                 # Test files
```

## Case Conventions by Context

| Context | Convention | Example |
|---------|-----------|---------|
| Command names | kebab-case | `work`, `obsidian:write.active` |
| File names | kebab-case | `command-specification.md` |
| Directory names | kebab-case | `obsidian-workflows/` |
| Script names | kebab-case | `check-frontmatter.sh` |
| Variable names (bash) | SCREAMING_SNAKE_CASE | `ERRORS`, `REQUIRED_FIELDS` |
| Function names (bash) | snake_case | `validate_command`, `check_path` |
| Variable names (JS) | camelCase | `commandNames`, `frontmatter` |
| Function names (JS) | camelCase | `validateCommand`, `checkDuplicates` |

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Command Specification](./command-specification.md)
