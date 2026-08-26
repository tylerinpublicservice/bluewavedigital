-- ============================================================
-- BlueWave Digital  —  03_BUSINESS.sql
-- CRM, projects, invoices, support, and growth features.
-- Clients see ONLY their own rows; staff see everything.
-- Run AFTER 02_content.sql. Safe to re-run.
-- ============================================================

-- --- Clients ---------------------------------------------------
create table if not exists public.clients (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,            -- company / client name
  email         citext,
  phone         text,
  country       text,
  website       text,
  notes         text,
  status        text not null default 'active',  -- active / archived
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- Now that clients exists, link profiles.client_id to it
do $$ begin
  alter table public.profiles
    add constraint profiles_client_fk
    foreign key (client_id) references public.clients(id) on delete set null;
exception when duplicate_object then null; end $$;

-- --- Projects (live client work, NOT portfolio) ---------------
create table if not exists public.projects (
  id            uuid primary key default gen_random_uuid(),
  client_id     uuid not null references public.clients(id) on delete cascade,
  name          text not null,
  description   text,
  status        text not null default 'planning', -- planning/design/dev/review/live/on_hold
  progress      int not null default 0,           -- 0-100
  start_date    date,
  target_date   date,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table if not exists public.project_milestones (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references public.projects(id) on delete cascade,
  title         text not null,
  description   text,
  status        text not null default 'pending',  -- pending/in_progress/done
  due_date      date,
  sort_order    int not null default 0,
  updated_at    timestamptz not null default now()
);

create table if not exists public.project_updates (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references public.projects(id) on delete cascade,
  author_id     uuid references public.profiles(id) on delete set null,
  body          text not null,
  created_at    timestamptz not null default now()
);

-- --- Approvals (client sign-off on sitemap/design/final) ------
create table if not exists public.approvals (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references public.projects(id) on delete cascade,
  title         text not null,           -- "Sitemap", "Homepage design"
  description   text,
  status        text not null default 'awaiting', -- awaiting/approved/changes_requested
  response_note text,
  responded_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- --- Files (metadata only — actual file lives on Drive/ImgBB) -
create table if not exists public.files (
  id               uuid primary key default gen_random_uuid(),
  client_id        uuid references public.clients(id) on delete cascade,
  project_id       uuid references public.projects(id) on delete cascade,
  uploaded_by      uuid references public.profiles(id) on delete set null,
  name             text not null,
  url              text not null,        -- the link
  storage_provider text not null default 'gdrive', -- gdrive/imgbb/supabase/link
  direction        text not null default 'deliverable', -- client_upload/deliverable
  size_note        text,
  created_at       timestamptz not null default now()
);

-- --- Invoices & payments --------------------------------------
create sequence if not exists public.invoice_seq;

create table if not exists public.invoices (
  id             uuid primary key default gen_random_uuid(),
  number         text unique,
  client_id      uuid not null references public.clients(id) on delete cascade,
  project_id     uuid references public.projects(id) on delete set null,
  status         text not null default 'draft', -- draft/sent/paid/overdue/void
  currency       text not null default 'SCR',
  subtotal       numeric(12,2) not null default 0,
  tax            numeric(12,2) not null default 0,
  total          numeric(12,2) not null default 0,
  notes          text,
  issue_date     date not null default current_date,
  due_date       date,
  paid_at        timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Auto invoice number like BW-2026-0007
create or replace function public.set_invoice_number()
returns trigger language plpgsql as $$
begin
  if new.number is null then
    new.number := 'BW-' || to_char(now(),'YYYY') || '-' ||
                  lpad(nextval('public.invoice_seq')::text, 4, '0');
  end if;
  return new;
end; $$;

drop trigger if exists trg_invoice_number on public.invoices;
create trigger trg_invoice_number
  before insert on public.invoices
  for each row execute function public.set_invoice_number();

create table if not exists public.invoice_line_items (
  id          uuid primary key default gen_random_uuid(),
  invoice_id  uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity    numeric(12,2) not null default 1,
  unit_price  numeric(12,2) not null default 0,
  amount      numeric(12,2) not null default 0,
  sort_order  int not null default 0
);

create table if not exists public.payments (
  id          uuid primary key default gen_random_uuid(),
  invoice_id  uuid not null references public.invoices(id) on delete cascade,
  client_id   uuid references public.clients(id) on delete set null,
  amount      numeric(12,2) not null,
  currency    text not null default 'SCR',
  method      text,                      -- paddle/lemonsqueezy/wise/bank/manual
  reference   text,
  status      text not null default 'completed',
  paid_at     timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

-- --- Support tickets ------------------------------------------
create table if not exists public.support_tickets (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid not null references public.clients(id) on delete cascade,
  project_id  uuid references public.projects(id) on delete set null,
  subject     text not null,
  category    text,                      -- issue/change/maintenance/emergency
  priority    text not null default 'normal',
  status      text not null default 'open', -- open/in_progress/resolved/closed
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.ticket_messages (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.support_tickets(id) on delete cascade,
  author_id   uuid references public.profiles(id) on delete set null,
  body        text not null,
  created_at  timestamptz not null default now()
);

-- --- Notifications --------------------------------------------
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  title       text not null,
  body        text,
  link        text,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);

-- --- Public form submissions ----------------------------------
create table if not exists public.quote_requests (
  id            uuid primary key default gen_random_uuid(),
  name          text,
  company       text,
  email         citext,
  phone         text,
  need          text,                    -- new website / redesign / ecommerce...
  business_info text,
  goals         text,
  has_website   boolean,
  website_url   text,
  features      jsonb default '[]'::jsonb,
  budget        text,
  timeline      text,
  status        text not null default 'new', -- new/reviewing/quoted/won/lost
  created_at    timestamptz not null default now()
);

create table if not exists public.contact_messages (
  id          uuid primary key default gen_random_uuid(),
  name        text,
  email       citext,
  phone       text,
  message     text,
  status      text not null default 'new',
  created_at  timestamptz not null default now()
);

-- --- Growth features ------------------------------------------
create table if not exists public.website_audits (
  id            uuid primary key default gen_random_uuid(),
  website_url   text not null,
  business_name text,
  email         citext,
  status        text not null default 'requested', -- requested/reviewed/sent
  results       jsonb,
  notes         text,
  created_at    timestamptz not null default now()
);

create table if not exists public.referrals (
  id              uuid primary key default gen_random_uuid(),
  referrer_client uuid references public.clients(id) on delete set null,
  referred_name   text,
  referred_email  citext,
  status          text not null default 'new', -- new/contacted/converted/rewarded
  reward_type     text,
  reward_amount   numeric(12,2),
  created_at      timestamptz not null default now()
);

create table if not exists public.newsletter_subscribers (
  id          uuid primary key default gen_random_uuid(),
  email       citext unique not null,
  source      text,
  created_at  timestamptz not null default now()
);

create table if not exists public.collaborators (
  id          uuid primary key default gen_random_uuid(),
  name        text,
  email       citext,
  role_type   text,                      -- designer/developer/writer...
  portfolio_url text,
  message     text,
  created_at  timestamptz not null default now()
);

-- --- Activity log ---------------------------------------------
create table if not exists public.activity_log (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid references public.profiles(id) on delete set null,
  action      text not null,
  entity      text,
  entity_id   uuid,
  meta        jsonb,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- updated_at triggers
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array[
    'clients','projects','project_milestones','approvals',
    'invoices','support_tickets'
  ] loop
    execute format('drop trigger if exists trg_%1$s_updated on public.%1$I;', t);
    execute format('create trigger trg_%1$s_updated before update on public.%1$I
                    for each row execute function public.set_updated_at();', t);
  end loop;
end $$;

-- ============================================================
-- Row Level Security
-- ============================================================

-- Enable RLS on everything in this file
do $$
declare t text;
begin
  foreach t in array array[
    'clients','projects','project_milestones','project_updates','approvals',
    'files','invoices','invoice_line_items','payments','support_tickets',
    'ticket_messages','notifications','quote_requests','contact_messages',
    'website_audits','referrals','newsletter_subscribers','collaborators',
    'activity_log'
  ] loop
    execute format('alter table public.%I enable row level security;', t);
  end loop;
end $$;

-- ---- Staff-full-access on every business table ----
do $$
declare t text;
begin
  foreach t in array array[
    'clients','projects','project_milestones','project_updates','approvals',
    'files','invoices','invoice_line_items','payments','support_tickets',
    'ticket_messages','notifications','quote_requests','contact_messages',
    'website_audits','referrals','newsletter_subscribers','collaborators',
    'activity_log'
  ] loop
    execute format('drop policy if exists "staff all %1$s" on public.%1$I;', t);
    execute format('create policy "staff all %1$s" on public.%1$I
                    for all using (public.is_staff()) with check (public.is_staff());', t);
  end loop;
end $$;

-- ---- Public can SUBMIT forms (insert only, no read back) ----
do $$
declare t text;
begin
  foreach t in array array[
    'quote_requests','contact_messages','website_audits',
    'newsletter_subscribers','collaborators'
  ] loop
    execute format('drop policy if exists "anon submit %1$s" on public.%1$I;', t);
    execute format('create policy "anon submit %1$s" on public.%1$I
                    for insert to anon, authenticated with check (true);', t);
  end loop;
end $$;

-- ---- Client can read their OWN data ----
drop policy if exists "client reads own client" on public.clients;
create policy "client reads own client" on public.clients
  for select using (id = public.current_client_id());

drop policy if exists "client reads own projects" on public.projects;
create policy "client reads own projects" on public.projects
  for select using (client_id = public.current_client_id());

drop policy if exists "client reads own milestones" on public.project_milestones;
create policy "client reads own milestones" on public.project_milestones
  for select using (project_id in (
    select id from public.projects where client_id = public.current_client_id()));

drop policy if exists "client reads own updates" on public.project_updates;
create policy "client reads own updates" on public.project_updates
  for select using (project_id in (
    select id from public.projects where client_id = public.current_client_id()));

-- Approvals: client can read AND respond (update) on their own
drop policy if exists "client reads own approvals" on public.approvals;
create policy "client reads own approvals" on public.approvals
  for select using (project_id in (
    select id from public.projects where client_id = public.current_client_id()));
drop policy if exists "client responds approvals" on public.approvals;
create policy "client responds approvals" on public.approvals
  for update using (project_id in (
    select id from public.projects where client_id = public.current_client_id()))
  with check (project_id in (
    select id from public.projects where client_id = public.current_client_id()));

-- Files: client reads own, and can upload (insert) to own client/project
drop policy if exists "client reads own files" on public.files;
create policy "client reads own files" on public.files
  for select using (client_id = public.current_client_id());
drop policy if exists "client uploads own files" on public.files;
create policy "client uploads own files" on public.files
  for insert to authenticated
  with check (client_id = public.current_client_id());

-- Invoices / line items / payments: client reads own (read-only)
drop policy if exists "client reads own invoices" on public.invoices;
create policy "client reads own invoices" on public.invoices
  for select using (client_id = public.current_client_id());

drop policy if exists "client reads own invoice items" on public.invoice_line_items;
create policy "client reads own invoice items" on public.invoice_line_items
  for select using (invoice_id in (
    select id from public.invoices where client_id = public.current_client_id()));

drop policy if exists "client reads own payments" on public.payments;
create policy "client reads own payments" on public.payments
  for select using (client_id = public.current_client_id());

-- Support tickets: client reads own + can create + reply
drop policy if exists "client reads own tickets" on public.support_tickets;
create policy "client reads own tickets" on public.support_tickets
  for select using (client_id = public.current_client_id());
drop policy if exists "client creates tickets" on public.support_tickets;
create policy "client creates tickets" on public.support_tickets
  for insert to authenticated
  with check (client_id = public.current_client_id());

drop policy if exists "client reads own ticket msgs" on public.ticket_messages;
create policy "client reads own ticket msgs" on public.ticket_messages
  for select using (ticket_id in (
    select id from public.support_tickets where client_id = public.current_client_id()));
drop policy if exists "client writes ticket msgs" on public.ticket_messages;
create policy "client writes ticket msgs" on public.ticket_messages
  for insert to authenticated
  with check (ticket_id in (
    select id from public.support_tickets where client_id = public.current_client_id()));

-- Referrals: referring client reads own + can submit
drop policy if exists "client reads own referrals" on public.referrals;
create policy "client reads own referrals" on public.referrals
  for select using (referrer_client = public.current_client_id());
drop policy if exists "client submits referrals" on public.referrals;
create policy "client submits referrals" on public.referrals
  for insert to authenticated
  with check (referrer_client = public.current_client_id());

-- Notifications: each user reads/updates their own
drop policy if exists "user reads own notifications" on public.notifications;
create policy "user reads own notifications" on public.notifications
  for select using (user_id = auth.uid());
drop policy if exists "user updates own notifications" on public.notifications;
create policy "user updates own notifications" on public.notifications
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================
-- Done. Next: run 04_storage.sql
-- ============================================================
