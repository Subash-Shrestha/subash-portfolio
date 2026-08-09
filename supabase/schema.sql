-- Run this once in your Supabase project's SQL Editor
-- (Project → SQL Editor → New query → paste → Run).

create table if not exists site_content (
  id int primary key,
  content jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);

insert into site_content (id, content)
values (1, '{}'::jsonb)
on conflict (id) do nothing;

alter table site_content enable row level security;

-- Anyone (including anonymous visitors) can read the published content.
create policy "Public can read site content"
  on site_content for select
  using (true);

-- Only a signed-in (authenticated) user can update it — this is what
-- the admin panel relies on. There's no INSERT/DELETE policy on purpose:
-- the single row already exists, the panel only ever updates it.
create policy "Authenticated users can update site content"
  on site_content for update
  using (auth.role() = 'authenticated');
