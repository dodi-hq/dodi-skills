#!/usr/bin/env bash
# Claude Stop hook: an autonomous Florist seat may not end its turn without the
# digest in its final message (DOD-1389). No-op in manual mode.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
payload="$(cat)"
exec python3 "$here/florist-digest-gate.py" hook-stop "$payload"
