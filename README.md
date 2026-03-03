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

```markdown
# Writing Configuration

source_paths:
  - /path/to/vault/sources

draft_path: /path/to/vault/drafts
final_path: /path/to/vault/finals
proposal_path: /path/to/vault/proposals
```

### Configuration Files

- `config/writing-config.example.md` - Example vault configuration
- `assets/SOUL.md` - Writing style template
- `assets/policy.md` - Channel-specific policies

## Usage

### 1. Plan (`/obsidian-workflows:plan`)

Plan your writing workflow before execution.

**Modes:**
- **Active mode**: Interactive planning with Claude
- **Passive mode**: Claude analyzes notes and suggests a plan

**Usage:**
```bash
/obsidian-workflows:plan [topic or note reference]
```

**Example:**
```bash
/obsidian-workflows:plan Write a technical blog post about Kubernetes operators
```

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
/obsidian-workflows:work [mode] [context]
```

**Examples:**
```bash
/obsidian-workflows:work draft "Introduction to Kubernetes operators"
/obsidian-workflows:work refine drafts/k8s-operators.md
/obsidian-workflows:work active "Add code examples section"
```

### 3. Review (`/obsidian-workflows:review`)

Review content quality against style guide and policies.

**Checks:**
- Policy compliance (`assets/policy.md`)
- Style consistency (`assets/SOUL.md`)
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
# 1. Plan the post
/obsidian-workflows:plan Write about Kubernetes operator patterns

# 2. Create initial draft
/obsidian-workflows:work draft "Kubernetes operator patterns"

# 3. Refine the content
/obsidian-workflows:work refine drafts/k8s-operator-patterns.md

# 4. Review for quality
/obsidian-workflows:review drafts/k8s-operator-patterns.md

# 5. After publishing, capture learnings
/obsidian-workflows:compound finals/k8s-operator-patterns.md
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
