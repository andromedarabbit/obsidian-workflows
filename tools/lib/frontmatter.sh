#!/usr/bin/env bash
# frontmatter.sh - Shared frontmatter-parsing helpers.
# Sourced by tools/check-frontmatter.sh and tools/check-skill-frontmatter.sh
# so the extraction logic exists in exactly one place -- previously each
# script carried its own copy, which meant a bug fix to one would not
# propagate to the other.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Extract a single-line frontmatter field value, stripping one layer of
# surrounding matching quotes (e.g. `version: "0.1.0"` -> `0.1.0`) so quoted
# and unquoted YAML scalars validate identically.
extract_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (++count == 2) exit }
        count == 1 && $0 ~ "^" field ":" {
            sub("^" field ": *", "")
            n = length($0)
            if (n >= 2) {
                first = substr($0, 1, 1)
                last = substr($0, n, 1)
                if ((first == "\"" && last == "\"") || (first == "'"'"'" && last == "'"'"'")) {
                    $0 = substr($0, 2, n - 2)
                }
            }
            print
        }
    ' "$file"
}

# Extract a description field's full value, joining a YAML block-scalar
# (`>`, `>-`, `|`, `|-`, etc.) into a single line so length/trigger-phrase
# checks measure the actual content rather than the scalar indicator alone.
extract_description() {
    local file="$1"
    local raw
    raw=$(extract_field "$file" "description")

    if [[ "$raw" =~ ^[\>\|] ]]; then
        awk '
            /^---$/ { if (++count == 2) exit; next }
            count == 1 && /^description:/ { found=1; next }
            count == 1 && found && /^[[:space:]]*$/ { printf " "; next }
            count == 1 && found && /^  / { sub(/^  /, ""); printf "%s ", $0; next }
            count == 1 && found { exit }
        ' "$file" | sed 's/  */ /g; s/ $//'
    else
        printf '%s' "$raw"
    fi
}

# Count the frontmatter delimiter lines (`---`) in a file. A well-formed
# file has at least 2 (opening + closing); fewer means the frontmatter
# block never closes, and any "required field" match found after that point
# is scanning the document body, not YAML.
count_frontmatter_delimiters() {
    local file="$1"
    grep -c '^---$' "$file" || true
}
