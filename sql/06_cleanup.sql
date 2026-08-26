-- ============================================================
-- BlueWave Digital  —  06_cleanup.sql
-- Fixes duplicate rows (from running the seed twice) and adds
-- longer descriptions for the "What we do" cards.
-- Run once in Supabase SQL Editor. Safe.
-- ============================================================

-- 1) Remove duplicate value_props (keep the earliest of each title)
delete from public.value_props a
using public.value_props b
where a.ctid < b.ctid
  and a.title = b.title;

-- 2) Remove duplicate process_steps (keep earliest of each title)
delete from public.process_steps a
using public.process_steps b
where a.ctid < b.ctid
  and a.title = b.title;

-- 3) Remove duplicate service_categories (keep earliest of each slug)
delete from public.service_categories a
using public.service_categories b
where a.ctid < b.ctid
  and a.slug = b.slug;

-- 4) Longer descriptions for the What We Do cards
update public.service_categories set description =
  'Custom-built business, corporate and portfolio websites designed to make a strong first impression and turn visitors into enquiries.'
  where slug = 'web-design';
update public.service_categories set description =
  'Complete online stores with product catalogues, secure checkout and an experience built to help you sell to customers anywhere in the world.'
  where slug = 'ecommerce';
update public.service_categories set description =
  'Give an outdated website a modern, mobile-first redesign that improves how it looks, how it performs and how easily people can use it.'
  where slug = 'redesign';
update public.service_categories set description =
  'Ongoing updates, backups, monitoring and technical support that keep your website secure, current and running smoothly year-round.'
  where slug = 'maintenance';
update public.service_categories set description =
  'Technical and on-page SEO plus performance tuning so your business ranks higher on Google and loads fast for every visitor.'
  where slug = 'seo';
update public.service_categories set description =
  'Everything you need to get set up online: domain, professional email, hosting, analytics and a polished Google Business presence.'
  where slug = 'digital-setup';
update public.service_categories set description =
  'Smart automations and AI-assisted tools that handle repetitive work, streamline enquiries and free up your time to run the business.'
  where slug = 'automation';

-- Done.
