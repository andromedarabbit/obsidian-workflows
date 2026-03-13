#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash ./tools/validate-fast.sh
npm run validate:commands
npm run validate:no-duplicates
npm run validate:behavior-contracts
npm run test:plan-passive-default
bash ./tools/lint-frontmatter.sh
bash ./tools/validate-markdown.sh
bash ./tools/validate-generated.sh
bash ./tools/validate-workflows.sh
