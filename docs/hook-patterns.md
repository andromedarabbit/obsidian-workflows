# Hook Patterns

Best practices and patterns for writing hook scripts in obsidian-workflows commands.

## Overview

Hook scripts are executable files that implement command functionality. They follow specific patterns to ensure reliability, maintainability, and consistency.

## Core Patterns

### 1. Fail Fast Pattern

Exit immediately on critical errors rather than attempting recovery.

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Check prerequisites
if [[ ! -f "required-file.txt" ]]; then
    echo "ERROR: required-file.txt not found" >&2
    exit 1
fi

# Proceed with work...
```

**Why**: Prevents cascading failures and makes debugging easier.

### 2. Dependency Auto-Install Pattern

Automatically install missing dependencies when possible.

```bash
#!/usr/bin/env bash

ensure_tool() {
    local tool="$1"

    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Installing $tool..."

        if command -v brew >/dev/null 2>&1; then
            brew install "$tool"
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y "$tool"
        else
            echo "ERROR: Cannot auto-install $tool" >&2
            return 1
        fi
    fi

    return 0
}

# Use it
ensure_tool "jq" || exit 1
```

**Why**: Reduces friction for users and makes commands more portable.

### 3. Silent Success Pattern

Only output when there's something to report (errors, warnings, or results).

```bash
#!/usr/bin/env bash
set -euo pipefail

# Do work silently
process_files() {
    # ... processing logic ...
    return 0
}

# Only output on error or when there are results
if ! process_files; then
    echo "ERROR: Processing failed" >&2
    exit 1
fi

# Silent success - no output needed
exit 0
```

**Why**: Reduces noise and makes actual issues more visible.

### 4. Path Safety Pattern

Always validate and sanitize paths to prevent security issues.

```bash
#!/usr/bin/env bash
set -euo pipefail

validate_path() {
    local path="$1"

    # Reject absolute paths
    if [[ "$path" =~ ^/ ]]; then
        echo "ERROR: Absolute paths not allowed: $path" >&2
        return 1
    fi

    # Reject global runtime state
    if [[ "$path" =~ ~/.claude/ ]]; then
        echo "ERROR: Global runtime state not allowed: $path" >&2
        return 1
    fi

    # Ensure path is within repository
    local real_path
    real_path=$(realpath "$path" 2>/dev/null) || return 1
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

    if [[ ! "$real_path" =~ ^"$repo_root" ]]; then
        echo "ERROR: Path outside repository: $path" >&2
        return 1
    fi

    return 0
}

# Use it
INPUT_PATH="$1"
validate_path "$INPUT_PATH" || exit 1
```

**Why**: Prevents path traversal attacks and ensures repository-scoped operations.

### 5. Status Reporting Pattern

Use consistent PASS|SKIP|FAIL status semantics.

```bash
#!/usr/bin/env bash
set -euo pipefail

STATUS="PASS"

# Check if there's work to do
if [[ ! -f "input.txt" ]]; then
    echo "STATUS: SKIP - No input file found"
    exit 0
fi

# Do work
if ! process_input "input.txt"; then
    echo "STATUS: FAIL - Processing failed"
    exit 1
fi

echo "STATUS: PASS - Processing complete"
exit 0
```

**Status Meanings**:
- **PASS**: Command completed successfully
- **SKIP**: No work to do (not an error)
- **FAIL**: Command failed with an error

**Why**: Provides consistent, machine-parseable status information.

### 6. Use Builtins Pattern

Prefer bash builtins over external commands when possible.

```bash
#!/usr/bin/env bash

# Good: Use builtin
if command -v tool >/dev/null 2>&1; then
    echo "Tool found"
fi

# Bad: Use external command
if which tool >/dev/null 2>&1; then
    echo "Tool found"
fi

# Good: Use parameter expansion
filename="${path##*/}"

# Bad: Use external command
filename=$(basename "$path")
```

**Why**: Faster, more portable, fewer dependencies.

## Anti-Patterns to Avoid

### ❌ Silent Fallback

```bash
# BAD: Silently falls back to default
config=$(cat config.json 2>/dev/null || echo "{}")
```

```bash
# GOOD: Fail fast
if [[ ! -f config.json ]]; then
    echo "ERROR: config.json not found" >&2
    exit 1
fi
config=$(cat config.json)
```

### ❌ Ignoring Errors

```bash
# BAD: Ignores errors
process_file || true
```

```bash
# GOOD: Handle errors explicitly
if ! process_file; then
    echo "ERROR: Failed to process file" >&2
    exit 1
fi
```

### ❌ Hardcoded Paths

```bash
# BAD: Hardcoded absolute path
CONFIG_FILE="/Users/username/.config/app.conf"
```

```bash
# GOOD: Relative to repository
CONFIG_FILE="config/app.conf"
```

### ❌ Global State Dependencies

```bash
# BAD: Depends on global state
STATE_FILE="~/.claude/state/app.json"
```

```bash
# GOOD: Repository-scoped state
STATE_FILE=".claude/state/app.json"
```

## Complete Example

Here's a complete hook script following all patterns:

```bash
#!/usr/bin/env bash
# process-documents.sh - Process markdown documents
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure required tools
ensure_tool() {
    local tool="$1"

    if ! command -v "$tool" >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing $tool...${NC}" >&2

        if command -v brew >/dev/null 2>&1; then
            brew install "$tool"
        else
            echo -e "${RED}ERROR: Cannot auto-install $tool${NC}" >&2
            return 1
        fi
    fi

    return 0
}

# Validate path safety
validate_path() {
    local path="$1"

    if [[ "$path" =~ ^/ ]] || [[ "$path" =~ ~/.claude/ ]]; then
        echo -e "${RED}ERROR: Invalid path: $path${NC}" >&2
        return 1
    fi

    return 0
}

# Main processing
main() {
    local input_dir="${1:-.}"

    # Validate input
    validate_path "$input_dir" || exit 1

    if [[ ! -d "$input_dir" ]]; then
        echo "STATUS: SKIP - Directory not found: $input_dir"
        exit 0
    fi

    # Ensure dependencies
    ensure_tool "pandoc" || exit 1

    # Process files
    local count=0
    while IFS= read -r -d '' file; do
        if ! pandoc "$file" -o "${file%.md}.html"; then
            echo -e "${RED}STATUS: FAIL - Failed to process $file${NC}" >&2
            exit 1
        fi
        ((count++))
    done < <(find "$input_dir" -name "*.md" -print0)

    if [[ $count -eq 0 ]]; then
        echo "STATUS: SKIP - No markdown files found"
        exit 0
    fi

    echo -e "${GREEN}STATUS: PASS - Processed $count files${NC}"
    exit 0
}

main "$@"
```

## Testing Hooks

Always test your hooks with:

```bash
# Test with ShellCheck
shellcheck your-hook.sh

# Test execution
bash -n your-hook.sh  # Syntax check
./your-hook.sh        # Actual run

# Test error cases
./your-hook.sh /invalid/path  # Should fail
./your-hook.sh                # Should handle missing args
```

## References

- [Command Specification](./command-specification.md)
- [Validation Guide](./validation-guide.md)
- [Path Safety Rules](./command-specification.md#path-resolution-rules)
