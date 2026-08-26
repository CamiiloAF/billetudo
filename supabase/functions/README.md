# Edge Functions

Deno. El deploy es **manual** (no está en CI). Dos proyectos: dev y prod.

| Function | Qué hace |
|---|---|
| `delete-account` | Borra la cuenta y todos sus datos (HU-07, requisito legal Apple/Google). |
| `ai-chat` | Asistente financiero con IA (Fase A). Broker sin estado hacia el proveedor de LLM. |

## Secretos

Se setean por proyecto con `supabase secrets set --project-ref <ref> NOMBRE=valor`.
Nunca entran al repo — `.gitignore` ya excluye `.env` y `.env.*` a cualquier profundidad.

| Variable | Default | Notas |
|---|---|---|
| `SUPABASE_URL` | — | La inyecta la plataforma. |
| `SUPABASE_SERVICE_ROLE_KEY` | — | La inyecta la plataforma. |
| `GEMINI_API_KEY` | — | **Keys distintas en dev y prod**, cada una en su propio proyecto de Google Cloud, para que el dogfooding no agote la cuota de producción. |
| `AI_PROVIDER` | `gemini` | Selecciona la implementación de `AiProvider`. |
| `AI_MODEL` | `gemini-2.5-flash` | Cambiar de modelo sin redeploy. |
| `AI_REQUEST_TIMEOUT_MS` | `25000` | Timeout de cada llamada al proveedor. Con el techo de 2 llamadas por invocación, el peor caso es ~50 s. |
| `AI_MAX_TOOL_ROUNDS` | `3` | Rondas de lectura permitidas por turno del usuario. |

## `ai-chat` — contrato

`POST /functions/v1/ai-chat`, `verify_jwt: true`. El body **nunca** lleva un id de
usuario: se resuelve del JWT con `auth.getUser`.

La función es un **broker sin estado**. No lee ninguna tabla financiera, no guarda
transcripciones y no guarda el snapshot. El cliente es dueño de la conversación y
la reenvía completa en cada turno; el cliente también resuelve las herramientas de
lectura contra su base local (Drift), porque Postgres es un espejo que puede ir
atrasado y porque así el servidor nunca necesita acceso al libro contable de nadie.

### Request

```jsonc
{
  "protocolVersion": 1,
  "conversationId": "uuid generado en el dispositivo",
  "locale": "es-CO",
  "timezone": "America/Bogota",
  "clientVersion": "1.12.0+134",
  "snapshot": { /* resumen agregado; ver abajo */ },
  "messages": [
    { "role": "user", "content": "¿en qué se me fue la plata este mes?" },
    { "role": "assistant", "content": "",
      "toolCalls": [
        { "id": "tc_0_0", "name": "get_category_breakdown",
          "arguments": { "from": 1754006400, "to": 1756598400,
                         "type": "expense", "currency": "COP", "topN": 8 } }
      ] },
    { "role": "tool", "toolCallId": "tc_0_0", "name": "get_category_breakdown",
      "content": null,
      "result": { "currency": "COP", "totalMinor": 284000000, "items": [] } }
  ]
}
```

Topes: `messages` ≤ 40 entradas; body total ≤ 128 KB (`413 payload_too_large`).

### Response 200

```jsonc
{
  "protocolVersion": 1,
  "finishReason": "message" | "tool_calls" | "max_iterations" | "blocked",
  "message": {
    "role": "assistant",
    "content": "Texto ya listo para la burbuja.",
    "proposals": [
      { "id": "tc_0_0",
        "kind": "create_budget",
        "title": "Gastaste 1.240.000 COP en Comida en los últimos 3 meses.",
        "payload": { "name": "Comida", "amountMinor": 45000000, "currency": "COP",
                     "period": "monthly", "categoryIds": [], "accountIds": [],
                     "rationale": "…" } }
    ]
  },
  "toolCalls": [ /* solo si finishReason == "tool_calls" */ ],
  "usage": { "promptTokens": 2211, "completionTokens": 180 }
}
```

Invariante: `finishReason == "tool_calls"` ⟺ `toolCalls` no vacío. En cualquier
otro caso `toolCalls` es `[]`.

`kind` de una propuesta: `create_budget`, `create_goal`, `create_category`,
`create_transaction`. **Cualquier otro valor debe degradar a `UnsupportedProposal`
en el cliente, nunca lanzar** — un hilo persistido hoy tiene que seguir
parseando cuando el contrato crezca.

### Errores

`{"error": {"code": "...", "message": "...", "retryAfterSeconds": 30}}`

| HTTP | `code` | Qué hace la app |
|---|---|---|
| 400 | `invalid_request` | Bug: Sentry + mensaje genérico. |
| 401 | `unauthenticated` | Pedir re-login. |
| 403 | `ai_not_enabled` | Ocultar la entrada; «aún no disponible». |
| 413 | `payload_too_large` | Podar el historial local y reintentar. |
| 426 | `unsupported_protocol` | «Actualiza la app». |
| 429 | `quota_exceeded` | Pantalla de cupo (Fase B). |
| 429 | `provider_rate_limited` | «Estoy con mucha demanda», reintentar en `retryAfterSeconds`. |
| 502 | `provider_unavailable` | «No pude responder», botón reintentar. |
| 504 | `provider_timeout` | Igual que 502. |
| 500 | `internal` | Genérico. |

### Herramientas

**Lectura — las resuelve el cliente contra Drift** y devuelve el resultado como
un mensaje `role: "tool"`: `get_transactions`, `get_category_breakdown`,
`compare_periods`, `get_budget_detail`, `get_goal_detail`.

Dos límites reales del cliente, reflejados en las descripciones de las tools
para que el modelo no pida lo imposible:

- **`currency` en `get_category_breakdown` y `compare_periods` es un guard, no
  un filtro.** Los agregadores de la feature `reports` suman todas las monedas
  en una sola cifra y no saben separarlas. El cliente responde solo si **todas**
  las cuentas activas ya usan la moneda pedida, y devuelve `not_found` si el
  usuario tiene varias. Etiquetar un total multi-moneda con un solo código sería
  precisamente la fabricación que estas reglas existen para evitar. Misma razón
  por la que el snapshot **omite** `topCategories` y `cashflow` en una cuenta
  multi-moneda.
- **No hay desglose de ingresos por categoría.** El agregado subyacente es la
  «estructura de gasto» (HU-03) y no tiene equivalente de ingresos, así que
  `get_category_breakdown` solo acepta `type: "expense"`.

Resultado esperado (objeto JSON, nunca un array suelto — Gemini exige objeto):

```jsonc
{ "currency": "COP", "from": 1754006400, "to": 1756598400,
  "count": 25, "truncated": false,
  "items": [ { "id": "…", "date": 1755100000, "amountMinor": 4500000,
               "currency": "COP", "type": "expense",
               "categoryName": "Comida", "accountName": "Bancolombia" } ] }
```

Si el cliente no puede resolverla: `{"error": "not_found", "message": "…"}` en el
mismo campo `result`. El prompt instruye al modelo a explicarlo, no a inventar.

**Escritura — nunca se ejecutan**: `propose_create_budget`, `propose_create_goal`,
`propose_create_category`, `propose_create_transaction`. La función las valida
(monto entero positivo y ≥ 100 en unidades menores, currency ISO de 3 letras
presente en el snapshot, ids presentes en el snapshot, fechas unix en segundos
dentro de rango) y las emite como `proposals[]`. Una propuesta inválida se le
devuelve al modelo para que corrija, con **un solo** reintento.

### Snapshot

Lo construye el cliente. Toda cifra viaja como entero en **unidades menores** con
su `currency` al lado; **nada se agrega entre monedas distintas** (el modelo de
datos es multi-moneda por fila y no hay moneda global del usuario). Fechas unix en
**segundos**. Sin `last4`, sin `institution`, sin notas de transacción.

Una sección que el cliente no pudo leer se **omite** del JSON — nunca se manda
vacía. Un modelo al que se le dice `budgets: []` afirma que no hay presupuestos;
uno al que no se le dice nada simplemente no habla de ellos.

## Probar en local

```bash
supabase functions serve ai-chat --env-file supabase/.env.local --no-verify-jwt
curl -X POST http://localhost:54321/functions/v1/ai-chat \
  -H "Authorization: Bearer $JWT" -H 'Content-Type: application/json' \
  -d @payload.json
```

## Después de aplicar la migración de IA

1. `select * from delete_account_data_coverage_gaps();` → **cero filas**, en dev y en prod.
2. Verificar en el dashboard de PowerSync que las sync rules **no** seleccionan
   `ai_access`, `ai_usage_log` ni `ai_feature_flags`. Es la única parte del
   contrato que no vive en este repo.
3. `get_advisors` para confirmar que `ai_access_state(uuid)` no quedó ejecutable
   por `authenticated` (es `SECURITY DEFINER` y recibe el user id por parámetro).
