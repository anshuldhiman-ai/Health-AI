# Builds HEALTH_AI_SKILL_AUDIT/SHARE_PACKAGE with hand-picked source files only.
# Preserves original directory structure. Excludes binaries, caches, generated code,
# model weights, datasets, and any artifact not needed to understand the engineering.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot   # repo root
Set-Location $root
$role = 'HEALTH_AI_SKILL_AUDIT\SHARE_PACKAGE'
Remove-Item -Recurse -Force HEALTH_AI_SKILL_AUDIT\SHARE_PACKAGE -ErrorAction SilentlyContinue

function Copy-Files($list) {
  foreach ($src in $list) {
    if (Test-Path $src) {
      $rel = $src -replace '/', '\'
      $dst = Join-Path $role $rel
      $dstDir = Split-Path $dst -Parent
      New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
      Copy-Item -LiteralPath $rel -Destination $dst
    } else {
      Write-Warning "missing: $src"
    }
  }
}

# --- split copy helpers: "src|dest-relative" so filenames can be mapped ---
function Copy-Split($pairs) {
  foreach ($p in $pairs) {
    $src, $dstrel = $p -split '\|', 2
    if (-not (Test-Path $src)) { Write-Warning "missing: $src"; continue }
    $dst = Join-Path $role $dstrel
    $dstDir = Split-Path $dst -Parent
    New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst
  }
}

# 1. root docs + repo hygiene files
Copy-Files @('README.md','AGENTS.md','CLAUDE.md','.gitignore')

# 2. docs/ (all markdown incl. adr/, safety/, specs/)
Get-ChildItem docs -Recurse -Filter *.md | ForEach-Object {
  $rel = $_.FullName.Substring($root.Length + 1)
  Copy-Files @($rel)
}

# 3. tools/ (all scripts)
Get-ChildItem tools -File | ForEach-Object { Copy-Files @("tools/$($_.Name)") }

# 4. CI workflows
Copy-Files @('.github/workflows/app-ci.yml','.github/workflows/ml-ci.yml')

# 5. app config
Copy-Files @(
  'app/pubspec.yaml','app/pubspec.lock','app/analysis_options.yaml',
  'app/l10n.yaml','app/.fvmrc','app/.gitignore'
)

# 6. android config (hand-picked)
Copy-Files @(
  'app/android/build.gradle.kts','app/android/settings.gradle.kts',
  'app/android/gradle.properties','app/android/gradle/wrapper/gradle-wrapper.properties',
  'app/android/app/build.gradle.kts','app/android/app/proguard-rules.pro',
  'app/android/app/src/main/AndroidManifest.xml',
  'app/android/app/src/debug/AndroidManifest.xml',
  'app/android/app/src/profile/AndroidManifest.xml',
  'app/android/app/src/main/res/xml/data_extraction_rules.xml',
  'app/android/app/src/main/res/values/strings.xml',
  'app/android/app/src/main/kotlin/com/anshuldhiman/app/MainActivity.kt'
)

# 7. app/lib (all Dart, excluding generated localizations)
Get-ChildItem -Recurse app\lib -Filter *.dart | Where-Object {
  $_.Name -notmatch '^app_localizations(_[a-z]{2})?\.dart$'
} | ForEach-Object {
  $rel = $_.FullName.Substring($root.Length + 1)
  Copy-Files @($rel)
}
# l10n: ARB source files + extensions only
Copy-Files @('app/lib/l10n/app_en.arb','app/lib/l10n/app_hi.arb','app/lib/l10n/app_pa.arb','app/lib/l10n/extensions.dart')

# 8. assets metadata (NO weights, NO fonts, only tiny JSON/MD/license files)
Copy-Files @(
  'app/assets/models/README.md','app/assets/models/labels.json','app/assets/models/container_profiles.json',
  'app/assets/nutrition/khana_catalog.json','app/assets/fonts/OFL.txt'
)

# 9. tests (all Dart fixture-free tests + the mass vectors fixture)
Get-ChildItem -Recurse app\test -Filter *.dart | ForEach-Object {
  $rel = $_.FullName.Substring($root.Length + 1)
  Copy-Files @($rel)
}
Copy-Split @('app/test/fixtures/mass_vectors.json|app/test/fixtures/mass_vectors.json')

# 10. ml/ (pipeline source, no venv, no weights, no notebooks, no uv.lock)
Copy-Files @('ml/pyproject.toml','ml/dvc.yaml','ml/.python-version','ml/DATA_LICENSES.md',
  'ml/data/classes.json','ml/data/LICENSES.md','ml/data/weighed_plates/plates.csv')
Get-ChildItem ml\taxonomy -File | ForEach-Object { Copy-Files @("ml/taxonomy/$($_.Name)") }
Get-ChildItem ml\scripts -File -Exclude *.ipynb | ForEach-Object {
  if ($_.Extension -ne '.pyc') { Copy-Files @("ml/scripts/$($_.Name)") }
}
Get-ChildItem ml\src -Recurse -Filter *.py | ForEach-Object {
  if ($_.FullName -notmatch '__pycache__') {
    $rel = $_.FullName.Substring($root.Length + 1)
    Copy-Files @($rel)
  }
}
Get-ChildItem ml\tests -Filter *.py | ForEach-Object { Copy-Files @("ml/tests/$($_.Name)") }

Write-Host "SHARE_PACKAGE built."
