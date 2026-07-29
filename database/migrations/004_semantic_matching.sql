-- Semantic matching metadata for stored profile embeddings.

alter table public.user_embeds
add column if not exists model_name text,
add column if not exists source_hash text,
add column if not exists llm_traits jsonb not null default '{}'::jsonb,
add column if not exists canonical_text jsonb not null default '{}'::jsonb,
add column if not exists status text not null default 'missing'
check (status in ('missing', 'stale', 'ready', 'failed')),
add column if not exists error text,
add column if not exists last_embedded_at timestamptz;

create index if not exists user_embeds_status_idx on public.user_embeds(status, updated_at desc);
create index if not exists user_embeds_source_hash_idx on public.user_embeds(source_hash);
