# Policy Specification

This document is the canonical source of truth for the **writing policy** schema in
the obsidian-workflows plugin. Before this file existed, the schema was defined only
implicitly — by the example files in `assets/Workflows/policy/*.md` and by whatever
`commands/write-review-policy.md` happened to check. That
implicit definition is a drift hazard: a policy can carry fields the review gate never
reads, and the review gate can expect fields no example demonstrates. This file makes
the contract explicit so both the generator (`commands/ow-policy.md`) and the consumer
(`write-review-policy`) reference one definition.

## What a policy is

A policy is a per-channel contract describing **what to write and in what
structure/length** (e.g. blog vs. daily-note vs. x-thread). It is orthogonal to
`SOUL.md`, which describes the **voice/tone** the text is written in. Both apply
together: policy is the structure gate, SOUL is the voice layer.

## Location and naming

- A policy is a single markdown file: `<policy_dir>/writing-policy.<name>.md`.
- `<policy_dir>` is resolved from the vault-local `writing-config.md` per
  [`contracts/path-resolution.md`](./contracts/path-resolution.md). It is never
  hardcoded, and its absence is a fail-fast error.
- `<name>` is the policy identifier. It MUST match `^[a-z0-9-]+$` and MUST equal the
  `policy_type` frontmatter value. It is also the key used in `writing-config.md`
  (`enabled_policies`, `default_policy`, `filename_rule.<name>`, etc.).

## Frontmatter schema

### Core fields (read by the review gate)

These are the fields `write-review-policy` inspects; keep them well-formed or
the structure gate silently degrades.

| Field | Type | Notes |
|---|---|---|
| `policy_type` | string | MUST equal `<name>` in the filename. This is also the key a target document's frontmatter carries to select its policy. |
| `output_type` | string | Artifact kind, e.g. `blog-post`, `x-thread`, `daily-note`, `linkedin-post`. |
| `target_length` | string | Length constraint. The **unit varies by channel** — words (`1200-1800 words`), posts (`8-15 posts`), etc. Free-form on purpose. |
| `required_sections` | list | Sections that must be present. Verified against the drafted body. |
| `cta_required` | boolean | Whether a call-to-action block is mandatory. |

### Housekeeping fields

| Field | Type | Notes |
|---|---|---|
| `created` / `updated` | string | ISO 8601 date-time, matching the plugin's frontmatter convention. |

### Optional channel-specific fields

Include only when the channel needs them. Observed fields (see the example policies for
concrete usage):

| Field | Example value | Used by |
|---|---|---|
| `reference_style` | `wikilink-first` | blog — how sources are cited |
| `line_style` | `short` | x-thread — per-post line discipline |
| `topic_required` | `false` | `ow-plan` active branch fail-fast contract |
| `source_strategy` | `previous-note` | draft/active — where to seed content from |
| `source_path_key` | `daily_notes_path` | config key that resolves the source directory |
| `missing_source_behavior` | `skip-and-prompt-recent` | what to do when the source is absent (drives `SKIP`) |
| `recent_candidates_limit` | `5` | how many recent files to offer as fallback |
| `creation_engine` | `obsidian` | note-creation engine |
| `template_engine` | `templater` | template engine |
| `template_key` | `daily_note_template` | config key resolving the template path |

The list is intentionally open: a new channel may introduce a new field. New fields
that the review gate should enforce must be added to the Core table above **and** to
`write-review-policy`, not just to an example file.

## Body structure

Below the frontmatter, the body is free-form guidance under a fixed section skeleton:

```markdown
# <Title> Policy

## Goal
<one or two sentences on what this channel's output is for>

## Structure
<ordered outline the draft should follow>

## Style   (or: ## Constraints)
<channel-specific writing rules>
```

The `## Structure` outline should correspond to `required_sections` so the review gate's
section check and the human-readable outline do not disagree.

## Relationship to `writing-config.md`

A policy file existing on disk is necessary but not sufficient. To be usable it must be
registered in the vault config:

- `enabled_policies` — the policy must appear here for `write-review-policy` and the
  `ow-*` tracks to accept it.
- `default_policy` — optional; the fallback when no policy is specified.
- `proposal_policy_allowlist` — optional; policies eligible for passive proposals.
- `filename_rule.<name>` — the output filename template (e.g. `{{date}}-{{slug}}`).

## Producers and consumers

- **Producer**: `commands/ow-policy.md` (`ow-policy`) generates a policy file
  interactively and, on confirmation, registers it in `writing-config.md`.
- **Validator**: `commands/write-review-policy.md` reads the
  Core fields to run the structure/length gate.
- **Other consumers**: `write-active`, `write-draft`, `write-refine`, `write-propose`,
  `write-init`, and the `ow-plan`/`ow-work`/`ow-review` tracks all resolve and validate
  policies through the same `policy_dir/writing-policy.<name>.md` path.

## Examples

See `assets/Workflows/policy/writing-policy.{blog,daily-note,x-thread,newsletter,weekly-review}.md`
for complete, working policies. `blog` demonstrates the core fields plus
`reference_style`; `daily-note` demonstrates the full set of source/template channel
fields.
