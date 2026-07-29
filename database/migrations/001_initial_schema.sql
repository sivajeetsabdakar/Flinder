-- Flinder initial Neon/Postgres schema.
-- Apply this against your Neon database, for example:
-- psql "$DATABASE_URL" -f database/migrations/001_initial_schema.sql

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  user_id bigint generated always as identity unique,
  google_sub text unique,
  auth_provider text not null default 'password' check (auth_provider in ('password', 'google')),
  email text not null unique,
  password text not null,
  name text not null,
  phone text,
  date_of_birth date,
  gender text not null check (gender in ('male', 'female', 'non_binary', 'prefer_not_to_say')),
  profile_completed boolean not null default false,
  verification_status jsonb not null default '{"email": false, "phone": false}'::jsonb,
  notification_settings jsonb not null default '{"newMatches": true, "messages": true, "appUpdates": true, "pushNotifications": true}'::jsonb,
  online_status text not null default 'offline' check (online_status in ('online', 'away', 'offline')),
  last_active timestamptz,
  last_online timestamptz,
  account_status text not null default 'active' check (account_status in ('active', 'inactive', 'suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

create table if not exists public.device_info (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  device_id text not null,
  push_token text,
  platform text not null check (platform in ('ios', 'android', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_id)
);

drop trigger if exists set_device_info_updated_at on public.device_info;
create trigger set_device_info_updated_at
before update on public.device_info
for each row execute function public.set_updated_at();

create table if not exists public.profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  bio text not null,
  generated_description jsonb,
  interests text[] not null default '{}',
  location jsonb not null,
  budget jsonb not null,
  room_preference text not null check (room_preference in ('private', 'shared', 'studio', 'any')),
  gender_preference text not null check (gender_preference in ('same_gender', 'any_gender')),
  move_in_date text not null,
  lease_duration text not null check (lease_duration in ('short_term', 'long_term', 'flexible')),
  lifestyle jsonb not null,
  languages text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table if not exists public.profile_pictures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  url text not null,
  is_primary boolean not null default false,
  uploaded_at timestamptz not null default now()
);

create unique index if not exists profile_pictures_one_primary_per_user
on public.profile_pictures(user_id)
where is_primary;

create table if not exists public.preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  critical jsonb not null,
  non_critical jsonb not null default '{}'::jsonb,
  discovery_settings jsonb not null default '{"ageRange": {"min": 18, "max": 99}, "distance": 50, "showMeToOthers": true}'::jsonb,
  interests jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_preferences_updated_at on public.preferences;
create trigger set_preferences_updated_at
before update on public.preferences
for each row execute function public.set_updated_at();

create index if not exists preferences_city_idx
on public.preferences ((critical #>> '{location,city}'));

create table if not exists public.swipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  target_user_id uuid not null references public.users(id) on delete cascade,
  action text not null check (action in ('like', 'pass')),
  swiper_id uuid generated always as (user_id) stored,
  direction text generated always as (
    case action
      when 'like' then 'left'
      else 'right'
    end
  ) stored,
  created_at timestamptz not null default now(),
  unique (user_id, target_user_id)
);

create index if not exists swipes_target_user_id_idx on public.swipes(target_user_id);
create index if not exists swipes_user_action_idx on public.swipes(user_id, action);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_id_1 uuid not null references public.users(id) on delete cascade,
  user_id_2 uuid not null references public.users(id) on delete cascade,
  matched_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'inactive', 'blocked')),
  compatibility jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint matches_no_self_match check (user_id_1 <> user_id_2)
);

create unique index if not exists matches_unique_pair_idx
on public.matches (
  least(user_id_1, user_id_2),
  greatest(user_id_1, user_id_2)
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid references public.matches(id) on delete set null,
  participants jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_message_at timestamptz,
  status text not null default 'active' check (status in ('active', 'archived', 'deleted'))
);

drop trigger if exists set_conversations_updated_at on public.conversations;
create trigger set_conversations_updated_at
before update on public.conversations
for each row execute function public.set_updated_at();

create index if not exists conversations_participants_gin_idx
on public.conversations using gin (participants jsonb_path_ops);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  name text,
  is_group boolean not null default false,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_chats_updated_at on public.chats;
create trigger set_chats_updated_at
before update on public.chats
for each row execute function public.set_updated_at();

create table if not exists public.chat_members (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (chat_id, user_id)
);

create index if not exists chat_members_user_id_idx on public.chat_members(user_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  chat_id uuid references public.chats(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text not null check (length(content) <= 5000),
  attachment text,
  attachment_type text,
  sent_at timestamptz not null default now(),
  is_read boolean not null default false,
  is_deleted boolean not null default false,
  constraint messages_has_parent check (conversation_id is not null or chat_id is not null)
);

create index if not exists messages_conversation_sent_at_idx on public.messages(conversation_id, sent_at desc);
create index if not exists messages_chat_sent_at_idx on public.messages(chat_id, sent_at desc);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null check (type in ('match', 'message', 'system', 'verification')),
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  expire_at timestamptz
);

create index if not exists notifications_user_created_at_idx on public.notifications(user_id, created_at desc);

create table if not exists public.flats (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  address text not null,
  city text not null,
  rent integer not null check (rent >= 0),
  num_rooms integer not null check (num_rooms > 0),
  amenities text[] not null default '{}',
  description text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_flats_updated_at on public.flats;
create trigger set_flats_updated_at
before update on public.flats
for each row execute function public.set_updated_at();

create index if not exists flats_city_idx on public.flats(city);
create index if not exists flats_rent_idx on public.flats(rent);
create unique index if not exists flats_unique_listing_idx
on public.flats(title, address, city);

create table if not exists public.flat_applications (
  id uuid primary key default gen_random_uuid(),
  flat_id uuid not null references public.flats(id) on delete cascade,
  group_chat_id uuid not null references public.chats(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  unique (flat_id, user_id)
);

create table if not exists public.user_embeds (
  user_id uuid primary key references public.users(id) on delete cascade,
  embedding_hobbies double precision[],
  embedding_interests double precision[],
  embedding_traits double precision[],
  embedding_personality double precision[],
  embedding_likes double precision[],
  embedding_dislikes double precision[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_user_embeds_updated_at on public.user_embeds;
create trigger set_user_embeds_updated_at
before update on public.user_embeds
for each row execute function public.set_updated_at();

insert into public.flats (title, address, city, rent, num_rooms, amenities, description, image_url)
values
  (
    'Modern 2BHK in City Center',
    '123 Main Street, Sector 15',
    'Gandhinagar',
    12000,
    2,
    array['WiFi', 'AC', 'Fully Furnished', 'Security'],
    'A modern flat in the city center with nearby amenities.',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1350&q=80'
  ),
  (
    'Spacious 3BHK Family Apartment',
    '45 Park Avenue, Sector 8',
    'Gandhinagar',
    18000,
    3,
    array['WiFi', 'AC', 'Parking', 'Swimming Pool', 'Gym'],
    'A spacious apartment with convenient community amenities.',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1350&q=80'
  ),
  (
    'Cozy 1BHK Studio Apartment',
    '78 College Road, Navrangpura',
    'Ahmedabad',
    8000,
    1,
    array['WiFi', 'AC', 'Balcony'],
    'A compact apartment suited for students or young professionals.',
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1350&q=80'
  )
on conflict (title, address, city) do nothing;

-- Access control note:
-- The Flutter app talks to the Python API only. Keep the Neon database private
-- and expose user-scoped behavior through authenticated API routes.
