# Página: Inicio

Sobreescribe/complementa `design-system/billetudo/MASTER.md` con el detalle específico de esta pantalla. Fuente real: `billetudo.pen`. Requerimientos funcionales en `docs/requirements/04-inicio.md`.

> **Nota de historia:** el diseño original de Inicio (bento con Hero grande + tarjeta de IA + card "Por categoría", y 8 frames de estados) fue **reemplazado** tras una revisión de valor con `ui-ux-reviewer`. Se eligió la composición **"actividad primero"** (variante A): la lista de movimientos recientes pasa a ser protagonista porque es lo más consultado, y el desglose por categoría sale del Home (vive en Gráficas). Los frames viejos se borraron del `.pen`.

## Frames en Pencil

| Frame | Node ID claro | Node ID oscuro | Estado |
|-------|---------------|----------------|--------|
| Inicio — con presupuesto | `aOhoY` | `ls7Ed` | con datos, hero con barra de presupuesto |
| Inicio — sin presupuesto | `A9v7s` | `hceQ1` | con datos, hero con invitación a presupuestar |
| Inicio — vacío | `DliNF` | `dJDHi` | sin transacciones — hero "$0" + `Empty State` |
| Inicio — carga | `AmifS` | `Y5TnWd` | skeletons de hero y filas |

Los frames oscuros se generaron por `Copy()` del claro + `theme:{mode:"dark"}` (todo recoloreó por variable, sin hex hardcodeado). Cualquier cambio de contenido/estructura se hace en el frame claro y se re-aplica al oscuro.

`aOhoY` y `A9v7s` son idénticas salvo el bloque de progreso del hero (barra vs. invitación). El componente de IA completa `AI Assistant` (`yTLHY`) NO se usa en el Home actual pero se **conserva movido al root del documento** para cuando la IA se habilite.

**Componente propio de esta página:** `Transaction Skeleton Row` (`gDAqP`) — fila plana de carga (círculo de icono + 2 líneas + bloque de monto, todo `$skeleton`) que imita la geometría de `Transaction Row` sin card envolvente. Se creó porque `Skeleton Row` (`CKnQC`, usado en Cuentas) es una tarjeta con contenedor y no coincidía con las filas planas de movimientos.

## Estructura (variante A — "actividad primero")

De arriba a abajo, dentro del wrapper `Content` (padding `[6,20]`, gap `16`, `height:fill_container`):

1. **Status Bar** — hora + iconos de sistema (`Status Bar/Android`).
2. **Header** — Avatar (gradiente `$primary`→`$primary-deep`, inicial del usuario) + saludo "Hola de nuevo, [nombre]" + botón de notificaciones (`$surface`, icono `bell`). La campana muestra un aviso **"Próximamente"** al presionarse (aún no hay centro de notificaciones).
3. **Hero Card** (compacta, ~190px) — gradiente `$primary-deep`→`$primary`, radio 28. Label "Gastado en [mes]" + chip selector de mes (área tocable ≥44pt). Monto grande (40px/800, `$on-primary`). Debajo, según el estado:
   - **Con presupuesto (`aOhoY`):** barra de progreso (`$on-primary` sobre `$track-overlay`) + "X% de $Y" + "faltan Z días" (texto secundario 13px/500).
   - **Sin presupuesto (`A9v7s`):** texto de invitación "Define un presupuesto para ver cuánto te queda este mes →" (14px/600, `$font-body`, `$on-primary`; intencionalmente más prominente que las métricas de progreso del otro estado). **No inventa un tope de gasto** — sin presupuesto la app no conoce un límite; en su lugar empuja el hábito de presupuestar.
4. **Movimientos recientes** — header de sección ("Movimientos recientes" + link "Ver todos →" en `$primary-on-soft`, área tocable ≥44pt, que enruta a la pestaña Movimientos). Lista de **5 `Transaction Row`** que agregan los movimientos de **todas las cuentas activas** (no filtra por cuenta). Montos de gasto en `$text-primary` (nunca rojo), ingresos en `$income-text`.
5. **AI Banner** (`$muted`, borde `$border`) — "Pronto: pregúntale a Billetudo →", **directamente debajo de los movimientos recientes** (no anclado al fondo: allá abajo se pierde y compite con el FAB). Estado **"próximamente"**: al presionarlo muestra una alerta/bottom-sheet "Próximamente estará disponible". **No ejecuta IA** ni llama a backend, por lo que no rompe Nivel 0.
6. **Spacer** (`height:fill_container`) — deja el espacio libre debajo del banner; el FAB flota sobre ese espacio sin encimarse al banner.
7. **Tab Bar** — instancia con "Inicio" activo.
8. **FAB flotante** (`$primary`, absolute, abajo-derecha) — abre el formulario de nueva transacción.
   - **Comportamiento de scroll (solo documentado, no se diseña frame aparte):** el FAB está visible en reposo y al hacer scroll hacia arriba; se **oculta al hacer scroll hacia abajo** (para no tapar contenido durante la lectura) y **reaparece al hacer scroll hacia arriba** o al detenerse. Transición suave (fade/slide down ~200ms). Implementación en Flutter (ej. escuchar la dirección del scroll y animar `offset`/`opacity`); no requiere pantalla de diseño propia.

Datos de ejemplo: gasto del mes `$1,297,900`, presupuesto `$3,000,000` (43%, faltan 12 días); movimientos Mercado (`-$82,000`), Netflix (`-$44,900`), Salario (`+$2,100,000`), Uber (`-$18,500`), Café (`-$9,000`).

## Decisiones específicas de esta página

- **Composición "actividad primero" (variante A)** elegida sobre B (dashboard equilibrado con movimientos + categorías) y C (safe-to-spend protagonista). Razón: los movimientos recientes son lo más consultado a diario; el desglose por categoría es análisis más reflexivo que tolera un click extra hacia Gráficas.
- **"Por categoría" NO vive en el Home** — se accede desde Gráficas e informes (`09`). El Home no lo muestra.
- **Hero de gasto siempre protagonista, presupuesto como capa opcional** — el gasto del mes se calcula solo con transacciones, así que el hero funciona con o sin presupuesto. Dos estados (con/sin), no un hero que asume presupuesto mensual siempre presente.
- **IA en modo "próximamente" como banner de una línea** (no la tarjeta completa) — decisión del dueño tras comparar ambas. La tarjeta `yTLHY` se conserva para el futuro. Nunca ejecuta IA en esta fase (Nivel 0 intacto).
- **Sin selector de mes con periodos flexibles en el Home** — el Home se ancla al mes calendario; los periodos `weekly/yearly/custom` de presupuesto se ven en la sección Presupuestos.

## Correcciones de accesibilidad aplicadas (`ui-ux-reviewer`)

- **Tap targets a ≥44pt:** chip de mes y link "Ver todos →" (padding vertical ampliado).
- **Link "Ver todos" en `$primary-on-soft`** (no `$primary` crudo) — seguro en tema oscuro (`$primary` cae a ~3:1 en oscuro).
- **Ingresos en `$income-text`** (~6.4:1) — `$income` habría fallado (~2.07:1).
- **Gastos en `$text-primary`**, nunca `$expense` rojo (tono de marca).
- **Texto secundario del hero a 13px** — holgura de contraste sobre el extremo claro del gradiente.
- **`$font-body` en la invitación** (no `Plus Jakarta Sans` literal) — consistencia de variables.

## Estados de pantalla

Cuatro estados construidos en claro + oscuro (8 frames, tabla arriba). El chrome (Status Bar, Header, Tab Bar, FAB) se mantiene IGUAL entre estados; solo cambia el área de contenido (hero + movimientos).

- **Vacío (`DliNF`/`dJDHi`):** hero en `$0` + subtexto "Aún no hay gastos este mes"; el bloque de movimientos se reemplaza por `Empty State` (icono `receipt`, "Aún no registras movimientos", CTA "Agregar movimiento"). El `Empty State` se **centra en el espacio libre** entre el hero y el tab bar (spacer arriba y abajo). **Sin banner de IA** en este estado — no aporta valor cuando no hay datos. Tono de bienvenida, no punitivo.
- **Carga (`AmifS`/`Y5TnWd`):** skeletons de hero y 5 `Transaction Skeleton Row` planas.
- **No hay estado de Error de pantalla completa** (a diferencia del diseño viejo): HU-10 resuelve el fallo de sync con un **indicador discreto**, porque el Home es local-first y no se vacía sin conexión.

## Interacciones y sub-pantallas

Bottom-sheets y elementos que se accionan desde el Home, todos en claro + oscuro:

| Pieza | Frame claro | Frame oscuro | Detalle |
|---|---|---|---|
| Sheet "Próximamente" (IA) | `ZMNrt` | `Tr8ZF` | Lo abre el banner de IA. `Bottom Sheet Base` + orbe `sparkles` + "Próximamente" + mensaje + disclaimer "No es asesoría financiera" + botón "Entendido". No ejecuta IA (Nivel 0). |
| Sheet "Próximamente" (notificaciones) | `HZTCs` | `Z7WpGJ` | Lo abre la campana (HU-07). Mismo sheet con icono `bell`, "Las notificaciones llegarán pronto", **sin** disclaimer. |
| Selector de mes | `k7kv4` | `iGwrg` | Lo abre el chip de mes (HU-04). Navegador de año ‹ 2026 › + grid 3×4 de meses. |

- **Componente `Month Cell` (`DB3bz`):** celda de mes (mismo espíritu que `Day Cell`). Estados: seleccionado (fill `$primary` + texto `$on-primary`), normal (`$text-primary`), y futuro/deshabilitado (`$text-secondary` + `opacity:0.4`). La flecha del navegador de año que solo lleva a meses futuros se atenúa (`opacity:0.35`).
- **Indicador de sync (HU-10):** vive en el componente `Home Header` (`vYdCt`), así que aparece en las 8 pantallas del Home y en ambos temas. Icono `cloud-check` discreto (`$text-secondary`) junto a la campana. Es **informativo/pasivo** (no es tap target; si a futuro se abre un detalle de sync, envolver en 44pt en Flutter). 3 estados (referencia `KpeGp`): Sincronizado (`cloud-check`), Sincronizando (`refresh-cw`), Sin conexión (`cloud-off`) — discretos y en tono positivo (offline no alarmante; local-first, datos a salvo).

## Pendientes

- **Implementación en Flutter** (`flutter-dev`): el diseño está completo en Pencil (claro + oscuro); pasar a código con este doc + `docs/requirements/04-inicio.md`, incluyendo el cableado de destinos y el comportamiento de scroll del FAB (documentado arriba en la estructura).
- **Override redundante:** el padding del chip de mes (`j6OObr` `[15,12]`) quedó como override de instancia en los 3 hero con contenido además de estar ya en el componente `Hero Compact` — cosmético, theme-agnóstico, sin impacto.
