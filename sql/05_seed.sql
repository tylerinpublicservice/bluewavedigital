-- ============================================================
-- BlueWave Digital  —  05_SEED.sql
-- Optional starter content so pages aren't blank while you build.
-- You'll edit all of this later from the staff dashboard.
-- Run AFTER 04_storage.sql. Safe to re-run (uses upserts where it can).
-- ============================================================

-- --- Site settings --------------------------------------------
insert into public.site_settings (key, value) values
  ('contact_email',  '"hello@bluewaveagency.online"'::jsonb),
  ('contact_phone',  '""'::jsonb),
  ('whatsapp',       '""'::jsonb),
  ('location',       '"Seychelles"'::jsonb),
  ('socials',        '{"instagram":"","facebook":"","linkedin":""}'::jsonb),
  ('business_hours', '"By appointment — flexible hours"'::jsonb),
  ('tagline',        '"Modern websites for businesses in Seychelles and beyond."'::jsonb)
on conflict (key) do nothing;

-- --- Service categories ---------------------------------------
insert into public.service_categories (name, slug, sort_order) values
  ('Website Design & Development', 'web-design', 1),
  ('E-Commerce', 'ecommerce', 2),
  ('Website Redesign', 'redesign', 3),
  ('Website Maintenance', 'maintenance', 4),
  ('SEO & Performance', 'seo', 5),
  ('Digital Business Setup', 'digital-setup', 6),
  ('AI & Automation', 'automation', 7)
on conflict (slug) do nothing;

-- --- Packages -------------------------------------------------
insert into public.packages (name, slug, price_from, currency, blurb, sort_order, published) values
  ('BlueWave Launch',   'launch',   3500,  'SCR', 'A clean, professional starter website.', 1, true),
  ('BlueWave Essential','essential',6500,  'SCR', 'A complete small-business website.',     2, true),
  ('BlueWave Business', 'business', 10500, 'SCR', 'A larger site with more features.',      3, true),
  ('BlueWave Premium',  'premium',  18000, 'SCR', 'A custom, high-end build.',              4, true)
on conflict (slug) do nothing;

-- --- Care plans -----------------------------------------------
insert into public.care_plans (name, slug, price_from, currency, interval, blurb, sort_order, published) values
  ('Care',          'care',          500,  'SCR', 'month', 'Essential monitoring, backups & updates.', 1, true),
  ('Care Plus',     'care-plus',     900,  'SCR', 'month', 'Everything in Care, plus content edits.',  2, true),
  ('Business Care', 'business-care', 1500, 'SCR', 'month', 'Priority support & performance checks.',   3, true)
on conflict (slug) do nothing;

-- --- Process steps --------------------------------------------
insert into public.process_steps (title, description, sort_order) values
  ('Discovery',   'Understand the client and requirements.', 1),
  ('Proposal',    'Scope, pricing and timeline.',            2),
  ('Design',      'Structure and visual direction.',         3),
  ('Development', 'Website production.',                      4),
  ('Review',      'Client revisions and testing.',           5),
  ('Launch',      'Deployment and domain setup.',            6),
  ('Support',     'Maintenance and optimisation.',           7)
on conflict do nothing;

-- --- Why BlueWave (value props) -------------------------------
insert into public.value_props (title, description, sort_order) values
  ('Modern design',      'Clean, current, professional.',        1),
  ('Fast development',    'Built quickly without cutting corners.',2),
  ('Mobile-first',        'Looks great on every device.',         3),
  ('Transparent pricing', 'Clear starting prices, no surprises.', 4),
  ('Personal support',    'You deal directly with the builder.',  5),
  ('Modern technology',   'Fast, secure, up-to-date stack.',      6)
on conflict do nothing;

-- --- Portfolio categories -------------------------------------
insert into public.portfolio_categories (name, slug, sort_order) values
  ('Business', 'business', 1),
  ('Nonprofit', 'nonprofit', 2),
  ('Tourism', 'tourism', 3),
  ('Corporate', 'corporate', 4),
  ('Personal', 'personal', 5),
  ('E-Commerce', 'ecommerce', 6),
  ('Events', 'events', 7)
on conflict (slug) do nothing;

-- --- A few starter FAQs ---------------------------------------
insert into public.faqs (question, answer, sort_order, published) values
  ('How much does a website cost?', 'Projects start around SCR 3,500. Final quotes depend on scope.', 1, true),
  ('How long does development take?', 'Most sites take a few weeks depending on size and content.', 2, true),
  ('Do I need to provide content?', 'Helpful, but we can guide you and help produce it.', 3, true),
  ('Do you work outside Seychelles?', 'Yes — we work with clients internationally.', 4, true)
on conflict do nothing;

-- ============================================================
-- AFTER you sign up in the app (or Auth → Users), make yourself admin.
-- Replace the email, then run just these two lines:
-- ============================================================
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'YOUR_EMAIL_HERE');

-- ============================================================
-- Backend seeding done. Your database is ready.
-- ============================================================
