#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

node <<'EOF'
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const workflowsDir = path.join(process.cwd(), '.github', 'workflows');
const files = fs.readdirSync(workflowsDir)
  .filter((file) => file.endsWith('.yml') || file.endsWith('.yaml'))
  .sort();

let failed = false;
for (const file of files) {
  const fullPath = path.join(workflowsDir, file);
  try {
    const content = fs.readFileSync(fullPath, 'utf8');
    yaml.loadAll(content);
    console.log(`YAML syntax OK: .github/workflows/${file}`);
  } catch (error) {
    failed = true;
    console.error(`YAML syntax error: .github/workflows/${file}`);
    console.error(error.message);
  }
}

if (failed) {
  process.exit(1);
}
EOF
