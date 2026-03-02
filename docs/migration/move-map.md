# Move Map: Vault Repo -> Dedicated Plugin Repo

## Source Repository

`/Users/keaton/Library/Mobile Documents/iCloud~md~obsidian/Documents/Markdown`

## Target Repository

`/Users/keaton/Workspace/Personal/obsidian-workflows`

## File Mapping

### Commands

- `.claude/commands/obsidian-workflows/*.md` -> `.claude/commands/obsidian-workflows/*.md`
- `.claude/commands/obsidian:write.*.md` -> `.claude/commands/obsidian:write.*.md`

### Skills

- `.claude/skills/*/SKILL.md` -> `.claude/skills/*/SKILL.md`
- `.claude/skills/skills.md` and companion `*.md` files -> same relative paths

### Plugin metadata

- `.claude-plugin/plugin.json` -> `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` -> `.claude-plugin/marketplace.json`

### Runtime templates

- `.claude/state/*.json` -> `.claude/state/*.json.example`
- `.claude/settings.local.json` -> `.claude/settings.local.json.example`

### Config/assets templates

- `writing-config.md` -> `config/writing-config.example.md`
- `Workflows/SOUL.md` -> `assets/Workflows/SOUL.md`
- `Workflows/policy/writing-policy*.md` -> `assets/Workflows/policy/writing-policy*.md`

## Notes

- Vault runtime data and user content are not moved as operational files.
- Dedicated repo stores templates/contracts; vault remains runtime/content host.
