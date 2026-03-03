# obsidian-workflows

[![Validate Commands](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/validate.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/validate.yml)
[![Lint](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/lint.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/lint.yml)
[![Generate Documentation](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/generate-docs.yml/badge.svg)](https://github.com/andromedarabbit/obsidian-workflows/actions/workflows/generate-docs.yml)

Obsidian writing workflows plugin for Claude Code.

## What is this?

A structured 4-stage workflow system for writing projects in Obsidian with Claude Code:

1. **Plan** - Organize thoughts and define scope
2. **Work** - Create and refine content
3. **Review** - Quality check against style guides
4. **Compound** - Capture learnings for future reference

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- Obsidian vault

### Install via Marketplace (Recommended)

```bash
/plugin marketplace add andromedarabbit/obsidian-workflows
/plugin install obsidian-workflows@andromedarabbit
```

### Install via npx skills

```bash
npx skills add git@github.com:andromedarabbit/obsidian-workflows.git
```

### Manual Installation

```bash
cd /path/to/your/obsidian-vault
git clone https://github.com/andromedarabbit/obsidian-workflows.git .claude
```

See the [official Claude Skills documentation](https://code.claude.com/docs) for more details.

## Configuration

Create `writing-config.md` in your Obsidian vault root:

```yaml
source_paths:
  - .
policy_dir: Workflows/policy
enabled_policies:
  - daily-note
default_policy: daily-note
proposal_policy_allowlist:
  - daily-note

daily_notes_path: Daily Notes
daily_note_template: 템플릿/Daily.md
note_creation_engine: obsidian-cli
templater_required: true
fallback_recent_files_limit: 5

draft_path: Workflows/Drafts
final_path: Workflows/Notes
proposal_path: Workflows/Proposals/passive-proposals
```

Policy resolution is config-driven: `policy` is valid only when it is included in `enabled_policies` and `policy_dir/writing-policy.<policy>.md` exists.

### Configuration Files

- `config/writing-config.example.md` - Example vault configuration
- `assets/Workflows/SOUL.md` - Writing style template asset
- `assets/Workflows/policy/writing-policy.*.md` - Policy templates (config-driven)

## Usage

### 1. Plan (`/obsidian-workflows:plan`)

Plan your writing workflow before execution.

**Modes:**
- **Active mode**: Interactive planning with Claude
- **Passive mode**: Claude analyzes notes and suggests a plan

**Usage:**
```bash
/obsidian-workflows:plan [--intent active|passive] [topic=...] [policy=<policy-name>]
```

**Examples:**
```bash
/obsidian-workflows:plan --intent passive
/obsidian-workflows:plan --intent active topic="Daily operations summary" policy=daily-note
```

Daily-note behavior is policy-driven. With `source_strategy: previous-note`, it reads the previous daily note from `daily_notes_path`. If previous note is missing and policy requires `missing_source_behavior: skip-and-prompt-recent`, it returns `SKIP` and suggests up to `fallback_recent_files_limit` recent files for manual selection.

### 2. Work (`/obsidian-workflows:work`)

Execute writing tasks and create content.

**Modes:**
- **Active mode**: Collaborative writing with suggestions
- **Passive mode**: Claude writes based on plan and sources
- **Draft mode**: Create initial draft
- **Refine mode**: Improve existing draft
- **Route mode**: Determine next workflow step

**Usage:**
```bash
/obsidian-workflows:work mode=<active|passive|draft|refine|route> [args...]
```

**Examples:**
```bash
/obsidian-workflows:work mode=passive
/obsidian-workflows:work mode=draft proposal="Workflows/Proposals/passive-proposals/proposal-2026-03-03.md" idea=1
/obsidian-workflows:work mode=active policy=daily-note
```

### 3. Review (`/obsidian-workflows:review`)

Review content quality against style guide and policies.

**Checks:**
- Policy compliance (`Workflows/policy/writing-policy.<policy>.md`)
- Style consistency (`Workflows/SOUL.md`)
- Grammar, clarity, structure, technical accuracy

**Usage:**
```bash
/obsidian-workflows:review [file or draft reference]
```

**Example:**
```bash
/obsidian-workflows:review drafts/k8s-operators.md
```

### 4. Compound (`/obsidian-workflows:compound`)

Capture learning points from completed work.

**Purpose:**
- Document solutions to problems
- Extract reusable patterns
- Build institutional knowledge
- Create reference material

**Usage:**
```bash
/obsidian-workflows:compound [completed work reference]
```

**Example:**
```bash
/obsidian-workflows:compound finals/k8s-operators-published.md
```

### Complete Workflow Example

```bash
# 1. Plan ideas from recent changes
/obsidian-workflows:plan --intent passive

# 2. Create draft from selected proposal idea
/obsidian-workflows:work mode=draft proposal="Workflows/Proposals/passive-proposals/proposal-2026-03-03.md" idea=1

# 3. Refine the content
/obsidian-workflows:work mode=refine file="Workflows/Drafts/2026-03-03.md" policy=daily-note

# 4. Review for quality
/obsidian-workflows:review file="Workflows/Drafts/2026-03-03.md" policy=daily-note

# 5. Capture learnings
/obsidian-workflows:compound file="Workflows/Notes/2026-03-03.md"
```

## Documentation

- [Command Specification](docs/command-specification.md) - Command contract definition
- [Repository Structure](docs/repository-structure.md) - Directory layout and organization
- [Migration Guide](docs/migration/README.md) - Migration from vault-coupled layout
- [Frontmatter Reference](docs/frontmatter-reference.md) - Field specifications
- [Hook Patterns](docs/hook-patterns.md) - Best practices for hooks
- [Naming Conventions](docs/naming-conventions.md) - Naming standards
- [Validation Guide](docs/validation-guide.md) - Validation and troubleshooting

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, validation workflow, and contribution guidelines.

## Core Principles

1. **Fail fast over silent fallback** - Exit immediately on critical errors
2. **Enforce path safety consistently** - All hook paths must start with `commands/`
3. **Keep command discovery deterministic** - Single canonical source per command name
4. **Preserve PASS|SKIP|FAIL status semantics** - Consistent status reporting
5. **No absolute path assumptions** - Use relative paths in contracts
6. **No global runtime state dependencies** - Don't rely on `~/.claude/*` for correctness
7. **No duplicate command definitions** - Enforce unique command names

## License

MIT
