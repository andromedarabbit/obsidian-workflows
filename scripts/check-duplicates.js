#!/usr/bin/env node
/**
 * check-duplicates.js - Detect duplicate command names and command-skill name collisions
 */

const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');

let errors = 0;
const commandNames = new Map();
const skillNames = new Map();

const COMMANDS_DIR = 'commands';
const SKILLS_DIR = 'skills';
const PLUGIN_MANIFEST_PATH = path.join('.claude-plugin', 'plugin.json');
const COMMANDS_ROOT = path.resolve(COMMANDS_DIR);

let pluginNamespace = null;

function readName(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const { data: frontmatter } = matter(content);
    return frontmatter.name || null;
  } catch (err) {
    console.error(`ERROR: ${filePath} - Failed to parse: ${err.message}`);
    errors++;
    return null;
  }
}

function reportDuplicate(type, name, firstPath, secondPath) {
  console.error(`ERROR: Duplicate ${type} name '${name}' found in:`);
  console.error(`  - ${firstPath}`);
  console.error(`  - ${secondPath}`);
  errors++;
}

function checkCommandDuplicates(filePath) {
  const name = readName(filePath);
  if (!name) return;

  const existingPath = commandNames.get(name);
  if (existingPath) {
    reportDuplicate('command', name, existingPath, filePath);
    return;
  }

  commandNames.set(name, filePath);
}

function checkSkillDuplicatesAndCollisions(filePath) {
  const name = readName(filePath);
  if (!name) return;

  const existingSkillPath = skillNames.get(name);
  if (existingSkillPath) {
    reportDuplicate('skill', name, existingSkillPath, filePath);
  } else {
    skillNames.set(name, filePath);
  }

  const collidingCommandPath = commandNames.get(name);
  if (collidingCommandPath) {
    console.error(`ERROR: Command/skill name collision '${name}' found in:`);
    console.error(`  - command: ${collidingCommandPath}`);
    console.error(`  - skill:   ${filePath}`);
    errors++;
  }
}

function relativePosixPath(filePath) {
  return path.relative(process.cwd(), path.resolve(filePath)).split(path.sep).join('/');
}

function loadPluginNamespace() {
  if (!fs.existsSync(PLUGIN_MANIFEST_PATH)) {
    return null;
  }

  try {
    const raw = fs.readFileSync(PLUGIN_MANIFEST_PATH, 'utf8');
    const parsed = JSON.parse(raw);

    if (typeof parsed.name === 'string' && parsed.name.trim()) {
      return parsed.name.trim();
    }

    console.error(`ERROR: ${PLUGIN_MANIFEST_PATH} - Missing non-empty 'name'`);
    errors++;
    return null;
  } catch (err) {
    console.error(`ERROR: ${PLUGIN_MANIFEST_PATH} - Failed to parse JSON: ${err.message}`);
    errors++;
    return null;
  }
}

function validateCommandsLayout(filePath) {
  if (!pluginNamespace) {
    return;
  }

  const absolutePath = path.resolve(filePath);
  const relativePath = relativePosixPath(filePath);

  if (!absolutePath.startsWith(COMMANDS_ROOT + path.sep) && absolutePath !== COMMANDS_ROOT) {
    return;
  }

  const rootName = relativePath.split('/')[1];
  if (rootName === pluginNamespace) {
    console.error(
      `ERROR: Legacy command root '${COMMANDS_DIR}/${pluginNamespace}/' detected at ${relativePath}`,
    );
    console.error(
      `  Move file under '${COMMANDS_DIR}/' directly (e.g., '${COMMANDS_DIR}/plan.md') to avoid double namespace discovery.`,
    );
    errors++;
  }
}

function findFiles(dir, isMatch) {
  const files = [];

  function walk(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);

      if (entry.isDirectory()) {
        walk(fullPath);
        continue;
      }

      if (entry.isFile() && isMatch(entry.name)) {
        files.push(fullPath);
      }
    }
  }

  walk(dir);
  return files;
}

function findMarkdownFiles(dir) {
  return findFiles(dir, (entryName) => entryName.endsWith('.md'));
}

function findSkillFiles(dir) {
  return findFiles(dir, (entryName) => entryName === 'SKILL.md');
}

function main() {
  if (!fs.existsSync(COMMANDS_DIR)) {
    console.error(`ERROR: ${COMMANDS_DIR} directory not found`);
    process.exit(1);
  }

  pluginNamespace = loadPluginNamespace();

  console.log('Checking for duplicate command names, command-skill collisions, and discovery layout issues...');

  const commandFiles = findMarkdownFiles(COMMANDS_DIR);
  for (const file of commandFiles) {
    checkCommandDuplicates(file);
    validateCommandsLayout(file);
  }

  let skillFiles = [];
  if (fs.existsSync(SKILLS_DIR)) {
    skillFiles = findSkillFiles(SKILLS_DIR);
    for (const file of skillFiles) {
      checkSkillDuplicatesAndCollisions(file);
    }
  }

  console.log(`\nChecked ${commandFiles.length} command files`);
  console.log(`Checked ${skillFiles.length} skill files`);

  if (errors > 0) {
    console.error(`Found ${errors} duplicate(s)/collision(s)/layout violation(s)`);
    process.exit(1);
  }

  console.log('No duplicates, collisions, or layout violations found!');
}

main();
