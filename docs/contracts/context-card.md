# Context Card Contract

## Policy

Every command that reports run provenance via a Context Card reports the
same fixed set of fields at start/end, so a run's provenance is always
inspectable the same way regardless of which command produced it. On
failure, emit every field below with a `null` value when it is unknown --
never omit a field, so two conformant implementations always produce the
same shape.

## Fields

`command`, `anchor`, `source_paths`, `exclude_paths`, `policy`,
`policy_type`, `soul`, `status`

## Coverage Scope

- `commands/write-active.md`
- `commands/write-autorun.md`
- `commands/write-propose.md`
- Any new command that reports run provenance
