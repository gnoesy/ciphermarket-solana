#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
while true; do
./scripts/p2_alert_check.sh
sleep 1800
done
