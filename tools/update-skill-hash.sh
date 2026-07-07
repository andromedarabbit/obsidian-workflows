#!/usr/bin/env bash
# update-skill-hash.sh - Regenerate the `mirror_hash` field in SKILL.md files
# from their paired command body. Run this after intentionally syncing a skill
# to its command so the drift check (tools/check-skill-sync.sh) goes green.
#
# Usage:
#   tools/update-skill-hash.sh              # update all skills
#   tools/update-skill-hash.sh plan work    # update named skills only
#
# Each target SKILL.md must already carry a `mirrors:` field and a
# `mirror_hash:` line (add both when creating the skill); this script only
# rewrites the recorded hash value.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh
source "$SCRIPT_DIR/lib/frontmatter.sh"
# shellcheck source=lib/mirror-hash.sh
source "$SCRIPT_DIR/lib/mirror-hash.sh"

update_one() {
    local file="$1"
    local mirrors hash

    mirrors=$(extract_field "$file" "mirrors")
    if [[ -z "$mirrors" ]]; then
        echo -e "${RED}ERROR${NC}: $file - missing 'mirrors' field"
        return 1
    fi
    if [[ ! -f "$mirrors" ]]; then
        echo -e "${RED}ERROR${NC}: $file - mirrors target '$mirrors' not found"
        return 1
    fi
    if ! grep -q '^mirror_hash:' "$file"; then
        echo -e "${RED}ERROR${NC}: $file - no 'mirror_hash:' line to update (add the field first)"
        return 1
    fi

    hash=$(mirror_hash_of_command "$mirrors")

    # Portable in-place rewrite (avoids GNU/BSD `sed -i` divergence).
    local tmp
    tmp=$(mktemp)
    sed "s|^mirror_hash:.*|mirror_hash: $hash|" "$file" > "$tmp" && mv "$tmp" "$file"
    echo -e "${GREEN}updated${NC}: $file  mirror_hash=$hash  ($mirrors)"
}

main() {
    local targets=()
    if [[ "$#" -gt 0 ]]; then
        local n
        for n in "$@"; do targets+=("skills/$n/SKILL.md"); done
    else
        local f
        while IFS= read -r -d '' f; do targets+=("$f"); done \
            < <(find skills -type f -name "SKILL.md" -print0)
    fi

    local rc=0 t
    for t in "${targets[@]}"; do
        update_one "$t" || rc=1
    done
    return $rc
}

main "$@"
