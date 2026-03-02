#!/usr/bin/env bash
# validate-hook-paths.sh - Verify hook paths start with commands/
# Validates that all hook references in command definitions use correct paths

set -euo pipefail
set -x

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKED=0

# Extract hook references from command file
extract_hook_references() {
    local file="$1"

    # Look for common hook patterns:
    # - commands/path/to/hook.sh
    # - Skill tool references
    # - File references in markdown
    grep -oE 'commands/[a-zA-Z0-9/:_.-]+\.(sh|md)' "$file" 2>/dev/null || true
}

# Validate hook path
validate_hook_path() {
    local file="$1"
    local hook_path="$2"

    # Check if path starts with commands/
    if [[ ! "$hook_path" =~ ^commands/ ]]; then
        echo -e "${RED}ERROR${NC}: $file - Hook path '$hook_path' does not start with commands/"
        ((ERRORS++))
        return 1
    fi

    # Check if referenced file exists
    if [[ ! -f "$hook_path" ]]; then
        echo -e "${YELLOW}WARNING${NC}: $file - Referenced file '$hook_path' does not exist"
        ((WARNINGS++))
    fi

    return 0
}

# Check single command file
check_command_hooks() {
    local file="$1"
    local hooks

    ((CHECKED++))

    # Extract hook references
    hooks=$(extract_hook_references "$file")

    if [[ -z "$hooks" ]]; then
        return 0
    fi

    # Validate each hook
    while IFS= read -r hook; do
        if [[ -n "$hook" ]]; then
            validate_hook_path "$file" "$hook" || true
        fi
    done <<< "$hooks"

    return 0
}

# Main execution
main() {
    echo "Validating hook paths..."

    if [[ ! -d "commands" ]]; then
        echo -e "${RED}ERROR${NC}: commands directory not found"
        exit 1
    fi

    # Process all command files
    while IFS= read -r -d '' file; do
        check_command_hooks "$file" || true
    done < <(find commands -type f -name "*.md" -print0)

    # Summary
    echo ""
    echo "Checked $CHECKED command files"

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}Found $ERRORS error(s)${NC}"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Found $WARNINGS warning(s)${NC}"
    fi

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}All checks passed!${NC}"
    fi

    [[ $ERRORS -eq 0 ]]
}

main "$@"
