# Resume Notes — where we left off

## What's working

- `index.html` loads, the layout and existing content are unchanged.
- Blog + Sign In nav links work. Auth modal opens, register/sign-in form is wired to Supabase.
- Supabase project at `https://xxagiypldvcizhocrfnb.supabase.co` is reachable; the `posts` table responds to anon queries.
- Local test server: run `.\serve.ps1` then open **http://localhost:8000/**.
- DB schema (`supabase-schema.sql`) has been run (the table exists).

## The blocker

You published a post but the blog list says **"No posts yet"**. Most likely cause: your `profiles` row was never created on signup (the trigger only fires for accounts created *after* `supabase-schema.sql` was run). The post list query inner-joins on `profiles`, so a post whose author has no profile row gets filtered out.

It's also possible the post insert itself was rejected — `posts.author_id` foreign-keys to `profiles.id`, so no profile = insert fails silently.

## First thing to do when you resume

**Run this once in Supabase → SQL Editor → New query** to backfill any missing profile rows for accounts that signed up before the trigger existed:

```sql
insert into public.profiles (id, email, display_name)
select u.id, u.email, split_part(u.email, '@', 1)
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;
```

Then in the browser:
1. Hard refresh `http://localhost:8000/` (Ctrl+Shift+R)
2. Sign in again
3. Go to **Blog** → **Write a Post** → publish
4. The post should now appear in the list

## If that doesn't fix it

- Open DevTools (F12) → Console → look for any red errors and the `[blog] loadPosts result:` log line. Share that with me.
- Also paste me the output of these in the Console (after signing in):
  ```js
  (await sb.from('posts').select('id,title,author_id')).data
  (await sb.from('profiles').select('id,display_name')).data
  ```
- If the second one is empty even after the backfill SQL, something is wrong with the schema. Re-run `supabase-schema.sql`.

## Files in this folder

| File | Purpose |
|---|---|
| `index.html` | The site (renamed from the original long filename) |
| `supabase-config.js` | Your project URL + anon key (already filled in) |
| `supabase-schema.sql` | Run once in Supabase SQL Editor |
| `SETUP.md` | Full setup walkthrough |
| `serve.ps1` | Local test server (no Python/Node needed) |
| `RESUME.md` | This file |
| `The Humanistic Leadership Project — Leadership Education…_website_files/` | Original asset folder (unchanged) |

## To restart the local server

If it's not running:
```powershell
.\serve.ps1
```
Open http://localhost:8000/ and **hard refresh** (Ctrl+Shift+R) so the browser doesn't serve a cached old copy.
