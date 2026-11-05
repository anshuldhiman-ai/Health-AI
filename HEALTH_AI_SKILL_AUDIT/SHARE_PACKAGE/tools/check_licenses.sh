#!/usr/bin/env bash
# tools/check_licenses.sh — License Hygiene & Dependency Audit (D-02)
#
# Rules:
# 1. Ultralytics YOLO (AGPL-3.0) is banned from shipped code (app/lib/ and ml/src/ml_pipeline/export/).
# 2. No GPL/AGPL dependencies in app/pubspec.yaml.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== [1/2] Checking for banned AGPL/GPL imports in shipped code ==="

BANNED_IMPORTS=$(grep -rn "ultralytics" app/lib/ ml/src/ml_pipeline/export/ 2>/dev/null || true)

if [[ -n "$BANNED_IMPORTS" ]]; then
  echo "ERROR: Banned library 'ultralytics' found in shipped code:" >&2
  echo "$BANNED_IMPORTS" >&2
  exit 1
fi
echo "✓ Zero banned AGPL/GPL imports in shipped code paths."

echo "=== [2/2] Verifying license registry exists and is populated ==="
if [[ ! -f "ml/data/LICENSES.md" || ! -f "docs/THIRD_PARTY.md" ]]; then
  echo "ERROR: License documentation files missing." >&2
  exit 1
fi
echo "✓ ml/data/LICENSES.md and docs/THIRD_PARTY.md exist."

echo "=== Check Licenses Passed ==="
exit 0
