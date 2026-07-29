# Página: Onboarding (flujo de bienvenida)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras 2 rondas de conceptos, refinamiento del elegido y 2 pases de `ui-ux-reviewer`. Requisitos en `docs/requirements/13-onboarding.md`. No confundir con `design-system/billetudo/pages/primer-arranque.md` (pantalla de "sin conexión" del primerísimo arranque, independiente y anterior a este flujo).

## Tesis (norte del diseño)

**"La billetera que se llena"**: la promesa financiera se representa como un abanico de tarjetas que crece una por paso (1→2→3→4), en vez del patrón genérico icon-circle + headline + subtítulo que se descartó en la primera ronda de conceptos por sentirse sin personalidad ("checklist de 4 pantallas planas"). Sobre la tarjeta superior de cada paso viaja un badge de estado (`+` en Cuenta, nube en Respaldo, check en Cierre) que resume la acción de esa pantalla. Pensado para animarse en la implementación: la tarjeta frontal de una pantalla se convierte en la tarjeta trasera de la siguiente (transición tipo hero/shared-element), no un crossfade — ver "Notas de animación para `flutter-dev`".

Reglas de tono que gobiernan el copy de las 6 pantallas: texto mínimo (una idea por pantalla, sin párrafos), "Nivel 0" nunca se presenta como "toda la app" (solo lo esencial es gratis para siempre — coherente con que sí habrá Premium/anuncios opt-in más adelante), y ningún mensaje de riesgo/pérdida de datos suena a amenaza (tono informativo, no punitivo).

## Frames

Todas las pantallas existen en tema Claro y su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido/estructura, solo recolorea — sin overrides manuales de color, verificado por `ui-ux-reviewer`).

| Pantalla | Claro | Oscuro |
|---|---|---|
| 1 — Bienvenida (HU-01, con enlace "Ya tengo cuenta" de HU-06) | `fRrDQ` | `mmFVh` |
| 2 — Tu primera cuenta (HU-02, default Ahorros/`savings`) | `G7vDVK` | `c2wua2` |
| 2b — Tu primera cuenta · Tarjeta de crédito seleccionada (referencia: campos condicionales cupo/día de corte/día de pago + label "Deuda actual") | `O2QbEF` | `yClJt` |
| 3 — Respalda tus datos (HU-07) | `MydOr` | `DfHXL` |
| 4 — Cierre: primer movimiento (HU-04) | `Gi0NV` | `Bylcp` |
| 4b — Cierre · Cuenta omitida (referencia: CTA cambia a "Crea tu primera cuenta" cuando el paso 2 se omitió) | `bAKS6` | `ld3xh` |

HU-03 (categorías semilla) no tiene pantalla propia — se menciona en una línea dentro de Bienvenida ("Ya dejamos categorías listas para ti."). HU-05 (niveles de pago) está congelada y no aparece en ninguna pantalla.

## Componentes nuevos (reusable:true)

- **`Onboarding Top Bar`** — Back Wrap (oculto en Bienvenida, visible en el resto) + 4 progress dots + spacer derecho. Reemplazó 6 instancias duplicadas a mano tras un hallazgo de `ui-ux-reviewer` (el indicador de progreso mal calibrado en una variante descartada habría sido más difícil de introducir por accidente si el componente hubiera existido desde el inicio).
- **`Onboarding Secondary Link`** — el link secundario ("Ya tengo cuenta" / "Omitir por ahora" / "Después" / "Lo hago después"), `padding:[14,16]` → ~46pt de alto, corrigiendo un hallazgo de touch-target (mínimo 44pt) detectado en la primera ronda de conceptos.
- **`Onboarding Wallet Card`** — la tarjeta con gradiente `$primary`→`$primary-deep` del motivo "billetera que se llena", instanciada con overrides de rotación/opacidad para el efecto de abanico.

## Decisiones cerradas durante el diseño (no repetir la discusión)

- **Default de la primera cuenta: Ahorros/`savings`, no Efectivo/`cash`.** Cambiado el 2026-07-29 sobre la decisión original de `docs/requirements/13-onboarding.md` — es el tipo de cuenta más común entre usuarios reales. Nombre, tipo, moneda (según región del locale) y saldo ($0) siguen siendo pre-llenados y editables; el mockup muestra COP como ejemplo de moneda, la real se deriva en runtime.
- **Sin "Agregar otra cuenta" en el flujo.** Cambiado el 2026-07-29 — permitir crear varias cuentas alargaba el onboarding sin necesidad; agregar cuentas adicionales es tarea normal de mantenimiento en Cuentas, no del arranque. El paso 2 crea como máximo una cuenta y avanza. (La pantalla de referencia que existió brevemente para este estado dejaba Tipo/Nombre vacíos en la segunda cuenta —para no duplicar en silencio el default "Ahorros"— mientras Moneda/Saldo seguían prellenados; queda como nota histórica, sin efecto real una vez eliminada la pantalla completa.)
- **Tipo de cuenta como campo de formulario, no como chip "ya asentado".** El campo "Tipo de cuenta" en `G7vDVK` usa el mismo componente `Form Field` que Nombre/Moneda/Saldo (no el chip colapsado que usa Cuentas en modo Editar) — para que el paso se lea como invitación a completar/editar, no como una decisión ya tomada por la app.
- **Tarjeta de crédito no relaja las reglas de dominio de Cuentas.** Si el usuario elige `card` en el paso 2, aparecen cupo máximo, día de corte y día de pago (obligatorios), y el campo de saldo cambia su label a "Deuda actual" — mismo comportamiento que el formulario real de `pages/cuentas.md`, sin excepciones. Ver `O2QbEF`.
- **Contraste de badges Plus/Check sobre `$income`:** el ícono blanco (`$on-primary`) medía ~2:1 en ambos temas — corregido a glifo oscuro fijo `#1C1B29` (no ligado a variable de tema, mismo criterio ya documentado en `MASTER.md` para el check sobre swatches de color de cuenta) en las 8 instancias del flujo. Resultado: ~7.4:1 claro, ~8.8:1 oscuro. **Nota:** el badge no está componentizado (8 instancias sueltas) — si se reutiliza en más pantallas, componentizarlo antes de duplicar el patrón otra vez.
- **Copy final del subtítulo de Cierre** (`Gi0NV`/`Bylcp`, nodo `m625C`), editado manualmente por el dueño de producto tras varias iteraciones: *"Registra tu primer movimiento y empieza a tomar el control de tu dinero."*

## Notas de animación para `flutter-dev`

No simuladas como frames estáticos adicionales (se mantuvo un frame por pantalla, sin multiplicar estados de transición) — descritas aquí como intención de diseño:

- **Entrada de las tarjetas del abanico:** stagger con spring — la tarjeta trasera entra primero, la frontal ~80ms después.
- **Badge de estado** (`+` / nube / check) sobre la tarjeta superior: pop-in con scale-bounce.
- **Transición entre pantallas:** la tarjeta frontal de la pantalla actual debería animarse/transformarse en la tarjeta trasera de la siguiente (shared-element/hero transition), no un crossfade — es el elemento central de la metáfora "la billetera que se llena".

## Pendiente / fuera de alcance de Pencil

- **Interacción real de los selectores** (tipo de cuenta, moneda, día de corte/pago dentro de `Form Field`) — bottom sheet vs. otro patrón, decisión de `flutter-dev` al implementar, igual que en Cuentas.
- **El puente/gate real cuando falta una cuenta** (`docs/requirements/15-gate-cuenta.md`) no tiene diseño propio en Pencil todavía. `bAKS6` (Cierre · Cuenta omitida) usa copy genérico y seguro ("Para registrar movimientos necesitas una cuenta. Crea la primera en un momento.") que no debería quedar desincronizado cuando ese documento se diseñe, pero vale confirmarlo cuando llegue su turno.
- **Moneda prellenada:** el mockup siempre muestra COP; la app deriva la moneda real de la región del locale del dispositivo en runtime (ver criterio de aceptación HU-02).
