-- Durable onboarding skip state for Google-only v1 onboarding.

alter table public.users
add column if not exists profile_questionnaire_skipped_at timestamptz;
