# Skill Specification

This document defines the contract for Agent Skill definitions in the obsidian-workflows plugin, and states this repository's relationship to the house rules in the sibling `oh-my-skills` repository.

## Overview

Skills are track entrypoints and the canonical source of behavioral truth. Each skill is defined by a single `SKILL.md` file with YAML frontmatter that specifies its metadata.

## File Structure

Skills are stored in `skills/<name>/` with the following structure:

```
skills/
├── ow-plan/
│   ├── SKILL.md
│   └── references/
├── ow-work/
│   ├── SKILL.md
│   └── references/
├── ow-review/
│   ├── SKILL.md
│   └── references/
├── ow-policy/
│   ├── SKILL.md
│   └── references/
└── ow-compound/
    └── SKILL.md
```

A skill directory MUST contain `SKILL.md`. It MAY additionally contain a `references/` directory for Anthropic-style progressive disclosure — large or runtime-only detail (handoff menu specs, mode-inference tables, voice-tool wiring) lives there and is read on demand, instead of staying resident in `SKILL.md` every turn the skill is active. `README.md`, `GUIDELINES.md`, and `scripts/tests/run.sh` remain prohibited. References must stay **one level deep** (`SKILL.md` → reference, no chaining A→B→C), and a reference over 100 lines should open with a table of contents so partial reads don't lose scope — see [Relationship to oh-my-skills House Rules](#relationship-to-oh-my-skills-house-rules).

## Frontmatter Contract

### Required Fields

#### `name` (string)
- **Format**: kebab-case, with `ow-` prefix for track entrypoints
- **Pattern**: `^[a-z0-9-]+$`
- **Rule**: MUST equal the skill's directory name
- **Examples**: `ow-plan`, `ow-work`, `ow-review`, `ow-compound`

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
- All five skills in this repository (`ow-plan`, `ow-work`, `ow-review`, `ow-policy`, `ow-compound`) are `context: inline` for exactly this reason

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

### Claude Code Official Fields (optional)

These fields are part of the official Claude Code skill spec ([docs](https://code.claude.com/docs/en/skills)) and are accepted by `tools/check-skill-frontmatter.sh`. This repository adopts some and merely permits others.

#### `disable-model-invocation` (boolean)

- **Purpose**: When `true`, Claude cannot load the skill autonomously — only an explicit slash invocation runs it. Use for workflows with side effects.
- **Adoption: Not adopted.** The `ow-*` skills hand off to each other through the `Skill` tool (ow-plan -> ow-work active handoff, ow-work passive -> ow-plan, ow-review -> ow-compound). The official Claude Code spec blocks a model-driven `Skill` tool call to a `disable-model-invocation: true` skill just as it blocks auto-loading, so setting it on any `ow-*` entry point would sever that chain — which is this plugin's core execution order. The side-effect concern it would guard against (state writes, config edits) is real, but the handoff chain is more fundamental, so `disable-model-invocation` is not used on the `ow-*` skills. Trigger-phrase coverage now scans `description` and `when_to_use` together (see [Validation](#validation)).

#### `when_to_use` (string)

- **Purpose**: Additional trigger context appended to `description` in the skill listing. Move verbose trigger phrases out of `description` so `description` stays a one-line summary.
- **Adoption**: **Adopted where descriptions run long.** `description` and `when_to_use` together are capped at 1,536 characters in the listing; this repository's own cap on `description` alone is 1,024. Splitting trigger phrases into `when_to_use` keeps `description` scannable.

#### `allowed-tools` / `disallowed-tools` (string/list)

- **Purpose**: Tools Claude may use without per-use approval during the turn that invokes the skill (`allowed-tools`), or tools removed from Claude's pool while the skill is active (`disallowed-tools`). The grant clears on the next message.
- **Adoption**: **Permitted, not yet applied.** `Skill(obsidian-workflows:*)` scoped pre-approval would cut handoff prompts, but it widens the permission surface, so applying actual values is deferred to a separate review. Documented here so the validator accepts them when introduced.

#### `paths` (string/list)

- **Purpose**: Glob patterns that limit when Claude loads the skill automatically.
- **Adoption**: **Permitted.** Not used today because the `ow-*` skills disable model invocation, which makes path-gated auto-loading moot.

#### `model` / `effort` (string)

- **Purpose**: Override the model or reasoning effort for the turn that invokes the skill.
- **Adoption**: **Permitted, not used.** The track skills inherit the session model and effort.

## Relationship to oh-my-skills House Rules

The sibling repository `oh-my-skills` (배민 데이터플랫폼팀) defines a stricter house layer on top of the public Agent Skills spec. obsidian-workflows adopts most of it, but diverges where the house rule assumes a scale or execution model this repository doesn't have.

### Adopted

- `name`, `description`, `version`, `context` are required fields
- `name` MUST be kebab-case and MUST equal the directory name
- `version` MUST be valid semver
- `agent` is meaningful, and set, only when `context: fork`

### Diverged

- **No mandatory `README.md`/`GUIDELINES.md` per skill.** This repository centralizes the skill contract in `docs/` (this file), the same way `docs/command-specification.md` centralizes the command contract instead of requiring per-command documentation files. Scattering the same contract across 4+ per-skill files would create drift surface without adding information.
- **No `scripts/tests/run.sh` mandate.** No skill in this repository ships a `scripts/` (executable code) directory. The rule only applies once a skill introduces one.
- **Optional `references/` is permitted for progressive disclosure.** Unlike mandatory boilerplate, a `references/` directory of on-demand Markdown is allowed and encouraged for skills whose `SKILL.md` body is dominated by runtime-only detail (e.g. `ow-plan`'s handoff menus). This aligns with Anthropic's skill authoring guidance (keep `SKILL.md` focused; read large/rarely-needed detail only when reached). The behavioral contract tests follow content into `references/` — they resolve a skill's full text as `SKILL.md` plus any `references/*.md` it points at, so pinned strings (handoff labels, routing rules) stay enforced after a split.
- **No re-adoption of `.claude/skills/` as the canonical path.** This repository intentionally uses a commands-centric model (`commands/` is the canonical, hook-path-relevant root); skills live at top-level `skills/<name>/SKILL.md`, not under `.claude/`.
- **The when-to-use trigger phrase is a WARNING, not an ERROR.** oh-my-skills treats a missing trigger phrase as an error because its skills rely primarily on Claude's autonomous description-matching for discovery. This repository's skills are invoked primarily via explicit slash commands (e.g. `/obsidian-workflows:ow-plan`); autonomous discovery only matters for the secondary case of one skill handing off to another via the `Skill` tool. A missing trigger phrase degrades a secondary path, not the primary one, so a hard CI block is disproportionate — but the trigger phrase is still cheap to add and should be added when writing or editing a skill's description.
- **Korean content style rules (em-dash ban, 외래어 표기법, terminology consistency) are NOT enforced by tooling — convention only.** oh-my-skills documents these as house rules. This repository is Korean-first and follows them as convention (see the root `CLAUDE.md` guidance on natural 우리말), but there is no lint gating them today. This is a deliberate "not yet", not "not applicable" — a terminology/em-dash linter over both `skills/` and `commands/` is a reasonable future addition; it is out of scope until the maintenance value clearly exceeds a per-author convention.

### Not Applicable

- Per-skill semver + CHANGELOG validation — over-engineered at this repository's scale (5 skills)
- Machine-readable divergence contracts or upstream rulebook lockfiles/pinning — oh-my-skills is a same-author internal repository, not a fast-moving external dependency that needs pinning
- `create-skill.sh` scaffolder and a generated `SKILLS.md` index — speculative tooling for a skill count (5) that shows no near-term growth signal. Revisit if the skill count grows past roughly 8–10 (see `CONTRIBUTING.md`)

## Skill Body Conventions

Each of the five track skills (`skills/ow-plan/SKILL.md`, `skills/ow-work/SKILL.md`, `skills/ow-review/SKILL.md`, `skills/ow-policy/SKILL.md`, `skills/ow-compound/SKILL.md`) is the canonical source of behavioral truth for its track. The skill is what tooling, the `Skill` tool, and slash-command invocations all read — there is no separate command file that takes precedence.

This model replaced the previous mirror/sync architecture (v0.3.0). Under the old model a `commands/ow-<name>.md` file was the behavioral source and the skill mirrored it; that relationship created drift risk and was removed. See `docs/solutions/logic-errors/ow-plan-passive-default-regression.md` for the regression that motivated the original enforcement mechanism, and `docs/plans/2026-07-07-001-feat-skill-command-mirror-sync-plan.md` for the superseded plan.

### Execution Layer Separation

The `ow-*` skills are deliberately `context: inline` and stay in the main conversation because they steer: they call `AskUserQuestion`, hand off to the next skill via the `Skill` tool within the same turn, and read/write session state (`.claude/state/*`). A `context: fork` skill runs in an isolated sub-agent with no conversation history — appropriate for self-contained tasks with explicit instructions, not for interactive steering, so the entry points do not fork (and `inline` + a stray `agent` field is rejected by `check-skill-frontmatter.sh`).

Execution is already separated into three layers, which is this plugin's agent/subagent split:

1. **Steering (`skills/ow-*`, inline)** — intent gating, mode routing, user questions, handoff menus.
2. **Deterministic execution (`commands/write-*`)** — the track skills route to these (e.g. `ow-work mode=active` → `write-active`). They carry the file/path/contract logic.
3. **Specialized external skills (via the `Skill` tool)** — e.g. `ow-review` delegates humanizing to `humanize-korean` rather than reimplementing voice cleanup.

When a skill needs deterministic investigation that would clutter the main context (external-tool availability probing, policy-schema validation), prefer delegating to an `Explore` sub-agent and acting on its summary, rather than loading those steps into the skill body. This keeps `SKILL.md` lean and the main thread focused on steering.

## Example Skill

```markdown
---
name: ow-plan
description: 'PLAN 트랙 진입점. 글쓰기 주제를 기획하거나 초안 작성 여부를 판단해 active/passive로 라우팅합니다.'
when_to_use: '"블로그 아이디어 3개 제안", "이 주제로 쓸까", "최근 노트에서 쓸 거 있나"처럼 주제를 정하거나 초안 착수 여부를 결정할 때 사용합니다.'
version: 0.3.0
context: inline
language: korean
created: 2026-03-02T01:34
updated: 2026-08-06T00:00
---

# PLAN Track Entry Point

...
```

The example mirrors the current `skills/ow-plan/SKILL.md` shape: a one-line `description` plus a `when_to_use` that carries the trigger examples. The actual file is always canonical.

## Validation

Skills are validated using:

1. **Frontmatter validation**: `tools/check-skill-frontmatter.sh` (required fields, `name`==directory, formats)
2. **Duplicate/collision detection**: `npm run validate:no-duplicates` (`scripts/check-duplicates.js` — checks duplicate skill names and skill/command name collisions; not re-implemented in the shell validator)

See [Validation Guide](./validation-guide.md) for details.
