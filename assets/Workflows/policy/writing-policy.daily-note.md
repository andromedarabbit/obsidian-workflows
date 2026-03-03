---
created: 2026-03-03T19:00
updated: 2026-03-03T19:00
policy_type: daily-note
output_type: daily-note
target_length: 300-800 words
required_sections:
  - today_summary
  - completed_work
  - blockers
  - next_actions
cta_required: false
topic_required: false
source_strategy: previous-note
source_path_key: daily_notes_path
missing_source_behavior: skip-and-prompt-recent
recent_candidates_limit: 5
creation_engine: obsidian-cli
template_engine: templater
template_key: daily_note_template
---

# Daily Note Policy

## Goal

직전 Daily Note를 참고해 오늘 한 일과 다음 행동을 명확하게 기록합니다.

## Structure

1. Today Summary
2. Completed Work
3. Blockers
4. Next Actions

## Constraints

- 사실 기반으로 작성하고 과장된 회고를 피합니다.
- 가능한 경우 직전 노트 맥락과 연결해 연속성을 유지합니다.
- 항목은 실행 가능한 수준으로 구체화합니다.
