---
created: 2026-03-02T00:00
updated: 2026-03-03T19:00
tags:
  - writing
  - config
source_paths:
  - .
exclude_paths:
  - .obsidian/
  - .git/
  - .trash/
  - Archive/
  - 첨부파일/
  - docs/
  - todos/
  - .claude/
workflow_base_path: Workflows
policy_dir: Workflows/policy
enabled_policies:
  - daily-note
default_policy: daily-note
proposal_policy_allowlist:
  - daily-note
soul_path: Workflows/SOUL.md
path_safety:
  enforce_vault_root: true
  allow_absolute_path: false
  allow_parent_segments: false
  deny_symlink_escape: true
research_path: Workflows/Artifacts
draft_path: Workflows/Drafts
archive_path: Workflows/Archive
final_path: Workflows/Notes
proposal_path: Workflows/Proposals/passive-proposals
daily_notes_path: Daily Notes
daily_note_template: 템플릿/Daily.md
note_creation_engine: obsidian-cli
templater_required: true
fallback_recent_files_limit: 5
passive_window_days: 30
passive_schedule: daily
last_written_strategy: final-folder-latest-file
soul_enforced: true
default_idea: 1
proposal_auto_select: true
filename_rule:
  daily-note: "{{date}}"
  blog: "{{date}}-{{slug}}"
  x-thread: "{{date}}-{{slug}}-thread"
  weekly-review: "{{iso_week}}-weekly-review"
  newsletter: "{{date}}-newsletter-{{slug}}"
archive_versioning: true
archive_format: v{version}-{date}
output_verbosity: minimal
idea_detail_lines: 3
show_context_card: false
show_wikilinks: true
external_tools:
  detection: auto  # auto | manual | disabled
  auto_use: ask    # ask | true | false
---

# Writing Config Example

This is an example profile for vault-side runtime configuration.
Use a vault-local `writing-config.md` as the operational source of truth.
