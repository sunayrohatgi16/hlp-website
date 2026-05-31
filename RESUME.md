# Resume Notes — site is live

## Current state (all verified working)

- **Live site:** deployed to Netlify, auto-deploys on every push to `main`.
- **Source:** https://github.com/sunayrohatgi16/hlp-website
- **Backend:** Supabase project `xxagiypldvcizhocrfnb.supabase.co`
- **End-to-end confirmed:** signup, login, write post, comments, likes, image upload all work on the live deploy.

## How to make a change and ship it

Edit any file locally, then in PowerShell from this folder:

```powershell
git add .
git commit -m "describe your change"
git push
```

Netlify redeploys within ~30 seconds. No build step.

## How to test locally before pushing

```powershell
.\serve.ps1
```

Open http://localhost:8000/ and hard-refresh (Ctrl+Shift+R) if something looks stale.

## What's where

| File | Purpose |
|---|---|
| `index.html` | The site |
| `supabase-config.js` | Supabase URL + anon key (safe to commit) |
| `supabase-schema.sql` | DB schema; already run in Supabase |
| `serve.ps1` | Local PS HttpListener server |
| `SETUP.md` | Original setup walkthrough |
| `DEPLOY-NETLIFY.md` | Netlify deploy guide (already executed) |
| `.gitignore` | Excludes OS / IDE noise |

## Common follow-ups you might want next

- **Custom domain** (e.g. `humanisticleadership.org`): Netlify → Site settings → Domain management → Add custom domain. Don't forget to update Supabase Site URL + Redirect URLs to the new domain.
- **Email subscribers** when a new post is published: Supabase Edge Functions + Resend.
- **Admin dashboard** if you ever switch from auto-publish to a moderation queue.
- **Image uploads with size enforcement** server-side (currently 5 MB enforced only in JS).
- **Pagination** on the blog list once you have more than ~50 posts.

## If something breaks

- Browser shows stale code: hard refresh (Ctrl+Shift+R).
- Posts exist in DB but don't show on the page: most likely a missing `profiles` row for the author. Backfill SQL is in `SETUP.md` troubleshooting + in memory.
- Auth confirmation emails point at localhost: re-check Supabase → Authentication → URL Configuration. Site URL must be the Netlify URL.
- "Tracking Prevention blocked access..." in Edge console: harmless warning, ignore.
