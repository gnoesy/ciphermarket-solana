const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const LOG_DIR = path.join(__dirname, 'logs');
const LOG_FILE = path.join(LOG_DIR, 'demo.jsonl');
if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

function readLines(file) {
if (!fs.existsSync(file)) return [];
return fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean);
}

app.get('/health', (req, res) => {
res.json({ ok: true, service: 'ciphermarket-solana-demo', ts: new Date().toISOString() });
});

app.post('/demo-run', (req, res) => {
const payload = {
ts: new Date().toISOString(),
action: 'demo-run',
input: req.body || {},
status: 'ok',
tx_hash: `demo_${Date.now()}`
};
fs.appendFileSync(LOG_FILE, JSON.stringify(payload) + '\n');
res.json(payload);
});

app.get('/evidence-summary', (req, res) => {
const rows = readLines(LOG_FILE).map(l => {
try { return JSON.parse(l); } catch { return null; }
}).filter(Boolean);

const runRows = rows.filter(r => r.action === 'demo-run');
const okRows = runRows.filter(r => r.status === 'ok');
const successRate = runRows.length ? ((okRows.length / runRows.length) * 100).toFixed(2) : '0.00';

res.json({
run_total: runRows.length,
run_ok: okRows.length,
success_rate: `${successRate}%`,
latest: runRows.slice(-5)
});
});

app.listen(PORT, () => {
console.log(`Demo server listening on http://localhost:${PORT}`);
});
