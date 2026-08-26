# BlueWave - Client Accounts & Custom Email Setup

This sets up: (1) inviting client accounts from your dashboard, and (2) sending invite/
confirmation emails from your own domain instead of the generic Supabase address.

Everything here is done in the browser (Supabase dashboard + your DNS provider). No CLI.

---

## PART 1 - Custom email with Resend (your own domain)

**Why:** emails from `bluewaveagency.online` look professional and trustworthy and are far
less likely to hit spam than the shared Supabase sender.

1. Create a free account at resend.com.
2. Resend -> Domains -> Add Domain -> enter `bluewaveagency.online`.
3. Resend shows you a few DNS records (usually 3): an **SPF** (TXT), a **DKIM** (TXT or
   CNAME), and sometimes a return-path/MX record. Copy each one.
4. Go to wherever your domain's DNS is managed and **add those records exactly** as shown.
5. Back in Resend, click **Verify**. (DNS can take a few minutes to a couple of hours.)
6. Resend -> API Keys -> create a key. Copy it (starts with `re_...`).

Once verified, you can send as `hello@bluewaveagency.online`.

---

## PART 2 - Point Supabase Auth emails at your domain (optional but recommended)

So even Supabase's own confirmation/recovery emails come from you:

1. Supabase -> Project Settings -> Authentication -> SMTP Settings -> **Enable Custom SMTP**.
2. Use Resend's SMTP details:
   - Host: `smtp.resend.com`
   - Port: `465` (or 587)
   - Username: `resend`
   - Password: your Resend API key (`re_...`)
   - Sender email: `hello@bluewaveagency.online`
   - Sender name: `BlueWave Digital`
3. Save. Now all auth emails come from your domain.

(Our invite function also sends its own branded email via Resend, so you get a BlueWave-
styled invite regardless.)

---

## PART 3 - Deploy the invite-client Edge Function (no CLI)

The function lives in `supabase/functions/invite-client/index.ts` in this project.

1. Supabase -> **Edge Functions** -> **Create a function** (or "Deploy a new function").
   - If your dashboard has an in-browser editor: name it exactly `invite-client`, then
     paste the entire contents of `supabase/functions/invite-client/index.ts` and Deploy.
   - If it only offers CLI: use the browser-based option in the Functions tab labelled
     "Via Editor" / "New function" - recent Supabase supports creating functions in the
     dashboard. Paste the code there.
2. After deploy, add the function's **secrets**: Edge Functions -> (your function) ->
   Settings/Secrets (or Project Settings -> Edge Functions -> Secrets). Add:

   | Name | Value |
   |------|-------|
   | `SERVICE_ROLE_KEY` | Supabase -> Settings -> API -> **service_role** secret key |
   | `SUPABASE_ANON_KEY` | Supabase -> Settings -> API -> anon public key |
   | `RESEND_API_KEY` | your `re_...` key from Resend |
   | `FROM_EMAIL` | `BlueWave Digital <hello@bluewaveagency.online>` |
   | `SITE_URL` | `https://bluewaveagency.online` |

   (`SUPABASE_URL` is provided automatically - no need to add it.)

3. Supabase -> Authentication -> URL Configuration: add
   `https://bluewaveagency.online/set-password/` to the **Redirect URLs** allowlist.

---

## PART 4 - Use it

1. Log in to `/admin/` as an admin.
2. Go to **Clients** -> fill name + email -> **Create & send invite**.
3. The client gets a branded email, clicks it, lands on `/set-password/`, sets a password,
   and is taken into their portal. Their account shows "Active login" in your Clients table.

To add **staff/admins**: create their user in Supabase -> Authentication, then run:
```sql
update public.profiles set role='staff'   -- or 'admin'
where id = (select id from auth.users where email='THEIR_EMAIL');
```

---

## TROUBLESHOOTING - "the dashboard isn't working"

Most dashboard issues are one of these:

- **Blank sections but no error** = that table has no rows yet. Add data (invite a client,
  create a project) and it appears. Empty is not broken.
- **"Invite failed"** = the `invite-client` function isn't deployed yet, or its secrets are
  missing. Do Part 3.
- **Can't see any data as admin** = your profile role isn't `admin`. Run the promote SQL
  from the main README, then log out and back in.
- **Login works but bounces you** = role mismatch (a client hitting an admin page is sent to
  the portal on purpose, and vice-versa).
- **Nothing loads at all / console errors** = open the browser console (F12) and read the
  first red error. RLS or a missing table is the usual cause; re-run the SQL files in order.

If a specific page misbehaves, note (a) which page, (b) blank vs error vs button-does-nothing,
and (c) any red console text - that pinpoints it fast.
