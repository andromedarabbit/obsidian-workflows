#!/usr/bin/env bash
# Find recently modified markdown files using filesystem tools
# Usage: scan-recent-files.sh <directory> <since-timestamp> [extension]
#
# Arguments:
#   directory: Directory to scan (relative or absolute)
#   since-timestamp: ISO 8601 timestamp (e.g., 2026-03-17T10:00:00)
#   extension: File extension to filter (default: md)
#
# Output: JSON array of {path, mtime} objects
#
# Strategy: fd (fast, no indexing) -> find (slower, always available)

set -euo pipefail

SCAN_DIR="${1:-.}"
SINCE_TS="${2:-}"
EXTENSION="${3:-md}"

if [[ -z "$SINCE_TS" ]]; then
    echo "Error: since-timestamp required" >&2
    echo "Usage: $0 <directory> <since-timestamp> [extension]" >&2
    exit 1
fi

# Try fd first (fast, no indexing required)
if command -v fd &>/dev/null; then
    fd --type f --extension "$EXTENSION" --changed-after "$SINCE_TS" . "$SCAN_DIR" 2>/dev/null | while IFS= read -r file; do
        mtime=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%S" "$file" 2>/dev/null || echo "")
        if [[ -n "$mtime" ]]; then
            printf '{"path":"%s","mtime":"%s"}\n' "$file" "$mtime"
        fi
    done | jq -s '.'
    exit 0
fi

# Fallback to find (slower but always available)
# Convert ISO timestamp to epoch for comparison
SINCE_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${SINCE_TS%%[+-]*}" "+%s" 2>/dev/null || echo "0")

find "$SCAN_DIR" -type f -name "*.$EXTENSION" ! -path "*/.*" 2>/dev/null | while IFS= read -r file; do
    mtime_epoch=$(stat -f "%m" "$file" 2>/dev/null || echo "0")
    if [[ "$mtime_epoch" -gt "$SINCE_EPOCH" ]]; then
        mtime=$(stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%S" "$file" 2>/dev/null || echo "")
        if [[ -n "$mtime" ]]; then
            printf '{"path":"%s","mtime":"%s"}\n' "$file" "$mtime"
        fi
    fi
done | jq -s '.'
