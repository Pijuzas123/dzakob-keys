# dzakob key server

## Deploy

1. In Vercel dashboard: **Add New → Project → Import**
2. If you have no GitHub repo, click **"deploy without a git repository"** (or drag this folder to Vercel CLI)
3. Set an env var: `KEY_SECRET = something-random-only-you-know-1234567890`
4. Deploy

Your URLs will be:
- Key page (Lootlabs destination): `https://YOUR_PROJECT.vercel.app/`
- Validate API (hub calls this): `https://YOUR_PROJECT.vercel.app/api/validate?key=X`

## Update Lootlabs

Set the destination URL of your Lootlabs link to `https://YOUR_PROJECT.vercel.app/`
