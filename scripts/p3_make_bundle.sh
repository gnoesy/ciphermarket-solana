#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
TS=$(date -u +"%Y%m%dT%H%M%SZ")
OUT="dist/ciphermarket_rtg_bundle_${TS}.tar.gz"
tar -czf "$OUT" \
scripts/p1_heartbeat.sh \
scripts/p1_loop.sh \
scripts/p1_report.sh \
scripts/p2_refresh_report.sh \
scripts/p2_alert_check.sh \
scripts/p2_alert_loop.sh \
evidence/P1_node_ops.jsonl \
evidence/P1_DAILY_REPORT.md \
evidence/P2_REPORT.md \
logs/p1_loop.pid \
logs/p2_alert_loop.pid 2>/dev/null || true
echo "$OUT"
