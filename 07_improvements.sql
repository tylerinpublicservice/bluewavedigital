-- ============================================================
-- BlueWave Digital  —  07_improvements.sql
-- Seeds the Legal pages so they're editable in the dashboard,
-- and adds small quality-of-life defaults.
-- Run once in Supabase SQL Editor. Safe to re-run.
-- ============================================================

-- Legal & about pages (edit these in Admin -> Content -> Legal & Pages)
insert into public.pages (slug, title, body) values
 ('privacy','Privacy Policy','<p>This is the BlueWave Digital privacy policy. Edit this from the dashboard.</p><p>We collect only the information you provide through our forms and use it to respond to your enquiry and deliver our services. We do not sell your data.</p>'),
 ('terms','Terms of Use','<p>These are the BlueWave Digital terms of use. Edit this from the dashboard.</p><p>By using this website you agree to use it lawfully and respectfully. All content and branding remain the property of BlueWave Digital.</p>'),
 ('about-story','Our Story','<p>BlueWave Digital was founded to give businesses in Seychelles and beyond access to modern, professional websites without the usual cost or complexity.</p>')
on conflict (slug) do nothing;

-- Make sure newsletter signups can be inserted by the public (used by future signup box)
-- (policy already exists from 03_business.sql; this is just a safety re-assert)
do $$ begin
  execute 'alter table public.newsletter_subscribers enable row level security';
exception when others then null; end $$;

-- Helpful: default invoice due date 14 days out if not set
alter table public.invoices alter column due_date set default (current_date + 14);

-- Done.
