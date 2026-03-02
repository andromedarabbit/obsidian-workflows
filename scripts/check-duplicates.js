#!/usr/bin/env node
/**
 * check-duplicates.js - Detect duplicate command names
 */

const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');

let errors = 0;
const commandNames = new Map();

function checkDuplicates(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const { data: frontmatter } = matter(content);

    if (frontmatter.name) {
      if (commandNames.has(frontmatter.name)) {
        console.error(`ERROR: Duplicate command name '${frontmatter.name}' found in:`);
        console.error(`  - ${commandNames.get(frontmatter.name)}`);
        console.error(`  - ${filePath}`);
        errors++;
      } else {
        commandNames.set(frontmatter.name, filePath);
      }
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
  const commandsDir = '.claude/commands';

  if (!fs.existsSync(commandsDir)) {
    console.error('ERROR: .claude/commands directory not found');
    process.exit(1);
  }

  console.log('Checking for duplicate command names...');

  const files = findCommandFiles(commandsDir);

  for (const file of files) {
    checkDuplicates(file);
  }

  console.log(`\nChecked ${files.length} command files`);

  if (errors > 0) {
    console.error(`Found ${errors} duplicate(s)`);
    process.exit(1);
  }

  console.log('No duplicates found!');
}

main();
