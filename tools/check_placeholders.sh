#!/usr/bin/env bash
# tools/check_placeholders.sh — Scan for PLACEHOLDER(Txx) markers (Golden Rule 9)
#
# Usage:
#   tools/check_placeholders.sh [--strict]
#
# In normal mode: lists all placeholders and exits with code 0.
# In --strict mode (Gate G10): fails if any placeholder exists.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

echo "=== Scanning codebase for PLACEHOLDER markers ==="

PLACEHOLDERS=$(grep -rn "PLACEHOLDER(" app/lib/ app/assets/models/ ml/src/ ml/catalog/ 2>/dev/null || true)

if [[ -z "$PLACEHOLDERS" ]]; then
  echo "✓ Zero placeholders found across app and ml."
  exit 0
else
  COUNT=$(echo "$PLACEHOLDERS" | wc -l)
  echo "Found $COUNT placeholder(s):"
  echo "$PLACEHOLDERS"
  if [[ $STRICT -eq 1 ]]; then
    echo "ERROR: Gate G10 strict check failed. Placeholders must be 0 before release." >&2
    exit 1
  fi
  echo "Note: Placeholders allowed during development prior to Gate G10."
fi
exit 0
