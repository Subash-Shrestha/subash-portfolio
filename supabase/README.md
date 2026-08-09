# Connecting the admin panel to Supabase

The site's admin login and content editing (the "Admin" button, bottom-right)
run on [Supabase](https://supabase.com) — a hosted Postgres database with a
real authentication service. Nothing about it works until you complete the
steps below; until then, clicking "Admin" just tells you it isn't connected
yet.

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

Open `index.html` in this repo, find this block near the bottom of the
`<script>` section, and paste them in:

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

This is your real login for the site's "Admin" button (Step 1: email +
password).

## 5. Turn on the second verification step

Step 2 of login sends a one-time code and requires you to enter it before the
admin panel unlocks — this is the "double authentication" part.

- **Email (default, works immediately):** Supabase sends OTP emails out of
  the box on the free tier. No setup needed — this is already active.
- **Phone/SMS (optional, costs money):** requires connecting a paid SMS
  provider. In your project: **Authentication → Providers → Phone**, enable
  it, and follow Supabase's instructions to connect Twilio (or another
  supported provider) with your own account and billing. Once that's done,
  change one line in `index.html`:

  ```js
  const OTP_CHANNEL = 'phone'; // was 'email'
  ```

  and use your phone number instead of email when signing in.

## 6. Try it

On the live site, click **Admin** (bottom-right) → sign in with your email
and password → enter the code from your inbox → the panel opens. Edit any
field and hit **Save changes** — it writes to Supabase and every visitor sees
the update immediately, no redeploy needed.

## What's editable right now

The panel currently covers the hero eyebrow/overview text, the four stat
numbers, the three About paragraphs, and the contact panel headline/subtext —
tagged in the HTML with `data-cms="..."` attributes. To make another section
editable later, add a matching `data-cms="your_key"` attribute to that
element and a matching entry to the `CMS_FIELDS` object in `index.html`.
