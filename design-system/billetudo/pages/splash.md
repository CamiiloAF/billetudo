# Página: Splash / Launch Screen

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** **Decisión final, ambos temas — aprobada (2026-08-19, usuario).** Reemplaza la
decisión de 2026-07-20 (wordmark solo, sin ícono) — ver historial abajo.

## Contexto de producto

Pantalla de tránsito fijo que se muestra al arrancar la app mientras carga el estado local
(Drift) y hace el handshake de sync (PowerSync) — duración variable e impredecible, no
determinada. No es un destino de tab ni una pantalla apilada: no lleva `Page Header` ni
`Tab Bar`. No tiene variantes de error/vacío — no consulta datos que puedan fallar de forma
visible al usuario en esta pantalla.

## Frames

| Pantalla | Node ID (Claro) | Node ID (Oscuro) | Estado |
|---|---|---|---|
| Splash — Ícono + Wordmark + carga (**ganadora**) | `QUsfN` | `U0WjJ` | Decisión final, ambos temas |

## Estructura (`QUsfN` claro / `U0WjJ` oscuro, misma composición)

De arriba a abajo, dentro de `Content` (`height:fill_container`, sin `Page Header` ni
`Tab Bar`):

1. **Status Bar** (instancia de `Status Bar/Android`, `vYZJT`).
2. **Brand Block** (centrado en el 50% del alto disponible, `layout:horizontal`,
   `alignItems:center`, `gap:14`):
   - **App Icon** (instancia de `App Icon Tile`, `ZiNl0`, 48×48): el ícono real de la app
     (billete + moneda, `assets/branding/ic_launcher_master.png` como `fill`), no una
     reconstrucción dibujada.
   - **Wordmark Text**: "Billetudo" plano (Plus Jakarta Sans 800, `fontSize:44`,
     `letterSpacing:-2`), sigue siendo el elemento más grande del bloque — el ícono
     acompaña, no reemplaza al wordmark como protagonista.
3. **Bottom Block** (bloque secundario, `y:820` dentro de los 972px del frame — sin
   cambios respecto a la decisión anterior):
   - **Loading Spinner**: `ellipse` 36×36, `innerRadius:0.82`, `sweepAngle:270` (arco tipo
     spinner indeterminado), `fill:"$primary"`.
   - **Loading Caption**: "Cargando tus finanzas..." en `$text-secondary`, 13px/500,
     `$font-body`.

## Historial de variantes exploradas (2026-08-19)

Regla de MASTER: no dejar variantes a medias en el canvas — ninguna sobrevive salvo la
ganadora de arriba. Motivador del cambio: el usuario quería que el splash "tuviera más
vida" (animación de entrada) apoyándose en el ícono de marca ya actualizado (con moneda).

- **Variante A — Ícono primero** (eliminada, `iITru`): `App Icon Tile` 88px centrado
  arriba, wordmark debajo. Descartada — el usuario prefirió el ícono acompañando en línea
  en vez de antecediendo verticalmente.
- **Variante C — Solo ícono** (eliminada, `hgDiK`): solo `App Icon Tile` 152px, sin
  wordmark de texto separado. Descartada — se prefirió mantener "Billetudo" en texto
  explícito para el reconocimiento de marca en el instante de arranque.
- **Variante B — Ícono integrado (ganadora)**: pasó a ser la decisión final, ver arriba.

**Decisión anterior (2026-07-20, retirada):** wordmark solo (`bSOQb`/`raS94`), sin ícono —
ver `docs/branding.md` para el historial completo de marca.

*Nota histórica sobre el wordmark:* hasta 2026-08-18 iba en minúscula y su "i" (una "ı" sin
punto, U+0131) era dotada por `Coin Glyph` (`U60Oq`), retirado junto con la dirección de
identidad anterior — ver `assets/branding/MARCA.md` y `docs/branding.md`.

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

- Generado como `Copy()` de `QUsfN` con `theme:{mode:"dark"}` (`U0WjJ`), **sin overrides
  manuales de color** — confirma que todo el frame claro estaba correctamente enlazado a
  variables.
- Componentes reusados (`App Icon Tile`, `Status Bar/Android`) recolorean solos, ya
  soportan ambos temas por sus propias variables. El ícono de app en sí **no cambia entre
  temas** (es el ícono real de la app, mismo asset siempre) — solo el fondo/texto de la
  pantalla siguen el tema.
- Contraste verificado contra `MASTER.md`: `$text-secondary` oscuro (`#9A98B5`) sobre
  `$background` oscuro (`#14141F`) ~5.8:1 (AA texto normal); `$primary` oscuro (`#6D4FE0`)
  para el spinner, uso decorativo/icónico (≥3:1).

## Animación de entrada (implementación, no diseño estático)

Pencil no renderiza movimiento — este bloque es la spec de comportamiento que
`flutter-dev` implementa sobre el keyframe estático de arriba. Energía **sutil /
profesional** (decisión del usuario, 2026-08-19): nada lúdico ni rebote, coherente con una
app financiera seria.

- **Qué entra:** el `Brand Block` completo (ícono + wordmark juntos, como una unidad — no
  animar el ícono y el texto por separado, se diseñaron como un solo bloque con `gap:14`).
- **Cómo:** fade-in (`opacity` 0→1) + scale-in sutil (`0.92→1.0`), sin overshoot. Curva
  `Curves.easeOut` (o `easeOutCubic`). Duración **450ms**.
- **Cuándo:** arranca apenas se pinta el frame (no espera ningún evento de `bootstrap()`).
  El `Bottom Block` (spinner + caption) puede aparecer con un fade simple más corto
  (200ms) y un pequeño delay (~150ms) respecto al `Brand Block`, para dar sensación de
  secuencia sin que se sienta lento — evitar que ambos aparezcan simultáneos y "de golpe".
- **Salida:** no se especifica transición de salida aquí — depende de cómo resuelva
  `flutter-dev`/`architect` la navegación a Home/Auth cuando `bootstrap()` termina (fuera
  de alcance de esta spec visual, ver pendiente abajo).
- **Qué NO animar:** el spinner ya tiene su propia animación continua (rotación
  indeterminada) — no se le agrega nada más encima. No animar el `Status Bar` (decorativo
  de la barra de sistema).

## Pendiente (fuera de alcance de diseño visual)

- Duración del splash: `AppBootstrapGate` (`lib/core/bootstrap/app_bootstrap_gate.dart`)
  no tiene piso mínimo de tiempo en pantalla — el swap a la app real ocurre apenas
  `bootstrap()`'s `_initApp` resuelve. La animación de entrada (800ms en total) es
  oportunista/best-effort: se ve completa en un arranque "frío" que tarda más que ella,
  pero en un arranque "tibio" (rápido) puede quedar cortada a la mitad o no llegar a
  empezar, y eso es intencional. billetudo prioriza la velocidad de apertura sobre lucir
  la animación completa — un piso artificial que retrasara el arranque solo para que la
  animación termine de jugar iría en contra del propósito del producto (captura rápida
  de gastos, sin la fricción que YNAB sí tiene).
- El ícono de app (moneda + ancho del billete) quedó resuelto en `docs/branding.md`
  (entrada 2026-08-19c). Pendiente menor que queda ahí, no aquí: que
  `ic_launcher_fg.png` nazca ya a la escala correcta en la fuente externa en vez de
  depender del parche mecánico de reescalado aplicado dos veces.
