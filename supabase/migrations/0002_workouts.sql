-- 0002_workouts.sql
-- Ejercicios, sesiones de entrenamiento y series, con RLS.

-- Ruling (ledger Task 7): el plan pedía sembrar el catálogo con el "user_id del
-- usuario principal", pero ese uuid no se conoce al aplicar la migración. Se usa
-- un propietario de sistema ('00000000-...') y una política SELECT extra para
-- que TODOS los usuarios autenticados compartan el catálogo común.
--
-- Ammendment (deploy): exercises.user_id NO lleva clave foránea a auth.users.
-- El seed del catálogo usa un propietario de sistema inexistente y la FK lo
-- rechazaba (SQLSTATE 23503). La integridad la impone la RLS
-- (with check (auth.uid() = user_id) en insert), no la FK.

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  name text not null,
  muscle_group text not null,
  is_custom boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  started_at timestamptz not null,
  ended_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create table public.workout_sets (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id),
  set_index int not null,
  reps int not null,
  weight numeric not null,
  rpe numeric check (rpe is null or (rpe >= 1 and rpe <= 10)),
  completed boolean not null default false
);

create index exercises_user_idx on public.exercises (user_id);
create index workout_sessions_user_idx on public.workout_sessions (user_id);
create index workout_sets_session_idx on public.workout_sets (session_id);
create index workout_sets_exercise_idx on public.workout_sets (exercise_id);

alter table public.exercises enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.workout_sets enable row level security;

-- exercises: cada usuario ve los suyos + el catálogo común de sistema.
create policy "exercises select own or catalog" on public.exercises
  for select using (auth.uid() = user_id or user_id = '00000000-0000-0000-0000-000000000000');
create policy "exercises insert own" on public.exercises
  for insert with check (auth.uid() = user_id);
create policy "exercises update own" on public.exercises
  for update using (auth.uid() = user_id);
create policy "exercises delete own" on public.exercises
  for delete using (auth.uid() = user_id);

-- workout_sessions: pertenencia directa.
create policy "sessions select own" on public.workout_sessions
  for select using (auth.uid() = user_id);
create policy "sessions insert own" on public.workout_sessions
  for insert with check (auth.uid() = user_id);
create policy "sessions update own" on public.workout_sessions
  for update using (auth.uid() = user_id);
create policy "sessions delete own" on public.workout_sessions
  for delete using (auth.uid() = user_id);

-- workout_sets: pertenencia vía la sesión.
create policy "sets select of own session" on public.workout_sets
  for select using (exists (
    select 1 from public.workout_sessions s
    where s.id = workout_sets.session_id and s.user_id = auth.uid()));
create policy "sets insert of own session" on public.workout_sets
  for insert with check (exists (
    select 1 from public.workout_sessions s
    where s.id = workout_sets.session_id and s.user_id = auth.uid()));
create policy "sets update of own session" on public.workout_sets
  for update using (exists (
    select 1 from public.workout_sessions s
    where s.id = workout_sets.session_id and s.user_id = auth.uid()));
create policy "sets delete of own session" on public.workout_sets
  for delete using (exists (
    select 1 from public.workout_sessions s
    where s.id = workout_sets.session_id and s.user_id = auth.uid()));

-- Catálogo común (propietario de sistema).
insert into public.exercises (user_id, name, muscle_group, is_custom) values
  ('00000000-0000-0000-0000-000000000000', 'Sentadilla', 'Pierna', false),
  ('00000000-0000-0000-0000-000000000000', 'Peso muerto', 'Espalda', false),
  ('00000000-0000-0000-0000-000000000000', 'Press banca', 'Pecho', false),
  ('00000000-0000-0000-0000-000000000000', 'Press militar', 'Hombro', false),
  ('00000000-0000-0000-0000-000000000000', 'Dominadas', 'Espalda', false),
  ('00000000-0000-0000-0000-000000000000', 'Remo con barra', 'Espalda', false),
  ('00000000-0000-0000-0000-000000000000', 'Curl de bíceps', 'Brazo', false),
  ('00000000-0000-0000-0000-000000000000', 'Fondos', 'Pecho', false),
  ('00000000-0000-0000-0000-000000000000', 'Zancadas', 'Pierna', false),
  ('00000000-0000-0000-0000-000000000000', 'Hip thrust', 'Glúteo', false);