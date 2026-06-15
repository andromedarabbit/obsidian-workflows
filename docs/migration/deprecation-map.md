# Deprecation Map

## Goal

Provide explicit transition from legacy invocation paths to canonical workflow entrypoints.

> Note: the legacy aliases listed below are documented on purpose for migration tracking. They are not the current canonical commands.
> Current canonical entrypoints live under the `ow:` namespace such as `/obsidian-workflows:ow:plan`, `/obsidian-workflows:ow:work`, `/obsidian-workflows:ow:review`, `/obsidian-workflows:ow:compound`.

## Mapping

- Legacy orchestration alias -> `/obsidian-workflows:plan`
- Legacy work alias -> `/obsidian-workflows:work`
- Legacy review alias -> `/obsidian-workflows:review`
- Legacy compound alias -> `/obsidian-workflows:compound`

## Phases

1. **Announce**: publish migration notice and preferred commands
2. **Warn**: old command paths still work but print warning
3. **Error**: old paths fail with actionable replacement hint
4. **Remove**: remove deprecated aliases

## Requirements

- Every warning includes replacement command
- No silent fallback across namespace boundaries
- Document phase dates in release notes
