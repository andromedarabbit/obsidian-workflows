# Smoke Test: Work Draft Auto-detect

## Objective

Verify `/obsidian-workflows:work mode=draft` auto-detects proposal by status priority.

## Steps

1. Prepare multiple proposal notes with statuses:
   - `in-progress`
   - `pending`
   - no status
2. Run `/obsidian-workflows:work mode=draft` without explicit proposal.
3. Observe selected proposal.

## Expected

- Selection order: in-progress > pending > no-status.
- completed proposals are ignored.
- Default idea fallback applies when `idea` omitted.
