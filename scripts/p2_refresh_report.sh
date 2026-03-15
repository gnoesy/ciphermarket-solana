#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

RUN_TOTAL=$(grep -c '"action":"demo-run"' app/logs/demo.jsonl || true)
RUN_OK=$(grep -c '"action":"demo-run".*"status":"ok"' app/logs/demo.jsonl || true)
RUN_FAIL=$((RUN_TOTAL-RUN_OK))
RATE=0
if [ "$RUN_TOTAL" -gt 0 ]; then
RATE=$(awk "BEGIN { printf \"%.2f\", ($RUN_OK/$RUN_TOTAL)*100 }")
fi

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > evidence/P2_REPORT.md <<RPT
# P2 Report

- generated_at: $TS
- run_total: $RUN_TOTAL
- run_ok: $RUN_OK
- run_fail: $RUN_FAIL
- success_rate: $RATE%

## latest runs
$(tail -n 5 app/logs/demo.jsonl)

## latest p1 heartbeat
$(tail -n 5 evidence/P1_node_ops.jsonl)
RPT

echo "updated evidence/P2_REPORT.md"
