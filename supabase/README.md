# Connecting the admin dashboard to Supabase

The site's admin login (`login.html`) and content editing (`dashboard.html`)
run on [Supabase](https://supabase.com) — a hosted Postgres database with a
real authentication service. Nothing about it works until you complete the
steps below; until then, the "Admin" button just tells you it isn't
connected yet.

This only works on the live site (GitHub Pages). It will not work inside a
Claude Artifact preview link — that environment blocks all outside network
calls by design, which includes calls to Supabase.

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up (free tier is enough).
2. Create a new project. Pick any name/region; save the database password
   Supabase generates — you likely won't need it again, but keep it somewhere
   safe just in case.

## 2. Get your API keys

In your project: **Settings → API**. Copy:
- **Project URL**
- **anon public** key

Paste both into **three** files in this repo — `index.html`, `login.html`,
and `dashboard.html` — each has this same block near the bottom of the
`<script>` section:

```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

The anon key is **meant** to be public — Supabase is designed so this key can
ship in client-side code safely. The actual security comes from the Row Level
Security policies in `schema.sql` (below), not from hiding this key.

## 3. Create the content table

In your project: **SQL Editor → New query**. Paste the contents of
`supabase/schema.sql` and run it. This creates a single-row `site_content`
table that anyone can read but only a signed-in user can update.

## 4. Create your admin login

**Authentication → Users → Add user → Create new user.**

- Use whichever email you want to sign in with (this doesn't have to be
  `contact.subashwork@gmail.com` — a separate address is fine).
- Set a real password here directly in the Supabase dashboard. **Do not**
  reuse `Payme@199702` or any password you've typed into a chat, a doc, or
  anywhere else that isn't a password manager — treat anything typed outside
  a password manager as potentially exposed.
- Tick "Auto Confirm User" so it's ready to use immediately.
- There is no signup form anywhere on the site by design — this is a
  single-admin project, so the only way to create an account is here, in
  the dashboard.

This is your real login on `login.html` (Step 1: email + password).

## 5. Turn on the second verification step

Step 2 of login sends a one-time code and requires you to enter it before
`dashboard.html` unlocks — this is the "double authentication" part.

- **Email (default, works immediately):** Supabase sends OTP emails out of
  the box on the free tier. No setup needed — this is already active.
- **Phone/SMS (optional, costs money):** requires connecting a paid SMS
  provider. In your project: **Authentication → Providers → Phone**, enable
  it, and follow Supabase's instructions to connect Twilio (or another
  supported provider) with your own account and billing. Once that's done,
  change one line in `login.html`:

  ```js
  const OTP_CHANNEL = 'phone'; // was 'email'
  ```

  and use your phone number instead of email when signing in.

## 6. Try it

On the live site, click **Admin** (bottom-right of the home page) → it opens
`login.html` → sign in with your email and password → enter the code from
your inbox → you land on `dashboard.html`. Edit any field and hit **Save
changes** — it writes to Supabase and every visitor sees the update
immediately, no redeploy needed.

## Page map

- `index.html` — the public site. Reads published content from Supabase
  (read-only, no login required) and links to `login.html` via the Admin
  button.
- `login.html` — two-step sign-in (password, then one-time code). Redirects
  to `dashboard.html` on success, or straight there if already signed in.
- `dashboard.html` — the editing screen. Redirects back to `login.html` if
  there's no valid session. Has its own **Sign out** button and a **View
  live site** link back to `index.html`.

## What's editable right now

The dashboard covers the whole site: Hero & Stats, About, Campaigns, Skills,
Experience, the Journey/Hook Duel copy, Blog, Articles, Off the Pitch, Why
Hire Me, FAQ, Contact & Social links, and SEO (page title/meta description).
Everything saves to one `site_content.content` jsonb blob — simple fields use
`data-cms="key"` attributes in `index.html`; repeating sections (Campaigns,
Skills, etc.) are JSON arrays rendered by matching `render*()` functions in
`index.html`, with add/remove/reorder support in `dashboard.html`'s list
editor.

A few known limits, by design:
- **No image upload.** The 6 photos on the site stay as their current image
  unless a list item's "Image URL" field is filled in with a link to an
  externally-hosted image — there's no upload/storage wired up.
- **Social-preview cards don't update from the dashboard.** Facebook,
  LinkedIn, Twitter/X, and Slack read the page's static HTML for their
  preview cards and never run JavaScript, so SEO title/description edits
  only affect Google's own indexed listing over time, not those previews.
- **Inline text styling is dropped when a field is edited.** A few defaults
  (About paragraphs, one Experience bullet) have highlighted words in the
  original copy; editing those fields via the dashboard replaces them with
  plain text, since the dashboard only ever writes safe plain text — never
  raw HTML — to avoid a stored-XSS risk on a public site.
