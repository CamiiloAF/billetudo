# Página: Splash / Launch Screen

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** **Decisión final, ambos temas — aprobada (2026-07-20, `ui-ux-reviewer`).**

## Contexto de producto

Pantalla de tránsito fijo que se muestra al arrancar la app mientras carga el estado local
(Drift) y hace el handshake de sync (PowerSync) — duración variable e impredecible, no
determinada. No es un destino de tab ni una pantalla apilada: no lleva `Page Header` ni
`Tab Bar`. No tiene variantes de error/vacío — no consulta datos que puedan fallar de forma
visible al usuario en esta pantalla.

## Frames

| Pantalla | Node ID (Claro) | Node ID (Oscuro) | Estado |
|---|---|---|---|
| Splash — Wordmark + carga (**ganadora**) | `bSOQb` | `raS94` | Decisión final, ambos temas |

**Historial de variantes exploradas** (regla de MASTER: no dejar variantes a medias en el
canvas — ninguna sobrevive salvo la ganadora de arriba):
- **Variante A — Minimalista** (eliminada): fondo `$primary`→`$primary-deep` a pantalla
  completa, `Coin Glyph` grande (120px) centrado, caption + spinner circular en
  `$on-primary`. Descartada por preferencia de wordmark protagonista sobre fondo claro.
- **Variante C — Tile + Progreso** (eliminada): `App Icon Tile` + wordmark chico arriba,
  barra de progreso horizontal + caption cerca del fondo. Fue la primera elección del
  usuario, luego revertida a favor de un wordmark protagonista sin ícono de tile
  acompañando (variante B).

## Estructura (`bSOQb` claro / `raS94` oscuro, misma composición)

De arriba a abajo, dentro de `Content` (`height:fill_container`, sin `Page Header` ni
`Tab Bar`):

1. **Status Bar** (`vYZJT`, `Status Bar/Android`).
2. **Brand Block** (`hg0l8`, centrado en el 50% del alto disponible): instancia de
   **`Logo Wordmark`** (`y5JJtf`, reusable) a tamaño protagonista (`fontSize:56`) —
   "billetudo" construido con texto real (Plus Jakarta Sans 800, `letterSpacing:-2`), no
   como imagen pegada. La "i" no lleva su punto natural; en su lugar, `Coin Glyph` (`U60Oq`,
   reusable — círculo `$primary`→`$primary-deep` con aro `$primary-light`) hace de punto,
   posicionado en `layoutPosition:"absolute"` sobre la "ı" sin punto (`H9Gwq`).
   - *Nota de fidelidad para `flutter-dev`:* `snapshot_layout` reporta el coin dot como
     "partially clipped" — es un overflow decorativo de ~2px por el posicionamiento
     absoluto dentro del contenedor `fit_content` de la "ı", preexistente y no bloqueante
     (confirmado visualmente, no afecta legibilidad). En Flutter no hace falta replicar el
     offset exacto en px de Pencil — un `Positioned`/`Stack` normal alineando el centro del
     coin sobre el ápice de la "ı" es suficiente.
3. **Bottom Block** (`KEolH`, bloque secundario, `y:820` dentro de los 972px del frame —
   ~90px de margen inferior seguro para gesture bar/home indicator):
   - **Loading Spinner** (`QqHXB`): `ellipse` 36×36, `innerRadius:0.82`, `sweepAngle:270`
     (arco tipo spinner indeterminado), `fill:"$primary"`.
   - **Loading Caption** (`M0TfmS`): "Cargando tus finanzas..." en `$text-secondary`,
     13px/500, `$font-body`.

## Decisión de diseño: spinner indeterminado, no barra de progreso

Evaluado explícitamente por `ui-ux-reviewer` (el usuario tenía preferencia personal por la
barra, pero delegó el veredicto final en el reviewer):

- En el resto de `billetudo.pen`, la **barra horizontal** (`Track`/`Fill`) se usa
  exclusivamente para **progreso determinado con dato real** (% de presupuesto gastado, %
  de meta cumplida — `Budget Line`, `Goal Panel`), siempre acompañada de una cifra concreta.
  Usarla en Splash sería un uso semánticamente indebido del componente.
- El **spinner/ícono circular indeterminado** es el patrón ya establecido para esperas de
  duración desconocida (ver el botón "Google Button (Cargando)" en Auth, `loader-2` de
  lucide) — mismo lenguaje visual que el spinner del splash.
- El arranque de Drift + el handshake de PowerSync es de duración variable. Una barra de
  progreso prometería implícitamente "sé cuánto falta", lo cual es falso aquí — si se queda
  pegada esperando la sync, se percibe como un cuelgue, contrario al tono "positivo, nunca
  genera ansiedad" de `CLAUDE.md`.

## Tratamiento de marca en oscuro

- Generado como `Copy()` de `bSOQb` con `theme:{mode:"dark"}`, **sin overrides manuales de
  color** — confirma que todo el frame claro estaba correctamente enlazado a variables.
- Componentes reusados (`Logo Wordmark`, `Coin Glyph`, `Status Bar/Android`) recolorean
  solos, ya soportan ambos temas por sus propias variables.
- Contraste verificado contra `MASTER.md`: `$text-secondary` oscuro (`#9A98B5`) sobre
  `$background` oscuro (`#14141F`) ~5.8:1 (AA texto normal); `$primary` oscuro (`#6D4FE0`)
  para el coin dot y el spinner, uso decorativo/icónico (≥3:1).

## Pendiente (fuera de alcance de diseño visual)

- Duración del splash y lógica de transición a Home/Auth: responsabilidad de
  `flutter-dev`/`architect`, no de esta spec.
