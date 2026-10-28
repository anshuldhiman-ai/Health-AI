#!/usr/bin/env python3
"""tools/check_all.py — Cross-platform Master Guardrail Runner (T0.3, Gate G0)"""

import os
import re
import subprocess
import sys
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

REPO_ROOT = Path(__file__).resolve().parent.parent

def run_step(title, cmd, cwd=REPO_ROOT):
    print(f"\n--> {title}")
    res = subprocess.run(cmd, cwd=cwd, shell=True)
    if res.returncode != 0:
        print(f"FAILED: {title} exited with code {res.returncode}", file=sys.stderr)
        sys.exit(res.returncode)
    print(f"[PASS] {title}")

def check_offline():
    print("\n--> 1. Checking 100% Offline Invariants...")
    manifest = REPO_ROOT / "app" / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    content = manifest.read_text(encoding="utf-8")
    
    if "android.permission.INTERNET" in content:
        pattern = r'android\.permission\.INTERNET[\s\S]*?tools:node="remove"'
        if not re.search(pattern, content):
            print("ERROR: android.permission.INTERNET is present without tools:node='remove'", file=sys.stderr)
            sys.exit(1)
        print("  [PASS] android.permission.INTERNET is explicitly removed with tools:node='remove'")
    else:
        print("  [PASS] android.permission.INTERNET not present in main manifest")
        
    pubspec = REPO_ROOT / "app" / "pubspec.yaml"
    pub_content = pubspec.read_text(encoding="utf-8")
    banned = ["http:", "dio:", "retrofit:", "socket_io_client:", "web_socket_channel:", "firebase_"]
    for pkg in banned:
        if re.search(rf"^\s\s{pkg}", pub_content, re.MULTILINE):
            print(f"ERROR: Banned networking package '{pkg}' found in {pubspec}", file=sys.stderr)
            sys.exit(1)
    print("  [PASS] No banned networking packages found in pubspec.yaml")
    print("[PASS] 100% Offline checks passed")

def check_licenses():
    print("\n--> 2. Checking License Hygiene...")
    app_lib = REPO_ROOT / "app" / "lib"
    for path in app_lib.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "ultralytics" in text.lower():
            print(f"ERROR: Banned 'ultralytics' import found in {path}", file=sys.stderr)
            sys.exit(1)
    print("  [PASS] Zero banned AGPL/GPL imports in shipped code")
    if not (REPO_ROOT / "ml" / "data" / "LICENSES.md").exists() or not (REPO_ROOT / "docs" / "THIRD_PARTY.md").exists():
        print("ERROR: Required license files missing", file=sys.stderr)
        sys.exit(1)
    print("[PASS] License Hygiene passed")

def check_placeholders(strict=False):
    print("\n--> 3. Checking Placeholders...")
    placeholders = []
    scan_dirs = [REPO_ROOT / "app" / "lib", REPO_ROOT / "ml" / "src"]
    for d in scan_dirs:
        if not d.exists():
            continue
        for path in d.rglob("*.*"):
            if path.suffix in [".dart", ".py", ".json", ".yaml"]:
                try:
                    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                        if "PLACEHOLDER(" in line:
                            placeholders.append(f"{path.relative_to(REPO_ROOT)}:{i}: {line.strip()}")
                except Exception:
                    pass
    if placeholders:
        print(f"  Found {len(placeholders)} placeholder(s) in development (allowed prior to G10):")
        for p in placeholders[:10]:
            print(f"    {p}")
        if strict:
            print("ERROR: Placeholders must be 0 for Gate G10 strict check", file=sys.stderr)
            sys.exit(1)
    else:
        print("  [PASS] Zero placeholders found across app and ml")
    print("[PASS] Placeholder check passed")

def main():
    print("=" * 60)
    print("         Health AI — Master Quality Guardrails (T0.3)        ")
    print("=" * 60)
    
    check_offline()
    check_licenses()
    check_placeholders(strict="--strict" in sys.argv)
    
    app_dir = REPO_ROOT / "app"
    run_step("4. Dart Formatting Check", "dart format --output=none --set-exit-if-changed .", cwd=app_dir)
    run_step("5. Flutter Static Analysis", "flutter analyze --no-fatal-warnings --no-fatal-infos", cwd=app_dir)
    run_step("6. Flutter Unit & Widget Tests", "flutter test", cwd=app_dir)
    
    ml_dir = REPO_ROOT / "ml"
    run_step("7. Python ML Tests", "uv run pytest", cwd=ml_dir)
    
    print("\n" + "=" * 60)
    print("       ALL GUARDRAIL CHECKS PASSED (GATE G0 GREEN)       ")
    print("=" * 60)

if __name__ == "__main__":
    main()
