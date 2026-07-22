# Namespace Boundary Contract

## Scope

Define command namespace ownership and invocation policy.

## Namespaces

All local commands and skills live under the single plugin namespace `obsidian-workflows:`
(the prefix is added automatically from the plugin manifest name). Within that namespace,
two dash-prefixed families divide the roles:

- Workflow track entrypoints: `/obsidian-workflows:ow-*` (`ow-plan`, `ow-work`, `ow-review`, `ow-compound`, `ow-policy`) — each is mirrored by a same-named skill (`/obsidian-workflows:plan` etc.)
- Execution commands: `/obsidian-workflows:write-*` (`write-active`, `write-draft`, …) — invoked by the tracks, not entered directly in normal flow
- External plugin namespaces (e.g., `/compound-engineering:*`) are out-of-scope for local workflow execution

Command slash names are flat and colon-free by design; the only `:` is the automatic
plugin prefix. There is no separate `obsidian:` namespace — that was an artifact of old
colon-in-filename naming and no longer exists.

## Invocation Policy

1. Workflow orchestration should enter through an `ow-*` track (or its mirror skill)
2. `write-*` execution commands are invoked by the track entrypoints
3. Cross-plugin namespaces must not be silently substituted
4. On wrong namespace usage, fail fast with explicit guidance

## Compatibility

- During migration window, wrappers may forward old entrypoints
- Wrappers must emit deprecation guidance
- End-state should retain one clear canonical entry namespace
