#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash ./tools/generate-index.sh

if ! git diff --exit-code COMMANDS.md; then
  echo "ERROR: COMMANDS.md is out of date. Run 'make validate-generated' or './tools/generate-index.sh' and commit the changes." >&2
  exit 1
fi
