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
4. `commands/` must not include a nested legacy root matching plugin namespace (for this repo: `commands/obsidian-workflows/`).
   - Canonical entrypoints must stay directly under `commands/` (`commands/plan.md`, `commands/work.md`, `commands/review.md`, `commands/compound.md`).
5. Companion docs may exist, but must not redefine command identities.

## Validation Checklist

- [ ] Every command file has frontmatter: `name`, `description`, `argument-hint`, `allowed-tools`, `created`, `updated`
- [ ] Every canonical `name` appears exactly once under `commands`
- [ ] `commands/obsidian-workflows/` does not exist
- [ ] `npm run validate:no-duplicates` passes (duplicates + command/skill collision + legacy layout checks)
