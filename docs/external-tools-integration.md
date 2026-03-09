# External Tools Integration

Keyword-based runtime detection system for external tools (skills, MCP servers).

## Architecture

### Keyword-Based Detection

External tools are detected at runtime by matching keywords against installed skills/MCP tools:

```python
STAGE_KEYWORDS = {
    "draft": ["markdown", "obsidian", "humanizer", "write", "draft", "template"],
    "refine": ["humanizer", "grammar", "style", "polish", "edit", "rewrite"],
    "review": ["grammar", "style", "checker", "lint", "review", "quality"],
    "compound": ["humanizer", "capture", "learn", "knowledge"],
    "research": ["defuddle", "web", "scrape", "extract", "research"],
    "plan": ["canvas", "visual", "graph", "mind-map", "plan"],
}
```

### Detection Flow

1. Command execution starts (e.g., `oe:draft`)
2. `src/external-tools/keyword_detector.py` parses available skills/MCP tools
3. Keywords for the stage are matched against tool names/descriptions
4. Detected tools are presented to user based on `auto_use` setting
5. Tool execution failures are logged but don't block workflow (fail-safe)

## Configuration

In `writing-config.md`:

```yaml
external_tools:
  detection: auto  # auto | manual | disabled
  auto_use: ask    # ask | true | false
```

- `detection: auto` - Automatically detect tools at runtime
- `auto_use: ask` - Prompt user before using detected tools (default)
- `auto_use: true` - Use detected tools without prompting
- `auto_use: false` - Skip external tools

## Supported Tool Categories

### Obsidian Skills (kepano/obsidian-skills)
- **obsidian-markdown**: Markdown syntax, wikilinks, callouts
- **obsidian-cli**: Vault interaction, Templater integration
- **defuddle**: Web scraping, markdown extraction
- **obsidian-bases**: Database views, filtering
- **json-canvas**: Visual graphs, mind mapping

### Writing Enhancement
- **humanizer**: AI text naturalization
- **grammar-checker**: Korean grammar/spelling
- **style-guide**: Style consistency checking

## Usage Example

```bash
# User runs draft command
/obsidian-workflows:ow:work mode=draft

# System detects: obsidian-markdown, humanizer
# If auto_use=ask:
#   "Detected tools: obsidian-markdown, humanizer. Use them? (y/n)"
# If auto_use=true:
#   Automatically applies tools
# If auto_use=false:
#   Skips tool detection
```

## Adding Custom Tools

No code changes needed! Install any skill/MCP tool with relevant keywords:

```bash
# Install a custom grammar tool
claude skill install my-grammar-tool

# Will be auto-detected in 'review' stage if description contains:
# "grammar", "style", "checker", "lint", "review", or "quality"
```
