import { createClient } from "jsr:@supabase/supabase-js@2";

// Secrets de la función (configurar con supabase secrets):
//   WORKERS_AI_ACCOUNT_ID
//   WORKERS_AI_API_TOKEN
//   USDA_API_KEY (opcional)

const WORKERS_AI_MODEL = "@cf/meta/llama-3.2-11b-vision-instruct";
const CLOUDFLARE_AI_URL =
  "https://api.cloudflare.com/client/v4/accounts/" +
  (Deno.env.get("WORKERS_AI_ACCOUNT_ID") ?? "") +
  "/ai/run/" +
  WORKERS_AI_MODEL;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  global: { headers: { Authorization: `Bearer ${SUPABASE_ANON_KEY}` } },
});

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PROMPT = `Eres un nutricionista experto. Analiza la comida de la foto y responde ÚNICAMENTE con un JSON válido, sin texto adicional, con esta forma exacta:
{"items":[{"name":"nombre del alimento","quantity":<gramos estimados>,"unit":"g","calories":<kcal>,"protein_g":<g>,"carbs_g":<g>,"fat_g":<g>,"confidence":<0.0-1.0>,"estimated":true}]}
Reglas:
- Lista cada alimento por separado (máximo 10).
- Estima los gramos razonablemente si no hay referencia de tamaño.
- "confidence" refleja tu seguridad en el total (0.5 si es ambiguo).
- "estimated" siempre true aquí (la verificación nutricional se hace después por separado).`;

interface AiItem {
  name: string;
  quantity: number;
  unit: string;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  confidence: number;
  estimated: boolean;
}

interface Nutrition {
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
}

function corsResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

/** Extrae el primer array JSON de objetos de un texto (tolerante a markdown). */
function extractItems(text: string): AiItem[] {
  const match = text.match(/\[[\s\S]*\]/);
  if (!match) return [];
  try {
    const parsed = JSON.parse(match[0]);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((it) => it && typeof it === "object");
  } catch {
    return [];
  }
}

async function fetchWithTimeout(url: string, init: RequestInit): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

/** Busca macros por 100 g en Open Food Facts. Devuelve null si no hay match. */
async function nutritionFromOpenFoodFacts(
  name: string,
): Promise<Nutrition | null> {
  const url =
    "https://world.openfoodfacts.org/cgi/search.pl?" +
    new URLSearchParams({
      action: "process",
      search_terms: name,
      json: "1",
      page_size: "1",
    });
  try {
    const res = await fetchWithTimeout(url, { headers: { "User-Agent": "fitness-tracker-app v1" } });
    if (!res.ok) return null;
    const data = await res.json();
    const product = data.products?.[0];
    const n = product?.nutriments;
    if (!n) return null;
    const calories = n["energy-kcal_100g"] ?? n["energy-kcal"];
    if (calories == null) return null;
    return {
      calories: Number(calories) || 0,
      protein_g: Number(n.proteins_100g ?? n.proteins) || 0,
      carbs_g: Number(n.carbohydrates_100g ?? n.carbohydrates) || 0,
      fat_g: Number(n.fat_100g ?? n.fat) || 0,
    };
  } catch {
    return null;
  }
}

const USDA_NUTRIENTS: Record<number, string> = {
  208: "calories",
  203: "protein_g",
  205: "carbs_g",
  204: "fat_g",
};

/** Busca macros por 100 g en USDA FDC. Devuelve null si no hay clave o match. */
async function nutritionFromUsda(name: string): Promise<Nutrition | null> {
  const key = Deno.env.get("USDA_API_KEY");
  if (!key) return null;
  const url =
    "https://api.nal.usda.gov/fdc/v1/foods/search?" +
    new URLSearchParams({ query: name, pageSize: "1", api_key: key });
  try {
    const res = await fetchWithTimeout(url);
    if (!res.ok) return null;
    const data = await res.json();
    const food = data.foods?.[0];
    if (!food) return null;
    const out: Partial<Record<string, number>> = {};
    for (const nutrient of food.foodNutrients ?? []) {
      const field = USDA_NUTRIENTS[nutrient.nutrientNumber];
      if (field) out[field] = Number(nutrient.amount) || 0;
    }
    if (out.calories == null) return null;
    return {
      calories: out.calories!,
      protein_g: out.protein_g ?? 0,
      carbs_g: out.carbs_g ?? 0,
      fat_g: out.fat_g ?? 0,
    };
  } catch {
    return null;
  }
}

async function verifiedItem(item: AiItem): Promise<AiItem> {
  const qty = Number(item.quantity) || 0;
  // Intentar primero USDA (más fiable), luego Open Food Facts.
  const nutrition =
    (await nutritionFromUsda(item.name)) ??
    (await nutritionFromOpenFoodFacts(item.name));
  if (!nutrition) {
    return {
      ...item,
      calories: Math.max(0, Math.round(Number(item.calories) || 0)),
      quantity: qty,
      estimated: true,
    };
  }
  const scale = qty / 100;
  return {
    ...item,
    calories: Math.max(0, Math.round(nutrition.calories * scale)),
    protein_g: +(nutrition.protein_g * scale).toFixed(1),
    carbs_g: +(nutrition.carbs_g * scale).toFixed(1),
    fat_g: +(nutrition.fat_g * scale).toFixed(1),
    quantity: qty,
    estimated: false,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsResponse({}, 204);

  if (req.method !== "POST") {
    return corsResponse({ error: "method_not_allowed" }, 405);
  }

  // Autenticación: token Bearer del usuario.
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return corsResponse({ error: "unauthorized" }, 401);
  }
  const { data: userData, error: userError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", ""),
  );
  if (userError || !userData.user) {
    return corsResponse({ error: "unauthorized" }, 401);
  }

  let body: { image_base64?: string; hint?: string };
  try {
    body = await req.json();
  } catch {
    return corsResponse({ error: "invalid_json" }, 400);
  }
  const imageBase64 = body.image_base64;
  if (!imageBase64 || typeof imageBase64 !== "string") {
    return corsResponse({ error: "image_base64_required" }, 400);
  }
  if (imageBase64.length > 6_000_000) {
    return corsResponse({ error: "image_too_large" }, 413);
  }

  // 1) Análisis visual con Workers AI.
  const hintText = body.hint?.trim() ? ` Contexto: ${body.hint.trim()}.` : "";
  let aiItems: AiItem[] = [];
  try {
    const aiRes = await fetchWithTimeout(CLOUDFLARE_AI_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("WORKERS_AI_API_TOKEN") ?? ""}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        messages: [
          {
            role: "system",
            content: PROMPT,
          },
          {
            role: "user",
            content: [
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${imageBase64}`,
                },
              },
              {
                type: "text",
                text:
                  "Detecta la comida de esta foto y devuelve el JSON de items." +
                  hintText,
              },
            ],
          },
        ],
        max_tokens: 1024,
      }),
    });
    if (aiRes.ok) {
      const aiData = await aiRes.json();
      aiItems = extractItems(aiData.result?.response ?? "");
    } else {
      console.error("Workers AI error", aiRes.status, await aiRes.text());
    }
  } catch (e) {
    console.error("Workers AI fetch error", e);
  }

  if (aiItems.length === 0) {
    // Sin resultados que devolver: respuesta vacía (no es un error del cliente).
    return corsResponse({ items: [] });
  }

  // 2) Verificación nutricional en paralelo (OFF/USDA).
  const items = await Promise.all(aiItems.map(verifiedItem));

  return corsResponse({ items });
});