-- Add Google OAuth identity columns for existing Neon databases.

alter table public.users
  add column if not exists google_sub text,
  add column if not exists auth_provider text not null default 'password';

create unique index if not exists users_google_sub_unique_idx
on public.users(google_sub)
where google_sub is not null;

alter table public.users
  drop constraint if exists users_auth_provider_check;

alter table public.users
  add constraint users_auth_provider_check
  check (auth_provider in ('password', 'google'));
