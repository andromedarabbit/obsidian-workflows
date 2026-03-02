---
status: complete
priority: p2
issue_id: 001
tags: [code-review, quality, lint, docs]
dependencies: []
---

# Problem Statement

Markdown lint configuration is currently split between `.markdownlint.json` and `.markdownlint-cli2.jsonc`.
This can create long-term drift where developers update one config and assume all lint execution paths use the same rules.

## Findings

- `.markdownlint.json` was added to configure markdown rules (`MD004`, `MD012`, `MD013`, etc.).
- `.markdownlint-cli2.jsonc` also defines markdown rules (`MD013`, `MD033`, `MD041`) and globs/ignores.
- `package.json` uses `markdownlint-cli2` in `lint:markdown`, so CLI2 config is the active execution path for npm/CI lint runs.
- Result: current behavior is working, but configuration ownership is ambiguous.

Evidence:
- `.markdownlint.json:1`
- `.markdownlint-cli2.jsonc:1`
- `package.json:9`
- `.github/workflows/lint.yml:35`

## Proposed Solutions

## Option 1: Keep both, document ownership clearly

- Pros: minimal code churn, preserves editor compatibility where `.markdownlint.json` is used.
- Cons: still two files to keep in sync, risk of future drift remains.
- Effort: Small
- Risk: Medium

## Option 2: Make `.markdownlint-cli2.jsonc` the single source of truth

- Pros: one authoritative config for CI and local npm path.
- Cons: some editor integrations may need explicit setup.
- Effort: Small
- Risk: Medium

## Option 3: Generate one config from the other (scripted sync)

- Pros: preserves compatibility while reducing manual drift.
- Cons: adds tooling complexity.
- Effort: Medium
- Risk: Low

## Recommended Action

Adopt **Option 1 (documented split ownership)** with explicit source-of-truth guidance:

- `.markdownlint.json` owns markdown rule configuration.
- `.markdownlint-cli2.jsonc` owns CLI2 runner options (`globs`, `ignores`) only.

## Technical Details

Affected files:
- `.markdownlint.json`
- `.markdownlint-cli2.jsonc`
- `package.json`
- `.github/workflows/lint.yml`

## Acceptance Criteria

- [x] A clear primary markdownlint configuration source is chosen.
- [x] Project docs specify how markdown lint config should be updated.
- [x] CI and local lint paths remain green after decision.

## Work Log

- 2026-03-02: Created from `/ce:review` synthesis for commit `20c688e`.
- 2026-03-02: Removed duplicated rule config from `.markdownlint-cli2.jsonc`.
- 2026-03-02: Added source-of-truth guidance to `docs/validation-guide.md`.
- 2026-03-02: Verified with `npm run lint:markdown` (0 errors).

## Resources

- PR/commit reviewed: `20c688e`
- Review context: `/ce:review` follow-up execution
