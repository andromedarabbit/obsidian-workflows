# Frontmatter Reference

Complete reference for command frontmatter fields, validation rules, and common patterns.

## Required Fields

### name

**Type**: `string`
**Required**: Yes
**Format**: kebab-case with optional namespace prefix

**Validation Rules**:
- Must match pattern: `^[a-z0-9]+([:-][a-z0-9]+)*(\.[a-z0-9]+)*$`
- Must be unique across all commands
- Should be descriptive and concise

**Valid Examples**:
```yaml
name: work
name: plan
name: obsidian:write.active
name: obsidian:write.draft
name: compound-learning
```

**Invalid Examples**:
```yaml
name: Work              # Capital letters not allowed
name: my_command        # Underscores not allowed
name: command name      # Spaces not allowed
name: 123command        # Cannot start with number
```

---

### description

**Type**: `string`
**Required**: Yes
**Length**: 1-2 sentences recommended

**Purpose**: Provides a brief, clear explanation of what the command does.

**Guidelines**:
- Be concise but informative
- Use active voice
- Mention key functionality
- Can be in any language (Korean, English, etc.)

**Examples**:
```yaml
description: WORK 트랙 진입점. mode 지정 시 active/passive/draft/refine/route 중 하나를 deterministic하게 실행합니다.
description: Active 모드. 사용자 입력(topic/sources/policy)으로 즉시 초안을 생성합니다.
description: Generate a comprehensive project plan from requirements
```

---

### argument-hint

**Type**: `string`
**Required**: Yes
**Format**: Command-line style argument specification

**Purpose**: Shows users how to invoke the command with its parameters.

**Conventions**:
- Use `<required>` for required parameters
- Use `[optional]` for optional parameters
- Use `|` for alternatives
- Use `...` for variable arguments

**Examples**:
```yaml
argument-hint: mode=<active|passive|draft|refine|route> [args...]
argument-hint: topic=... [policy=<policy-name>] [sources=[[노트A]],[[노트B]]]
argument-hint: --intent <active|passive>
argument-hint: [proposal=<path>] [idea=<number>]
```

---

### allowed-tools

**Type**: `string` or `array`
**Required**: Yes
**Format**: Comma-separated string or YAML array

**Purpose**: Specifies which tools the command is allowed to use.

**Common Tools**:
- `Read` - Read files
- `Write` - Create new files
- `Edit` - Modify existing files
- `Glob` - Find files by pattern
- `Grep` - Search file contents
- `Bash` - Execute shell commands
- `Skill` - Invoke other skills

**Examples**:
```yaml
# String format
allowed-tools: Read, Write, Edit, Glob, Grep

# Array format
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
```

---

### created

**Type**: `string`
**Required**: Yes
**Format**: ISO 8601 date-time

**Validation Rules**:
- Must match pattern: `YYYY-MM-DDTHH:MM` or `YYYY-MM-DDTHH:MM:SS`
- Should represent when the command was first created

**Examples**:
```yaml
created: 2026-03-01T17:28
created: 2026-03-02T14:30:00
```

**Invalid Examples**:
```yaml
created: 2026-03-01           # Missing time
created: 03/01/2026           # Wrong format
created: 2026-03-01 17:28     # Space instead of T
```

---

### updated

**Type**: `string`
**Required**: Yes
**Format**: ISO 8601 date-time

**Validation Rules**:
- Must match pattern: `YYYY-MM-DDTHH:MM` or `YYYY-MM-DDTHH:MM:SS`
- Should be updated whenever the command definition changes
- Should be >= `created` date

**Examples**:
```yaml
updated: 2026-03-02T17:38
updated: 2026-03-02T14:30:00
```

---

## Optional Fields

### version

**Type**: `string`
**Required**: No
**Format**: Semantic versioning (MAJOR.MINOR.PATCH)

**Purpose**: Track command version for compatibility and changes.

**Examples**:
```yaml
version: 1.0.0
version: 2.1.3
version: 0.1.0-beta
```

---

### tags

**Type**: `array`
**Required**: No
**Purpose**: Categorization and discovery

**Examples**:
```yaml
tags: [workflow, writing, automation]
tags:
  - obsidian
  - passive
  - proposal
```

---

## Common Validation Errors

### Missing Required Field

**Error**: `Missing required field: name`

**Fix**: Add the missing field to frontmatter:
```yaml
---
name: my-command
description: ...
# ... other required fields
---
```

---

### Invalid Date Format

**Error**: `Invalid created date format: 2026-03-01`

**Fix**: Include time component:
```yaml
created: 2026-03-01T14:30
```

---

### Invalid Name Format

**Error**: `name 'My_Command' should be kebab-case`

**Fix**: Use kebab-case:
```yaml
name: my-command
```

---

### Duplicate Command Name

**Error**: `Duplicate command name 'work' found in:`

**Fix**: Ensure each command has a unique name. Consider using namespaces:
```yaml
name: obsidian-workflows:work
```

---

## Best Practices

1. **Keep descriptions concise**: 1-2 sentences is ideal
2. **Update the `updated` field**: Whenever you modify the command
3. **Use clear argument hints**: Make it obvious how to use the command
4. **Be specific with allowed-tools**: Only include tools the command actually uses
5. **Use semantic versioning**: If you include version field
6. **Add meaningful tags**: For better discoverability

---

## Validation Tools

Run these commands to validate your frontmatter:

```bash
# Check frontmatter fields
./tools/check-frontmatter.sh

# Validate command structure
./tools/validate-command.sh

# Check for duplicates
npm run validate:no-duplicates

# Lint YAML syntax
npm run lint:frontmatter
```
