# Command Specification

This document defines the contract for command definitions in the obsidian-workflows plugin.

## Overview

Commands are the core building blocks of the obsidian-workflows plugin. Each command is defined by a markdown file with YAML frontmatter that specifies its metadata and behavior.

## File Structure

Commands are stored in `commands/` with the following structure:

```
commands/
├── obsidian:write.active.md
├── obsidian:write.draft.md
├── obsidian-workflows/
│   ├── work.md
│   ├── plan.md
│   ├── review.md
│   └── compound.md
└── ...
```

## Frontmatter Contract

Each command file MUST include YAML frontmatter with the following required fields:

### Required Fields

#### `name` (string)
- **Format**: kebab-case with optional namespace prefix
- **Pattern**: `^[a-z0-9]+([:-][a-z0-9]+)*(\.[a-z0-9]+)*$`
- **Examples**:
  - `work`
  - `obsidian:write.active`
  - `plan-review`
- **Uniqueness**: Must be unique across all commands

#### `description` (string)
- **Purpose**: Brief description of what the command does
- **Length**: 1-2 sentences recommended
- **Example**: `"WORK 트랙 진입점. mode 지정 시 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다."`

#### `argument-hint` (string)
- **Purpose**: Shows users how to invoke the command
- **Format**: Command-line style argument specification
- **Example**: `"mode=<active|passive|draft|refine|route> [args...]"`

#### `allowed-tools` (string or array)
- **Purpose**: Specifies which tools the command can use
- **Format**: Comma-separated string or YAML array
- **Examples**:
  - String: `"Read, Write, Edit, Glob, Grep"`
  - Array: `["Read", "Write", "Edit"]`

#### `created` (string)
- **Format**: ISO 8601 date-time
- **Pattern**: `YYYY-MM-DDTHH:MM` or `YYYY-MM-DDTHH:MM:SS`
- **Example**: `"2026-03-01T17:28"`

#### `updated` (string)
- **Format**: ISO 8601 date-time
- **Pattern**: `YYYY-MM-DDTHH:MM` or `YYYY-MM-DDTHH:MM:SS`
- **Example**: `"2026-03-02T17:38"`
- **Note**: Should be updated whenever the command definition changes

### Optional Fields

#### `version` (string)
- **Format**: Semantic versioning
- **Example**: `"1.0.0"`

#### `tags` (array)
- **Purpose**: Categorization and discovery
- **Example**: `["workflow", "writing", "automation"]`

## Command Body

After the frontmatter, the command body contains:

1. **Description**: Detailed explanation of the command's purpose
2. **Usage**: How to invoke and use the command
3. **Parameters**: Detailed parameter specifications
4. **Behavior**: Expected behavior and execution flow
5. **Examples**: Usage examples (optional but recommended)

## Hook Execution Model

Commands may reference hook scripts that execute specific functionality:

### Hook Path Requirements

- All hook paths MUST start with `commands/`
- Hooks MUST be executable (`chmod +x`)
- Hooks SHOULD be shell scripts (`.sh`) or other executable formats

### Hook Patterns

See [Hook Patterns](./hook-patterns.md) for detailed patterns and best practices.

## Status Semantics

Commands MUST use consistent status reporting:

- **PASS**: Command completed successfully
- **SKIP**: Command was skipped (not an error, e.g., no work to do)
- **FAIL**: Command failed with an error

### Status Reporting Rules

1. Use ONLY these three status values
2. Empty results are `SKIP`, not `FAIL`
3. Missing dependencies are `FAIL`
4. User cancellation is `SKIP`

## Path Resolution Rules

### Path Safety

Commands MUST follow these path safety rules:

1. **No absolute paths** in command contracts
2. **No global runtime state** dependencies (`~/.claude/*`)
3. **Relative paths only** for file references
4. **Repository-scoped** operations only

### Path Validation

All paths referenced in commands are validated to ensure:

- They start with `commands/` (for hooks)
- They are relative to the repository root
- They don't reference global state

## Example Command

```markdown
---
name: example-command
description: Example command demonstrating the specification
argument-hint: input=<value> [--option]
allowed-tools: Read, Write, Edit
created: 2026-03-02T19:00
updated: 2026-03-02T19:00
version: 1.0.0
tags: [example, documentation]
---

This is an example command that demonstrates the command specification.

## Usage

Invoke with: `/example-command input=value`

## Parameters

- `input` (required): The input value to process
- `--option` (optional): An optional flag

## Behavior

1. Validates input parameter
2. Processes the input
3. Returns PASS/SKIP/FAIL status

## Examples

```bash
/example-command input=test
/example-command input=test --option
```

## Status Codes

- PASS: Input processed successfully
- SKIP: No input provided
- FAIL: Invalid input format
```

## Validation

Commands are validated using:

1. **Frontmatter validation**: `tools/check-frontmatter.sh`
2. **Structure validation**: `tools/validate-command.sh`
3. **Hook path validation**: `tools/validate-hook-paths.sh`

See [Validation Guide](./validation-guide.md) for details.
