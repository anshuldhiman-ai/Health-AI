# tools/check_all.ps1 — Master Guardrail Runner for Windows PowerShell (T0.3, Gate G0)
python (Join-Path $PSScriptRoot "check_all.py") $args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
