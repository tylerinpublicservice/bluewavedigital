-- ============================================================
-- BlueWave Digital  —  02_CONTENT.sql
-- The "everything editable" layer: all marketing-site content.
-- Every image is a URL (ImgBB / Drive) — no files stored here.
-- Run AFTER 01_foundation.sql. Safe to re-run.
-- ============================================================

-- --- Global site settings (key/value) -------------------------
create table if not exists public.site_settings (
  key         text primary key,           -- e.g. 'contact_email'
  value       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- --- Services --------------------------------------------------
create table if not exists public.service_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  icon        text,
  description text,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.services (
  id           uuid primary key default gen_random_uuid(),
  category_id  uuid references public.service_categories(id) on delete set null,
  title        text not null,
  slug         text unique not null,
  summary      text,
  body         text,
  icon         text,
  sort_order   int not null default 0,
  published    boolean not null default false,
  updated_at   timestamptz not null default now(),
  created_at   timestamptz not null default now()
);

-- --- Pricing packages & comparison rows -----------------------
create table if not exists public.packages (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,              -- Launch / Essential / Business / Premium
  slug        text unique not null,
  price_from  numeric(12,2),
  currency    text not null default 'SCR',
  blurb       text,
  highlight   boolean not null default false,  -- "most popular"
  sort_order  int not null default 0,
  published   boolean not null default false,
  updated_at  timestamptz not null default now()
);

create table if not exists public.package_features (
  id          uuid primary key default gen_random_uuid(),
  package_id  uuid references public.packages(id) on delete cascade,
  label       text not null,             -- e.g. "Pages", "SEO", "CMS"
  value       text,                      -- "5", "Yes", "Basic"
  included    boolean not null default true,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

-- --- Care plans ------------------------------------------------
create table if not exists public.care_plans (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,             -- Care / Care Plus / Business Care
  slug        text unique not null,
  price_from  numeric(12,2),
  currency    text not null default 'SCR',
  interval    text not null default 'month',
  blurb       text,
  sort_order  int not null default 0,
  published   boolean not null default false,
  updated_at  timestamptz not null default now()
);

create table if not exists public.care_plan_features (
  id            uuid primary key default gen_random_uuid(),
  care_plan_id  uuid references public.care_plans(id) on delete cascade,
  label         text not null,
  included      boolean not null default true,
  sort_order    int not null default 0,
  updated_at    timestamptz not null default now()
);

-- --- Process & value props ------------------------------------
create table if not exists public.process_steps (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  icon        text,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.value_props (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  icon        text,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

-- --- Portfolio / case studies ---------------------------------
create table if not exists public.portfolio_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.portfolio_projects (
  id             uuid primary key default gen_random_uuid(),
  category_id    uuid references public.portfolio_categories(id) on delete set null,
  title          text not null,
  slug           text unique not null,
  client_name    text,
  industry       text,
  project_year   int,
  service        text,
  cover_image_url text,
  summary        text,
  challenge      text,
  solution       text,
  design_notes   text,
  dev_notes      text,
  results        text,
  live_url       text,
  featured       boolean not null default false,
  published      boolean not null default false,
  sort_order     int not null default 0,
  updated_at     timestamptz not null default now(),
  created_at     timestamptz not null default now()
);

create table if not exists public.portfolio_gallery (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references public.portfolio_projects(id) on delete cascade,
  image_url   text not null,
  caption     text,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

-- --- Testimonials ---------------------------------------------
create table if not exists public.testimonials (
  id          uuid primary key default gen_random_uuid(),
  author      text not null,
  role        text,
  company     text,
  quote       text not null,
  avatar_url  text,
  project_id  uuid references public.portfolio_projects(id) on delete set null,
  rating      int,
  published   boolean not null default false,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

-- --- FAQs ------------------------------------------------------
create table if not exists public.faq_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.faqs (
  id          uuid primary key default gen_random_uuid(),
  category_id uuid references public.faq_categories(id) on delete set null,
  question    text not null,
  answer      text not null,
  sort_order  int not null default 0,
  published   boolean not null default true,
  updated_at  timestamptz not null default now()
);

-- --- Insights / blog ------------------------------------------
create table if not exists public.insight_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  sort_order  int not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.insights (
  id              uuid primary key default gen_random_uuid(),
  category_id     uuid references public.insight_categories(id) on delete set null,
  author_id       uuid references public.profiles(id) on delete set null,
  title           text not null,
  slug            text unique not null,
  excerpt         text,
  body            text,
  cover_image_url text,
  seo_title       text,
  seo_description text,
  published       boolean not null default false,
  published_at    timestamptz,
  updated_at      timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

-- --- Team ------------------------------------------------------
create table if not exists public.team_members (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  role        text,
  bio         text,
  photo_url   text,
  socials     jsonb default '{}'::jsonb,
  sort_order  int not null default 0,
  published   boolean not null default false,
  updated_at  timestamptz not null default now()
);

-- --- Partners --------------------------------------------------
create table if not exists public.partners (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  logo_url    text,
  url         text,
  blurb       text,
  sort_order  int not null default 0,
  published   boolean not null default false,
  updated_at  timestamptz not null default now()
);

-- --- Free-form pages (About story, mission, legal, etc.) ------
create table if not exists public.pages (
  slug        text primary key,          -- 'privacy', 'terms', 'about-story'
  title       text,
  body        text,
  updated_at  timestamptz not null default now()
);

-- ============================================================
-- updated_at triggers for every content table (loop)
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array[
    'site_settings','service_categories','services','packages','package_features',
    'care_plans','care_plan_features','process_steps','value_props',
    'portfolio_categories','portfolio_projects','portfolio_gallery','testimonials',
    'faq_categories','faqs','insight_categories','insights','team_members',
    'partners','pages'
  ] loop
    execute format('drop trigger if exists trg_%1$s_updated on public.%1$I;', t);
    execute format('create trigger trg_%1$s_updated before update on public.%1$I
                    for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- ============================================================
-- Row Level Security
-- ============================================================

-- Group A: tables with a `published` flag → public sees published, staff see all
do $$
declare t text;
begin
  foreach t in array array[
    'services','packages','care_plans','portfolio_projects',
    'testimonials','team_members','partners'
  ] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "public read %1$s" on public.%1$I;', t);
    execute format('create policy "public read %1$s" on public.%1$I
                    for select using (published = true or public.is_staff());', t);
    execute format('drop policy if exists "staff manage %1$s" on public.%1$I;', t);
    execute format('create policy "staff manage %1$s" on public.%1$I
                    for all using (public.is_staff()) with check (public.is_staff());', t);
  end loop;
end $$;

-- insights uses published too (kept separate for clarity)
alter table public.insights enable row level security;
drop policy if exists "public read insights" on public.insights;
create policy "public read insights" on public.insights
  for select using (published = true or public.is_staff());
drop policy if exists "staff manage insights" on public.insights;
create policy "staff manage insights" on public.insights
  for all using (public.is_staff()) with check (public.is_staff());

-- faqs (default published = true)
alter table public.faqs enable row level security;
drop policy if exists "public read faqs" on public.faqs;
create policy "public read faqs" on public.faqs
  for select using (published = true or public.is_staff());
drop policy if exists "staff manage faqs" on public.faqs;
create policy "staff manage faqs" on public.faqs
  for all using (public.is_staff()) with check (public.is_staff());

-- Group B: always-public reference/child tables → anyone can read, staff manage
do $$
declare t text;
begin
  foreach t in array array[
    'site_settings','service_categories','package_features','care_plan_features',
    'process_steps','value_props','portfolio_categories','portfolio_gallery',
    'faq_categories','insight_categories','pages'
  ] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "public read %1$s" on public.%1$I;', t);
    execute format('create policy "public read %1$s" on public.%1$I
                    for select using (true);', t);
    execute format('drop policy if exists "staff manage %1$s" on public.%1$I;', t);
    execute format('create policy "staff manage %1$s" on public.%1$I
                    for all using (public.is_staff()) with check (public.is_staff());', t);
  end loop;
end $$;

-- ============================================================
-- Done. Next: run 03_business.sql
-- ============================================================
