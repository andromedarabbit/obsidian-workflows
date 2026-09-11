#!/usr/bin/env bash
# check-version-bump.sh - 배포 대상 파일 변경 시 플러그인 버전 bump 강제
#
# Claude Code 플러그인 설치 캐시는 버전 문자열을 무효화 키로 쓴다. 배포 대상
# 파일(hooks/ skills/ commands/ assets/ config/)이 변경됐는데
# .claude-plugin/plugin.json의 버전이 배포 기준(base)과 같으면 실패한다.
# plugin.json과 marketplace.json의 버전 어긋남(drift)도 함께 검사한다.
#
# 사용:
#   check-version-bump.sh             # pre-commit: 스테이지된 내용을 origin/main 대비 검사
#   check-version-bump.sh <base-ref>  # CI: <base-ref>..HEAD 커밋 범위 검사
#
# base를 확인할 수 없으면(최초 push 전, CI의 zero-SHA 등) 검사를 건너뛴다.
# 배경: docs/solutions/conventions/claude-code-plugin-version-bump-required-for-cache-refresh.md

set -euo pipefail

PLUGIN=".claude-plugin/plugin.json"
MARKETPLACE=".claude-plugin/marketplace.json"
# 런타임 동작에 영향을 주는 배포 대상 경로. docs/, tools/ 등 개발 인프라는 제외.
TRIGGER='^(hooks|skills|commands|assets|config|\.claude-plugin)/'

# --- base 결정 --------------------------------------------------------------
# 인자가 있으면 CI 모드(base..HEAD 커밋 범위), 없으면 pre-commit 모드(스테이지).
# diff 계산 전에 base를 먼저 검증한다 — 존재하지 않는 base로 git diff가
# fatal로 죽는 것(set -e)을 막기 위함.
if [ $# -ge 1 ]; then
  base=$1
else
  base=origin/main
fi

if ! git rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then
  echo "check-version-bump: base '$base'를 확인할 수 없어 검사를 건너뜁니다 (배포된 버전이 없거나 CI 이벤트에 base가 없음)."
  exit 0
fi

if [ $# -ge 1 ]; then
  changed=$(git diff --name-only "$base" HEAD)
else
  changed=$(git diff --cached --no-renames --name-only)
  [ -n "$changed" ] || exit 0
fi

# --- 버전 읽기 (인덱스 기준: pre-commit에선 스테이지 내용, CI 체크아웃에선 HEAD와 동일) ---
read_version() {  # $1=file, $2=jq filter
  git show ":$1" 2>/dev/null | jq -er "$2" 2>/dev/null
}

# plugin.json은 최상위 version, marketplace.json은 plugins 배열 항목 안의 version.
PLUGIN_FILTER='.version'
MARKET_FILTER='.plugins[] | select(.name == "obsidian-workflows") | .version'

if ! plugin_v=$(read_version "$PLUGIN" "$PLUGIN_FILTER"); then
  echo "check-version-bump: ${PLUGIN}를 읽지 못했습니다." >&2
  exit 1
fi
if ! market_v=$(read_version "$MARKETPLACE" "$MARKET_FILTER"); then
  echo "check-version-bump: ${MARKETPLACE}를 읽지 못했습니다." >&2
  exit 1
fi

errors=0

# --- 검사 1: 두 매니페스트 버전 동기화 --------------------------------------
# 둘 중 하나만 bump하면 업데이터가 다른 필드를 기준으로 판단할 수 있다.
if printf '%s\n' "$changed" | grep -qE '^\.claude-plugin/'; then
  if [ "$plugin_v" != "$market_v" ]; then
    echo "ERROR: $PLUGIN($plugin_v)와 $MARKETPLACE($market_v)의 버전이 어긋나 있습니다."
    echo "  → 두 파일의 version을 같은 값으로 함께 올리세요."
    errors=1
    fi
fi

# --- 검사 2: 배포 대상 파일 변경 시 버전 bump 여부 ---------------------------
if printf '%s\n' "$changed" | grep -qE "$TRIGGER"; then
  if ! released_v=$(git show "$base:$PLUGIN" 2>/dev/null | jq -er '.version' 2>/dev/null); then
    echo "check-version-bump: base '$base'에서 $PLUGIN를 읽지 못해 검사를 건너뜁니다."
    exit 0
  fi
  if [ "$plugin_v" = "$released_v" ] && [ "$market_v" = "$released_v" ]; then
    echo "ERROR: 배포 대상 파일이 변경됐는데 플러그인 버전이 배포 기준 '$base'($released_v)와 같습니다."
    echo "  설치 캐시는 버전 문자열로 무효화되므로 이 변경은 설치본에 반영되지 않습니다."
    echo "  → ${PLUGIN}과 ${MARKETPLACE}의 version을 함께 올리세요."
    errors=1
  fi
fi

if [ "$errors" -ne 0 ]; then
  echo "  참고: docs/solutions/conventions/claude-code-plugin-version-bump-required-for-cache-refresh.md"
  exit 1
fi
