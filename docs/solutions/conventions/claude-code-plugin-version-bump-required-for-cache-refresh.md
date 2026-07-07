---
title: Claude Code 플러그인은 버전 문자열로 캐시된다 — 코드 변경 시 버전을 올려야 반영된다
date: 2026-07-07
category: conventions
module: Claude Code 플러그인 배포 (obsidian-workflows)
problem_type: convention
component: development_workflow
severity: medium
applies_when:
  - git 마켓플레이스로 설치한 Claude Code 플러그인의 코드를 바꿔 배포할 때
  - 코드를 push했는데도 Claude Code에 새 동작이 반영되지 않을 때
  - 플러그인 릴리스 절차를 문서화하거나 자동화할 때
tags:
  - claude-code-plugin
  - plugin-versioning
  - marketplace
  - cache-invalidation
  - plugin-release
related_components:
  - tooling
---

## Context

`obsidian-workflows`는 git 마켓플레이스(`andromedarabbit` → `github.com/andromedarabbit/obsidian-workflows.git`, `autoUpdate: true`)로 설치돼 있다. `ow:work` 동작을 고쳐 커밋·push까지 마쳤는데(`24645db`, origin/main), Claude Code는 계속 **옛 코드**로 동작했다.

원인을 추적해 보니 실제로 실행되는 플러그인은 소스 repo가 아니라 **버전으로 이름 붙은 스냅샷 복사본**이었다:

```
~/.claude/plugins/cache/andromedarabbit/obsidian-workflows/0.1.10
```

- 이 경로는 소스 repo를 가리키는 심링크가 아니라 **별도 복사본**이다. 소스 repo에서 편집·커밋·push해도 실행 중인 플러그인은 전혀 바뀌지 않는다.
- 캐시는 커밋 `532c3e5`(버전 `0.1.10`)에 고정돼 있었고, origin/main은 같은 `0.1.10`인 채로 여러 커밋(`6d7911e`, `24645db`) 앞서 있었다. **같은 버전으로 올라간 커밋들은 push됐어도 캐시에 반영되지 않았다.**

## Guidance

Claude Code 플러그인 코드를 바꿔 실제로 반영시키려면 세 가지가 **모두** 필요하다:

1. **버전을 올린다** — `.claude-plugin/plugin.json`과 `.claude-plugin/marketplace.json`의 plugin 항목, **두 곳 모두**. patch 변경이면 `0.1.10` → `0.1.11`. **실행 코드에 영향을 주는 주요 커밋마다 올린다** — 여러 코드 커밋을 같은 버전 아래 쌓아두면 안 된다. 마지막 한 번만 올리면 되는 게 아니라, 배포 단위(커밋)와 버전을 1:1로 맞춰야 중간 상태도 반영된다.
2. **마켓플레이스가 추적하는 브랜치에 push한다** (보통 `main`). 로컬 feature 브랜치 커밋만으로는 부족하다.
3. **캐시를 재복사시킨다** — `/plugin` 메뉴에서 수동 업데이트(또는 `autoUpdate` 대기) → **Claude Code 세션 재시작**. 그러면 `.../0.1.11`에서 새 코드가 로드된다.

```jsonc
// .claude-plugin/plugin.json
- "version": "0.1.10"
+ "version": "0.1.11"

// .claude-plugin/marketplace.json  (plugin 항목에도 동일하게)
-      "version": "0.1.10",
+      "version": "0.1.11",
```

## Why This Matters

설치 캐시는 **버전 문자열을 무효화 키로** 삼는다. `autoUpdate: true`가 마켓플레이스 repo를 주기적으로 pull하더라도, 광고된 버전이 설치된 버전과 같으면 업데이터는 "이미 최신"으로 판단하고 **파일을 다시 복사하지 않는다**. 즉 버전을 그대로 두고 배포한 변경은 **조용히 무시된다** — "고쳐서 올렸다"고 믿지만 Claude Code는 끝내 로드하지 않는다.

이번 세션은 정확히 이 함정에 시간을 크게 썼다. 올바른 수정이 origin/main에 push까지 됐는데도, 버전이 `0.1.10` 그대로라 캐시가 `532c3e5`에 머물러 새 코드가 한 번도 로드되지 않았다. "push했는데 왜 안 바뀌지?"의 답은 거의 항상 **버전 미변경**이다.

## When to Apply

- git 마켓플레이스로 배포되는 Claude Code 플러그인에 코드 변경을 배포할 때마다 — 예외 없이 버전 bump.
- 실행 코드에 영향을 주는 **주요 커밋마다** 버전을 올린다. 여러 코드 커밋을 같은 버전 아래 쌓지 말 것 — 이번 사례가 정확히 그 실패였다: `6d7911e`와 `24645db`가 모두 `0.1.10`에 묶여 push됐지만 캐시에 한 번도 반영되지 않았다. (문서·주석 등 런타임 무관 커밋은 예외.)
- push가 성공했는데도 새 플러그인 동작이 반영되지 않을 때 — 가장 먼저 버전이 올랐는지 확인.
- `plugin.json`과 `marketplace.json` **두 파일 모두** 버전을 담으므로 항상 함께 올려 동기화 유지.

## Examples

### 진단: 캐시가 실제로 무슨 코드를 돌리는지 확인

```bash
# 설치된 버전/커밋 확인
python3 -c "import json; d=json.load(open('$HOME/.claude/plugins/installed_plugins.json'));
print([v for k,v in d['plugins'].items() if 'obsidian-workflows' in k])"

# 캐시된 파일에 내 변경이 들어있는지 직접 grep (없으면 캐시가 낡은 것)
grep -c "내가-추가한-문구" \
  ~/.claude/plugins/cache/andromedarabbit/obsidian-workflows/*/commands/ow/work.md
```

### 반영 절차 (이번 사례 그대로)

```bash
# 1. 두 파일 버전 bump 후 커밋
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: 플러그인 버전 0.1.11로 올림"

# 2. 마켓플레이스가 추적하는 main에 push
git push origin main

# 3. Claude Code에서 /plugin 업데이트 → 세션 재시작
```

## Related

- 마켓플레이스 매니페스트와 플러그인 매니페스트가 같은 repo에 공존하는 구조(`.claude-plugin/marketplace.json` + `.claude-plugin/plugin.json`)이므로 두 버전 필드를 반드시 함께 관리한다.
