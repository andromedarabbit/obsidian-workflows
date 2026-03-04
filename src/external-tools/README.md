# External Tools Detection

Python-based keyword detection for runtime tool discovery.

## Usage

```bash
# Detect tools for a specific stage
uvx --from ./src/external-tools keyword-detector draft

# Output:
# Found 3 relevant tool(s):
# - **obsidian-markdown**: Obsidian Flavored Markdown syntax
# - **humanizer**: AI text naturalization
# - **obsidian-cli**: Vault interaction via CLI
```

## Integration

Commands call the detector at runtime:

```python
# In command implementation
import subprocess
result = subprocess.run(
    ["uvx", "--from", "./src/external-tools", "keyword-detector", "draft"],
    capture_output=True,
    text=True
)
```

## Stages and Keywords

- **draft**: markdown, obsidian, humanizer, write, draft, template
- **refine**: humanizer, grammar, style, polish, edit, rewrite
- **review**: grammar, style, checker, lint, review, quality
- **compound**: humanizer, capture, learn, knowledge
- **research**: defuddle, web, scrape, extract, research
- **plan**: canvas, visual, graph, mind-map, plan

## Configuration

In `writing-config.md`:

```yaml
external_tools:
  detection: auto  # auto | manual | disabled
  auto_use: ask    # ask | true | false
```

## Adding Custom Tools

No code changes needed. Install any skill with matching keywords:

```bash
claude skill install my-grammar-tool
# Auto-detected in 'review' stage if description contains relevant keywords
```
