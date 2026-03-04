/**
 * Keyword-based External Tools Detector
 *
 * Detects relevant skills/MCP tools at runtime by parsing /help output
 * and matching against keywords for each workflow stage.
 */

const { execSync } = require('child_process');

/**
 * Keyword mappings for each workflow stage
 */
const STAGE_KEYWORDS = {
  draft: ['markdown', 'obsidian', 'humanizer', 'write', 'draft', 'template'],
  refine: ['humanizer', 'grammar', 'style', 'polish', 'edit', 'rewrite'],
  review: ['grammar', 'style', 'checker', 'lint', 'review', 'quality'],
  compound: ['humanizer', 'capture', 'learn', 'knowledge'],
  research: ['defuddle', 'web', 'scrape', 'extract', 'research'],
  plan: ['canvas', 'visual', 'graph', 'mind-map', 'plan'],
};

/**
 * Parse /help output to get available skills and MCP tools
 * @returns {Array<{name: string, description: string, type: 'skill'|'mcp'}>}
 */
function getAvailableTools() {
  try {
    // Get skills
    const skillsJson = execSync('claude skill list --json', { encoding: 'utf8' });
    const skills = JSON.parse(skillsJson).skills || [];

    // Get MCP tools (from /help output parsing)
    // Note: This is a simplified approach - actual implementation may need
    // to parse /help output or use MCP introspection

    return skills.map(skill => ({
      name: skill.name,
      description: skill.description || '',
      type: 'skill',
    }));
  } catch (error) {
    console.error('Failed to get available tools:', error.message);
    return [];
  }
}

/**
 * Detect relevant tools for a workflow stage
 * @param {string} stage - Workflow stage (draft, refine, review, etc.)
 * @returns {Array<{name: string, description: string, type: string}>}
 */
function detectToolsForStage(stage) {
  const keywords = STAGE_KEYWORDS[stage] || [];
  if (keywords.length === 0) {
    return [];
  }

  const availableTools = getAvailableTools();

  return availableTools.filter(tool => {
    const searchText = `${tool.name} ${tool.description}`.toLowerCase();
    return keywords.some(keyword => searchText.includes(keyword.toLowerCase()));
  });
}

/**
 * Format detected tools for user prompt
 * @param {Array} tools - Detected tools
 * @returns {string}
 */
function formatToolsForPrompt(tools) {
  if (tools.length === 0) {
    return '';
  }

  return tools.map(tool => `- **${tool.name}**: ${tool.description}`).join('\n');
}

module.exports = {
  detectToolsForStage,
  formatToolsForPrompt,
  getAvailableTools,
  STAGE_KEYWORDS,
};
