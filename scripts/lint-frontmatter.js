#!/usr/bin/env node
/**
 * lint-frontmatter.js - Validate YAML frontmatter structure
 */

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

let errors = 0;
let warnings = 0;

function lintFrontmatter(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');

    // Extract frontmatter
    const match = content.match(/^---\n([\s\S]*?)\n---/);

    if (!match) {
      console.warn(`WARNING: ${filePath} - No frontmatter found`);
      warnings++;
      return;
    }

    const frontmatterText = match[1];

    // Try to parse YAML
    try {
      const data = yaml.load(frontmatterText);

      // Check for common issues
      if (typeof data !== 'object' || data === null) {
        console.error(`ERROR: ${filePath} - Frontmatter is not a valid object`);
        errors++;
      }
    } catch (yamlError) {
      console.error(`ERROR: ${filePath} - Invalid YAML: ${yamlError.message}`);
      errors++;
    }
  } catch (err) {
    console.error(`ERROR: ${filePath} - Failed to read: ${err.message}`);
    errors++;
  }
}

function findCommandFiles(dir) {
  const files = [];

  function walk(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);

      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        files.push(fullPath);
      }
    }
  }

  walk(dir);
  return files;
}

function main() {
  const commandsDir = '.claude/commands';

  if (!fs.existsSync(commandsDir)) {
    console.error('ERROR: .claude/commands directory not found');
    process.exit(1);
  }

  console.log('Linting frontmatter...');

  const files = findCommandFiles(commandsDir);

  for (const file of files) {
    lintFrontmatter(file);
  }

  console.log(`\nLinted ${files.length} command files`);

  if (errors > 0) {
    console.error(`Found ${errors} error(s)`);
  }

  if (warnings > 0) {
    console.warn(`Found ${warnings} warning(s)`);
  }

  if (errors === 0 && warnings === 0) {
    console.log('All checks passed!');
  }

  process.exit(errors > 0 ? 1 : 0);
}

main();
