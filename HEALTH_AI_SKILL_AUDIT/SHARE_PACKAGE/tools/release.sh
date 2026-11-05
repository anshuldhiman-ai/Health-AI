#!/usr/bin/env bash
# Release helper (Section 13).
#
# Builds the release AAB with obfuscation and runs the mandatory
# pre-upload checks. Usage:
#   tools/release.sh
#
# Requires: key.properties in app/ (gitignored, R8), FVM, Android SDK.
set -euo pipefail

cd "$(dirname "$0")/../app"

if [[ ! -f key.properties ]]; then
  echo "ERROR: app/key.properties not found (gitignored, R8)." >&2
  echo "Create it from your password manager:" >&2
  echo "  storePassword=..." >&2
  echo "  keyPassword=..." >&2
  echo "  keyAlias=..." >&2
  echo "  storeFile=..." >&2
  exit 1
fi

echo "== Building release AAB"
fvm flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols

AAB="build/app/outputs/bundle/release/app-release.aab"

echo "== Merged manifest check (R1)"
../tools/check_manifest.sh "$AAB"

echo "== Size budget"
../tools/size_budget.sh "$AAB"

echo ""
echo "Release AAB: $AAB"
echo "Symbols:     build/symbols  (archive PRIVATELY for stack-trace decoding)"
echo ""
echo "Pre-upload checklist (Section 12.4) — verify manually:"
echo "  [ ] Model card present, gates met, SHA-256 matches asset"
echo "  [ ] Nutrition DB version/checksum recorded"
echo "  [ ] Migration tested from all prior versions"
echo "  [ ] Full offline run-through in airplane mode on a real device"
echo "  [ ] TalkBack, 200% font scale, dark mode, small screen pass"
echo "  [ ] Device matrix results updated"
echo "  [ ] SafetyGuard rules re-reviewed; disclaimers present"
echo "  [ ] Privacy policy and Data safety form match the build"
echo "  [ ] Target API level and Play policies re-checked on the day"
echo "  [ ] Upload keystore backed up"
echo "  [ ] Release notes written in plain language"
