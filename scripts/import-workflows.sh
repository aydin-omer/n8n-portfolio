#!/usr/bin/env bash
# Imports workflows from ./workflows into n8n (for anyone cloning the repo).
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T n8n n8n import:workflow --separate --input=/home/node/workflows/
echo "Workflows imported."
