#!/usr/bin/env bash
# tools/check_all.sh — Master Guardrail Runner (T0.3, Gate G0)
set -euo pipefail
python3 tools/check_all.py "$@" || python tools/check_all.py "$@"
