#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

HB_TOTAL=$(grep -c '"action":"heartbeat"' evidence/P1_node_ops.jsonl 2>/dev/null || true)
HB_OK=$(grep -c '"action":"heartbeat".*"status":"ok"' evidence/P1_node_ops.jsonl 2>/dev/null || true)
HB_FAIL=$((HB_TOTAL-HB_OK))
HB_RATE=0
if [ "$HB_TOTAL" -gt 0 ]; then
HB_RATE=$(awk "BEGIN { printf \"%.2f\", ($HB_OK/$HB_TOTAL)*100 }")
fi

LAST_24H=$(awk -v d="$(date -u -v-1d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '1 day ago' +"%Y-%m-%dT%H:%M:%SZ")" '
$0 ~ /"action":"heartbeat"/ && $0 ~ /"ts":/ {
if (match($0, /"ts":"([^"]+)"/, a)) if (a[1] >= d) c++
}
END { print c+0 }
' evidence/P1_node_ops.jsonl 2>/dev/null || echo 0)

FALLBACK="none"
if [ "${LAST_24H:-0}" -eq 0 ]; then
FALLBACK="$(tail -n 5 evidence/P1_node_ops.jsonl 2>/dev/null || true)"
fi

TS_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > evidence/P2_REPORT.md <<RPT
# CipherMarket P2 Report

- generated_at: $TS_NOW
- heartbeat_total: $HB_TOTAL
- heartbeat_ok: $HB_OK
- heartbeat_fail: $HB_FAIL
- uptime_rate: $HB_RATE%
- last_24h_heartbeat: ${LAST_24H:-0}

## latest heartbeat
$(tail -n 5 evidence/P1_node_ops.jsonl 2>/dev/null || true)

## fallback_when_last_24h_zero
$FALLBACK
RPT

echo "updated evidence/P2_REPORT.md"
