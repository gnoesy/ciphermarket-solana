#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] 기본 파일 확인"
for f in .env.example .gitignore README.md; do
[[ -f "$f" ]] || { echo "missing $f"; exit 1; }
done

echo "[2/4] .env 존재 확인 (없으면 생성 안내)"
if [[ ! -f .env ]]; then
echo "- .env 없음: .env.example 복사 필요"
echo " cp .env.example .env"
else
echo "- .env 있음"
fi

echo "[3/4] 필수 키 이름 점검"
for k in RPC_URL ARCIUM_CLUSTER WALLET_PRIVATE_KEY WALLET_PUBLIC_KEY ARCIUM_PROGRAM_ID; do
grep -q "^${k}=" .env.example || { echo "missing key in .env.example: $k"; exit 1; }
done

echo "[4/4] smoke 통과"
echo "OK: bootstrap template is ready"
