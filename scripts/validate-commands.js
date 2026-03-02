#!/usr/bin/env node
/**
 * validate-commands.js - Parse and validate command frontmatter
 */

const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');

const REQUIRED_FIELDS = ['name', 'description', 'argument-hint', 'allowed-tools', 'created', 'updated'];
const ISO_DATE_REGEX = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?$/;

let errors = 0;
let warnings = 0;

function validateCommand(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const { data: frontmatter } = matter(content);

    // Check required fields
    for (const field of REQUIRED_FIELDS) {
      if (!frontmatter[field]) {
        console.error(`ERROR: ${filePath} - Missing required field: ${field}`);
        errors++;
      }
    }

    // Validate date formats
    if (frontmatter.created && !ISO_DATE_REGEX.test(frontmatter.created)) {
      console.error(`ERROR: ${filePath} - Invalid created date format: ${frontmatter.created}`);
      errors++;
    }

    if (frontmatter.updated && !ISO_DATE_REGEX.test(frontmatter.updated)) {
      console.error(`ERROR: ${filePath} - Invalid updated date format: ${frontmatter.updated}`);
      errors++;
    }

    // Validate name format (kebab-case with optional namespace)
    if (frontmatter.name && !/^[a-z0-9]+([:-][a-z0-9]+)*(\.[a-z0-9]+)*$/.test(frontmatter.name)) {
      console.warn(`WARNING: ${filePath} - name '${frontmatter.name}' should be kebab-case`);
      warnings++;
    }

  } catch (err) {
    console.error(`ERROR: ${filePath} - Failed to parse: ${err.message}`);
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
  const commandsDir = 'commands';

  if (!fs.existsSync(commandsDir)) {
    console.error('ERROR: commands directory not found');
    process.exit(1);
  }

  console.log('Validating commands...');

  const files = findCommandFiles(commandsDir);

  for (const file of files) {
    validateCommand(file);
  }

  console.log(`\nValidated ${files.length} command files`);

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
