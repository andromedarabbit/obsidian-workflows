# External Tools Integration Contract

## Policy

After a writing-track command finishes its primary output, it optionally
routes that output through external quality tools (humanizer /
grammar-checker / style-guide) before handing off to the next step. Not
every command uses every tool — each call site states its own applicable
subset (see Coverage Scope).

## Usage Mode

Controlled by `writing-config.md`'s `external_tools.auto_use`:

- `ask` (default): if an applicable tool is available, ask the user once
  before running it
- `true`: apply automatically, no question
- `false`: skip entirely

## Execution Order

When more than one tool applies at a call site, run them in this fixed
order: humanizer → grammar-checker → style-guide.

## Output

Report which tools ran and what they changed (counts/highlights), then
state the workflow's `Next:` command.

## Fail-safe

A tool failure produces a warning only; the workflow continues and the
primary output is never discarded because of it.

## Coverage Scope

- `commands/write-draft.md` — humanizer only
- `commands/write-refine.md` — humanizer, grammar-checker, style-guide
- `commands/write-review-policy.md` — grammar-checker, style-guide
- `commands/write-compound-capture.md` — humanizer only
