#!/usr/bin/env bash
# mirror-hash.sh - Compute the content hash of a command file's BODY.
# Shared by tools/check-skill-sync.sh (drift detection) and
# tools/update-skill-hash.sh (hash regeneration) so both compute the hash
# identically. See docs/skill-specification.md ("Skill Body Conventions").
#
# The hash covers only the command BODY (everything after the closing
# frontmatter delimiter), NOT the frontmatter. The command's frontmatter
# carries volatile `created`/`updated` timestamps that would otherwise churn
# the hash on every edit; the behavioral truth a skill mirrors lives in the
# body. Interface frontmatter fields (`description`/`argument-hint`) are
# validated independently by tools/check-frontmatter.sh.

# Emit a sha256 hash of stdin. Wrapped in a function (not a string variable)
# so it does not depend on word-splitting, which differs between bash and zsh
# and would break when this file is sourced into a non-bash shell.
_mirror_sha256() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256
    else
        sha256sum
    fi
}

# Print the sha256 (first 16 hex chars) of a command file's body.
# Body = lines after the second `---` delimiter, with trailing whitespace
# stripped per line so the hash matches the repo's trailing-whitespace
# pre-commit normalization and does not churn on invisible edits.
mirror_hash_of_command() {
    local file="$1"
    awk '/^---$/ && c < 2 { c++; next } c >= 2 { print }' "$file" \
        | sed 's/[[:space:]]*$//' \
        | _mirror_sha256 \
        | cut -c1-16
}
