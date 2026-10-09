-- 0003_food.sql
-- Comidas y alimentos, con RLS.

create table public.food_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  logged_at timestamptz not null,
  meal_type text not null check (meal_type in ('breakfast','lunch','dinner','snack')),
  total_calories int not null default 0,
  total_protein_g numeric not null default 0,
  total_carbs_g numeric not null default 0,
  total_fat_g numeric not null default 0,
  photo_path text,
  source text not null check (source in ('ai','manual')),
  created_at timestamptz not null default now()
);

create table public.food_entry_items (
  id uuid primary key default gen_random_uuid(),
  food_entry_id uuid not null references public.food_entries(id) on delete cascade,
  name text not null,
  quantity numeric not null default 0,
  unit text not null default 'g',
  calories int not null default 0,
  protein_g numeric not null default 0,
  carbs_g numeric not null default 0,
  fat_g numeric not null default 0,
  confidence numeric check (confidence is null or (confidence >= 0 and confidence <= 1)),
  estimated boolean not null default false
);

create index food_entries_user_idx on public.food_entries (user_id);
create index food_entry_items_entry_idx on public.food_entry_items (food_entry_id);

alter table public.food_entries enable row level security;
alter table public.food_entry_items enable row level security;

-- food_entries: pertenencia directa.
create policy "food_entries select own" on public.food_entries
  for select using (auth.uid() = user_id);
create policy "food_entries insert own" on public.food_entries
  for insert with check (auth.uid() = user_id);
create policy "food_entries update own" on public.food_entries
  for update using (auth.uid() = user_id);
create policy "food_entries delete own" on public.food_entries
  for delete using (auth.uid() = user_id);

-- food_entry_items: pertenencia vía la entrada.
create policy "food_items select of own entry" on public.food_entry_items
  for select using (exists (
    select 1 from public.food_entries e
    where e.id = food_entry_items.food_entry_id and e.user_id = auth.uid()));
create policy "food_items insert of own entry" on public.food_entry_items
  for insert with check (exists (
    select 1 from public.food_entries e
    where e.id = food_entry_items.food_entry_id and e.user_id = auth.uid()));
create policy "food_items update of own entry" on public.food_entry_items
  for update using (exists (
    select 1 from public.food_entries e
    where e.id = food_entry_items.food_entry_id and e.user_id = auth.uid()));
create policy "food_items delete of own entry" on public.food_entry_items
  for delete using (exists (
    select 1 from public.food_entries e
    where e.id = food_entry_items.food_entry_id and e.user_id = auth.uid()));