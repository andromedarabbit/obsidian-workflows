#!/usr/bin/env bash
# create-command.sh - Interactive command generator with validation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Template directory
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR=".claude/commands"

# Validate kebab-case
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9]+([:-][a-z0-9]+)*(\.[a-z0-9]+)*$ ]]; then
        return 1
    fi
    return 0
}

# Check for duplicate names
check_duplicate() {
    local name="$1"

    while IFS= read -r -d '' file; do
        local existing_name
        existing_name=$(awk '/^---$/ { if (++count == 2) exit } count == 1 && /^name:/ { sub(/^name: */, ""); print }' "$file")

        if [[ "$existing_name" == "$name" ]]; then
            echo -e "${YELLOW}WARNING: Command '$name' already exists in $file${NC}" >&2
            return 1
        fi
    done < <(find "$COMMANDS_DIR" -type f -name "*.md" -print0 2>/dev/null)

    return 0
}

# Get current timestamp
get_timestamp() {
    date +"%Y-%m-%dT%H:%M"
}

# Main interactive flow
main() {
    echo -e "${BLUE}=== Command Generator ===${NC}"
    echo ""

    # Get command name
    while true; do
        echo -n "Command name (kebab-case): "
        read -r name

        if [[ -z "$name" ]]; then
            echo -e "${YELLOW}Name cannot be empty${NC}"
            continue
        fi

        if ! validate_name "$name"; then
            echo -e "${YELLOW}Invalid format. Use kebab-case (e.g., 'my-command' or 'namespace:command')${NC}"
            continue
        fi

        if ! check_duplicate "$name"; then
            echo -n "Continue anyway? (y/N): "
            read -r confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi

        break
    done

    # Get description
    echo -n "Description: "
    read -r description

    # Get argument hint
    echo -n "Argument hint (e.g., 'input=<value> [--option]'): "
    read -r argument_hint

    # Get allowed tools
    echo -n "Allowed tools (comma-separated, e.g., 'Read, Write, Edit'): "
    read -r allowed_tools

    # Select category
    echo ""
    echo "Select category:"
    echo "1) General"
    echo "2) Obsidian Workflows"
    echo "3) Obsidian Write"
    echo "4) Custom"
    echo -n "Choice (1-4): "
    read -r category_choice

    case "$category_choice" in
        1) category="general" ;;
        2) category="obsidian-workflows" ;;
        3) category="obsidian-write" ;;
        4)
            echo -n "Custom category name: "
            read -r category
            ;;
        *) category="general" ;;
    esac

    # Determine file path
    local file_path
    if [[ "$category" == "general" ]]; then
        file_path="$COMMANDS_DIR/${name}.md"
    else
        mkdir -p "$COMMANDS_DIR/$category"
        file_path="$COMMANDS_DIR/$category/${name}.md"
    fi

    # Get timestamp
    local timestamp
    timestamp=$(get_timestamp)

    # Generate command file
    cat > "$file_path" <<EOF
---
name: $name
description: $description
argument-hint: $argument_hint
allowed-tools: $allowed_tools
created: $timestamp
updated: $timestamp
---

## Overview

$description

## Usage

\`\`\`bash
/$name $argument_hint
\`\`\`

## Parameters

- TODO: Document parameters

## Behavior

1. TODO: Document behavior
2. TODO: Add execution steps

## Status Codes

- PASS: Command completed successfully
- SKIP: No work to do (not an error)
- FAIL: Command failed with an error

## Examples

\`\`\`bash
# TODO: Add usage examples
/$name
\`\`\`
EOF

    # Set permissions
    chmod 644 "$file_path"

    echo ""
    echo -e "${GREEN}✓ Created command: $file_path${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Edit the command file to add implementation details"
    echo "2. Run validation: ./tools/check-frontmatter.sh"
    echo "3. Update COMMANDS.md: ./tools/generate-index.sh"
    echo "4. Commit changes: git add $file_path && git commit"
}

main "$@"
