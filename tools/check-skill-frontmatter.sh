#!/usr/bin/env bash
# check-skill-frontmatter.sh - Validate skill frontmatter
# Validates required fields, formats, name==directory match, and description
# constraints for all skills/*/SKILL.md files. See docs/skill-specification.md
# for the contract this script enforces.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh
source "$SCRIPT_DIR/lib/frontmatter.sh"

# Counters
ERRORS=0
WARNINGS=0
CHECKED=0

# Required fields (ERROR if missing)
REQUIRED_FIELDS=("name" "description" "version" "context" "mirrors" "mirror_hash")

# Valid values for the conditionally required `agent` field
VALID_AGENTS=("general-purpose" "Explore" "Plan")

# Function to validate kebab-case, no namespace prefix (skill names are plain,
# unlike command names which allow ':'/'.' namespace separators)
validate_kebab_case() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate semantic version
validate_semver() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

# Function to check single skill file
check_skill() {
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
            continue
        fi

        case "$field" in
            name)
                if ! validate_kebab_case "$value"; then
                    echo -e "${RED}ERROR${NC}: $file - name '$value' must be kebab-case (^[a-z0-9-]+\$)"
                    ((ERRORS++))
                    has_error=1
                fi

                local dir_name
                dir_name=$(basename "$(dirname "$file")")
                if [[ "$value" != "$dir_name" ]]; then
                    echo -e "${RED}ERROR${NC}: $file - name '$value' does not match directory name '$dir_name'"
                    ((ERRORS++))
                    has_error=1
                fi
                ;;
            version)
                if ! validate_semver "$value"; then
                    echo -e "${RED}ERROR${NC}: $file - version '$value' must be MAJOR.MINOR.PATCH"
                    ((ERRORS++))
                    has_error=1
                fi
                ;;
            context)
                if [[ "$value" != "fork" && "$value" != "inline" ]]; then
                    echo -e "${RED}ERROR${NC}: $file - context '$value' must be 'fork' or 'inline'"
                    ((ERRORS++))
                    has_error=1
                fi
                ;;
            mirrors)
                # Paired canonical command path (see docs/skill-specification.md).
                if [[ ! "$value" =~ ^commands/.*\.md$ ]]; then
                    echo -e "${RED}ERROR${NC}: $file - mirrors '$value' must be a repo-relative command path (commands/....md)"
                    ((ERRORS++))
                    has_error=1
                fi
                ;;
            mirror_hash)
                # Content hash of the paired command body; regenerate with
                # tools/update-skill-hash.sh. Drift is caught by check-skill-sync.sh.
                if [[ ! "$value" =~ ^[0-9a-f]{16,}$ ]]; then
                    echo -e "${RED}ERROR${NC}: $file - mirror_hash '$value' must be lowercase hex (>=16 chars); run tools/update-skill-hash.sh"
                    ((ERRORS++))
                    has_error=1
                fi
                ;;
            description)
                # Use the block-scalar-aware extractor so a folded/literal
                # YAML description (`description: >` etc.) is measured by its
                # actual joined content, not just the scalar indicator.
                local desc_value
                desc_value=$(extract_description "$file")

                # Length: UTF-8 codepoint count, official cap 1024
                local desc_length
                desc_length=$(printf '%s' "$desc_value" | LC_ALL=C tr -d '\200-\277' | LC_ALL=C wc -c | tr -d ' ')
                if [[ "$desc_length" -gt 1024 ]]; then
                    echo -e "${RED}ERROR${NC}: $file - description is ${desc_length} chars (exceeds 1024 limit)"
                    ((ERRORS++))
                    has_error=1
                fi

                # When-to-use trigger phrase: WARNING only (see docs/skill-specification.md
                # "Diverged" section for why this is not an ERROR in this repository)
                if ! printf '%s' "$desc_value" | grep -qiE "할 때|일 때|요청 시|트리거|when.to.use|use when|trigger"; then
                    echo -e "${YELLOW}WARNING${NC}: $file - description has no when-to-use trigger phrase"
                    ((WARNINGS++))
                fi
                ;;
        esac
    done

    # Conditionally required: agent (only meaningful when context: fork)
    local context_value agent_value
    context_value=$(extract_field "$file" "context")
    agent_value=$(extract_field "$file" "agent")

    if [[ "$context_value" == "fork" && -z "$agent_value" ]]; then
        echo -e "${YELLOW}WARNING${NC}: $file - context is 'fork' but 'agent' is not set"
        ((WARNINGS++))
    elif [[ "$context_value" == "inline" && -n "$agent_value" ]]; then
        echo -e "${YELLOW}WARNING${NC}: $file - context is 'inline' but 'agent' is set (agent is only meaningful for 'fork'; remove it)"
        ((WARNINGS++))
    fi

    if [[ -n "$agent_value" ]]; then
        local agent_valid=0
        for valid in "${VALID_AGENTS[@]}"; do
            [[ "$agent_value" == "$valid" ]] && agent_valid=1 && break
        done
        if [[ "$agent_valid" -eq 0 ]]; then
            echo -e "${YELLOW}WARNING${NC}: $file - agent '$agent_value' is not one of general-purpose|Explore|Plan"
            ((WARNINGS++))
        fi
    fi

    return $has_error
}

# Main execution
main() {
    echo "Checking skill frontmatter..."

    if [[ ! -d "skills" ]]; then
        echo -e "${RED}ERROR${NC}: skills directory not found"
        exit 1
    fi

    while IFS= read -r -d '' file; do
        check_skill "$file" || true
    done < <(find skills -type f -name "SKILL.md" -print0)

    # Note: duplicate skill names and skill/command name collisions are
    # checked by `npm run validate:no-duplicates` (scripts/check-duplicates.js),
    # not re-implemented here.

    echo ""
    echo "Checked $CHECKED skill files"

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
