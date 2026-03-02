#!/usr/bin/env bash
# validate-command.sh - Comprehensive command structure validation
# Validates required files, path safety, status semantics, and hook permissions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKED=0

# Auto-install ShellCheck if missing
ensure_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo -e "${YELLOW}ShellCheck not found. Installing...${NC}"
        if command -v brew >/dev/null 2>&1; then
            brew install shellcheck
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y shellcheck
        else
            echo -e "${YELLOW}WARNING${NC}: Could not auto-install ShellCheck. Skipping shell script validation."
            return 1
        fi
    fi
    return 0
}

# Check for absolute paths or global runtime state
check_path_safety() {
    local file="$1"
    local content
    content=$(cat "$file")

    # Check for ~/.claude/* references, but exclude documentation/examples
    if echo "$content" | grep -qE '~/.claude/'; then
        # Check if it's in a documentation context (preceded by "not", "don't", "avoid", etc.)
        if ! echo "$content" | grep -B2 -A2 '~/.claude/' | grep -qiE '(not|don'\''t|avoid|never|같은.*상태를|해결책으로 사용하지)'; then
            echo -e "${RED}ERROR${NC}: $file - Contains reference to global runtime state (~/.claude/*)"
            ((ERRORS++))
            return 1
        fi
    fi

    return 0
}

# Check status semantics (PASS|SKIP|FAIL)
check_status_semantics() {
    local file="$1"
    local content
    content=$(cat "$file")

    # Look for status-related text
    if echo "$content" | grep -qiE 'status|상태'; then
        # Check if PASS|SKIP|FAIL pattern is mentioned
        if ! echo "$content" | grep -qE 'PASS|SKIP|FAIL'; then
            echo -e "${YELLOW}WARNING${NC}: $file - Mentions status but doesn't use PASS|SKIP|FAIL semantics"
            ((WARNINGS++))
        fi
    fi

    return 0
}

# Check hook scripts
check_hook_scripts() {
    local file="$1"
    local dir
    dir=$(dirname "$file")

    # Find associated hook scripts (*.sh files in same directory)
    while IFS= read -r -d '' hook; do
        # Check execute permissions
        if [[ ! -x "$hook" ]]; then
            echo -e "${YELLOW}WARNING${NC}: $hook - Missing execute permission"
            ((WARNINGS++))
        fi

        # Run ShellCheck if available
        if ensure_shellcheck; then
            if ! shellcheck -x "$hook" 2>/dev/null; then
                echo -e "${YELLOW}WARNING${NC}: $hook - ShellCheck found issues"
                ((WARNINGS++))
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -type f -name "*.sh" -print0 2>/dev/null)

    return 0
}

# Validate single command
validate_command() {
    local file="$1"

    ((CHECKED++))

    # Check file exists and is readable
    if [[ ! -r "$file" ]]; then
        echo -e "${RED}ERROR${NC}: $file - Not readable"
        ((ERRORS++))
        return 1
    fi

    # Run all checks
    check_path_safety "$file"
    check_status_semantics "$file"
    check_hook_scripts "$file"

    return 0
}

# Main execution
main() {
    echo "Validating command structure..."

    if [[ ! -d ".claude/commands" ]]; then
        echo -e "${RED}ERROR${NC}: .claude/commands directory not found"
        exit 1
    fi

    # Process all command files
    while IFS= read -r -d '' file; do
        validate_command "$file"
    done < <(find .claude/commands -type f -name "*.md" -print0)

    # Summary
    echo ""
    echo "Validated $CHECKED command files"

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
