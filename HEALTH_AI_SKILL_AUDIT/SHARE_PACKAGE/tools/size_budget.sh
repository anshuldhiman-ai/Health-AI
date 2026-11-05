#!/usr/bin/env bash
# Size budget check (Section 12.2).
#
# Fails if the release artifact exceeds the budget. Set budgets in
# the BUDGETS associative array below. M0 budgets are provisional —
# tighten them after M2 (Section 12.2: "set after M2; track the trend").
#
# Usage:
#   tools/size_budget.sh <path-to-release.aab-or-apk>
set -euo pipefail

ARTIFACT="${1:?Usage: size_budget.sh <release.aab-or-apk>}"

if [[ ! -f "$ARTIFACT" ]]; then
  echo "ERROR: artifact not found: $ARTIFACT" >&2
  exit 1
fi

# Provisional budgets (bytes). TODO(M2): set real budgets after the
# first release-size measurement.
AAB_BUDGET=$((60 * 1024 * 1024))   # 60 MB provisional
APK_BUDGET=$((80 * 1024 * 1024))   # 80 MB provisional

SIZE_BYTES=$(stat -c%s "$ARTIFACT" 2>/dev/null || stat -f%z "$ARTIFACT" 2>/dev/null)

if [[ "$ARTIFACT" == *.aab ]]; then
  BUDGET=$AAB_BUDGET
else
  BUDGET=$APK_BUDGET
fi

MB=$((SIZE_BYTES / 1024 / 1024))
BUDGET_MB=$((BUDGET / 1024 / 1024))

echo "Artifact: $(basename "$ARTIFACT")"
echo "Size:     ${MB} MB ($SIZE_BYTES bytes)"
echo "Budget:   ${BUDGET_MB} MB"

if [[ $SIZE_BYTES -gt $BUDGET ]]; then
  echo "FAIL: artifact exceeds the ${BUDGET_MB} MB budget by $(((SIZE_BYTES - BUDGET) / 1024 / 1024)) MB" >&2
  exit 1
fi

echo "OK: within budget."
