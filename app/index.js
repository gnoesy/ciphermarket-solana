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
const EVIDENCE_FILE = path.join(__dirname, '..', 'evidence', 'mxe_runs.jsonl');
const WALLET = process.env.WALLET_PUBLIC_KEY || '';

if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

function readRows(file) {
if (!fs.existsSync(file)) return [];
return fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean).map(l => {
try { return JSON.parse(l); } catch { return null; }
}).filter(Boolean);
}
function appendRow(file, row) {
fs.appendFileSync(file, JSON.stringify(row) + '\n');
}
function parseSignature(out) {
try {
const j = JSON.parse(out);
if (j?.signature) return j.signature;
if (j?.result?.signature) return j.result.signature;
if (typeof j?.result === 'string') return j.result;
} catch {}
const m1 = out.match(/(?:Signature|서명)\s*:\s*([1-9A-HJ-NP-Za-km-z]{43,88})/);
if (m1) return m1[1];
const m2 = out.match(/([1-9A-HJ-NP-Za-km-z]{43,88})/);
return m2 ? m2[1] : '';
}

app.get('/health', (req, res) => {
res.json({ ok: true, service: 'ciphermarket-solana-demo', ts: new Date().toISOString() });
});

app.post('/demo-run', (req, res) => {
const pattern = (req.query.pattern || (req.body && req.body.pattern) || 'A').toString().toUpperCase();
let txHash = '';
let status = 'ok';
let note = '';
try {
if (!WALLET) throw new Error('WALLET_PUBLIC_KEY missing');
const cmd = `solana transfer ${WALLET} 0.000001 --allow-unfunded-recipient --output json`;
let out = '';
try {
out = execSync(cmd, { encoding: 'utf8' });
txHash = parseSignature(out);
} catch {
out = execSync(cmd, { encoding: 'utf8' }); // 1회 재시도
txHash = parseSignature(out);
}
if (!txHash) throw new Error(`signature parse failed: ${String(out).slice(0, 200)}`);
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
appendRow(LOG_FILE, row);

// 자동 증빙 파일 반영
appendRow(EVIDENCE_FILE, {
ts: row.ts,
stage: 'P0',
action: 'run',
network: 'devnet',
pattern,
status,
tx_hash: row.tx_hash,
note: status === 'ok' ? 'auto tx from /demo-run' : row.note
});

res.json(row);
});

app.get('/evidence-summary', (req, res) => {
const rows = readRows(LOG_FILE).filter(r => r.action === 'demo-run');
const ok = rows.filter(r => r.status === 'ok').length;
const total = rows.length;
const rate = total ? ((ok / total) * 100).toFixed(2) : '0.00';
const byPattern = rows.reduce((acc, r) => {
const p = (r.input?.pattern || 'UNK').toUpperCase();
acc[p] = acc[p] || { total: 0, ok: 0 };
acc[p].total += 1;
if (r.status === 'ok') acc[p].ok += 1;
return acc;
}, {});
res.json({ run_total: total, run_ok: ok, success_rate: `${rate}%`, by_pattern: byPattern, latest: rows.slice(-5) });
});

app.listen(PORT, () => console.log(`Demo server listening on http://localhost:${PORT}`));
