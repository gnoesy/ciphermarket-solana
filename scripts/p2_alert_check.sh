#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

FAIL_LIMIT=${FAIL_LIMIT:-1}
HB_TOTAL=$(grep -c '"action":"heartbeat"' evidence/P1_node_ops.jsonl 2>/dev/null || true)
HB_OK=$(grep -c '"action":"heartbeat".*"status":"ok"' evidence/P1_node_ops.jsonl 2>/dev/null || true)
HB_FAIL=$((HB_TOTAL-HB_OK))

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MSG="[P2-ALERT][ciphermarket] ts=$TS total=$HB_TOTAL ok=$HB_OK fail=$HB_FAIL limit=$FAIL_LIMIT"

if [ "$HB_FAIL" -gt "$FAIL_LIMIT" ]; then
echo "$MSG status=TRIGGERED" | tee -a logs/p2_alert.log
else
echo "$MSG status=OK" | tee -a logs/p2_alert.log
fi
