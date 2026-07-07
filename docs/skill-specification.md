# Skill Specification

This document defines the contract for Agent Skill definitions in the obsidian-workflows plugin, and states this repository's relationship to the house rules in the sibling `oh-my-skills` repository.

## Overview

Skills are entrypoint routers that mirror the behavior of a canonical command. Each skill is defined by a single `SKILL.md` file with YAML frontmatter that specifies its metadata.

## File Structure

Skills are stored in `skills/<name>/` with the following structure:

```
skills/
├── plan/
│   └── SKILL.md
├── work/
│   └── SKILL.md
├── review/
│   └── SKILL.md
└── compound/
    └── SKILL.md
```

A skill directory contains only `SKILL.md`. `README.md`, `GUIDELINES.md`, and `scripts/` are not required in this repository — see [Relationship to oh-my-skills House Rules](#relationship-to-oh-my-skills-house-rules).

## Frontmatter Contract

### Required Fields

#### `name` (string)
- **Format**: kebab-case, no namespace prefix
- **Pattern**: `^[a-z0-9-]+$`
- **Rule**: MUST equal the skill's directory name
- **Examples**: `plan`, `work`, `review`, `compound`

#### `description` (string)
- **Purpose**: What the skill does and when to use it
- **Length**: ≤1024 UTF-8 codepoints
- **Should** include a when-to-use trigger phrase (Korean: `할 때`/`일 때`/`요청 시`/`트리거`; English: `when to use`/`use when`/`trigger`) — see [Diverged](#diverged) for why this is a warning, not a hard requirement, here
- **Example**: `"PLAN 트랙 진입점. ... 글쓰기 주제를 계획하거나 초안 작성 여부를 판단해야 할 때 사용합니다."`

#### `version` (string)
- **Format**: Semantic versioning `MAJOR.MINOR.PATCH`
- **Example**: `"0.1.0"`

#### `context` (string)
- **Values**: `fork` | `inline`
- **`fork`**: the skill runs as an isolated sub-agent
- **`inline`**: the skill runs in the main conversation and shares its context — required when the skill calls `AskUserQuestion`, invokes the `Skill` tool to hand off to another skill within the same turn, or reads/writes session state
- All four skills in this repository (`plan`, `work`, `review`, `compound`) are `context: inline` for exactly this reason

### Conditionally Required Fields

#### `agent` (string)
- **Values**: `general-purpose` | `Explore` | `Plan`
- **Rule**: set ONLY when `context: fork`. When `context: inline`, omit `agent` entirely — a present-but-unused `agent` field is misleading metadata, not harmless extra documentation

### Optional Fields

#### `dependencies` (array)
- **Purpose**: External tool/version requirements, e.g. `["glab>=1.30"]`

#### `language` (string)
- **Purpose**: Declares the primary content language
- **Example**: `"korean"`

#### `user-invocable` (boolean)
- **Purpose**: Repository-specific extension field (not part of the oh-my-skills schema). Documents that this skill is meant to be invoked directly by the user (typically mirroring a slash command) rather than discovered autonomously

#### `created` / `updated` (string)
- **Format**: ISO 8601 date-time (matches the command frontmatter convention in [Frontmatter Reference](./frontmatter-reference.md))
- **Purpose**: Track when the skill was authored and when it was last modified. Not currently validated by `tools/check-skill-frontmatter.sh` (unlike the command validator, which enforces both fields as required and format-checked)

## Relationship to oh-my-skills House Rules

The sibling repository `oh-my-skills` (배민 데이터플랫폼팀) defines a stricter house layer on top of the public Agent Skills spec. obsidian-workflows adopts most of it, but diverges where the house rule assumes a scale or execution model this repository doesn't have.

### Adopted

- `name`, `description`, `version`, `context` are required fields
- `name` MUST be kebab-case and MUST equal the directory name
- `version` MUST be valid semver
- `agent` is meaningful, and set, only when `context: fork`

### Diverged

- **No mandatory `README.md`/`GUIDELINES.md` per skill.** This repository centralizes the skill contract in `docs/` (this file), the same way `docs/command-specification.md` centralizes the command contract instead of requiring per-command documentation files. Scattering the same contract across 4+ per-skill files would create drift surface without adding information.
- **No `scripts/tests/run.sh` mandate.** No skill in this repository ships a `scripts/` directory today. The rule only applies once a skill introduces one.
- **No re-adoption of `.claude/skills/` as the canonical path.** This repository intentionally uses a commands-centric model (`commands/` is the canonical, hook-path-relevant root); skills live at top-level `skills/<name>/SKILL.md`, not under `.claude/`.
- **The when-to-use trigger phrase is a WARNING, not an ERROR.** oh-my-skills treats a missing trigger phrase as an error because its skills rely primarily on Claude's autonomous description-matching for discovery. This repository's skills are invoked primarily via explicit slash commands (e.g. `/obsidian-workflows:ow:plan`); autonomous discovery only matters for the secondary case of one skill handing off to another via the `Skill` tool. A missing trigger phrase degrades a secondary path, not the primary one, so a hard CI block is disproportionate — but the trigger phrase is still cheap to add and should be added when writing or editing a skill's description.

### Not Applicable

- Per-skill semver + CHANGELOG validation — over-engineered at this repository's scale (4 skills)
- Machine-readable divergence contracts or upstream rulebook lockfiles/pinning — oh-my-skills is a same-author internal repository, not a fast-moving external dependency that needs pinning
- `create-skill.sh` scaffolder and a generated `SKILLS.md` index — speculative tooling for a skill count (4) that shows no near-term growth signal. Revisit if the skill count grows past roughly 8–10 (see `CONTRIBUTING.md`)

## Skill Body Conventions

Each of the four existing skills mirrors a canonical command file (`skills/plan/SKILL.md` mirrors `commands/ow/plan.md`, and so on for `work`, `review`, `compound`). This is intentional: the command is the single source of behavioral truth, and the skill file mirrors that behavior for the cases where the `Skill` tool (rather than the slash command) is the entry point. A skill's body MUST NOT diverge into independent behavior — if the command and skill disagree, the command wins, and the skill file must be updated to match.

This principle was already established the hard way: see `docs/solutions/logic-errors/ow-plan-passive-default-regression.md`, where a skill file drifted from its canonical command and caused a real regression. Keep this in mind when editing either file: a change to `commands/ow/<name>.md` that affects behavior should also be reflected in `skills/<name>/SKILL.md` in the same change.

## Example Skill

```markdown
---
name: plan
description: PLAN 트랙 진입점. 자연어 작성 요청은 active로, 작성 지시 없는 빈 plan은 passive 제안으로 라우팅하고, 종료는 텍스트 명령어가 아니라 AskUserQuestion handoff로 처리합니다. 글쓰기 주제를 계획하거나 초안 작성 여부를 판단해야 할 때 사용합니다.
version: 0.1.0
context: inline
language: korean
user-invocable: true
created: 2026-03-02T01:34
updated: 2026-07-07T00:00
---

# PLAN Track Entry Point

...
```

## Validation

Skills are validated using:

1. **Frontmatter validation**: `tools/check-skill-frontmatter.sh`
2. **Duplicate/collision detection**: `npm run validate:no-duplicates` (`scripts/check-duplicates.js` — checks duplicate skill names and skill/command name collisions; not re-implemented in the shell validator)

See [Validation Guide](./validation-guide.md) for details.
