#!/usr/bin/env bash
# Claude Stop hook: consult only the explicitly armed native-session marker.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
payload="$(cat)"
exec python3 "$here/clean-park.py" hook-stop "$payload"
