/**
 * External Tools Detector
 *
 * Detects installed external tools/skills using filesystem-based checks.
 * Pattern inspired by compound-engineering-plugin's detect-tools.ts
 */

const fs = require('fs').promises;
const path = require('path');
const os = require('os');
const { TOOL_REGISTRY } = require('./registry');

/**
 * @typedef {Object} DetectedTool
 * @property {string} name - Tool name
 * @property {boolean} detected - Whether tool was found
 * @property {string} reason - Detection result message
 * @property {string} [path] - Path where tool was found
 */

/**
 * Check if a path exists
 * @param {string} p - Path to check
 * @returns {Promise<boolean>}
 */
async function pathExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

/**
 * Detect installed external tools
 * @param {string} [home] - Home directory (defaults to os.homedir())
 * @param {string} [cwd] - Current working directory (defaults to process.cwd())
 * @returns {Promise<DetectedTool[]>}
 */
async function detectInstalledTools(home = os.homedir(), cwd = process.cwd()) {
  const results = [];

  for (const tool of TOOL_REGISTRY) {
    let detected = false;
    let reason = 'not found';
    let foundPath = null;

    const paths = tool.detectPaths(home, cwd);
    for (const p of paths) {
      if (await pathExists(p)) {
        detected = true;
        reason = `found at ${p}`;
        foundPath = p;
        break;
      }
    }

    results.push({
      name: tool.name,
      detected,
      reason,
      path: foundPath,
    });
  }

  return results;
}

/**
 * Detect tools for a specific integration point
 * @param {string} integrationPoint - e.g., 'draft', 'refine', 'review'
 * @param {string} [home] - Home directory
 * @param {string} [cwd] - Current working directory
 * @returns {Promise<DetectedTool[]>}
 */
async function detectToolsForIntegrationPoint(integrationPoint, home, cwd) {
  const allDetected = await detectInstalledTools(home, cwd);

  return allDetected.filter(detected => {
    const tool = TOOL_REGISTRY.find(t => t.name === detected.name);
    return tool && tool.integrationPoints.includes(integrationPoint);
  });
}

/**
 * Get names of detected tools
 * @param {string} [home] - Home directory
 * @param {string} [cwd] - Current working directory
 * @returns {Promise<string[]>}
 */
async function getDetectedToolNames(home, cwd) {
  const detected = await detectInstalledTools(home, cwd);
  return detected.filter(t => t.detected).map(t => t.name);
}

/**
 * Check if a specific tool is installed
 * @param {string} toolName - Tool name to check
 * @param {string} [home] - Home directory
 * @param {string} [cwd] - Current working directory
 * @returns {Promise<boolean>}
 */
async function isToolInstalled(toolName, home, cwd) {
  const detected = await detectInstalledTools(home, cwd);
  const tool = detected.find(t => t.name === toolName);
  return tool ? tool.detected : false;
}

// CLI interface for testing
if (require.main === module) {
  (async () => {
    console.log('Detecting installed external tools...\n');

    const detected = await detectInstalledTools();

    console.log('Detection Results:');
    console.log('==================\n');

    for (const tool of detected) {
      const icon = tool.detected ? '✓' : '✗';
      console.log(`${icon} ${tool.name} — ${tool.reason}`);
    }

    const installedCount = detected.filter(t => t.detected).length;
    console.log(`\nTotal: ${installedCount}/${detected.length} tools detected`);
  })();
}

module.exports = {
  detectInstalledTools,
  detectToolsForIntegrationPoint,
  getDetectedToolNames,
  isToolInstalled,
  pathExists,
};
