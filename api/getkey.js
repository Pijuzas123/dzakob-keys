const crypto = require('crypto');

const SECRET = process.env.KEY_SECRET || "dzakob-change-me-2026";
const HUB_NAME = "dzakob";

function getIP(req) {
    const fwd = req.headers['x-forwarded-for'];
    if (fwd) return fwd.split(',')[0].trim();
    return req.headers['x-real-ip'] || req.socket?.remoteAddress || "0.0.0.0";
}

function keyFor(ip) {
    const day = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    const hash = crypto.createHash('sha256').update(day + ip + SECRET).digest('hex');
    return HUB_NAME + "-" + hash.slice(0, 20);
}

function timeLeft() {
    const ms = (86400000 - (Date.now() % 86400000));
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    return h + "h " + m + "m";
}

module.exports = (req, res) => {
    const ip = getIP(req);
    const key = keyFor(ip);
    const expires = timeLeft();

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(`<!DOCTYPE html>
<html>
<head>
<title>dzakob Key</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, "Segoe UI", Roboto, sans-serif; }
body { background: #0e0e12; color: #e6e6f0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
.card { background: #16161c; border: 1px solid #2a2a3a; border-radius: 14px; padding: 40px; max-width: 460px; width: 100%; box-shadow: 0 20px 60px rgba(0,0,0,0.4); }
h1 { font-size: 28px; font-weight: 700; margin-bottom: 6px; letter-spacing: -0.5px; }
.sub { color: #7a7a90; font-size: 13px; margin-bottom: 28px; }
.key-box { background: #0a0a10; border: 1px solid #2a2a3a; border-radius: 10px; padding: 20px; font-family: "SF Mono", Consolas, monospace; font-size: 15px; color: #6acc80; text-align: center; word-break: break-all; margin-bottom: 20px; }
.copy-btn { width: 100%; background: linear-gradient(135deg, #4d7cff, #6b5cff); color: white; border: 0; padding: 14px; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; transition: transform 0.15s; }
.copy-btn:hover { transform: translateY(-1px); }
.copy-btn:active { transform: translateY(0); }
.expires { text-align: center; color: #7a7a90; font-size: 12px; margin-top: 18px; }
.expires b { color: #b8b8d0; }
</style>
</head>
<body>
<div class="card">
<h1>dzakob</h1>
<p class="sub">Your key for today</p>
<div class="key-box" id="key">${key}</div>
<button class="copy-btn" onclick="copy()">COPY KEY</button>
<p class="expires">Expires in <b>${expires}</b></p>
</div>
<script>
function copy() {
    const key = document.getElementById('key').textContent;
    navigator.clipboard.writeText(key).then(() => {
        const btn = document.querySelector('.copy-btn');
        btn.textContent = 'COPIED';
        setTimeout(() => btn.textContent = 'COPY KEY', 1500);
    });
}
</script>
</body>
</html>`);
};
