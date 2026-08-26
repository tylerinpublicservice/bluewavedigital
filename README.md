# BlueWave Digital — Website

The complete BlueWave Digital website: public marketing site, client portal, and staff
admin dashboard. Plain HTML/CSS/JS (no build step) with a Supabase backend. Designed to be
hosted on GitHub Pages with the custom domain `bluewaveagency.online`.

## What's inside

```
index.html              Home (banner hero, live sections, currency switchers)
404.html                Custom not-found page
CNAME                   Custom domain for GitHub Pages
.nojekyll               Tells GitHub Pages to serve files as-is

assets/
  style.css             The whole site's design system (edit styling here)
  app.js                Supabase connection + shared nav/footer/loader + auth helpers

Public pages (each is a folder so the URL is clean, e.g. /services/):
  services/ websites/ work/ pricing/ care/ process/ about/
  insights/ faq/ quote/ contact/ support/ privacy/ terms/ thank-you/

login/                  One login for everyone (routes by role)

portal/                 CLIENT area (login required, role = client)
  index/ projects/ invoices/ files/ approvals/ support/

admin/                  STAFF area (login required, role = admin/staff)
  index/ content/ leads/ clients/ projects/ invoices/ support/ growth/

sql/                    Database setup (run these in Supabase, in order)
  01_foundation.sql 02_content.sql 03_business.sql
  04_storage.sql 05_seed.sql 06_cleanup.sql
```

## First-time setup

### 1. Database (if not already done)
In Supabase → SQL Editor, run the files in `sql/` in order: 01 → 02 → 03 → 04 → 05 → 06.
(If you already ran 01–05, just run 06_cleanup.sql.)

### 2. Make yourself an admin
- In Supabase → Authentication → Users → Add user, create your own login (your email + a password).
- Then in SQL Editor run (with your email):
  ```sql
  update public.profiles set role='admin'
  where id = (select id from auth.users where email='YOUR_EMAIL');
  ```
- Now log in at `/login/` and you'll be sent to `/admin/`.

### 3. Add a client (so the portal works)
- Admin → Clients → add a client (gives you a client ID).
- In Supabase → Authentication, create that client's login.
- In SQL Editor, link their profile to the client and set role:
  ```sql
  update public.profiles set role='client', client_id='THE_CLIENT_ID'
  where id = (select id from auth.users where email='CLIENT_EMAIL');
  ```
- They can now log in at `/login/` and land in `/portal/`.
  (A one-click "invite client" button arrives when we add the Supabase Edge Function.)

## Deploy to GitHub Pages (browser only)

1. Upload the **contents** of this folder to your repo (drag the folder into GitHub's
   "Add file → Upload files", or edit via github.dev by pressing `.` on the repo).
2. Repo → Settings → Pages → set Source to your main branch, root.
3. Keep the `CNAME` file so the site serves at `bluewaveagency.online`
   (point the domain's DNS to GitHub Pages in your domain provider).
4. Because pages use clean URLs like `/services/`, the custom domain is recommended —
   links resolve cleanly. `404.html` handles unknown paths.

## Editing content (no code)

Log in as admin → **Content** tab. You can edit services, packages (prices), care plans,
Why BlueWave, process steps, FAQs, testimonials and portfolio — changes show on the public
site immediately. Everything visible on the marketing site is stored in Supabase, not
hardcoded.

## Images

All images are URLs (ImgBB for public images, Google Drive links for large client files).
To change the hero banner or portal image, edit the relevant `<img src>` (home) or the
`IMAGES`/URL references. The logo and banner are already set to your ImgBB URLs.

## Currency

Pricing and Care pages let visitors switch between SCR / USD / EUR / GBP. Rates are fixed
and editable in one place: `assets/app.js` → the `RATES` object.

## What's fully built vs. next

**Fully working now:** the entire public site, the multi-step quote form (saves to
`quote_requests`), contact/support forms, login with role routing, the client portal
(projects, invoices with .txt download, files, approvals, support tickets), and the staff
dashboard (leads, clients, projects, invoices with mark-paid, support, growth, and the
live Content editor).

**Coming with the Edge Functions step:** transactional email (Resend), one-click client
invites, PDF invoices, online payments (Paddle/Lemon Squeezy), and Cloudflare Turnstile
spam protection on the public forms. The database and UI are already prepared for these.
