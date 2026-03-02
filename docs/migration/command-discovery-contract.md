# Command Discovery Contract

## Goal

Define deterministic command discovery rules for this plugin repository.

## Canonical Sources

- Canonical command definitions live in `commands/`.
- `name` in frontmatter is the canonical command identity.
- One command name must map to one canonical file.

## Rules

1. No duplicate files defining the same canonical `name`.
2. If duplicates are detected, treat as contract violation and fail fast.
3. Keep command namespaces explicit:
   - Public workflow entrypoints: `obsidian-workflows:*`
   - Execution commands: `obsidian:write.*`
4. Companion docs may exist, but must not redefine command identities.

## Validation Checklist

- [ ] Every command file has frontmatter: `name`, `description`, `argument-hint`, `allowed-tools`, `created`, `updated`
- [ ] Every canonical `name` appears exactly once under `commands`
- [ ] No stale alternate command roots remain undocumented
