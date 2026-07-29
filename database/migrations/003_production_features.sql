-- Production feature layer for Flinder.

alter table public.users
add column if not exists role text not null default 'user'
check (role in ('user', 'admin'));

alter table public.profiles
add column if not exists onboarding_step text not null default 'basic'
check (onboarding_step in ('basic', 'photos', 'preferences', 'complete')),
add column if not exists completion_score integer not null default 0 check (completion_score between 0 and 100),
add column if not exists latitude double precision,
add column if not exists longitude double precision,
add column if not exists city text,
add column if not exists country text;

alter table public.flats
add column if not exists latitude double precision,
add column if not exists longitude double precision,
add column if not exists owner_id uuid references public.users(id) on delete set null,
add column if not exists status text not null default 'active'
check (status in ('active', 'inactive', 'reported', 'removed'));

alter table public.messages
add column if not exists read_at timestamptz;

create table if not exists public.user_blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.users(id) on delete cascade,
  blocked_id uuid not null references public.users(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index if not exists user_blocks_blocker_idx on public.user_blocks(blocker_id);
create index if not exists user_blocks_blocked_idx on public.user_blocks(blocked_id);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  reported_user_id uuid not null references public.users(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  admin_notes text,
  resolved_by uuid references public.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (reporter_id <> reported_user_id)
);

create index if not exists user_reports_status_idx on public.user_reports(status, created_at desc);
create index if not exists user_reports_reported_user_idx on public.user_reports(reported_user_id);

create table if not exists public.flat_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  flat_id uuid not null references public.flats(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  admin_notes text,
  resolved_by uuid references public.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists flat_reports_status_idx on public.flat_reports(status, created_at desc);
create index if not exists flat_reports_flat_idx on public.flat_reports(flat_id);

create table if not exists public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references public.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists admin_audit_logs_admin_created_idx on public.admin_audit_logs(admin_id, created_at desc);

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  device_info_id uuid references public.device_info(id) on delete set null,
  provider text not null default 'fcm',
  status text not null default 'pending' check (status in ('pending', 'sent', 'failed', 'skipped')),
  provider_message_id text,
  error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create index if not exists notification_deliveries_notification_idx on public.notification_deliveries(notification_id);

create table if not exists public.boosts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists boosts_active_idx on public.boosts(user_id, expires_at desc) where is_active;

create table if not exists public.swipe_rewinds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  swipe_id uuid references public.swipes(id) on delete set null,
  target_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists swipe_rewinds_user_created_idx on public.swipe_rewinds(user_id, created_at desc);

create table if not exists public.geocode_cache (
  id uuid primary key default gen_random_uuid(),
  query text not null unique,
  provider text not null default 'nominatim',
  result jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists profiles_city_idx on public.profiles(city);
create index if not exists profiles_coordinates_idx on public.profiles(latitude, longitude);
create index if not exists flats_coordinates_idx on public.flats(latitude, longitude);
