const crypto = require('crypto');

const SECRET = process.env.KEY_SECRET || "dzakob-change-me-2026";
const HUB_NAME = "dzakob";
const GRACE_DAYS = 1;

function keyForDay(day) {
    const hash = crypto.createHash('sha256').update(day + SECRET).digest('hex');
    return HUB_NAME + "-" + hash.slice(0, 16);
}

module.exports = (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');

    const key = (req.query.key || "").trim();
    if (!key) {
        return res.status(400).json({ valid: false, error: "missing key" });
    }

    const today = Math.floor(Date.now() / 86400000);
    for (let i = 0; i <= GRACE_DAYS; i++) {
        if (key === keyForDay(today - i)) {
            return res.status(200).json({ valid: true });
        }
    }

    res.status(200).json({ valid: false, error: "invalid or expired key" });
};
