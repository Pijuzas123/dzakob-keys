const crypto = require('crypto');

const SECRET = process.env.KEY_SECRET || "dzakob-change-me-2026";
const HUB_NAME = "dzakob";
const GRACE_DAYS = 1;

function getIP(req) {
    const fwd = req.headers['x-forwarded-for'];
    if (fwd) return fwd.split(',')[0].trim();
    return req.headers['x-real-ip'] || req.socket?.remoteAddress || "0.0.0.0";
}

function keyForDayAndIP(day, ip) {
    const hash = crypto.createHash('sha256').update(day + ip + SECRET).digest('hex');
    return HUB_NAME + "-" + hash.slice(0, 20);
}

const ADMIN_KEYS = (process.env.ADMIN_KEYS || "").split(",").map(k => k.trim()).filter(Boolean);

module.exports = (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');

    const key = (req.query.key || "").trim();
    if (!key) {
        return res.status(400).json({ valid: false, error: "missing key" });
    }

    if (ADMIN_KEYS.includes(key)) {
        return res.status(200).json({ valid: true, admin: true });
    }

    const ip = getIP(req);
    const today = Math.floor(Date.now() / 86400000);
    for (let i = 0; i <= GRACE_DAYS; i++) {
        if (key === keyForDayAndIP(today - i, ip)) {
            return res.status(200).json({ valid: true });
        }
    }

    res.status(200).json({ valid: false, error: "invalid or expired key" });
};
