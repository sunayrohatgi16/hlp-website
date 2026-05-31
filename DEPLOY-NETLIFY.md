# Deploy to Netlify

Netlify gives you free hosting, free HTTPS, and a free `*.netlify.app`
subdomain. The whole site is static files + Supabase as the backend, so
there's no build step and no server config — you just upload.

Pick **one** of the three methods below.

---

## Method A — Drag and drop (simplest, 2 minutes)

Best if you just want to get a live URL fast.

1. Sign up at **https://app.netlify.com/signup** (free; use Google or email).
2. Open **https://app.netlify.com/drop**.
3. In Windows Explorer, **open this folder**:
   `C:\Users\nishr\OneDrive\Documents\Nish\SunayWebsite\The Humanistic Leadership Project — Leadership Education for the Next Generation_website_files`
4. **Select all files and folders** inside (Ctrl+A), and drag them onto the
   Netlify Drop zone. (Drag the *contents*, not the parent folder.)
5. Netlify gives you a URL like `https://random-words-12345.netlify.app`.
   That's your live site.

**Important:** every time you make a change locally, you have to drag the
folder in again. For ongoing updates, use Method C instead.

---

## Method B — Netlify CLI (one command after install)

Better if you make changes often and want to redeploy with one command.

1. Install Node.js LTS from https://nodejs.org (if not already installed).
2. Open PowerShell in this folder and run:
   ```powershell
   npm install -g netlify-cli
   netlify login
   netlify deploy --prod --dir=.
   ```
3. The CLI prints your live URL. To redeploy later, just rerun the last
   command.

---

## Method C — Git-based continuous deploy (recommended long-term)

Best if you want the site to auto-update whenever you change a file. Every
`git push` triggers a redeploy.

1. **Install Git** from https://git-scm.com/download/win (if not already).
2. **Create a GitHub account** at https://github.com (free).
3. **Create a new empty repository** on GitHub (e.g. `hlp-website`). Do
   not initialize with a README.
4. In PowerShell, from this folder:
   ```powershell
   git init
   git add .
   git commit -m "Initial site"
   git branch -M main
   git remote add origin https://github.com/<your-username>/hlp-website.git
   git push -u origin main
   ```
5. In Netlify: **Add new site → Import an existing project → GitHub →**
   pick your repo.
6. Build settings — leave everything blank/default:
   - Build command: *(blank)*
   - Publish directory: *(blank, or `.`)*
7. Click **Deploy**.

From now on, any `git push` to `main` triggers a new deploy automatically.

---

## After your first deploy — wire Supabase to the live URL

Email confirmation and password-reset links from Supabase need to know
your live URL, otherwise they'll point to `http://localhost:3000` and
break.

1. Open your Supabase project → **Authentication → URL Configuration**.
2. **Site URL:** set to your Netlify URL, e.g.
   `https://random-words-12345.netlify.app`
3. **Redirect URLs:** add the same URL (and `http://localhost:8000` if
   you'll still test locally). One per line.
4. Save.

Now signups and auth flows on the live site work correctly.

---

## (Optional) Use your own domain

If you have a custom domain (e.g. `humanisticleadership.org`):

1. In Netlify: **Site settings → Domain management → Add custom domain**.
2. Netlify shows you the DNS records to set at your domain registrar
   (GoDaddy, Namecheap, Google Domains, etc.). Add them.
3. DNS propagation takes 5 minutes to a few hours. Netlify auto-issues
   a free HTTPS certificate once DNS resolves.
4. **Don't forget** to update the Supabase Site URL + Redirect URLs to
   the new domain (same as the step above).

---

## What gets deployed (and what doesn't)

These files are needed for the live site:

| File / folder | Needed? |
|---|---|
| `index.html` | Yes |
| `supabase-config.js` | **Yes** — the anon key is safe to ship publicly; RLS controls it |
| `The Humanistic Leadership Project — …_website_files/` | Yes (asset folder, even though currently mostly empty) |
| `supabase-schema.sql` | No — already run in your Supabase project |
| `SETUP.md`, `RESUME.md`, `DEPLOY-NETLIFY.md` | No (harmless if uploaded; they're just notes) |
| `serve.ps1` | No (local-only dev server) |

If you want a clean deploy, you can either:
- Just upload everything (Netlify will serve files but ignore `.md` and
  `.ps1` — harmless), **or**
- Add a `.gitignore` / Netlify ignore list to exclude them.

---

## Troubleshooting

- **"Page not found" on Netlify** → make sure `index.html` is at the
  *root* of what you uploaded, not inside a nested folder.
- **Auth works locally but not on the live site** → you forgot to update
  Supabase's Site URL + Redirect URLs (above).
- **Posts/comments don't load** → open DevTools Console on the live site;
  most likely `supabase-config.js` is missing from the deploy.
- **Mixed-content warning** → all your CDN scripts already use `https://`,
  so this shouldn't happen. If it does, check `index.html` for any
  `http://` URLs.

---

## Costs

Netlify free tier: 100 GB bandwidth/month, unlimited sites. Way more than
you'll need for a blog this size.

Supabase free tier: 500 MB Postgres + 1 GB Storage + 50,000 monthly auth
users. Also way more than enough to start.

You can launch and grow on free tiers indefinitely. The first paid step
is only needed if traffic explodes.
