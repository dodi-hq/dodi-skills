#!/usr/bin/env bash
# Offline: real temporary git repositories; fake Linear transport; no live writes.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$here/test-clean-park.py" "$@"
