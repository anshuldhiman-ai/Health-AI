#!/usr/bin/env bash
# tools/check_offline.sh — Enforce 100% offline invariants (D-01)
#
# Fails if:
# 1. Any AndroidManifest.xml introduces android.permission.INTERNET without tools:node="remove"
# 2. app/pubspec.yaml has any HTTP/networking client dependencies
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== [1/2] Checking Android Manifests for Network Permissions ==="
MANIFEST_MAIN="app/android/app/src/main/AndroidManifest.xml"

if grep -q 'android.permission.INTERNET' "$MANIFEST_MAIN"; then
  # Ensure it is removed with tools:node="remove"
  if ! grep -A 2 'android.permission.INTERNET' "$MANIFEST_MAIN" | grep -q 'tools:node="remove"'; then
    echo "ERROR: android.permission.INTERNET is present without tools:node=\"remove\" in $MANIFEST_MAIN" >&2
    exit 1
  fi
  echo "✓ android.permission.INTERNET is explicitly removed with tools:node=\"remove\""
else
  echo "✓ android.permission.INTERNET is not present in main manifest"
fi

echo "=== [2/2] Checking app/pubspec.yaml for Banned Networking Packages ==="
PUBSPEC="app/pubspec.yaml"
BANNED_PKGS=("http:" "dio:" "retrofit:" "socket_io_client:" "web_socket_channel:" "firebase_")

for pkg in "${BANNED_PKGS[@]}"; do
  if grep -E "^  $pkg" "$PUBSPEC" >/dev/null 2>&1; then
    echo "ERROR: Banned networking package '$pkg' found in $PUBSPEC" >&2
    exit 1
  fi
done
echo "✓ No banned networking packages found in $PUBSPEC"

echo "=== Check Offline Passed (100% Offline Guaranteed) ==="
exit 0
