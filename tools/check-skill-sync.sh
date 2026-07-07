#!/usr/bin/env bash
# check-skill-sync.sh - Detect SKILL.md <-> command mirror drift.
#
# Each skills/<name>/SKILL.md records `mirrors: <command-path>` and
# `mirror_hash: <hash of that command's body>`. This script recomputes the
# paired command's body hash and fails when it no longer matches the recorded
# value -- i.e. the command changed but the skill was not re-synced.
#
# It is a forcing function, not a proof of semantic equivalence: a mismatch
# means "the command body moved since this skill was last acknowledged; review
# the skill against the command, then run tools/update-skill-hash.sh <name>".
# See docs/skill-specification.md ("Skill Body Conventions").
#
# Args (SKILL.md paths from a pre-commit hook) are ignored: the check always
# evaluates every skill so a change to a command alone still triggers it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh
source "$SCRIPT_DIR/lib/frontmatter.sh"
# shellcheck source=lib/mirror-hash.sh
source "$SCRIPT_DIR/lib/mirror-hash.sh"

ERRORS=0
CHECKED=0

check_one() {
    local file="$1"
    ((CHECKED++))

    local mirrors recorded actual
    mirrors=$(extract_field "$file" "mirrors")
    recorded=$(extract_field "$file" "mirror_hash")

    if [[ -z "$mirrors" ]]; then
        echo -e "${RED}ERROR${NC}: $file - missing 'mirrors' field"
        ((ERRORS++))
        return
    fi
    if [[ -z "$recorded" ]]; then
        echo -e "${RED}ERROR${NC}: $file - missing 'mirror_hash' field"
        ((ERRORS++))
        return
    fi
    if [[ ! -f "$mirrors" ]]; then
        echo -e "${RED}ERROR${NC}: $file - mirrors target '$mirrors' not found"
        ((ERRORS++))
        return
    fi

    actual=$(mirror_hash_of_command "$mirrors")
    if [[ "$recorded" != "$actual" ]]; then
        local name
        name=$(basename "$(dirname "$file")")
        echo -e "${RED}ERROR${NC}: $file - drift from '$mirrors'"
        echo -e "        recorded=$recorded actual=$actual"
        echo -e "        The command body changed. Review the skill against the command, then run:"
        echo -e "        tools/update-skill-hash.sh $name"
        ((ERRORS++))
    fi
}

main() {
    echo "Checking skill<->command sync..."

    if [[ ! -d "skills" ]]; then
        echo -e "${RED}ERROR${NC}: skills directory not found"
        exit 1
    fi

    local file
    while IFS= read -r -d '' file; do
        # `|| true` suppresses `set -e` inside check_one so the `(( CHECKED++ ))`
        # / `((ERRORS++))` arithmetic (which returns exit 1 when the pre-increment
        # value is 0) does not abort the loop under bash 5.x. Matches the sibling
        # pattern in check-skill-frontmatter.sh. ERRORS is a global; the final
        # `[[ $ERRORS -eq 0 ]]` still governs the exit code.
        check_one "$file" || true
    done < <(find skills -type f -name "SKILL.md" -print0)

    echo ""
    echo "Checked $CHECKED skill files"

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}Found $ERRORS drift error(s)${NC}"
    else
        echo -e "${GREEN}All checks passed!${NC}"
    fi

    [[ $ERRORS -eq 0 ]]
}

main "$@"
