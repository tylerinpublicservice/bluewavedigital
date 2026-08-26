-- ============================================================
-- BlueWave Digital  —  04_STORAGE.sql
-- Private buckets for the few files we DO keep in Supabase
-- (small contracts/proposals). Big files go to Google Drive;
-- public images go to ImgBB. Invoices are generated on the fly.
-- Run AFTER 03_business.sql. Safe to re-run.
-- ============================================================

-- --- Create private buckets -----------------------------------
insert into storage.buckets (id, name, public)
values
  ('client-files', 'client-files', false),
  ('documents',    'documents',    false)
on conflict (id) do nothing;

-- --- Storage RLS policies -------------------------------------
-- Files are organised in folders named after the client id, e.g.
--   client-files/<client_id>/brandkit.zip
-- A client can only touch objects inside their own folder; staff see all.

-- client-files bucket
drop policy if exists "cf staff all" on storage.objects;
create policy "cf staff all" on storage.objects
  for all to authenticated
  using ( bucket_id = 'client-files' and public.is_staff() )
  with check ( bucket_id = 'client-files' and public.is_staff() );

drop policy if exists "cf client own folder" on storage.objects;
create policy "cf client own folder" on storage.objects
  for all to authenticated
  using (
    bucket_id = 'client-files'
    and (storage.foldername(name))[1] = public.current_client_id()::text
  )
  with check (
    bucket_id = 'client-files'
    and (storage.foldername(name))[1] = public.current_client_id()::text
  );

-- documents bucket (proposals, contracts) — staff manage, client reads own folder
drop policy if exists "doc staff all" on storage.objects;
create policy "doc staff all" on storage.objects
  for all to authenticated
  using ( bucket_id = 'documents' and public.is_staff() )
  with check ( bucket_id = 'documents' and public.is_staff() );

drop policy if exists "doc client read own" on storage.objects;
create policy "doc client read own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = public.current_client_id()::text
  );

-- ============================================================
-- Done. Next: run 05_seed.sql (optional starter content)
-- ============================================================
