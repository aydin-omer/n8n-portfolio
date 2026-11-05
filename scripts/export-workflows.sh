#!/usr/bin/env bash
# Exports all n8n workflows to ./workflows as separate JSON files.
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose exec -T n8n n8n export:workflow --all --separate --output=/home/node/workflows/

# Strip pinned test data (pinData)
if command -v jq >/dev/null 2>&1; then
  for f in workflows/*.json; do
    [ -e "$f" ] || continue
    jq 'del(.pinData)' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
else
  echo "Warning: jq not installed, pinData was not removed."
fi

# Scan for possible secrets
if grep -rniE 'bearer |api[_-]?key|password|secret|token' workflows/ >/dev/null 2>&1; then
  echo "WARNING: Possible secrets found in workflow files:"
  grep -rniE 'bearer |api[_-]?key|password|secret|token' workflows/ | cut -c1-160
  echo "Review before committing."
fi

echo "Done. Workflows exported to ./workflows"
