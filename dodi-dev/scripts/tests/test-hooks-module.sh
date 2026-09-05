#!/usr/bin/env bash
# Offline test for the no-re-entry function-hook module (dodi-dev/hooks/hooks.js).
# Needs node >= 22.7 (ESM syntax detection on a bare .js).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MODULE="$HERE/../../hooks/hooks.js"
DRIVER="$HERE/hooks-module-driver.mjs"

command -v node >/dev/null || { echo "test-hooks-module: node not found — concrete blocker" >&2; exit 2; }
test -f "$MODULE"
node --check --input-type=module < "$MODULE"
node "$DRIVER"
