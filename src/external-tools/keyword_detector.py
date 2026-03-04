#!/usr/bin/env python3
"""
Keyword-based External Tools Detector

Detects relevant skills/MCP tools at runtime by parsing /help output
and matching against keywords for each workflow stage.

Usage:
    uvx --from . keyword_detector.py [stage]
"""

import json
import subprocess
import sys
from typing import List, Dict

# Keyword mappings for each workflow stage
STAGE_KEYWORDS = {
    "draft": ["markdown", "obsidian", "humanizer", "write", "draft", "template"],
    "refine": ["humanizer", "grammar", "style", "polish", "edit", "rewrite"],
    "review": ["grammar", "style", "checker", "lint", "review", "quality"],
    "compound": ["humanizer", "capture", "learn", "knowledge"],
    "research": ["defuddle", "web", "scrape", "extract", "research"],
    "plan": ["canvas", "visual", "graph", "mind-map", "plan"],
}


def get_available_tools() -> List[Dict[str, str]]:
    """
    Parse available skills and MCP tools.

    Returns:
        List of tools with name, description, and type
    """
    tools = []

    try:
        # Get skills
        result = subprocess.run(
            ["claude", "skill", "list", "--json"],
            capture_output=True,
            text=True,
            check=True
        )
        skills_data = json.loads(result.stdout)

        for skill in skills_data.get("skills", []):
            tools.append({
                "name": skill.get("name", ""),
                "description": skill.get("description", ""),
                "type": "skill"
            })
    except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError) as e:
        print(f"Warning: Failed to get available tools: {e}", file=sys.stderr)

    return tools


def detect_tools_for_stage(stage: str) -> List[Dict[str, str]]:
    """
    Detect relevant tools for a workflow stage.

    Args:
        stage: Workflow stage (draft, refine, review, etc.)

    Returns:
        List of detected tools
    """
    keywords = STAGE_KEYWORDS.get(stage, [])
    if not keywords:
        return []

    available_tools = get_available_tools()
    detected = []

    for tool in available_tools:
        search_text = f"{tool['name']} {tool['description']}".lower()
        if any(keyword.lower() in search_text for keyword in keywords):
            detected.append(tool)

    return detected


def format_tools_for_prompt(tools: List[Dict[str, str]]) -> str:
    """
    Format detected tools for user prompt.

    Args:
        tools: List of detected tools

    Returns:
        Formatted string
    """
    if not tools:
        return ""

    lines = []
    for tool in tools:
        lines.append(f"- **{tool['name']}**: {tool['description']}")

    return "\n".join(lines)


def main():
    """CLI interface for testing."""
    if len(sys.argv) < 2:
        print("Usage: uvx keyword_detector.py <stage>")
        print(f"Available stages: {', '.join(STAGE_KEYWORDS.keys())}")
        sys.exit(1)

    stage = sys.argv[1]

    if stage not in STAGE_KEYWORDS:
        print(f"Error: Unknown stage '{stage}'")
        print(f"Available stages: {', '.join(STAGE_KEYWORDS.keys())}")
        sys.exit(1)

    print(f"Detecting tools for stage: {stage}\n")

    detected = detect_tools_for_stage(stage)

    if detected:
        print(f"Found {len(detected)} relevant tool(s):\n")
        print(format_tools_for_prompt(detected))
    else:
        print("No relevant tools detected.")


if __name__ == "__main__":
    main()
