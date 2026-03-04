/**
 * External Tools Registry
 *
 * Defines external tools/skills that can be detected and integrated
 * into the obsidian-workflows plugin.
 *
 * Pattern inspired by compound-engineering-plugin's syncTargets registry.
 */

const os = require('os');
const path = require('path');

/**
 * @typedef {Object} ToolDefinition
 * @property {string} name - Tool identifier
 * @property {function(string, string): string[]} detectPaths - Returns paths to check for tool presence
 * @property {string[]} capabilities - What the tool can do
 * @property {string[]} integrationPoints - Which workflow stages use this tool
 * @property {string} [description] - Human-readable description
 */

/**
 * Tool Registry
 * @type {ToolDefinition[]}
 */
const TOOL_REGISTRY = [
  // kepano/obsidian-skills
  {
    name: 'obsidian-markdown',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'obsidian-markdown'),
      path.join(cwd, '.claude', 'skills', 'obsidian-markdown'),
    ],
    capabilities: ['markdown-syntax', 'wikilinks', 'callouts', 'embeds', 'frontmatter'],
    integrationPoints: ['draft', 'refine', 'propose'],
    description: 'Obsidian Flavored Markdown syntax support',
  },
  {
    name: 'obsidian-cli',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'obsidian-cli'),
      path.join(cwd, '.claude', 'skills', 'obsidian-cli'),
    ],
    capabilities: ['vault-interaction', 'templater', 'note-creation'],
    integrationPoints: ['draft', 'active'],
    description: 'Direct Obsidian vault interaction via CLI',
  },
  {
    name: 'defuddle',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'defuddle'),
      path.join(cwd, '.claude', 'skills', 'defuddle'),
    ],
    capabilities: ['web-scraping', 'markdown-extraction'],
    integrationPoints: ['research', 'plan'],
    description: 'Clean markdown extraction from web pages',
  },
  {
    name: 'obsidian-bases',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'obsidian-bases'),
      path.join(cwd, '.claude', 'skills', 'obsidian-bases'),
    ],
    capabilities: ['database-views', 'filtering', 'aggregation'],
    integrationPoints: ['analytics'],
    description: 'Database-like views of notes (.base files)',
  },
  {
    name: 'json-canvas',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'json-canvas'),
      path.join(cwd, '.claude', 'skills', 'json-canvas'),
    ],
    capabilities: ['visual-graphs', 'mind-mapping'],
    integrationPoints: ['visualize', 'plan'],
    description: 'Visual knowledge graphs (.canvas files)',
  },

  // Existing tools
  {
    name: 'humanizer',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'humanizer'),
      path.join(cwd, '.claude', 'skills', 'humanizer'),
    ],
    capabilities: ['text-naturalization', 'ai-pattern-removal'],
    integrationPoints: ['draft', 'refine', 'compound'],
    description: 'AI text naturalization to human writing',
  },
  {
    name: 'grammar-checker',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'grammar-checker'),
      path.join(cwd, '.claude', 'skills', 'grammar-checker'),
    ],
    capabilities: ['grammar-check', 'spelling-check', 'spacing-check'],
    integrationPoints: ['refine', 'review'],
    description: 'Korean grammar, spelling, and spacing checker',
  },
  {
    name: 'style-guide',
    detectPaths: (home, cwd) => [
      path.join(home, '.claude', 'skills', 'style-guide'),
      path.join(cwd, '.claude', 'skills', 'style-guide'),
    ],
    capabilities: ['style-consistency', 'terminology-check'],
    integrationPoints: ['refine', 'review'],
    description: 'Project style guide compliance checker',
  },
];

/**
 * Get tool definition by name
 * @param {string} name - Tool name
 * @returns {ToolDefinition|undefined}
 */
function getToolDefinition(name) {
  return TOOL_REGISTRY.find(tool => tool.name === name);
}

/**
 * Get all tools for a specific integration point
 * @param {string} integrationPoint - e.g., 'draft', 'refine', 'review'
 * @returns {ToolDefinition[]}
 */
function getToolsForIntegrationPoint(integrationPoint) {
  return TOOL_REGISTRY.filter(tool =>
    tool.integrationPoints.includes(integrationPoint)
  );
}

/**
 * Get all tool names
 * @returns {string[]}
 */
function getAllToolNames() {
  return TOOL_REGISTRY.map(tool => tool.name);
}

module.exports = {
  TOOL_REGISTRY,
  getToolDefinition,
  getToolsForIntegrationPoint,
  getAllToolNames,
};
