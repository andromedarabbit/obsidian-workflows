---
title: "셸 검증기의 (( count++ ))는 bash 5 set -e에서 중단된다 — 호출을 || true로 감싸라"
date: 2026-07-07
category: conventions
module: "tools/ 셸 검증기 (obsidian-workflows)"
problem_type: convention
component: development_workflow
severity: medium
applies_when:
  - "tools/ 아래 셸 검증기를 새로 작성하거나 수정할 때"
  - "파일을 순회하며 (( CHECKED++ )) / ((ERRORS++)) 같은 산술 증가를 쓰는 스크립트를 짤 때"
  - "로컬(macOS)에서는 통과하는데 GitHub Actions(Linux)에서만 셸 스크립트가 실패할 때"
tags:
  - bash
  - set-e
  - shell-validator
  - ci
  - macos-vs-linux
related_components:
  - tooling
  - ci
---

## Context

`tools/check-skill-sync.sh`(SKILL↔command 미러 드리프트 검증기)를 추가·머지·push했는데, 로컬에서는 모든 검증이 통과했지만 GitHub Actions의 `Validate Commands` 워크플로가 **첫 번째 skill 파일에서** 실패했다:

```text
+ check_one skills/review/SKILL.md
+ (( CHECKED++ ))
Skill mirror sync validation failed
Error: Process completed with exit code 1.
```

로컬 macOS 기본 셸은 bash 3.2, GitHub Linux 러너는 bash 5.x다. 같은 스크립트가 셸 버전에 따라 다르게 동작했다.

## Guidance

파일을 순회하며 카운터를 증가시키는 셸 검증기에서는, **순회 함수 호출을 `|| true`로 감싸** 함수 본문의 `set -e`를 억제하라. 이 저장소의 형제 검증기 `tools/check-skill-frontmatter.sh`가 이미 쓰는 패턴이다.

```bash
# ❌ set -e 하에서 첫 파일에 중단됨 (bash 5.x)
while IFS= read -r -d '' file; do
    check_one "$file"
done < <(find skills -type f -name "SKILL.md" -print0)

# ✅ 함수 호출을 || true로 감싸 함수 내부 set -e를 억제
while IFS= read -r -d '' file; do
    check_one "$file" || true
done < <(find skills -type f -name "SKILL.md" -print0)
```

`check_one` 내부에서 `(( CHECKED++ ))`, `((ERRORS++))`로 카운트하고, `ERRORS`는 전역으로 누적한다. 종료 코드는 함수 반환값이 아니라 스크립트 끝의 `[[ $ERRORS -eq 0 ]]`가 좌우하므로, `|| true`로 감싸도 실패 검출은 정상 동작한다.

대안(더 방어적): 산술 증가 대신 **대입형** `CHECKED=$((CHECKED + 1))`을 쓴다. 대입은 항상 종료 코드 0을 반환하므로 `set -e`에 걸리지 않는다. 다만 이 저장소는 형제 검증기와의 일관성을 위해 `(( count++ ))` + `|| true` 패턴을 표준으로 둔다.

## Why This Matters

핵심 메커니즘:

- `(( expr ))`는 expr이 **0으로 평가되면 종료 코드 1**을 반환한다.
- `CHECKED++`는 **후위 증가**라 증가 *전* 값을 반환한다 — 첫 호출 때 `CHECKED`는 0이므로 `(( CHECKED++ ))`는 exit 1.
- `set -euo pipefail` 하에서 이 exit 1이 함수를 중단시킨다. 순회 루프 본문에서 함수가 실패하면 `set -e`가 스크립트 전체를 종료시킨다.
- 호출을 `|| true`(또는 `&&`/`||` 목록의 피연산자)로 두면 **그 함수 실행 동안 `set -e`가 비활성화**된다 — 이것이 형제 검증기가 무사했던 이유다.

버전 차이가 함정이다. bash 3.2(오래된 macOS 기본)는 이 상황에서 `set -e` 전파가 관대해 중단하지 않는다. bash 5.x(Linux 러너)는 엄격해 중단한다. 그래서 **로컬 통과 ≠ CI 통과**가 되고, "왜 로컬은 되는데 CI만 깨지지?"에 시간을 쓰게 된다.

실측 확인:

```text
/bin/bash 3.2.57        : set -e; f(){ (( c++ )); echo REACHED; }; c=0; f  → REACHED 출력(중단 안 함)
/opt/homebrew/bin/bash 5.3.15 : 같은 코드 → (( c++ ))에서 중단(REACHED 안 나옴)
```

## When to Apply

- `tools/`에 파일 순회 + 카운터 증가 셸 검증기를 새로 만들 때 → 처음부터 `호출 || true` 패턴을 쓴다.
- 셸 스크립트가 로컬은 통과하는데 CI(Linux/bash 5.x)만 실패할 때 → `set -e` + `(( x++ ))`(또는 0으로 평가되는 산술) 조합을 먼저 의심한다.
- 검증기 로컬 테스트는 **bash 5.x로도** 돌린다. macOS라면 `/opt/homebrew/bin/bash <script>`(Homebrew bash)로 확인하면 러너 동작을 재현할 수 있다.

## Examples

이 저장소에서 실제로 고친 커밋: `check-skill-sync.sh`의 순회 호출을 `check_one "$file"` → `check_one "$file" || true`로 바꿔 CI를 그린으로 복구했다. 관련 파일: `tools/check-skill-sync.sh`, 형제 패턴 원본 `tools/check-skill-frontmatter.sh`.

미러 동기 검증기 자체의 배경은 `docs/skill-specification.md`의 "Skill Body Conventions"를, 관련 배포 함정은 `docs/solutions/conventions/claude-code-plugin-version-bump-required-for-cache-refresh.md`를 참고하라.
