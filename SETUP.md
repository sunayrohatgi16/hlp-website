# Blog Setup — The Humanistic Leadership Project

Your site is now a dynamic blog. Authentication, posts, comments, likes,
author profiles, and image uploads all live in **Supabase** (free
Postgres + Auth + Storage). The HTML stays a static file you can host
anywhere (Netlify, Vercel, GitHub Pages, etc.).

You only need to do this setup once.

---

## 1. Create a Supabase project (~5 min, free)

1. Go to **https://supabase.com** → sign up.
2. Click **"New project"**.
   - Name: `humanistic-leadership` (or anything)
   - Choose a strong database password (save it somewhere)
   - Region: closest to your audience
3. Wait ~1 minute for it to provision.

## 2. Run the database schema

1. In your Supabase project, open **SQL Editor** (left sidebar).
2. Click **"New query"**.
3. Open `supabase-schema.sql` from this folder, copy **everything**,
   paste into the editor.
4. Click **Run**. You should see "Success. No rows returned."

This creates:
- `profiles`, `posts`, `comments`, `likes` tables
- A trigger that auto-creates a profile row when someone signs up
- Row-Level Security policies (so visitors can only edit their own stuff)
- A public **`post-images`** storage bucket for image uploads in posts

## 3. Plug your project into the website

1. In Supabase: **Settings → API**.
2. Copy two values:
   - **Project URL** (looks like `https://abcdwxyz.supabase.co`)
   - **`anon` `public` key** (long string starting with `eyJ…`)
3. Open `supabase-config.js` and paste them in:
   ```js
   window.SUPABASE_URL      = "https://abcdwxyz.supabase.co";
   window.SUPABASE_ANON_KEY = "eyJ...";
   ```

The `anon` key is **safe to commit** — Row-Level Security controls what
it can do.

## 4. (Optional) Turn off email confirmation while testing

By default Supabase requires users to click a confirmation link in their
email before they can sign in. To skip that during local testing:

**Authentication → Providers → Email** → turn **"Confirm email"** OFF.

Turn it back on before launch to prevent spam signups.

---

## 5. Test the site locally on your computer

You **cannot** just double-click `index.html` — browsers block JavaScript
fetch + Supabase auth on `file://` URLs. You need to serve the folder
through a tiny local web server. Pick one of these — any works:

### Option A — Python (already on most computers)

Open PowerShell, `cd` into this folder, then:

```powershell
python -m http.server 8000
```

Open **http://localhost:8000/** in your browser.

### Option B — Node.js

```powershell
npx serve .
```

Then open the URL it prints (usually `http://localhost:3000`).

### Option C — VS Code "Live Server" extension

Install the *Live Server* extension by Ritwick Dey, right-click
`index.html` → **"Open with Live Server"**.

### What you should see

- The site loads exactly like before — same hero, same nav, same content.
- Nav now has a **Blog** link and a **Sign In** button on the right.
- Click **Blog** → "No posts yet. Be the first to write one!"
- Click **Sign In** → switch to **Register** tab → fill in display name,
  email, password (≥ 6 chars), and optionally occupation / LinkedIn / bio.
  Hit **Create Account**.
- If you turned off email confirmation (step 4), you're signed in
  immediately. Otherwise, click the email link, come back, sign in.
- Click **Write a Post** → write a title, format with the toolbar (incl.
  the **image** icon — uploads to Supabase Storage), click **Publish**.
- Post appears in the list with your name + occupation. Click it to view,
  like, or comment. Click your name to see your author profile.

### Quick diagnostics (browser DevTools → Console)

| What you see | Meaning |
|---|---|
| `[blog] supabase-config.js is not configured` | You skipped step 3. |
| `Backend not configured yet` in the blog list | Same — fix `supabase-config.js`. |
| `Sign-up: User already registered` | Try Sign In tab instead. |
| `permission denied for table posts` | The schema didn't run cleanly. Re-run step 2. |
| `new row violates row-level security policy "post_images_insert"` | Storage policies missing — re-run step 2 (schema includes them). |

## 6. Deploy

The site is just static files. Drop the entire folder onto:

- **Netlify**: drag-and-drop on https://app.netlify.com/drop
- **Vercel**: `npm i -g vercel && vercel` in this folder
- **GitHub Pages**: push to a repo, enable Pages

Make sure these are deployed together:
- `index.html`
- `supabase-config.js`
- `SETUP.md` (optional, just docs)
- the existing `…_website_files/` folder (if you reference assets from it)

---

## What you can do later

- **Moderate / delete a post as admin**: Supabase → **Table Editor → posts** → delete the row.
- **Email subscribers when a new post is published**: Supabase Edge Functions + Resend.
- **Add an admin dashboard / approval queue**: small follow-up if you ever switch from auto-publish to moderation.
- **Custom domain**: Netlify/Vercel both support free custom domains.

## Troubleshooting

- **"Backend not configured"** → `supabase-config.js` still has the placeholder.
- **Sign-up succeeds but sign-in fails** → email confirmation is on. Confirm via email link or turn it off (step 4).
- **Images don't upload** → re-run `supabase-schema.sql`; it sets up the storage bucket + policies.
- **`file://` URL doesn't work** → use a local server (step 5).
