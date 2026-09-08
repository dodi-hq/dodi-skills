#!/usr/bin/env bash
# Arm and execute the deterministic clean-park protocol.
#
# Usage:
#   clean-park.sh begin <request.json>
#   clean-park.sh run <record>
#   clean-park.sh finish <record> --refresher-stopped
#   clean-park.sh status <record>
#   clean-park.sh interrupt <record> --reason <text> --workers-stopped [--refresher-stopped]
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$here/clean-park.py" "$@"
