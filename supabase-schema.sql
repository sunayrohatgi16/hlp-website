-- ═══════════════════════════════════════════════════════════════════
-- HUMANISTIC LEADERSHIP PROJECT — BLOG DATABASE SCHEMA (Supabase)
-- ═══════════════════════════════════════════════════════════════════
-- Run this entire file ONCE in your Supabase project:
--   Supabase Dashboard → SQL Editor → New Query → paste → Run
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. PROFILES ────────────────────────────────────────────────────
-- One row per user. Linked to Supabase auth.users by id.
-- Auto-created on signup via the trigger below.
create table if not exists public.profiles (
  id          uuid        primary key references auth.users on delete cascade,
  email       text        not null,
  display_name text       not null default '',
  occupation  text        default '',
  linkedin    text        default '',
  bio         text        default '',
  created_at  timestamptz not null default now()
);

-- ── 2. POSTS ───────────────────────────────────────────────────────
create table if not exists public.posts (
  id          bigserial   primary key,
  author_id   uuid        not null references public.profiles(id) on delete cascade,
  title       text        not null,
  content     text        not null,        -- HTML from rich-text editor
  excerpt     text        default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists posts_author_idx  on public.posts(author_id);
create index if not exists posts_created_idx on public.posts(created_at desc);

-- ── 3. COMMENTS ────────────────────────────────────────────────────
create table if not exists public.comments (
  id          bigserial   primary key,
  post_id     bigint      not null references public.posts(id) on delete cascade,
  author_id   uuid        not null references public.profiles(id) on delete cascade,
  content     text        not null,
  created_at  timestamptz not null default now()
);
create index if not exists comments_post_idx on public.comments(post_id);

-- ── 4. LIKES ───────────────────────────────────────────────────────
create table if not exists public.likes (
  post_id     bigint      not null references public.posts(id) on delete cascade,
  user_id     uuid        not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index if not exists likes_post_idx on public.likes(post_id);

-- ── 5. AUTO-CREATE PROFILE ON SIGNUP ───────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, occupation, linkedin, bio)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'occupation', ''),
    coalesce(new.raw_user_meta_data->>'linkedin', ''),
    coalesce(new.raw_user_meta_data->>'bio', '')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ── 6. ROW-LEVEL SECURITY ─────────────────────────────────────────
alter table public.profiles enable row level security;
alter table public.posts    enable row level security;
alter table public.comments enable row level security;
alter table public.likes    enable row level security;

-- Profiles: everyone can read, only owner can update
drop policy if exists "profiles_select_all"     on public.profiles;
drop policy if exists "profiles_update_own"     on public.profiles;
create policy "profiles_select_all" on public.profiles for select using (true);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

-- Posts: everyone can read; authenticated users can insert their own;
--        only the author can edit/delete.
drop policy if exists "posts_select_all"     on public.posts;
drop policy if exists "posts_insert_authed"  on public.posts;
drop policy if exists "posts_update_own"     on public.posts;
drop policy if exists "posts_delete_own"     on public.posts;
create policy "posts_select_all"    on public.posts for select using (true);
create policy "posts_insert_authed" on public.posts for insert with check (auth.uid() = author_id);
create policy "posts_update_own"    on public.posts for update using (auth.uid() = author_id);
create policy "posts_delete_own"    on public.posts for delete using (auth.uid() = author_id);

-- Comments: same pattern
drop policy if exists "comments_select_all"     on public.comments;
drop policy if exists "comments_insert_authed"  on public.comments;
drop policy if exists "comments_delete_own"     on public.comments;
create policy "comments_select_all"    on public.comments for select using (true);
create policy "comments_insert_authed" on public.comments for insert with check (auth.uid() = author_id);
create policy "comments_delete_own"    on public.comments for delete using (auth.uid() = author_id);

-- Likes: everyone can read; each user can only like as themselves; can unlike own
drop policy if exists "likes_select_all"    on public.likes;
drop policy if exists "likes_insert_self"   on public.likes;
drop policy if exists "likes_delete_self"   on public.likes;
create policy "likes_select_all"  on public.likes for select using (true);
create policy "likes_insert_self" on public.likes for insert with check (auth.uid() = user_id);
create policy "likes_delete_self" on public.likes for delete using (auth.uid() = user_id);

-- ── 7. STORAGE BUCKET FOR POST IMAGES ─────────────────────────────
-- Public-read bucket; only authenticated users can upload.
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

-- Anyone can read images (bucket is public, but RLS also applies)
drop policy if exists "post_images_read"   on storage.objects;
drop policy if exists "post_images_insert" on storage.objects;
drop policy if exists "post_images_delete" on storage.objects;

create policy "post_images_read"
  on storage.objects for select
  using (bucket_id = 'post-images');

-- Authenticated users can upload; the path must start with their user id (folder isolation)
create policy "post_images_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'post-images'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own images
create policy "post_images_delete"
  on storage.objects for delete
  using (
    bucket_id = 'post-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── 8. STORIES (Student Voices) ───────────────────────────────────
-- Submissions to the "Share Your Story" form on the Student Voices page.
-- Logged-in users submit; admin manually flips `approved` to true via the
-- Supabase Table Editor; only approved rows are visible to the public.
create table if not exists public.stories (
  id           bigserial   primary key,
  author_id    uuid        not null references public.profiles(id) on delete cascade,
  display_name text        not null default 'Anonymous',
  school_grade text        default '',
  quality      text        default '',
  reflection   text        not null,
  approved     boolean     not null default false,
  created_at   timestamptz not null default now()
);
create index if not exists stories_approved_created_idx
  on public.stories(approved, created_at desc);

alter table public.stories enable row level security;

-- Drop and recreate so this is idempotent
drop policy if exists "stories_select_approved" on public.stories;
drop policy if exists "stories_select_own"      on public.stories;
drop policy if exists "stories_insert_authed"   on public.stories;
drop policy if exists "stories_delete_own"      on public.stories;

-- Anyone can see approved stories
create policy "stories_select_approved"
  on public.stories for select
  using (approved = true);

-- A signed-in user can always see their own submissions (even pending)
create policy "stories_select_own"
  on public.stories for select
  using (auth.uid() = author_id);

-- Signed-in users can submit, but only as themselves and always pending
create policy "stories_insert_authed"
  on public.stories for insert
  with check (auth.uid() = author_id and approved = false);

-- Authors can withdraw their own submissions
create policy "stories_delete_own"
  on public.stories for delete
  using (auth.uid() = author_id);

-- NOTE: there is no UPDATE policy. Approval is done by you in the
-- Supabase Table Editor (which uses service_role and bypasses RLS).

-- ── 9. CONTACT MESSAGES (Partner page form) ──────────────────────
-- Submissions to the "Get in Touch" form on the Partner page.
-- Open insert (anyone can send a message — no signup required) but no
-- public SELECT policy — only the dashboard / service_role can read.
create table if not exists public.contact_messages (
  id           bigserial   primary key,
  first_name   text        not null,
  last_name    text        default '',
  email        text        not null,
  organization text        default '',
  role         text        default '',
  interest     text        default '',
  message      text        not null,
  created_at   timestamptz not null default now()
);
create index if not exists contact_messages_created_idx
  on public.contact_messages(created_at desc);

alter table public.contact_messages enable row level security;

drop policy if exists "contact_messages_insert_anyone" on public.contact_messages;
create policy "contact_messages_insert_anyone"
  on public.contact_messages for insert
  with check (true);

-- NO select / update / delete policies — only the Supabase dashboard
-- (using service_role) can read these. That keeps user emails private.

-- ═══════════════════════════════════════════════════════════════════
-- Done. Tables, security policies, signup trigger, and storage ready.
-- ═══════════════════════════════════════════════════════════════════
