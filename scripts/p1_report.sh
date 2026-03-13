#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TOTAL=$(grep -c '"action":"heartbeat"' evidence/P1_node_ops.jsonl || true)
OK=$(grep -c '"action":"heartbeat".*"status":"ok"' evidence/P1_node_ops.jsonl || true)
FAIL=$((TOTAL-OK))
RATE=0
if [ "$TOTAL" -gt 0 ]; then
RATE=$(awk "BEGIN { printf \"%.2f\", ($OK/$TOTAL)*100 }")
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > evidence/P1_DAILY_REPORT.md <<RPT
# P1 Daily Report

- generated_at: $TS
- heartbeat_total: $TOTAL
- heartbeat_ok: $OK
- heartbeat_fail: $FAIL
- uptime_rate: $RATE%

## latest heartbeat
$(tail -n 5 evidence/P1_node_ops.jsonl)
RPT

echo "report generated: evidence/P1_DAILY_REPORT.md"
