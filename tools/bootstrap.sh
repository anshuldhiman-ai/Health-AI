#!/usr/bin/env bash
# One-time bootstrap: install FVM + Flutter SDK (Section 3.1).
#
# Run from anywhere. Idempotent — safe to re-run.
#
# Requires: git, curl, unzip, Java 17+ (Android builds).
# After this: `cd app && fvm flutter pub get`
set -euo pipefail

FVM_VERSION="${FVM_VERSION:-6.1.2}"

echo "== Installing FVM"
if command -v fvm >/dev/null 2>&1; then
  echo "fvm already installed: $(fvm --version)"
else
  # FVM installer (pub global activate needs Dart; if Dart is absent,
  # use the standalone installer below instead).
  if command -v dart >/dev/null 2>&1; then
    dart pub global activate fvm
  else
    echo "Dart not found — downloading FVM standalone..."
    # See fvm.app for the latest installer URL.
    curl -fsSL https://raw.githubusercontent.com/leoafarias/fvm/main/install.sh | bash
  fi
fi

# Ensure fvm is on PATH for this session.
export PATH="$PATH:$HOME/.pub-cache/bin:$HOME/AppData/Local/Pub/Cache/bin"

echo "== Reading pinned Flutter version from app/.fvmrc"
FLUTTER_VERSION="$(grep '^flutter:' app/.fvmrc | awk '{print $2}')"
if [[ -z "$FLUTTER_VERSION" ]]; then
  echo "ERROR: could not read flutter version from app/.fvmrc" >&2
  exit 1
fi
echo "Pinned version: $FLUTTER_VERSION"

echo "== Installing Flutter $FLUTTER_VERSION via FVM"
fvm install "$FLUTTER_VERSION"

echo ""
echo "Bootstrap complete. Next steps:"
echo "  cd app"
echo "  fvm flutter pub get"
echo "  fvm dart run build_runner build --delete-conflicting-outputs"
echo "  fvm flutter gen-l10n"
echo "  fvm flutter analyze"
echo "  fvm flutter test"
echo ""
echo "Android builds additionally need the Android SDK (cmdline-tools,"
echo "platform android-36, build-tools) and Java 17+. Set ANDROID_HOME."
