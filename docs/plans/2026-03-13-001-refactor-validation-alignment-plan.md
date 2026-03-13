---
title: Align local validation with CI to prevent recurring lint failures
type: refactor
status: active
date: 2026-03-13
---

## Align local validation with CI to prevent recurring lint failures

## Overview

This repository has strong validation coverage, but the validation experience is fragmented across local scripts, npm commands, pre-commit hooks, and GitHub Actions. That fragmentation makes it too easy for contributors to pass a partial local check set and still fail in CI for predictable reasons such as frontmatter syntax errors, markdown lint issues, generated `COMMANDS.md` drift, hook-path validation failures, or workflow-only YAML problems.

This plan proposes a validation-alignment refactor focused on reducing **CI-only failures that should have been caught locally**. The goal is not to add more independent checks, but to make the existing checks easier to run consistently, easier to understand, and harder to bypass accidentally.

The preferred implementation shape is:

- **small validation scripts in `tools/`** as the executable units of policy
- **a `Makefile`** as the single human-facing discovery and orchestration layer
- **CI jobs calling the same underlying scripts** so local and CI behavior stay aligned

## Problem Statement

The current repository already enforces important contracts:

- command frontmatter structure
- command-name uniqueness and namespace boundaries
- hook path safety
- generated `COMMANDS.md` freshness
- markdown/frontmatter/YAML linting
- fail-fast command semantics

However, those rules are not presented through a single canonical local workflow.

### Current pain points

1. **Local validation does not fully mirror CI**
   - `package.json:6-12` defines `validate:all`, but it does not cover all CI-relevant checks such as markdown lint, hook-path validation, command shell validation, or generated `COMMANDS.md` drift.

2. **Pre-commit is powerful but optional**
   - `CLAUDE.md:47-54` recommends pre-commit, but contributors who skip installation can reach CI without ever running the highest-value local checks.

3. **Generated artifact drift is detected late**
   - `.github/workflows/generate-docs.yml:23-39` correctly fails when `COMMANDS.md` is stale, but the failure often appears only after a push.

4. **Documentation and canonical rules have migration drift**
   - Some docs still describe older namespaces/layout expectations while validators enforce newer canonical rules, which increases the chance of contributor mistakes.

5. **Workflow YAML changes are more likely to fail only in CI**
   - `.pre-commit-config.yaml:5-6` excludes `.github/workflows/` from `check-yaml`, so workflow syntax/config issues may bypass the normal local path.

## Proposed Solution

Create a **validation alignment layer** that makes the repository's existing rules operationally consistent across:

- local development
- pre-commit
- CI
- contributor onboarding

The refactor should center on five changes:

1. **Split validation into explicit scripts under `tools/`**
   - Each major validation concern should have a stable executable unit, such as frontmatter, markdown, hook paths, generated docs freshness, and workflow validation.

2. **Add a `Makefile` as the canonical local interface**
   - Contributors should be able to discover and run validation through clear targets such as `make help`, `make validate-fast`, and `make validate-ci`.

3. **Separate fast checks from CI-parity checks**
   - Keep a lightweight inner-loop path for iteration speed, but make the PR-ready path explicit and canonical.

4. **Move late failures earlier**
   - Surface generated-file drift, hook-path issues, frontmatter parse failures, markdown lint issues, and workflow YAML problems before push whenever possible.

5. **Make rule ownership and contributor guidance explicit**
   - Clearly state which artifacts are canonical (`commands/` and validator rules) and which are derived (`COMMANDS.md`, explanatory docs), then document exactly what contributors should run and when.

## Technical Approach

### Architecture

Treat validation as a layered system with explicit responsibilities:

1. **Canonical rules layer**
   - Frontmatter schema, command discovery rules, namespace rules, hook-path requirements, generated-doc expectations.

2. **Execution layer**
   - Shell scripts in `tools/`, existing Node validators in `scripts/`, pre-commit hooks, and CI workflows.

3. **Contributor interface layer**
   - A `Makefile` that exposes one or two stable commands users actually run.
   - Clear documentation for when to use each target.

4. **Recovery layer**
   - Standardized failure messages and remediation guidance.

The refactor should reduce the gap between layers rather than replacing them.

### Implementation Phases

#### Phase 1: Define the validation contract

- Inventory current checks and classify them as:
  - CI-blocking and locally reproducible
  - CI-blocking but currently not surfaced locally
  - convention-only / review-time guidance
- Establish source-of-truth hierarchy:
  - canonical source: `commands/` plus validators
  - derived output: `COMMANDS.md`
  - explanatory docs: guides and migration references
- Decide the standard local entrypoints:
  - fast feedback command
  - CI-parity command
- Define change-type-specific check sets:
  - docs-only
  - command/frontmatter changes
  - validator/tooling changes
  - workflow YAML changes

#### Phase 2: Align the execution surface

- Normalize validation into named scripts under `tools/`, reusing existing shell and Node validators where possible instead of rewriting them.
- Add a root `Makefile` that serves as the canonical contributor interface.
- Expose clear targets such as:
  - `make help`
  - `make validate-fast`
  - `make validate-ci`
  - `make validate-commands`
  - `make validate-workflows`
  - `make validate-generated`
- Ensure `make validate-ci` includes, at minimum:
  - command frontmatter validation
  - duplicate/namespace validation
  - markdown lint
  - frontmatter lint
  - hook-path validation
  - command shell validation
  - generated `COMMANDS.md` freshness check
- Decide whether workflow YAML validation should be implemented as a dedicated script such as `tools/validate-workflows.sh` and surfaced via `make validate-workflows`.
- Update CI jobs so they call the same underlying `tools/` scripts used by the `Makefile`, reducing local-vs-CI drift.

#### Phase 3: Improve contributor UX and failure recovery

- Update validation documentation and contributor guidance.
- Add a concise pre-PR checklist.
- Standardize failure output so it answers:
  - what failed
  - why it failed
  - what command to run next
- Add remediation guidance for the most common classes of CI-only failures:
  - stale `COMMANDS.md`
  - invalid frontmatter YAML
  - markdown lint violations
  - invalid hook paths
  - workflow YAML issues

#### Phase 4: Clean migration drift in docs and examples

- Update outdated command layout/namespace references.
- Remove or rewrite docs that present legacy structures as current practice.
- Distinguish between enforced rules and conventions not currently enforced by tooling.
- Ensure that validator behavior and docs agree on canonical paths and naming.

#### Phase 5: Measure and stabilize

- Track recurring CI failures by category for a defined window before and after rollout.
- Verify that the top recurring local-reproducible CI failures are now caught by the CI-parity local command.
- Adjust check grouping if local friction becomes excessive.

## Alternative Approaches Considered

### 1. Add more CI jobs only

Rejected because the problem is not a lack of CI coverage. CI already catches many issues correctly. The recurring pain is that contributors often discover predictable failures too late.

### 2. Force everything through pre-commit only

Rejected as the sole strategy because pre-commit is optional in this repository today, and some contributors will continue to use manual flows. Pre-commit should remain a strong path, but not the only reliable one.

### 3. Remove generated `COMMANDS.md` from version control

Not chosen as the default direction in this plan. That could reduce drift, but it changes repository ergonomics and may affect discoverability/review workflows. The lower-risk first step is to make drift detection earlier and clearer.

### 4. Replace shell and Node validators with one new validator framework

Rejected for now. That would be a much larger rewrite than needed. The more direct fix is to align existing validators behind clearer entrypoints and clearer ownership.

### 5. Keep validation entrypoints split across npm scripts, ad-hoc shell invocations, and CI-only commands

Rejected because discoverability is a major part of the problem. A small-script-plus-Makefile structure gives contributors one obvious place to look without requiring all validation logic to move into Make itself.

## System-Wide Impact

### Interaction Graph

A typical command-file change currently triggers multiple partially overlapping systems:

- contributor edits `commands/**/*.md`
- pre-commit may run frontmatter validation, command validation, and command-index regeneration
- CI `validate.yml` runs shell validators and structure checks
- CI `lint.yml` runs markdown/frontmatter/YAML lint
- CI `generate-docs.yml` regenerates `COMMANDS.md` and fails if the checked-in file is stale

This means a single logical mistake can surface at different times depending on which local tooling the contributor happened to run.

### Error & Failure Propagation

Current failure propagation is too late for several common issues:

- invalid frontmatter syntax may first appear in CI frontmatter lint
- stale `COMMANDS.md` may first appear in generated-docs CI
- workflow YAML mistakes may first appear in CI because local pre-commit excludes `.github/workflows/`
- outdated docs can lead contributors into invalid structures that validators later reject

The planned system should shift failures left so CI becomes confirmation, not first discovery.

### State Lifecycle Risks

There is no production data risk, but there is repository-state drift risk:

- generated file drift (`COMMANDS.md`)
- documentation drift from validator-enforced rules
- contributor environment drift when local toolchains differ from CI expectations

The plan should explicitly manage these states rather than leaving them implicit.

### API Surface Parity

Equivalent validation surfaces need consistent expectations:

- `Makefile` targets as the human-facing entrypoint
- shell validator scripts in `tools/`
- Node validators in `scripts/`
- pre-commit hooks in `.pre-commit-config.yaml`
- GitHub Actions workflows in `.github/workflows/`
- contributor-facing docs in `CLAUDE.md` and `docs/validation-guide.md`

If one surface says “run X” while another actually enforces Y+Z, the system remains fragile.

### Integration Test Scenarios

The implementation should validate at least these cross-layer scenarios:

1. **Command frontmatter change**
   - Modify a command file with malformed frontmatter and confirm the CI-parity local path catches it before push.

2. **Generated docs drift**
   - Modify `commands/**/*.md` without regenerating `COMMANDS.md` and confirm the local PR-ready path fails with a clear remediation message.

3. **Workflow-only change**
   - Modify `.github/workflows/*.yml` and confirm there is a documented and runnable local validation path.

4. **Docs migration drift**
   - Introduce an outdated namespace/path example in docs and confirm maintainers can identify whether that rule is enforced or convention-only.

5. **Fresh contributor path**
   - In a clean environment, follow onboarding instructions and verify a contributor can reach a successful pre-PR validation flow without tribal knowledge.

## Acceptance Criteria

### Functional Requirements

- [ ] The repository has a root `Makefile` with documented validation targets for contributor discovery.
- [ ] The repository has a documented **single CI-parity local validation target** for PR readiness (for example, `make validate-ci`).
- [ ] The CI-parity local validation target covers the major recurring CI failure classes that are locally reproducible:
  - [ ] frontmatter validation
  - [ ] duplicate/namespace validation
  - [ ] markdown lint
  - [ ] frontmatter lint
  - [ ] hook-path validation
  - [ ] command shell validation
  - [ ] generated `COMMANDS.md` freshness
- [ ] The repository also has a clearly documented **fast local validation target** for inner-loop iteration (for example, `make validate-fast`).
- [ ] Change-type-specific validation guidance exists for docs changes, command changes, validator changes, and workflow changes.
- [ ] Workflow YAML changes have a documented local validation path instead of relying on CI as the first feedback point.
- [ ] Validation docs explicitly define canonical vs derived artifacts.
- [ ] Documentation no longer presents legacy namespace/layout examples as current canonical practice.

### Non-Functional Requirements

- [ ] The `Makefile` targets are easy to discover from top-level docs and via `make help`.
- [ ] Validation failures provide actionable remediation guidance.
- [ ] The fast path remains lightweight enough that contributors will actually use it.
- [ ] The plan preserves the repository's fail-fast philosophy from `CLAUDE.md:12-16`.

### Quality Gates

- [ ] Updated validation guidance is consistent across `CLAUDE.md`, `docs/validation-guide.md`, and any contributor-facing command references.
- [ ] At least one explicit scenario test exists for generated-file drift detection.
- [ ] At least one explicit scenario test exists for invalid command frontmatter detection.
- [ ] At least one explicit scenario test exists for workflow YAML validation guidance.

## Success Metrics

Measure over a defined post-rollout window:

- reduction in CI failures caused by locally reproducible issues
- reduction in `generate-docs` failures caused by stale `COMMANDS.md`
- reduction in frontmatter/markdown lint failures first discovered in CI
- improved first-PR success rate for contributors following the documented setup flow
- lower median time-to-fix after CI validation failures due to better remediation messaging

## Dependencies & Prerequisites

- agreement on canonical validation script boundaries and `Makefile` target names
- agreement on whether pre-commit remains optional or becomes the strongly preferred default
- agreement on how to validate workflow YAML locally
- maintainers available to clean migration-drift documentation

## Risk Analysis & Mitigation

### Risk: Added local friction slows contributors down

Mitigation:
- keep fast and PR-ready paths separate
- document when each path should be used
- avoid forcing heavyweight checks on every small edit loop

### Risk: `Makefile` targets diverge from CI over time

Mitigation:
- treat `make validate-ci` as a maintained interface, not a convenience alias
- keep CI jobs pointed at the same underlying `tools/` scripts
- review target composition whenever CI workflows change
- document ownership explicitly

### Risk: Docs and validators drift again after cleanup

Mitigation:
- define canonical ownership in docs
- update docs in the same workstream as validator changes
- distinguish enforced rules from conventions

### Risk: Workflow validation remains CI-first despite guidance

Mitigation:
- explicitly add a workflow change path to validation docs
- decide whether a dedicated local workflow validation command is required

### Risk: Scope expands into a full validator rewrite

Mitigation:
- keep this effort focused on alignment and contributor experience
- reuse the current shell/Node validation structure where possible

## Documentation Plan

Update, at minimum:

- `CLAUDE.md`
- `docs/validation-guide.md`
- `docs/command-specification.md`
- `docs/migration/command-discovery-contract.md`
- any contributor-facing README/quick-start references to validation entrypoints

Document these explicitly:

- canonical `Makefile` targets and what each one runs
- which `tools/` scripts back each target
- when to use fast vs PR-ready validation
- generated `COMMANDS.md` policy
- workflow YAML validation path
- canonical vs derived artifacts
- enforced rules vs conventions

## AI-Era Considerations

This repository is especially vulnerable to AI-assisted breakage because command markdown, frontmatter, and generated docs are easy to edit quickly but easy to misalign with validators. The validation strategy should assume contributors will use AI for rapid edits and therefore must provide:

- one obvious pre-PR validation target
- deterministic remediation messages
- strong generated-file drift guidance
- explicit documentation of canonical structures

AI tools used during planning:

- Claude Code local repository research agents
- Claude Code spec-flow analysis

## Sources & References

### Internal References

- `CLAUDE.md:12-16` — fail-fast, path safety, deterministic command discovery
- `CLAUDE.md:29-58` — local validation, pre-commit, CI overview
- `package.json:6-12` — current npm validation scripts and scope gap
- `.pre-commit-config.yaml:5-6` — workflow YAML excluded from `check-yaml`
- `.pre-commit-config.yaml:15-38` — local hooks for frontmatter validation and command index generation
- `.github/workflows/validate.yml:17-72` — shell-based validation jobs in CI
- `.github/workflows/lint.yml:19-69` — markdown/YAML/frontmatter lint jobs in CI
- `.github/workflows/generate-docs.yml:23-39` — generated `COMMANDS.md` freshness enforcement
- `tools/check-frontmatter.sh:26-60` — required fields and basic frontmatter validation
- `tools/validate-command.sh:34-95` — command contract checks and shell hook validation
- `tools/validate-hook-paths.sh:18-45` — hook path enforcement
- `scripts/validate-commands.js:10-44` — Node-based frontmatter and date validation
- `scripts/check-duplicates.js:53-188` — namespace, duplicate, and layout validation
- `scripts/lint-frontmatter.js:17-38` — YAML frontmatter parsing lint
- `docs/command-specification.md:25-135` — command contract and path/status rules
- `docs/frontmatter-reference.md:13-152` — frontmatter field conventions and date expectations
- `docs/migration/command-discovery-contract.md:7-29` — canonical source and duplicate/layout constraints
- `docs/validation-guide.md` — contributor-facing validation workflow guidance

### Institutional Learnings

- No `docs/solutions/` directory was present; relevant historical guidance was inferred from current validation docs, CI workflows, and validator scripts.
- Existing repo structure already has strong primitives; the main issue is operational alignment, not missing validation categories.

### External References

- No external research performed. The problem is repository-specific and local documentation/code patterns were sufficient.

## Recommended Next Step

Implement this as a **standard issue / refactor plan**, starting with validation contract definition, extraction of stable `tools/` validation scripts, and introduction of a root `Makefile` before any validator rewrites.
