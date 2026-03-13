#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
while true; do
./scripts/p1_heartbeat.sh
sleep 1800
done
