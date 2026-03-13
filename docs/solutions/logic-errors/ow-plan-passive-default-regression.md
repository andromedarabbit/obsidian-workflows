---
title: ow:plan passive-default regression
category: logic-errors
date: 2026-03-13
tags:
  - ow-plan
  - passive-default
  - intent-gate
  - regression-test
  - external-tools
  - command-contract
---

## Problem

`/obsidian-workflows:ow:plan` should default to the passive branch when `--intent` is omitted. After updating the command contract, the flow was still reported as interactive in real use.

This looked like a branch-selection regression, but the visible prompt was not always the intent gate itself.

## Symptom

Observed behavior:

- Running `/obsidian-workflows:plan` without `--intent` still appeared to ask a question.
- Users interpreted the visible question as an intent-selection prompt.
- This made it look as though omitted `--intent` was no longer defaulting to passive.

## Root Cause

The issue was a **behavior-contract drift plus prompt-source ambiguity**.

Two things were happening:

1. The canonical command contract and the internal skill/reference document were not guaranteed to stay aligned.
2. A prompt caused by `external_tools.auto_use: ask` could be mistaken for an intent-selection prompt.

So the real failure mode was not only “wrong branch routing,” but also “we had no regression coverage that distinguished intent prompts from external-tool prompts.”

## Canonical Source

Treat this file as the behavioral source of truth:

- `commands/ow/plan.md`

Important contract points in the canonical command:

- omitted `--intent` defaults to `passive`
- explicit `--intent=active` routes without prompting
- explicit `--intent=passive` routes without prompting
- `external_tools.auto_use: ask` may still produce an external-tool confirmation prompt
- fast mode skips external-tools detection
- passive flow preserves `PASS|SKIP` semantics

## Solution

The fix was implemented in two layers.

### 1. Align the PLAN reference with the canonical command contract

Updated:

- `skills/plan/SKILL.md`

This removed the stale “first confirm user intent” behavior description and changed it to:

- omitted `--intent` defaults to passive
- explicit active/passive both proceed without questions

### 2. Add automated regression coverage

Added:

- `scripts/validate-behavior-contracts.js`
- `scripts/test-plan-passive-default.js`
- `tests/migration/fixtures/plan-passive-default.json`

Integrated into:

- `package.json`
- `tools/validate-ci.sh`

This added two different protections:

#### Canonical contract validation

`validate-behavior-contracts.js` checks the structure of `commands/ow/plan.md` only.

It verifies that the canonical command contract still contains:

- omitted intent => passive
- explicit active/passive => no prompt
- external-tool ask behavior
- fast-mode external-tool skip
- active/passive branch documentation
- passive `PASS|SKIP` semantics

This keeps CI anchored to the canonical command definition instead of treating README or other mirrors as behavioral truth.

#### Scenario-based regression check

`test-plan-passive-default.js` reads the canonical command contract and evaluates fixture scenarios such as:

- omitted intent defaults to passive
- explicit passive stays passive
- external-tools ask is not intent prompt
- fast mode skips external-tools question
- explicit active routes without prompt

The fixture lives in:

- `tests/migration/fixtures/plan-passive-default.json`

This is not a full runtime E2E harness, but it is stronger than a plain text consistency check because it validates behavior-oriented scenarios against the canonical contract.

## Supporting Documentation Updates

Updated:

- `tests/migration/smoke-plan-passive.md`
- `README.md`

These changes make the expected behavior explicit for humans:

- `/obsidian-workflows:plan` with omitted intent should behave like passive
- any remaining prompt under `external_tools.auto_use: ask` is not an intent-selection prompt

## Why This Fix Works

It closes the actual failure mode instead of only patching wording.

- The canonical command contract is now the only CI-gated behavioral source.
- The internal PLAN reference is aligned with the canonical contract.
- Regression checks now distinguish:
  - intent-selection prompt
  - external-tool confirmation prompt
- Passive behavior keeps its existing `PASS|SKIP` meaning.

This prevents the original class of regression:

- command contract updated, but reference/interpretation drifted
- a later visible prompt gets misclassified as intent-selection behavior

## Prevention

### 1. Keep behavioral truth in one place

Use `commands/ow/plan.md` as the single behavioral source of truth.

Reference files like `skills/plan/SKILL.md`, README examples, and smoke docs should mirror that behavior, but they should not become independent sources of CI truth.

### 2. Distinguish prompt origin

When a user says “it still asked me,” check whether the prompt came from:

- the **intent gate**
- or **external tools detection**

Useful signal:

- intent prompt changes branch selection
- external-tools prompt only changes whether a detected tool is used

### 3. Test omitted intent explicitly

Do not rely only on explicit passive examples.

Always keep a regression case for:

- `/obsidian-workflows:plan`

not just:

- `/obsidian-workflows:plan --intent passive`

### 4. Verify fast mode separately

Fast mode changes the prompt surface by skipping external-tools detection. That should remain a separate scenario in regression coverage.

## Validation Commands

Run these after changing plan behavior:

```bash
npm run validate:behavior-contracts
npm run test:plan-passive-default
make validate-ci
```

## Files Involved

### Canonical behavior
- `commands/ow/plan.md`

### Reference and user-facing docs
- `skills/plan/SKILL.md`
- `README.md`
- `tests/migration/smoke-plan-passive.md`

### Regression coverage
- `scripts/validate-behavior-contracts.js`
- `scripts/test-plan-passive-default.js`
- `tests/migration/fixtures/plan-passive-default.json`
- `tools/validate-ci.sh`
- `package.json`

## Related References

- `docs/contracts/error-messages.md`
- `docs/migration/command-discovery-contract.md`
- `tests/migration/smoke-work-draft-autodetect.md`
- `docs/validation-guide.md`

## Takeaway

This bug was not just “the wrong default branch.”

It was a contract-maintenance problem:

- one canonical command contract
- multiple mirrored descriptions
- and no automated way to distinguish intent prompts from external-tool prompts

The fix was to make the canonical behavior explicit, align the mirror, and add regression coverage that tests the behavior people actually perceive.
