-- =====================================================================
-- Registro Alimentación Bebé — esquema para Supabase
-- Pegá todo este archivo en Supabase → SQL Editor → New query → Run.
-- Se puede ejecutar más de una vez sin romper nada.
-- =====================================================================

-- ---------- Tablas ----------

-- Un "grupo familiar": las personas que comparten el registro de un bebé.
create table if not exists public.households (
  id           uuid primary key default gen_random_uuid(),
  name         text not null default 'Mi bebé' check (char_length(name) between 1 and 60),
  invite_code  text not null unique,
  interval_min integer not null default 180 check (interval_min between 15 and 1440),
  default_ml   numeric not null default 60 check (default_ml between 0 and 1000),
  created_by   uuid references auth.users(id) on delete set null default auth.uid(),
  created_at   timestamptz not null default now()
);

create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade default auth.uid(),
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id)
);
create index if not exists household_members_user_idx on public.household_members(user_id);

-- Cada toma. El id lo genera la app (permite crear tomas sin conexión).
-- start_at / end_at: milisegundos desde 1970 (Date.now() en JS).
create table if not exists public.feeds (
  id           text primary key check (char_length(id) between 1 and 64),
  household_id uuid not null references public.households(id) on delete cascade,
  start_at     bigint not null,
  end_at       bigint,
  active       boolean not null default false,
  type         text not null check (type in ('relactador','mamadera','jeringa')),
  ml           numeric not null default 0 check (ml between 0 and 1000),
  note         text not null default '' check (char_length(note) <= 200),
  created_by   uuid references auth.users(id) on delete set null default auth.uid(),
  updated_at   timestamptz not null default now(),
  check (end_at is null or end_at >= start_at)
);
create index if not exists feeds_household_start_idx on public.feeds(household_id, start_at desc);

create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at := now(); return new; end $$;
drop trigger if exists feeds_touch on public.feeds;
create trigger feeds_touch before update on public.feeds
  for each row execute function public.touch_updated_at();

-- ---------- Funciones auxiliares ----------

-- ¿El usuario actual pertenece al grupo? (security definer evita recursión en RLS)
create or replace function public.is_member(hid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.household_members
                 where household_id = hid and user_id = auth.uid());
$$;

-- Código de invitación legible: 8 caracteres sin letras confusas (0/O, 1/I/L).
create or replace function public.new_invite_code() returns text
language plpgsql volatile set search_path = public as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text;
begin
  loop
    code := '';
    for i in 1..8 loop
      code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.households where invite_code = code);
  end loop;
  return code;
end $$;

-- Crear un grupo y quedar como miembro.
create or replace function public.create_household(p_name text)
returns public.households
language plpgsql security definer set search_path = public as $$
declare h public.households;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  insert into public.households (name, invite_code, created_by)
  values (coalesce(nullif(trim(p_name), ''), 'Mi bebé'), public.new_invite_code(), auth.uid())
  returning * into h;
  insert into public.household_members (household_id, user_id) values (h.id, auth.uid());
  return h;
end $$;

-- Unirse a un grupo con su código.
create or replace function public.join_household(p_code text)
returns public.households
language plpgsql security definer set search_path = public as $$
declare h public.households;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select * into h from public.households
   where invite_code = upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  if h.id is null then raise exception 'invalid_code'; end if;
  insert into public.household_members (household_id, user_id)
  values (h.id, auth.uid()) on conflict do nothing;
  return h;
end $$;

-- Generar un código nuevo (invalida el anterior).
create or replace function public.regenerate_invite_code(p_household uuid)
returns text
language plpgsql security definer set search_path = public as $$
declare c text;
begin
  if not public.is_member(p_household) then raise exception 'not_member'; end if;
  c := public.new_invite_code();
  update public.households set invite_code = c where id = p_household;
  return c;
end $$;

-- Salir de un grupo. Si queda vacío, se borra con todas sus tomas.
create or replace function public.leave_household(p_household uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.household_members
   where household_id = p_household and user_id = auth.uid();
  if not exists (select 1 from public.household_members where household_id = p_household) then
    delete from public.households where id = p_household;
  end if;
end $$;

revoke all on function public.new_invite_code() from public, anon, authenticated;
revoke all on function public.create_household(text) from public, anon;
revoke all on function public.join_household(text) from public, anon;
revoke all on function public.regenerate_invite_code(uuid) from public, anon;
revoke all on function public.leave_household(uuid) from public, anon;
grant execute on function public.create_household(text) to authenticated;
grant execute on function public.join_household(text) to authenticated;
grant execute on function public.regenerate_invite_code(uuid) to authenticated;
grant execute on function public.leave_household(uuid) to authenticated;
grant execute on function public.is_member(uuid) to authenticated;

-- ---------- Seguridad por filas (RLS) ----------
alter table public.households        enable row level security;
alter table public.household_members enable row level security;
alter table public.feeds             enable row level security;

drop policy if exists "households: miembros leen"      on public.households;
drop policy if exists "households: miembros editan"    on public.households;
create policy "households: miembros leen"   on public.households for select to authenticated using (public.is_member(id));
create policy "households: miembros editan" on public.households for update to authenticated
  using (public.is_member(id)) with check (public.is_member(id));

drop policy if exists "members: miembros ven el grupo" on public.household_members;
create policy "members: miembros ven el grupo" on public.household_members for select to authenticated
  using (public.is_member(household_id));

drop policy if exists "feeds: miembros leen"    on public.feeds;
drop policy if exists "feeds: miembros crean"   on public.feeds;
drop policy if exists "feeds: miembros editan"  on public.feeds;
drop policy if exists "feeds: miembros borran"  on public.feeds;
create policy "feeds: miembros leen"   on public.feeds for select to authenticated using (public.is_member(household_id));
create policy "feeds: miembros crean"  on public.feeds for insert to authenticated with check (public.is_member(household_id));
create policy "feeds: miembros editan" on public.feeds for update to authenticated
  using (public.is_member(household_id)) with check (public.is_member(household_id));
create policy "feeds: miembros borran" on public.feeds for delete to authenticated using (public.is_member(household_id));

-- Sólo se puede cambiar nombre e intervalos del grupo, no el código ni el creador.
revoke update on public.households from authenticated;
grant  update (name, interval_min, default_ml) on public.households to authenticated;
grant select on public.households, public.household_members to authenticated;
grant select, insert, update, delete on public.feeds to authenticated;

-- ---------- Tiempo real ----------
alter table public.feeds replica identity full;
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin alter publication supabase_realtime add table public.feeds;      exception when duplicate_object then null; end;
    begin alter publication supabase_realtime add table public.households; exception when duplicate_object then null; end;
  end if;
end $$;
