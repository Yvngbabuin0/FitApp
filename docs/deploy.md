# Despliegue — Fitness Tracker

Instrucciones para llevar la app a producción con servicios gratuitos.

## 1. Variables y secretos

Nunca se commitean claves. En local viven en `app/lib/core/config/env.dart`
(fichero versionado con **placeholders**):

| Variable | Dónde se obtiene |
| --- | --- |
| `SUPABASE_URL` | Panel de Supabase → Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Panel de Supabase → Project Settings → API → anon public key |
| Workers AI (Account ID + API Token) | Dashboard de Cloudflare → Workers AI |
| `USDA_API_KEY` (opcional) | data.usda.gov (plan gratuito) |

## 2. Base de datos (Supabase)

1. Crear proyecto gratis en https://supabase.com (se pausa solo tras 7 días de inactividad; se reanuda pulsando un botón).
2. En **SQL Editor** ejecutar, en orden:
   - `supabase/migrations/0001_profiles.sql`
   - `supabase/migrations/0002_workouts.sql`
   - `supabase/migrations/0003_food.sql`
3. Verificar RLS con `supabase/tests/profiles_rls.md`.

## 3. Edge Function `analyze-meal` (Cloudflare Workers AI)

La función vive en `supabase/functions/analyze-meal/index.ts`.

Se puede desplegar de dos maneras:

- **Supabase Edge Functions** (gratis): copiar el código a la función `analyze-meal`
  en el dashboard (Edge Functions → Create) y configurar los secretos
  `CLOUDFLARE_AI_ACCOUNT_ID` y `CLOUDFLARE_AI_API_TOKEN` (más opcional
  `USDA_API_KEY`), o
- **Workers AI / Workers direto en Cloudflare** apuntando a la misma URL que la
  app espera (`SUPABASE_URL/functions/v1/analyze-meal`).

Contrato: `POST` con JSON `{ "image": "<base64 jpeg ≤1024px>", "hint": "opcional" }`
→ `{ "items": [ { name, quantity, unit, calories, protein_g, carbs_g, fat_g, confidence, estimated } ] }`.
Sin alimentos detectados responde `{ "items": [] }` (no es un error).

## 4. Web / PWA (`flutter build web --release`)

1. `cd app` y `flutter build web --release` → genera `app/build/web`.
2. Subir la carpeta a cualquier hosting estático gratuito (Netlify, Vercel,
   Cloudflare Pages, GitHub Pages…).
3. En el iPhone/Safari: abrir la URL → compartir → **Añadir a pantalla de inicio**
   (aparece el icono y abre a pantalla completa gracias al manifest PWA).
4. La cámara en web usa el `input[type=file]` con `capture`, por lo que Safari
   abre la cámara sin permisos extra. En Android/Chrome pedirá acceso si se usa
   captura directa.

## 5. Android APK (`flutter build apk --release`)

1. Tener el SDK de Android instalado con `cmdline-tools` y licencias aceptadas
   (`flutter doctor --android-licenses`).
2. `cd app` y `flutter build apk --release` → genera
   `app/build/app/outputs/flutter-apk/app-release.apk`.
3. Ese APK va firmado con la clave de depuración por defecto: vale para
   instalarlo directamente en un Android, pero **no** se puede publicar en
   Play Store así; para publicar hay que configurar un keystore propio
   (fuera del alcance de v1).

## 6. Verificación en varios dispositivos

- Registro con email → confirmar correo.
- Registrar una comida con foto (IA) y editarla; registrar un entrenamiento;
  el **resumen semanal** debe reflejar ambas cosas.
- Repetir en un segundo dispositivo y comprobar que los datos se sincronizan
  (un solo login compartido y RLS por usuario).

## Costes

| Servicio | Plan gratis | Notas |
| --- | --- | --- |
| Supabase | Sí | 500 MB base de datos; se pausa tras 7 días sin actividad |
| Cloudflare Workers AI | Sí | cuota diaria gratuita de inferencias |
| Hosting estático web | Sí | Netlify/Vercel/CF Pages |