-- Bible Study Library: run this entire file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  study_date date not null,
  title_zh text default '',
  title_en text default '',
  public_summary_zh text not null default '',
  public_summary_en text not null default '',
  private_notes text not null default '',
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  private_notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.private_reflections (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid references public.students(id) on delete cascade,
  session_id uuid references public.study_sessions(id) on delete cascade,
  reflection text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.share_settings (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  token_hash text not null,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.study_sessions enable row level security;
alter table public.students enable row level security;
alter table public.private_reflections enable row level security;
alter table public.share_settings enable row level security;

-- Only the authenticated owner/admin can access private tables.
drop policy if exists "admin owns study sessions" on public.study_sessions;
create policy "admin owns study sessions" on public.study_sessions for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "admin owns students" on public.students;
create policy "admin owns students" on public.students for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "admin owns reflections" on public.private_reflections;
create policy "admin owns reflections" on public.private_reflections for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "admin owns share settings" on public.share_settings;
create policy "admin owns share settings" on public.share_settings for all to authenticated
using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Visitors call this function with the unguessable link token. It returns ONLY published public fields.
create or replace function public.public_get_studies(p_token text)
returns table (
  id uuid,
  study_date date,
  title_zh text,
  title_en text,
  public_summary_zh text,
  public_summary_en text
)
language sql
security definer
set search_path = public, extensions
as $$
  select s.id, s.study_date, s.title_zh, s.title_en, s.public_summary_zh, s.public_summary_en
  from public.study_sessions s
  where s.is_published = true
    and exists (
      select 1 from public.share_settings sh
      where sh.owner_id = s.owner_id
        and sh.active = true
        and sh.token_hash = encode(digest(coalesce(p_token, ''), 'sha256'), 'hex')
    )
  order by s.study_date desc;
$$;

-- Authenticated administrator creates/replaces the share token hash.
create or replace function public.admin_set_share_token(p_token_hash text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_token_hash !~ '^[a-f0-9]{64}$' then raise exception 'Invalid token hash'; end if;
  insert into public.share_settings(owner_id, token_hash, active, updated_at)
  values (auth.uid(), p_token_hash, true, now())
  on conflict (owner_id) do update
    set token_hash = excluded.token_hash, active = true, updated_at = now();
end;
$$;

revoke all on function public.public_get_studies(text) from public;
grant execute on function public.public_get_studies(text) to anon, authenticated;
revoke all on function public.admin_set_share_token(text) from public;
grant execute on function public.admin_set_share_token(text) to authenticated;

-- Do not add anon SELECT policies to private tables. Never expose service-role keys in the browser.
