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

# 최근 24h 집계
NOW_EPOCH=$(date +%s)
RUN24_TOTAL=0
RUN24_OK=0
RUN24_FAIL=0

while IFS= read -r line; do
TS=$(echo "$line" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
ST=$(echo "$line" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
if [ -n "$TS" ]; then
TS_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S.%NZ" "$TS" "+%s" 2>/dev/null || echo "")
if [ -n "$TS_EPOCH" ]; then
AGE=$((NOW_EPOCH-TS_EPOCH))
if [ "$AGE" -le 86400 ]; then
RUN24_TOTAL=$((RUN24_TOTAL+1))
if [ "$ST" = "ok" ]; then
RUN24_OK=$((RUN24_OK+1))
else
RUN24_FAIL=$((RUN24_FAIL+1))
fi
fi
fi
fi
done < <(grep '"action":"demo-run"' app/logs/demo.jsonl || true)

RUN24_RATE=0
if [ "$RUN24_TOTAL" -gt 0 ]; then
RUN24_RATE=$(awk "BEGIN { printf \"%.2f\", ($RUN24_OK/$RUN24_TOTAL)*100 }")
fi

# 실패 원인 Top3
FAIL_TOP3=$(grep '"action":"demo-run".*"status":"fail"' app/logs/demo.jsonl 2>/dev/null \
| sed -n 's/.*"note":"\([^"]*\)".*/\1/p' \
| sed '/^$/d' \
| sort | uniq -c | sort -nr | head -n 3 || true)

# 최신 성공 tx 5개 링크
LATEST_TX=$(grep '"action":"demo-run".*"status":"ok"' app/logs/demo.jsonl 2>/dev/null \
| sed -n 's/.*"tx_hash":"\([^"]*\)".*/\1/p' \
| tail -n 5)

TS_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

{
echo "# P2 Report"
echo
echo "- generated_at: $TS_NOW"
echo "- run_total: $RUN_TOTAL"
echo "- run_ok: $RUN_OK"
echo "- run_fail: $RUN_FAIL"
echo "- success_rate: $RATE%"
echo
echo "## last_24h"
echo "- run_total_24h: $RUN24_TOTAL"
echo "- run_ok_24h: $RUN24_OK"
echo "- run_fail_24h: $RUN24_FAIL"
echo "- success_rate_24h: $RUN24_RATE%"
echo
echo "## latest success tx links"
if [ -n "$LATEST_TX" ]; then
while IFS= read -r tx; do
[ -n "$tx" ] && echo "- https://explorer.solana.com/tx/$tx?cluster=devnet"
done <<< "$LATEST_TX"
else
echo "- (none)"
fi
echo
echo "## fail top3"
if [ -n "$FAIL_TOP3" ]; then
echo "$FAIL_TOP3" | awk '{$1=$1; print "- "$0}'
else
echo "- (none)"
fi
echo
echo "## latest p1 heartbeat"
tail -n 5 evidence/P1_node_ops.jsonl 2>/dev/null || true
} > evidence/P2_REPORT.md

echo "updated evidence/P2_REPORT.md"
