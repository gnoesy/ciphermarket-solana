#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
STATUS="ok"
NOTE="demo service heartbeat"

if ! curl -fsS http://localhost:3000/health >/dev/null; then
STATUS="fail"
NOTE="health check failed"
fi

echo "{\"ts\":\"$TS\",\"stage\":\"P1\",\"action\":\"heartbeat\",\"status\":\"$STATUS\",\"host\":\"macbook\",\"note\":\"$NOTE\"}" >> evidence/P1_node_ops.jsonl
echo "logged: $STATUS at $TS"
