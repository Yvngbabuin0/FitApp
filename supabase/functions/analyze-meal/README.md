# Edge Function `analyze-meal`

Identifica la comida de una foto (IA de visión) y devuelve kcal y macros
verificados contra bases nutricionales gratuitas.

## API

`POST /functions/v1/analyze-meal`

Headers:

- `Authorization: Bearer <JWT del usuario>` (obligatorio)
- `Content-Type: application/json`

Body:

```json
{
  "image_base64": "<foto comprimida a JPEG ≤1024 px en base64>",
  "hint": "opcional: contexto (p. ej. 'cena italiana')"
}
```

Respuesta:

```json
{
  "items": [
    {
      "name": "Pollo a la plancha",
      "quantity": 150,
      "unit": "g",
      "calories": 248,
      "protein_g": 46.5,
      "carbs_g": 0,
      "fat_g": 5.4,
      "confidence": 0.82,
      "estimated": false
    }
  ]
}
```

- `estimated: true` → no se pudo verificar en ninguna base nutricional
  (Open Food Facts / USDA) y el valor es el estimado de la IA.

Errores: `401` sin token válido, `400` sin `image_base64`, `413` imagen >6 MB
en base64.

## Despliegue

Requisitos: CLI de Supabase (`supabase`), proyecto creado.

```bash
# 1) Configurar secrets de la función
supabase secrets set WORKERS_AI_ACCOUNT_ID=tu_account_id
supabase secrets set WORKERS_AI_API_TOKEN=tu_api_token
supabase secrets set USDA_API_KEY=tu_clave_opcional

# 2) Desplegar
supabase functions deploy analyze-meal
```

Los secrets se obtienen del panel de Cloudflare (Workers AI) y de USDA FDC.
Nunca se suben al repositorio.

## Configuración de Workers AI (Cloudflare)

1. Cuenta gratis en https://dash.cloudflare.com.
2. Registrar `Workers AI` y anotar el **Account ID**.
3. Crear un **API Token** con permiso `Workers AI:Edit`.

Modelo usado: `@cf/meta/llama-3.2-11b-vision-instruct`.

## Límites del plan gratuito

- Workers AI: ~10 000 neuronas/día (≈ cientos de análisis de comida/día).
- Open Food Facts / USDA FDC: gratuitos, con límites de peticiones muy
  folgados para uso personal.

## Prueba manual

```bash
supabase functions serve analyze-meal
# En otra terminal, con el JWT de un usuario de prueba:
curl -X POST http://127.0.0.1:54321/functions/v1/analyze-meal \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{"image_base64":"<base64 de una foto pequeña>"}'
```

### Resultado de la prueba de la foto de prueba (⌛ pendiente)

| Fecha | Imagen | Items devueltos | Observaciones |
| --- | --- | --- | --- |
| (pendiente) | (pendiente) | (pendiente) | (pendiente) |