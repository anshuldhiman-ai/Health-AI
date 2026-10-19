#!/usr/bin/env bash
# Merged-manifest permission check (R1, ADR 0008).
#
# Dumps the FINAL MERGED manifest of a release APK/AAB and fails on
# any permission not on the allow-list. The release build MUST NOT
# contain INTERNET or ACCESS_NETWORK_STATE.
#
# Usage:
#   tools/check_manifest.sh <path-to-release.aab-or-apk>
#
# Requires: aapt2 (from the Android SDK build-tools) on PATH, or
# set ANDROID_BUILD_TOOLS. Debug builds legitimately contain
# INTERNET for tooling — NEVER use a debug build as evidence of
# offline behaviour (Section 7.1).
set -euo pipefail

ARTIFACT="${1:?Usage: check_manifest.sh <release.aab-or-apk>}"

if [[ ! -f "$ARTIFACT" ]]; then
  echo "ERROR: artifact not found: $ARTIFACT" >&2
  exit 1
fi

# --- locate aapt2 ---
AAPT2="${AAPT2:-}"
if [[ -z "$AAPT2" ]]; then
  if command -v aapt2 >/dev/null 2>&1; then
    AAPT2=aapt2
  elif [[ -n "${ANDROID_BUILD_TOOLS:-}" && -x "$ANDROID_BUILD_TOOLS/aapt2" ]]; then
    AAPT2="$ANDROID_BUILD_TOOLS/aapt2"
  elif [[ -n "${ANDROID_HOME:-}" ]]; then
    AAPT2="$(ls "$ANDROID_HOME"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -n1)"
  else
    echo "ERROR: aapt2 not found. Set AAPT2 or ANDROID_BUILD_TOOLS." >&2
    exit 1
  fi
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "== Extracting manifest from $(basename "$ARTIFACT")"
if [[ "$ARTIFACT" == *.aab ]]; then
  # AABs need the manifest extracted from the bundle.
  unzip -o -q "$ARTIFACT" AndroidManifest.xml -d "$WORKDIR" || {
    echo "ERROR: could not extract AndroidManifest.xml from AAB" >&2
    exit 1
  }
  MANIFEST_XML="$WORKDIR/AndroidManifest.xml"
  # AAB manifests are binary XML; dump permissions directly.
  PERMISSIONS="$("$AAPT2" dump permissions "$MANIFEST_XML" 2>/dev/null || true)"
else
  PERMISSIONS="$("$AAPT2" dump permissions "$ARTIFACT" 2>/dev/null || true)"
fi

if [[ -z "$PERMISSIONS" ]]; then
  echo "ERROR: could not read permissions (aapt2 problem?)" >&2
  exit 1
fi

echo "$PERMISSIONS"

# --- check against the allow-list (ADR 0008) ---
# Every permission the app may hold in v1.
ALLOWED=(
  android.permission.CAMERA
  android.permission.ACTIVITY_RECOGNITION
  android.permission.POST_NOTIFICATIONS
  android.permission.USE_BIOMETRIC
  # Health Connect permissions are requested via a separate API, not
  # manifest permissions; the health package handles them at runtime.
)

FAILED=0

# Extract permission names. aapt2 prints
# `uses-permission: name='android.permission.X'` — take the
# android.permission.* tokens only (app-defined permission strings
# such as com.<pkg>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, which
# AndroidX auto-generates, name nothing outside this app and are not
# real grants).
mapfile -t FOUND < <(echo "$PERMISSIONS" | grep -oE "android\.permission\.[A-Za-z0-9_.]+" | sort -u || true)

for perm in "${FOUND[@]}"; do
  ok=0
  for allowed in "${ALLOWED[@]}"; do
    if [[ "$perm" == "$allowed" ]]; then
      ok=1
      break
    fi
  done
  if [[ $ok -eq 0 ]]; then
    echo "FAIL: permission not on allow-list: $perm" >&2
    FAILED=1
  fi
done

# --- R1: no network, ever ---
if echo "$PERMISSIONS" | grep -q "android.permission.INTERNET"; then
  echo "FAIL: INTERNET permission present in release build (R1)" >&2
  FAILED=1
fi
if echo "$PERMISSIONS" | grep -q "android.permission.ACCESS_NETWORK_STATE"; then
  echo "FAIL: ACCESS_NETWORK_STATE permission present in release build (R1)" >&2
  FAILED=1
fi

if [[ $FAILED -eq 1 ]]; then
  echo "" >&2
  echo "Manifest check FAILED. The release build must not hold any" >&2
  echo "permission outside the allow-list, and must never contain" >&2
  echo "INTERNET or ACCESS_NETWORK_STATE." >&2
  exit 1
fi

echo "OK: merged manifest contains only allow-listed permissions."
