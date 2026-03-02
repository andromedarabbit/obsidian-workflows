# Namespace Boundary Contract

## Scope

Define command namespace ownership and invocation policy.

## Namespaces

- Local plugin workflow entrypoints: `/obsidian-workflows:*`
- Local execution commands: `/obsidian:write.*`
- External plugin namespaces (e.g., `/compound-engineering:*`) are out-of-scope for local workflow execution

## Invocation Policy

1. Workflow orchestration should enter through `/obsidian-workflows:*`
2. Execution-level commands are invoked by workflow entrypoints
3. Cross-plugin namespaces must not be silently substituted
4. On wrong namespace usage, fail fast with explicit guidance

## Compatibility

- During migration window, wrappers may forward old entrypoints
- Wrappers must emit deprecation guidance
- End-state should retain one clear canonical entry namespace
