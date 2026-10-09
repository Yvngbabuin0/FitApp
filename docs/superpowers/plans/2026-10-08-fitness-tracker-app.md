# Plan de implementación — App de fitness y control de calorías por foto

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir una app Flutter (Android + Web/PWA) con login, diario de comidas por foto con IA, registro de entrenamientos con métricas y resumen semanal, usando solo servicios gratuitos.

**Architecture:** App Flutter con Riverpod y go_router. El backend es Supabase (Auth email/contraseña + Postgres con RLS + Edge Function `analyze-meal`). La Edge Function llama a Cloudflare Workers AI (visión) y a Open Food Facts/USDA para los valores nutricionales. La app guarda caché local de solo lectura.

**Tech Stack:** Flutter/Dart, Riverpod, go_router, supabase_flutter, sembast, image_picker, image, intl, fl_chart, http; Supabase (Postgres + Edge Functions en Deno/TypeScript); Cloudflare Workers AI.

**Spec:** `docs/superpowers/specs/2026-10-08-fitness-tracker-app-design.md`

## Global Constraints

- Todo debe funcionar en **planes gratuitos**, sin tarjeta de crédito (Supabase free, Workers AI free, Open Food Facts/USDA).
- App compilable a **Android** y **Web** desde una sola base de código.
- Los datos se guardan en Supabase; **RLS obligatorio**: `user_id = auth.uid()` en toda tabla de usuario.
- La **clave de IA nunca viaja al cliente**; vive solo en la Edge Function.
- Peso en las **unidades del perfil** (`kg` | `lb`); zona horaria **local** del dispositivo.
- Imágenes comprimidas a **lado mayor ≤ 1024 px** en formato JPEG antes de enviarse.
- Semanas según **ISO 8601** (lunes a domingo).
- Comandos de Flutter se ejecutan dentro de `app/` salvo indicación contraria.
- Todos los cálculos derivados (volumen, 1RM, deltas, adherencia, medias) son **funciones puras testeables**.

## Review Focus

Fallos de entrada que el spec implica pero que ningún test cubre por defecto; cada uno se fija con un test en la tarea que posee el código:

1. **Semana sin días registrados** → las medias deben ser 0/estado vacío, nunca `NaN` ni `Infinity`.
2. **Entrada de comida sin alimentos** (la IA no detectó nada o falló) → mostrar "no se detectaron alimentos" con opción de reintentar/añadir a mano, sin crashear.
3. **Frontera de semana ISO en hora local** → una comida del domingo 23:59 cuenta en la semana que termina ese domingo; la del lunes 00:01 en la siguiente.
4. **Usuario nuevo sin datos** → todas las pantallas muestran estado vacío sin errores (resumen semanal, gráficas, totales).
5. **Serie/sesión con volumen cero** (reps o peso 0) → volumen = 0 y la gráfica no rompe sin puntos.

---

## Estructura de archivos

```
app/                                  # proyecto Flutter
  lib/
    main.dart                         # arranque + Supabase init + ProviderScope
    app.dart                          # MaterialApp + router (go_router)
    core/
      config/env.dart                 # SUPABASE_URL / SUPABASE_ANON_KEY
      supabase/supabase_client.dart   # inicialización de Supabase
      theme/app_theme.dart
      router/app_router.dart          # rutas + redirección por sesión
    features/
      auth/
        data/auth_repository.dart
        application/auth_controller.dart
        presentation/login_screen.dart
        presentation/register_screen.dart
      profile/
        domain/profile.dart
        data/profile_repository.dart
        application/profile_controller.dart
        presentation/profile_screen.dart
      workouts/
        domain/exercise.dart
        domain/workout_set.dart
        domain/workout_session.dart
        domain/workout_metrics.dart   # funciones puras
        data/workout_repository.dart
        application/workout_controller.dart
        presentation/exercise_list_screen.dart
        presentation/workout_log_screen.dart
        presentation/exercise_chart_screen.dart
      progress/
        domain/weekly_summary.dart    # modelos + comparación (funciones puras)
        data/progress_repository.dart
        application/progress_controller.dart
        presentation/weekly_summary_screen.dart
      food/
        domain/food_item.dart
        domain/food_entry.dart
        data/food_repository.dart
        data/meal_analysis_service.dart
        application/food_controller.dart
        presentation/food_capture_screen.dart
        presentation/food_review_screen.dart
        presentation/daily_log_screen.dart
    shared/
      widgets/empty_state.dart
      widgets/loading_overlay.dart
  test/
    ...                               # tests por feature
  pubspec.yaml
supabase/
  migrations/                         # SQL versionado
  functions/analyze-meal/index.ts
```

---

## Fase 0 — Entorno

### Task 1: Instalar Flutter y crear el proyecto base

**Files:**
- Create: `app/` (proyecto Flutter completo)
- Create: `app/pubspec.yaml`
- Modify: `app/lib/main.dart`
- Test: `app/test/smoke_test.dart`

**Interfaces:**
- Produces: proyecto Flutter en `app/` que compila a Android y Web y pasa `flutter test`.

- [ ] **Step 1: Instalar el SDK de Flutter y verificar**

En Windows: descargar el SDK estable de Flutter, añadirlo al `PATH` y verificar.

Run: `flutter --version`
Expected: imprime la versión de Flutter/Dart sin error.

Run: `flutter doctor`
Expected: al menos Android toolchain y Chrome marcados (aceptar licencias con `flutter doctor --android-licenses`).

- [ ] **Step 2: Crear el proyecto**

Run: `flutter create --platforms=android,web --org com.fitnessapp --project-name fitness_app app`
Expected: crea `app/` con `pubspec.yaml`, `lib/main.dart`, `test/`.

- [ ] **Step 3: Añadir dependencias**

Modify `app/pubspec.yaml` añadiendo bajo `dependencies`:

```yaml
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  supabase_flutter: ^2.5.6
  sembast: ^3.7.1
  image_picker: ^1.1.2
  image: ^4.2.1
  intl: ^0.19.0
  fl_chart: ^0.69.0
  http: ^1.2.2
```

y bajo `dev_dependencies`:

```yaml
  mocktail: ^1.0.4
```

Run: `flutter pub get`
Expected: resuelve dependencias sin error.

- [ ] **Step 4: Escribir el test de humo**

Create `app/test/smoke_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el entorno de test funciona', () {
    expect(1 + 1, 2);
  });
}
```

- [ ] **Step 5: Verificar analyze y test**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: todos los tests pasan (1 test).

- [ ] **Step 6: Commit**

```bash
git add app
git commit -m "chore: proyecto Flutter base con dependencias"
```

---

## Fase 1 — Cuenta, datos y perfil

### Task 2: Configuración de Supabase y cliente

**Files:**
- Create: `app/lib/core/config/env.dart`
- Create: `app/lib/core/supabase/supabase_client.dart`
- Modify: `app/lib/main.dart`
- Test: `app/test/core/supabase_init_test.dart`

**Interfaces:**
- Produces: `Env.supabaseUrl`, `Env.supabaseAnonKey` (String); `Future<void> initSupabase()` que llama a `Supabase.initialize(...)`.
- Consumes: nada.

- [ ] **Step 1: Crear el proyecto en Supabase (manual)**

En el panel de Supabase (plan free): crear proyecto, copiar **Project URL** y **anon public key**, y en Authentication habilitar **Email** provider. Guardarlos en `app/lib/core/config/env.dart` como `Env.supabaseUrl` y `Env.supabaseAnonKey`. Nota: la `anon key` es pública por diseño; la seguridad real la da RLS.

- [ ] **Step 2: Escribir el test**

Create `app/test/core/supabase_init_test.dart`:

```dart
import 'package:fitness_app/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Env expone url y anon key no vacías', () {
    expect(Env.supabaseUrl, isNotEmpty);
    expect(Env.supabaseAnonKey, isNotEmpty);
  });
}
```

- [ ] **Step 3: Implementar `Env` y `initSupabase`**

Create `app/lib/core/config/env.dart` con las dos constantes `static const String`.

Create `app/lib/core/supabase/supabase_client.dart`:

```dart
Future<void> initSupabase() async { /* Supabase.initialize(url, anonKey) */ }
```

Modify `app/lib/main.dart` para llamar `WidgetsFlutterBinding.ensureInitialized(); await initSupabase();` antes de `runApp`.

- [ ] **Step 4: Verificar**

Run: `flutter test test/core/supabase_init_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/core app/test/core app/lib/main.dart
git commit -m "feat: configuracion e inicializacion de Supabase"
```

### Task 3: Migración de `profiles` con RLS y auto-creación

**Files:**
- Create: `supabase/migrations/0001_profiles.sql`
- Test: `supabase/tests/profiles_rls.md` (procedimiento manual documentado)

**Interfaces:**
- Produces: tabla `profiles` con RLS y trigger `on_auth_user_created` que inserta una fila al crear usuario.

- [ ] **Step 1: Escribir la migración**

Create `supabase/migrations/0001_profiles.sql` con:

```sql
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
```

- [ ] **Step 2: Aplicar la migración**

Run: `supabase db push` (o pegar el SQL en el SQL Editor de Supabase).
Expected: sin errores.

- [ ] **Step 3: Documentar y ejecutar la comprobación de RLS**

Create `supabase/tests/profiles_rls.md` describiendo: crear dos usuarios A y B; con el token de A, `select * from profiles` debe devolver solo la fila de A; `update` de la fila de B debe afectar 0 filas. Ejecutarlo y anotar el resultado.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations supabase/tests
git commit -m "feat(db): tabla profiles con RLS y trigger de alta"
```

### Task 4: `AuthRepository`

**Files:**
- Create: `app/lib/features/auth/data/auth_repository.dart`
- Test: `app/test/features/auth/auth_repository_test.dart`

**Interfaces:**
- Produces:
  - `class AuthRepository { AuthRepository(this._client); }`
  - `Future<void> signUp({required String email, required String password, String? displayName})`
  - `Future<void> signIn({required String email, required String password})`
  - `Future<void> signOut()`
  - `User? get currentUser`
  - `Stream<AuthState> get authStateChanges`
- Consumes: `SupabaseClient`.

- [ ] **Step 1: Escribir el test (con mock)**

Create `app/test/features/auth/auth_repository_test.dart` usando `mocktail` para simular `SupabaseClient`/`GoTrueClient`. Test: `signIn` exitoso no lanza; `signIn` con error de credenciales propaga `AuthException`.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/auth/auth_repository_test.dart`
Expected: FAIL (la clase no existe).

- [ ] **Step 3: Implementar `AuthRepository`**

Implementar los métodos delegando en `_client.auth.*`. `signUp` pasa `data: {'display_name': displayName}`.

- [ ] **Step 4: Verificar que pasa**

Run: `flutter test test/features/auth/auth_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/auth/data app/test/features/auth
git commit -m "feat(auth): AuthRepository con signUp/signIn/signOut"
```

### Task 5: Sesión, router y pantallas de login/registro

**Files:**
- Create: `app/lib/features/auth/application/auth_controller.dart`
- Create: `app/lib/core/router/app_router.dart`
- Create: `app/lib/features/auth/presentation/login_screen.dart`
- Create: `app/lib/features/auth/presentation/register_screen.dart`
- Modify: `app/lib/app.dart`, `app/lib/main.dart`
- Test: `app/test/features/auth/login_flow_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `AuthState`.
- Produces: `authStateProvider` (StreamProvider<AuthState>); rutas `/login`, `/register`, `/`; `appRouterProvider`.

- [ ] **Step 1: Escribir el test de widget**

Create `app/test/features/auth/login_flow_test.dart`: montar `LoginScreen` con un `AuthRepository` simulado; al pulsar "Entrar" con email/contraseña y éxito, no hay error; con fallo, se muestra el mensaje.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/auth/login_flow_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

- `AuthController` (Riverpod `AsyncNotifier`) con `signIn`, `signUp`, `signOut`.
- `app_router.dart`: `GoRouter` con `redirect` que manda a `/login` si no hay sesión y a `/` si la hay.
- `LoginScreen` y `RegisterScreen` con `TextField` (email, contraseña) y botón; estados de carga y error visibles.
- Cablear en `app.dart` (`MaterialApp.router`) y refactorizar `main.dart` para envolver en `ProviderScope`.

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/auth/login_flow_test.dart`
Expected: PASS.

Run: `flutter analyze`
Expected: sin issues.

- [ ] **Step 5: Commit**

```bash
git add app/lib app/test
git commit -m "feat(auth): controlador, router y pantallas de login/registro"
```

### Task 6: Modelo y repositorio de perfil + pantalla

**Files:**
- Create: `app/lib/features/profile/domain/profile.dart`
- Create: `app/lib/features/profile/data/profile_repository.dart`
- Create: `app/lib/features/profile/application/profile_controller.dart`
- Create: `app/lib/features/profile/presentation/profile_screen.dart`
- Test: `app/test/features/profile/profile_test.dart`

**Interfaces:**
- Produces:
  - `enum Units { kg, lb }`
  - `class Profile { final String id; final String? displayName; final int dailyCalorieTarget; final double proteinTargetG, carbsTargetG, fatTargetG; final Units units; Profile copyWith({...}); Map<String,dynamic> toMap(); factory Profile.fromMap(Map<String,dynamic>); }`
  - `class ProfileRepository { Future<Profile> fetch(String userId); Future<void> update(Profile p); }`
  - `profileProvider` (AsyncNotifier<Profile>).

- [ ] **Step 1: Escribir el test**

Create `app/test/features/profile/profile_test.dart`: verifica `Profile.fromMap(toMap())` round-trip y `copyWith` sobre `units` y `dailyCalorieTarget`.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/profile/profile_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar modelo, repositorio, controlador y pantalla**

`Profile.fromMap` lee las columnas de `profiles`; `units` se parsea a `Units`. `ProfileScreen` permite editar objetivo de calorías, macros y unidades y guarda con `profileProvider`.

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/profile/profile_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/profile app/test/features/profile
git commit -m "feat(profile): modelo, repositorio y edicion de perfil"
```

---

## Fase 2 — Entrenamientos

### Task 7: Migración de ejercicios, sesiones y series con RLS

**Files:**
- Create: `supabase/migrations/0002_workouts.sql`

**Interfaces:**
- Produces: tablas `exercises`, `workout_sessions`, `workout_sets` con RLS; catálogo de ejercicios comunes sembrado.

- [ ] **Step 1: Escribir la migración**

Create `supabase/migrations/0002_workouts.sql` con las tres tablas del spec (sección 6.3), `enable row level security`, y políticas `using (auth.uid() = user_id)` para `exercises` y `workout_sessions`; para `workout_sets` la política comprueba pertenencia vía `session_id` (`exists (select 1 from workout_sessions s where s.id = workout_sets.session_id and s.user_id = auth.uid())`). Incluir un `insert` del catálogo común (p. ej. sentadilla, press banca, peso muerto, dominadas, etc.) con el `user_id` del usuario principal.

- [ ] **Step 2: Aplicar**

Run: `supabase db push`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/0002_workouts.sql
git commit -m "feat(db): tablas de entrenamiento con RLS y catalogo"
```

### Task 8: Modelos de dominio de entrenamiento

**Files:**
- Create: `app/lib/features/workouts/domain/exercise.dart`
- Create: `app/lib/features/workouts/domain/workout_set.dart`
- Create: `app/lib/features/workouts/domain/workout_session.dart`
- Test: `app/test/features/workouts/models_test.dart`

**Interfaces:**
- Produces:
  - `class Exercise { final String id; final String userId; final String name; final String muscleGroup; final bool isCustom; }`
  - `enum Rpe` no (usar `double?`).
  - `class WorkoutSet { final String? id; final String exerciseId; final int setIndex; final int reps; final double weight; final double? rpe; final bool completed; }`
  - `class WorkoutSession { final String? id; final String userId; final DateTime startedAt; final DateTime? endedAt; final String? notes; final List<WorkoutSet> sets; }`
  - Cada modelo con `toMap()`/`fromMap()`.

- [ ] **Step 1: Escribir el test**

Create `app/test/features/workouts/models_test.dart`: round-trip `toMap`/`fromMap` de `WorkoutSet` y `WorkoutSession` (con lista de series vacía y con series).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/workouts/models_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar los modelos**

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/workouts/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workouts/domain app/test/features/workouts/models_test.dart
git commit -m "feat(workouts): modelos de dominio"
```

### Task 9: Métricas puras (volumen, 1RM, PRs)

**Files:**
- Create: `app/lib/features/workouts/domain/workout_metrics.dart`
- Test: `app/test/features/workouts/workout_metrics_test.dart`

**Interfaces:**
- Produces (funciones puras):
  - `double sessionVolume(List<WorkoutSet> sets)` → Σ(reps × weight); lista vacía → 0.
  - `double estimateOneRepMax(double weight, int reps)` → `weight * (1 + reps / 30)`; `reps <= 0` → `weight`.
  - `double bestWeightForExercise(String exerciseId, List<WorkoutSession> sessions)` → máxima `weight`; sin datos → 0.
  - `Set<String> detectNewPrs(List<WorkoutSession> sessions)` → ids de ejercicio cuyo último peso máximo supera a todos los anteriores.

- [ ] **Step 1: Escribir los tests**

Create `app/test/features/workouts/workout_metrics_test.dart` con casos: volumen de lista vacía = 0; volumen de una serie 3×100 = 300; 1RM de 100 kg × 5 reps = 116.67 (≈, con `closeTo(..., 0.01)`); `reps <= 0` devuelve `weight`; `detectNewPrs` con historial [100, 100, 110] devuelve el ejercicio afectado (caso Review Focus n.º 5: volumen cero → 0, no NaN).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/workouts/workout_metrics_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar las funciones**

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/workouts/workout_metrics_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workouts/domain/workout_metrics.dart app/test/features/workouts/workout_metrics_test.dart
git commit -m "feat(workouts): metricas puras de volumen, 1RM y PRs"
```

### Task 10: `WorkoutRepository` y controlador

**Files:**
- Create: `app/lib/features/workouts/data/workout_repository.dart`
- Create: `app/lib/features/workouts/application/workout_controller.dart`
- Test: `app/test/features/workouts/workout_repository_test.dart`

**Interfaces:**
- Consumes: `WorkoutSession`, `WorkoutSet`, `Exercise`, `SupabaseClient`.
- Produces:
  - `Future<List<Exercise>> fetchExercises()`
  - `Future<Exercise> createExercise(String name, String muscleGroup)`
  - `Future<void> saveSession(WorkoutSession session)`
  - `Future<List<WorkoutSession>> fetchSessions({DateTime? from, DateTime? to})`
  - `Future<List<WorkoutSession>> fetchSessionsForExercise(String exerciseId)`

- [ ] **Step 1: Escribir el test**

Create `app/test/features/workouts/workout_repository_test.dart` con un cliente Supabase simulado: `saveSession` inserta la sesión y luego las series; `fetchSessions` filtra por rango de fechas.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/workouts/workout_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar el repositorio y el controlador**

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/workouts/workout_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workouts/data app/lib/features/workouts/application app/test/features/workouts/workout_repository_test.dart
git commit -m "feat(workouts): repositorio y controlador"
```

### Task 11: Pantallas de ejercicios y registro de entrenamiento

**Files:**
- Create: `app/lib/features/workouts/presentation/exercise_list_screen.dart`
- Create: `app/lib/features/workouts/presentation/workout_log_screen.dart`
- Modify: `app/lib/core/router/app_router.dart`
- Test: `app/test/features/workouts/workout_log_test.dart`

**Interfaces:**
- Consumes: `workoutControllerProvider`, `WorkoutRepository`.
- Produces: rutas `/workouts` y `/workouts/log`.

- [ ] **Step 1: Escribir el test de widget**

Create `app/test/features/workouts/workout_log_test.dart`: añadir una serie (reps 5, peso 100) a un ejercicio y verificar que el volumen mostrado es 500; verificar estado vacío sin series (Review Focus n.º 4).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/workouts/workout_log_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar las pantallas**

Lista de ejercicios (con alta de ejercicio propio) y pantalla de registro con filas de series (reps/peso/RPE), botón "añadir serie" y "guardar sesión".

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/workouts/workout_log_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workouts/presentation app/lib/core/router app/test/features/workouts/workout_log_test.dart
git commit -m "feat(workouts): pantallas de lista y registro"
```

### Task 12: Gráfica de evolución por ejercicio

**Files:**
- Create: `app/lib/features/workouts/presentation/exercise_chart_screen.dart`
- Modify: `app/lib/core/router/app_router.dart`
- Test: `app/test/features/workouts/exercise_chart_test.dart`

**Interfaces:**
- Consumes: `fetchSessionsForExercise`, `sessionVolume`, `estimateOneRepMax`.
- Produces: ruta `/workouts/chart/:exerciseId`.

- [ ] **Step 1: Escribir el test**

Create `app/test/features/workouts/exercise_chart_test.dart`: con 0 sesiones no hay puntos y se muestra estado vacío; con 2 sesiones hay 2 puntos (Review Focus n.º 4 y 5).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/workouts/exercise_chart_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar la pantalla**

Usar `fl_chart` (`LineChart`) con la evolución del peso máximo y del volumen por fecha.

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/workouts/exercise_chart_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/workouts/presentation/exercise_chart_screen.dart app/lib/core/router app/test/features/workouts/exercise_chart_test.dart
git commit -m "feat(workouts): grafica de evolucion por ejercicio"
```

---

## Fase 3 — Progreso semanal

### Task 13: Cálculo del resumen semanal (puro)

**Files:**
- Create: `app/lib/features/progress/domain/weekly_summary.dart`
- Test: `app/test/features/progress/weekly_summary_test.dart`

**Interfaces:**
- Produces:
  - `class WeeklySummary { final DateTime weekStart; final double volume; final int sessions; final int newPrs; final double avgCalories; final double avgProteinG, avgCarbsG, avgFatG; final double adherence; }`
  - `class WeeklyComparison { final WeeklySummary current; final WeeklySummary previous; double get volumeDelta; ... }`
  - `DateTime isoWeekStart(DateTime localDate)` → lunes 00:00 local.
  - `WeeklySummary buildWeeklySummary({required DateTime weekStart, required List<WorkoutSession> sessions, required List<FoodEntry> foodEntries})`
  - `WeeklyComparison compareWeeks({required DateTime currentWeekStart, required List<WorkoutSession> sessions, required List<FoodEntry> foodEntries})`

- [ ] **Step 1: Escribir los tests**

Create `app/test/features/progress/weekly_summary_test.dart`:
- `isoWeekStart` de un domingo y del lunes siguiente devuelven lunes distintos (Review Focus n.º 3).
- Semana sin datos: `avgCalories`, `avgProteinG`, `adherence` = 0 y **no** `NaN` (Review Focus n.º 1).
- Semana con 2 días y 2 sesiones: volumen, sesiones, adherencia (=contar días con registro / 7) y deltas correctos.
- `newPrs` cuenta PRs nuevos de esa semana.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/progress/weekly_summary_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar los modelos y funciones puras**

Las medias se calculan **solo sobre los días con registro**; si no hay días, devolver 0 (nunca dividir entre cero).

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/progress/weekly_summary_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/progress/domain app/test/features/progress/weekly_summary_test.dart
git commit -m "feat(progress): calculo puro del resumen semanal con deltas"
```

### Task 14: Repositorio y pantalla de resumen semanal

**Files:**
- Create: `app/lib/features/progress/data/progress_repository.dart`
- Create: `app/lib/features/progress/application/progress_controller.dart`
- Create: `app/lib/features/progress/presentation/weekly_summary_screen.dart`
- Modify: `app/lib/core/router/app_router.dart`
- Test: `app/test/features/progress/weekly_summary_screen_test.dart`

**Interfaces:**
- Consumes: `WorkoutRepository.fetchSessions`, `FoodRepository.fetchEntries` (Task 17), `compareWeeks`.
- Produces: `progressControllerProvider`, ruta `/progress`.

- [ ] **Step 1: Escribir el test de widget**

Create `app/test/features/progress/weekly_summary_screen_test.dart`: con datos simulados de dos semanas, mostrar los deltas con flechas ↑/↓; con usuario nuevo sin datos, estado vacío (Review Focus n.º 1 y 4).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/progress/weekly_summary_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar repositorio, controlador y pantalla**

La pantalla permite navegar a semanas anteriores (RF-25).

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/progress/weekly_summary_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/progress app/lib/core/router app/test/features/progress/weekly_summary_screen_test.dart
git commit -m "feat(progress): pantalla de resumen semanal con comparacion"
```

---

## Fase 4 — Comida por foto

### Task 15: Migración de comidas con RLS

**Files:**
- Create: `supabase/migrations/0003_food.sql`

**Interfaces:**
- Produces: tablas `food_entries` y `food_entry_items` con RLS (items vía pertenencia de la entrada).

- [ ] **Step 1: Escribir la migración**

Create `supabase/migrations/0003_food.sql` con las tablas del spec (sección 6.2), RLS para `food_entries` por `user_id`, y para `food_entry_items` por pertenencia de la entrada.

- [ ] **Step 2: Aplicar**

Run: `supabase db push`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/0003_food.sql
git commit -m "feat(db): tablas de comidas con RLS"
```

### Task 16: Modelos de dominio de comida

**Files:**
- Create: `app/lib/features/food/domain/food_item.dart`
- Create: `app/lib/features/food/domain/food_entry.dart`
- Test: `app/test/features/food/food_models_test.dart`

**Interfaces:**
- Produces:
  - `enum MealType { breakfast, lunch, dinner, snack }`
  - `enum FoodSource { ai, manual }`
  - `class FoodItem { final String name; final double quantity; final String unit; final int calories; final double proteinG, carbsG, fatG; final double? confidence; final bool estimated; factory FoodItem.fromAnalysisJson(Map<String,dynamic>); }`
  - `class FoodEntry { final String? id; final String userId; final DateTime loggedAt; final MealType mealType; final List<FoodItem> items; final String? photoPath; final FoodSource source; int get totalCalories; double get totalProteinG, totalCarbsG, totalFatG; }`

- [ ] **Step 1: Escribir el test**

Create `app/test/features/food/food_models_test.dart`: `FoodItem.fromAnalysisJson` parsea el JSON de la Edge Function; `FoodEntry` con lista vacía da totales 0.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/food/food_models_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar los modelos**

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/food/food_models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/food/domain app/test/features/food/food_models_test.dart
git commit -m "feat(food): modelos de dominio de comida"
```

### Task 17: Edge Function `analyze-meal` (IA de visión + nutrición)

**Files:**
- Create: `supabase/functions/analyze-meal/index.ts`
- Create: `supabase/functions/analyze-meal/README.md`

**Interfaces:**
- Produces: endpoint `POST /functions/v1/analyze-meal`, cuerpo `{ "image_base64": string, "hint": string? }`, respuesta `{ "items": FoodItemJson[] }` donde `FoodItemJson = { name, quantity, unit, calories, protein_g, carbs_g, fat_g, confidence, estimated }`.
- Consumes: Cloudflare Workers AI (`@cf/meta/llama-3.2-11b-vision-instruct`), Open Food Facts, USDA FDC.

- [ ] **Step 1: Escribir la función**

En `index.ts`: validar el token del usuario con Supabase (`auth.getUser`); enviar la imagen a Workers AI pidiendo **JSON estructurado** (lista de alimentos + gramos); para cada alimento consultar Open Food Facts (y USDA si hay clave) y usar esos valores; si no hay coincidencia, marcar `estimated: true`; devolver `{ items }`. Guardar `WORKERS_AI_ACCOUNT_ID`, `WORKERS_AI_API_TOKEN` y `USDA_API_KEY` como **secrets** de la función.

Documentar en `README.md` cómo desplegar (`supabase functions deploy analyze-meal`) y cómo configurar los secrets.

- [ ] **Step 2: Probar la función de forma manual**

Run (ejemplo): `supabase functions serve` + `curl` con una imagen pequeña y el token de un usuario de prueba.
Expected: JSON con `items` coherentes. Añadir el resultado al `README.md`.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/analyze-meal
git commit -m "feat(ai): edge function analyze-meal con vision y nutricion"
```

### Task 18: Servicio de análisis y repositorio de comidas

**Files:**
- Create: `app/lib/features/food/data/meal_analysis_service.dart`
- Create: `app/lib/features/food/data/food_repository.dart`
- Test: `app/test/features/food/meal_analysis_service_test.dart`, `app/test/features/food/food_repository_test.dart`

**Interfaces:**
- Consumes: `SupabaseClient`, `Uint8List`.
- Produces:
  - `Future<List<FoodItem>> MealAnalysisService.analyze(Uint8List imageBytes, {String? hint})` (comprime a ≤1024 px JPEG y llama a la función; si no hay items, devuelve lista vacía sin lanzar — Review Focus n.º 2).
  - `Future<void> saveEntry(FoodEntry entry)`, `Future<List<FoodEntry>> fetchEntries({DateTime? from, DateTime? to})`, `Future<void> deleteEntry(String id)`.

- [ ] **Step 1: Escribir los tests**

`meal_analysis_service_test.dart`: con respuesta simulada de la función que devuelve `items: []`, `analyze` devuelve lista vacía y no lanza (Review Focus n.º 2); con `items` completos, los mapea a `FoodItem`.
`food_repository_test.dart`: `saveEntry` inserta entrada + items; `fetchEntries` filtra por rango.

- [ ] **Step 2: Verificar que fallan**

Run: `flutter test test/features/food/meal_analysis_service_test.dart test/features/food/food_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar servicio y repositorio**

La compresión usa el paquete `image` (`copyResize` + `encodeJpg`).

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/food/meal_analysis_service_test.dart test/features/food/food_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/food/data app/test/features/food/meal_analysis_service_test.dart app/test/features/food/food_repository_test.dart
git commit -m "feat(food): servicio de analisis y repositorio de comidas"
```

### Task 19: Pantallas de comida (captura, revisión y diario)

**Files:**
- Create: `app/lib/features/food/application/food_controller.dart`
- Create: `app/lib/features/food/presentation/food_capture_screen.dart`
- Create: `app/lib/features/food/presentation/food_review_screen.dart`
- Create: `app/lib/features/food/presentation/daily_log_screen.dart`
- Modify: `app/lib/core/router/app_router.dart`
- Test: `app/test/features/food/food_flow_test.dart`

**Interfaces:**
- Consumes: `MealAnalysisService`, `FoodRepository`.
- Produces: `foodControllerProvider`; rutas `/food`, `/food/review`, `/food/log`.

- [ ] **Step 1: Escribir el test de widget**

Create `app/test/features/food/food_flow_test.dart`: desde captura con análisis simulado, la pantalla de revisión muestra items editables; si el análisis devuelve vacío se muestra "no se detectaron alimentos" con opción de añadir a mano (Review Focus n.º 2); el diario con entrada vacía muestra totales 0 (Review Focus n.º 4).

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/features/food/food_flow_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar las pantallas**

- `food_capture_screen`: botones de cámara/galería (`image_picker`) y estado de carga.
- `food_review_screen`: lista editable de items, totales, selector de tipo de comida, botón guardar.
- `daily_log_screen`: entradas del día, totales y progreso frente al objetivo del perfil; alta manual.

- [ ] **Step 4: Verificar**

Run: `flutter test test/features/food/food_flow_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/food app/lib/core/router app/test/features/food/food_flow_test.dart
git commit -m "feat(food): pantallas de captura, revision y diario"
```

---

## Fase 5 — Multiplataforma y pulido

### Task 20: Navegación principal, caché local y estados de error

**Files:**
- Create: `app/lib/shared/widgets/empty_state.dart`, `app/lib/shared/widgets/loading_overlay.dart`
- Create: `app/lib/core/cache/local_cache.dart` (sembast)
- Modify: `app/lib/app.dart`, `app/lib/core/router/app_router.dart`
- Test: `app/test/core/local_cache_test.dart`

**Interfaces:**
- Produces: navegación inferior con pestañas (Comidas, Entrenos, Progreso, Perfil); `LocalCache` con `Future<void> put(String key, Object value)`, `Future<Object?> get(String key)`.

- [ ] **Step 1: Escribir el test**

Create `app/test/core/local_cache_test.dart`: `put` y `get` devuelven el valor; `get` de clave inexistente devuelve `null`.

- [ ] **Step 2: Verificar que falla**

Run: `flutter test test/core/local_cache_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

Añadir `NavigationBar` con las cuatro secciones; widgets reutilizables de estado vacío/carga/error; capa de caché local usada para lecturas rápidas.

- [ ] **Step 4: Verificar**

Run: `flutter test`
Expected: PASS (toda la suite).

Run: `flutter analyze`
Expected: sin issues.

- [ ] **Step 5: Commit**

```bash
git add app/lib app/test
git commit -m "feat(core): navegacion, cache local y estados de UI"
```

### Task 21: Configuración Web/PWA y build Android

**Files:**
- Modify: `app/web/index.html`, `app/web/manifest.json`
- Create: `docs/deploy.md`

**Interfaces:**
- Produces: app instalable como PWA en Safari iOS y APK de Android.

- [ ] **Step 1: Configurar la PWA**

Ajustar `manifest.json` (nombre, colores, iconos) y `index.html` (título, meta viewport). Permitir acceso a cámara en web.

- [ ] **Step 2: Compilar Web y Android**

Run: `flutter build web --release`
Expected: genera `app/build/web`.

Run: `flutter build apk --release`
Expected: genera el APK.

- [ ] **Step 3: Probar en dispositivos reales**

Desplegar la build web (p. ej. cualquier hosting estático gratis) y abrirla en Safari del iPhone → "Añadir a pantalla de inicio"; instalar el APK en el Android. Verificar login y sincronización entre dispositivos.

- [ ] **Step 4: Documentar**

Create `docs/deploy.md` con los pasos de despliegue, variables de entorno y secrets de Supabase.

- [ ] **Step 5: Commit**

```bash
git add app/web docs/deploy.md
git commit -m "chore(deploy): configuracion PWA y builds Android/Web"
```

---

## Notas de ejecución

- **Orden obligatorio entre fases:** Fase 1 antes que 2, 3 y 4 (auth y datos son la base). La Fase 4 (comida) puede ir en paralelo a la Fase 2/3 en cuanto exista la base de datos, pero el resumen semanal (Fase 3) usa `FoodRepository` (Task 18), así que la Task 14 depende de la 18.
- **Migraciones:** mantener el orden `0001`, `0002`, `0003`.
- **Secretos:** nunca commitear claves; usar variables de entorno de Supabase y, en local, un archivo no versionado.
