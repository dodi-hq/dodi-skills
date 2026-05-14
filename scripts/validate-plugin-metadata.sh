#!/usr/bin/env bash
set -euo pipefail

python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool dodi-dev/.claude-plugin/plugin.json >/dev/null
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/dodi-dev/.codex-plugin/plugin.json >/dev/null

python3 - <<'PY'
import json
from pathlib import Path

market = json.loads(Path('.claude-plugin/marketplace.json').read_text())
claude = json.loads(Path('dodi-dev/.claude-plugin/plugin.json').read_text())
codex = json.loads(Path('plugins/dodi-dev/.codex-plugin/plugin.json').read_text())

market_version = market['plugins'][0]['version']
assert market_version == claude['version'], (market_version, claude['version'])
assert claude['version'] == codex['version'], (claude['version'], codex['version'])
assert claude['version'] == '0.9.0', claude['version']

print(f"plugin metadata ok: {claude['version']}")
PY
