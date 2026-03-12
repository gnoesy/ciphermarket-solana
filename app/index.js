require("dotenv").config();
const express = require('express');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const LOG_DIR = path.join(__dirname, 'logs');
const LOG_FILE = path.join(LOG_DIR, 'demo.jsonl');
const WALLET = process.env.WALLET_PUBLIC_KEY || '';

if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

function readRows() {
if (!fs.existsSync(LOG_FILE)) return [];
return fs.readFileSync(LOG_FILE, 'utf8').trim().split('\n').filter(Boolean).map(l => {
try { return JSON.parse(l); } catch { return null; }
}).filter(Boolean);
}

function writeRow(row) {
fs.appendFileSync(LOG_FILE, JSON.stringify(row) + '\n');
}

function parseSignature(out) {
// 1) JSON output parse
try {
const j = JSON.parse(out);
if (j?.signature) return j.signature;
if (j?.result?.signature) return j.result.signature;
if (typeof j?.result === 'string') return j.result;
} catch {}

// 2) text parse: Signature: xxx / 서명: xxx
const m1 = out.match(/(?:Signature|서명)\s*:\s*([1-9A-HJ-NP-Za-km-z]{43,88})/);
if (m1) return m1[1];

// 3) fallback: first base58-like long token
const m2 = out.match(/([1-9A-HJ-NP-Za-km-z]{43,88})/);
if (m2) return m2[1];

return '';
}

app.get('/health', (req, res) => {
res.json({ ok: true, service: 'ciphermarket-solana-demo', ts: new Date().toISOString() });
});

app.post('/demo-run', (req, res) => {
const pattern = (req.body && req.body.pattern) || 'A';
let txHash = '';
let status = 'ok';
let note = '';

try {
if (!WALLET) throw new Error('WALLET_PUBLIC_KEY missing');
const out = execSync(
`solana transfer ${WALLET} 0.000001 --allow-unfunded-recipient --output json`,
{ encoding: 'utf8' }
);
txHash = parseSignature(out);
if (!txHash) throw new Error(`signature parse failed: ${out.slice(0, 200)}`);
} catch (e) {
status = 'fail';
note = String(e.message || e);
}

const row = {
ts: new Date().toISOString(),
action: 'demo-run',
input: { pattern },
status,
tx_hash: txHash || `err_${Date.now()}`,
note
};
writeRow(row);
res.json(row);
});

app.get('/evidence-summary', (req, res) => {
const rows = readRows().filter(r => r.action === 'demo-run');
const ok = rows.filter(r => r.status === 'ok').length;
const total = rows.length;
const rate = total ? ((ok / total) * 100).toFixed(2) : '0.00';
res.json({ run_total: total, run_ok: ok, success_rate: `${rate}%`, latest: rows.slice(-5) });
});

app.listen(PORT, () => console.log(`Demo server listening on http://localhost:${PORT}`));
