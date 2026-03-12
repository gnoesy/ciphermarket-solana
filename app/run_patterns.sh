#!/usr/bin/env bash
set -euo pipefail
URL="http://localhost:3000/demo-run"
patterns=(A B C A B C A B C A)

for p in "${patterns[@]}"; do
curl -s -X POST "$URL" \
-H "Content-Type: application/json" \
-d "{\"pattern\":\"$p\"}" >/dev/null
echo "sent pattern=$p"
sleep 1
done

echo "done: 10 runs"
