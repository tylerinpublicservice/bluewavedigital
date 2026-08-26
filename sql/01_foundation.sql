-- ============================================================
-- BlueWave Digital  —  01_FOUNDATION.sql
-- RUN THIS FIRST in Supabase → SQL Editor → New query → paste → Run.
-- Sets up: extensions, the role system, the profiles table,
-- security helper functions, and the auto-profile trigger.
-- Safe to re-run.
-- ============================================================

-- --- Extensions -------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "citext";      -- case-insensitive emails

-- --- Role type --------------------------------------------------
do $$ begin
  create type public.user_role as enum ('admin','staff','client');
exception when duplicate_object then null; end $$;

-- --- updated_at helper (used by every table) -------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

-- --- Profiles: one row per logged-in user ----------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  role        public.user_role not null default 'client',
  full_name   text,
  avatar_url  text,          -- an ImgBB / Drive URL
  client_id   uuid,          -- FK to clients() added in 03_business.sql
  phone       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- --- Security helper functions ---------------------------------
-- SECURITY DEFINER = these run with elevated rights so they can read
-- profiles without triggering the table's own RLS (prevents recursion).

create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and role = 'admin');
$$;

create or replace function public.is_staff()
returns boolean language sql security definer stable set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and role in ('admin','staff'));
$$;

create or replace function public.current_client_id()
returns uuid language sql security definer stable set search_path = public as $$
  select client_id from public.profiles where id = auth.uid();
$$;

-- --- Auto-create a profile whenever someone signs up ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- --- Row Level Security on profiles ----------------------------
alter table public.profiles enable row level security;

drop policy if exists "read own or staff" on public.profiles;
create policy "read own or staff" on public.profiles
  for select using (id = auth.uid() or public.is_staff());

drop policy if exists "update own profile" on public.profiles;
create policy "update own profile" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "staff manage profiles" on public.profiles;
create policy "staff manage profiles" on public.profiles
  for all using (public.is_staff()) with check (public.is_staff());

-- IMPORTANT: stop users from promoting themselves.
-- Role & client assignment happen via the SQL editor or an Edge Function
-- (which use the service key and bypass this).
revoke update (role, client_id) on public.profiles from authenticated, anon;

-- ============================================================
-- Done. Next: run 02_content.sql
-- ============================================================
