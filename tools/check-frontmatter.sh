#!/usr/bin/env bash
# check-frontmatter.sh - Validate command frontmatter
# Validates required fields, formats, and detects duplicate command names

set -euo pipefail

# Ensure we're using bash 4+ for associative arrays
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    # Fallback for older bash - use temp files instead
    USE_TEMP_FILES=1
else
    USE_TEMP_FILES=0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh
source "$SCRIPT_DIR/lib/frontmatter.sh"

# Counters
ERRORS=0
WARNINGS=0
CHECKED=0

# Required fields
REQUIRED_FIELDS=("name" "description" "argument-hint" "allowed-tools" "created" "updated")

# Function to validate ISO 8601 date format
validate_date() {
    local date="$1"
    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate kebab-case
validate_kebab_case() {
    local name="$1"
    # Flat kebab-case, dash-separated, no ':' or '.' (runtime slash name is path-derived;
    # internal colons/dots add extra namespace segments). Group with a dash prefix instead.
    if [[ ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        return 1
    fi
    return 0
}

# Function to check single command file
check_command() {
    local file="$1"
    local has_error=0

    ((CHECKED++))

    # Check if file has frontmatter
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null || true)
    if [[ "$first_line" != "---" ]]; then
        echo -e "${RED}ERROR${NC}: $file - Missing frontmatter"
        ((ERRORS++))
        return 1
    fi

    local delimiter_count
    delimiter_count=$(count_frontmatter_delimiters "$file")
    if [[ "$delimiter_count" -lt 2 ]]; then
        echo -e "${RED}ERROR${NC}: $file - Unterminated frontmatter (missing closing ---)"
        ((ERRORS++))
        return 1
    fi

    # Check required fields
    for field in "${REQUIRED_FIELDS[@]}"; do
        local value
        value=$(extract_field "$file" "$field")

        if [[ -z "$value" ]]; then
            echo -e "${RED}ERROR${NC}: $file - Missing required field: $field"
            ((ERRORS++))
            has_error=1
        else
            # Validate specific field formats
            case "$field" in
                name)
                    if ! validate_kebab_case "$value"; then
                        echo -e "${YELLOW}WARNING${NC}: $file - name '$value' should be kebab-case"
                        ((WARNINGS++))
                    fi
                    ;;
                created|updated)
                    if ! validate_date "$value"; then
                        echo -e "${RED}ERROR${NC}: $file - $field '$value' is not valid ISO 8601 format (YYYY-MM-DDTHH:MM or YYYY-MM-DDTHH:MM:SS)"
                        ((ERRORS++))
                        has_error=1
                    fi
                    ;;
            esac
        fi
    done

    return $has_error
}

# Main execution
main() {
    echo "Checking command frontmatter..."

    # Find all command markdown files
    if [[ ! -d "commands" ]]; then
        echo -e "${RED}ERROR${NC}: commands directory not found"
        exit 1
    fi

    # Collect all command names to check for duplicates
    local temp_names
    temp_names=$(mktemp)
    trap "rm -f $temp_names" EXIT

    while IFS= read -r -d '' file; do
        check_command "$file" || true

        # Extract name for duplicate checking
        local name
        name=$(extract_field "$file" "name")
        if [[ -n "$name" ]]; then
            # Check if name already exists
            if grep -q "^${name}|" "$temp_names" 2>/dev/null; then
                local prev_file
                prev_file=$(grep "^${name}|" "$temp_names" | cut -d'|' -f2)
                echo -e "${RED}ERROR${NC}: Duplicate command name '$name' found in:"
                echo "  - $prev_file"
                echo "  - $file"
                ((ERRORS++))
            else
                echo "${name}|${file}" >> "$temp_names"
            fi
        fi
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

    # Exit with error if any errors found
    [[ $ERRORS -eq 0 ]]
}

main "$@"
