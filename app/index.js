const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const LOG_DIR = path.join(__dirname, 'logs');
const LOG_FILE = path.join(LOG_DIR, 'demo.jsonl');

if (!fs.existsSync(LOG_DIR)) fs.mkdirSync(LOG_DIR, { recursive: true });

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

app.listen(PORT, () => {
console.log(`Demo server listening on http://localhost:${PORT}`);
});
