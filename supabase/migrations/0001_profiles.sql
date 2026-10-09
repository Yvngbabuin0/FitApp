-- 0001_profiles.sql
-- Perfil del usuario. La fila se auto-crea al registrar un nuevo usuario.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  daily_calorie_target int not null default 2000,
  protein_target_g numeric not null default 150,
  carbs_target_g numeric not null default 200,
  fat_target_g numeric not null default 70,
  units text not null default 'kg' check (units in ('kg','lb')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "own profile select" on public.profiles
  for select using (auth.uid() = id);
create policy "own profile update" on public.profiles
  for update using (auth.uid() = id);

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data->>'display_name');
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();