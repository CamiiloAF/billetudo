# Página: Inicio

Sobreescribe/complementa `design-system/billetudo/MASTER.md` con el detalle específico de esta pantalla. Fuente real: `billetudo.pen`. Requerimientos funcionales en `docs/requirements/fase-1/04-inicio.md`.

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
4. **Acceso rápido** (`Quick Access A`, componente `Quick Access Chip A`) — fila de scroll horizontal justo debajo del Hero, antes de Movimientos recientes. Caption "Acceso rápido" (12px/600, `$text-secondary`) + fila de pills (`$surface` + `stroke:$border`, radio 22, alto 44px, ícono 18px `$text-secondary` + label 13px/600 `$text-primary`, `padding:[13,16]`, gap 8, contenedor `clip:true` para simular el scroll). Cada chip es **navegación directa** (push a una ruta nueva, sin bottom nav bar visible). Ningún chip tiene estado seleccionado/activo (no es un tab). Es **chrome fijo**: aparece igual en los 4 estados de la pantalla.

**Cambios de `bugfixes-0.0.1.md` (2026-07-22):**
- **Orden del Home:** ahora es **Hero → Acceso rápido → tira "Mis cuentas" → Movimientos recientes → AI Banner** (item 8 + reorden a pedido del usuario: accesos rápidos ANTES de la tira de saldos). Frames de la variante con tira: `LktTm` (claro) / `AVgUv` (oscuro). *Deuda de fidelidad:* la tira "Mis cuentas" solo vive en esos frames V2; los canónicos (`aOhoY` etc.) aún no la tienen — falta portarla + sus estados vacío/carga.
- **Tira "Mis cuentas" (item 8):** debajo de Acceso rápido, solo si hay cuentas. Componentes `HomeBalancesStrip` + `BalanceMiniCard` (`EVe8a`): scroll horizontal de mini-cards por cuenta, cada una con **ícono+color por TIPO** (mint/sky/peach/primary-on-soft según `AccountType`, mapeo real de la app) + nombre + saldo. Sin total (multi-moneda Fase 0 no normaliza). Header "Mis cuentas" + "Ver todas" → Cuentas.
- **Acceso rápido (item 7):** el set final es **Pagos programados → Deudas → Gráficas e informes → Metas** (Metas entró como último chip porque Pagos Programados dejó de necesitar chip al entrar al Tab Bar — ver abajo). **Cuentas salió del Acceso rápido** porque la tira "Mis cuentas" que va justo debajo ya cubre ese acceso directo (tener el mismo destino dos veces seguidas era redundante). El código es la fuente de verdad del set exacto de chips.
- **Tab Bar (item 7):** **Pagos Programados reemplazó a Metas** en el bottom nav (ícono `calendar-clock`, label "Pagos"). Metas salió del tab → vive en "Más" + Acceso rápido. Falta actualizar el Tab Bar del `.pen` (`u3b5s9`) — hecho en un pase de sync.
- **Icono de sync interactivo (item 6, HU-10):** el indicador de nube pasó de pasivo a **tappable** (≥44pt). offline sin sesión → login; con sesión → `SyncStatusSheet` **reactivo** (un solo bottom sheet que refleja el `SyncState` en vivo: `synced`→"Todo a salvo", `syncing`→"Sincronizando…", `offline`→"Sin conexión"; cambia en sitio sin cerrarse). Frames: `CaLYm`/`WAW55`/`nzxqu` (claro), `NdZ9M`/`G07puo`/`oanys` (oscuro). Mensaje simple/honesto, sin detalle por-entidad (el `SyncState` es grueso a propósito).
5. **Movimientos recientes** — header de sección ("Movimientos recientes" + link "Ver todos →" en `$primary-on-soft`, área tocable ≥44pt, que enruta a la pestaña Movimientos). Lista de **5 `Transaction Row`** que agregan los movimientos de **todas las cuentas activas** (no filtra por cuenta). Montos de gasto en `$text-primary` (nunca rojo), ingresos en `$income-text`.
6. **AI Banner** (`$muted`, borde `$border`) — "Pronto: pregúntale a Billetudo →", **directamente debajo de los movimientos recientes** (no anclado al fondo: allá abajo se pierde y compite con el FAB). Estado **"próximamente"**: al presionarlo muestra una alerta/bottom-sheet "Próximamente estará disponible". **No ejecuta IA** ni llama a backend, por lo que no rompe Nivel 0.
7. **Spacer** (`height:fill_container`) — deja el espacio libre debajo del banner; el FAB flota sobre ese espacio sin encimarse al banner.
8. **Tab Bar** — instancia con "Inicio" activo.
9. **FAB flotante** (`$primary`, absolute, abajo-derecha) — abre el formulario de nueva transacción.
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

## Hero Period Stepper — reemplazo del selector de mes (aprobado, claro + oscuro)

**Contexto del cambio:** el hero de Inicio reemplaza su selector de mes calendario (`MonthSelectorChip`/`MonthPickerSheet`, eliminados) por un **stepper de período** que navega la ventana REAL del presupuesto destacado (`BudgetPeriodWindow`, con ancla de día personalizada) cuando hay uno. "Movimientos recientes" ya no se filtra por mes.

- **Variante elegida — "B: Adaptada on-primary".** Vive integrada directo sobre el degradado del hero (no una pastilla `$surface` separada como el stepper de Presupuestos). Chevrones en círculos `$surface` sólido (44×44) con ícono `$text-primary` — mismo patrón ya aprobado del botón de campana del Header. Rango de fechas 13px/700 `$on-primary`, texto de estado "· vigente" 13px `$on-primary` (subido de 12 a 13px por holgura de contraste, mismo criterio ya documentado para el texto secundario del hero).
- **Posición:** en medio del bloque del hero — balance (con kicker "Gastado" 12px/600 `$on-primary` restituido sobre el monto) → stepper de período → barra de progreso. Se descartaron arriba (le robaba protagonismo al monto) y abajo (dejaba sin contexto el periodo hasta el final).
- **Ajustes de layout:** gaps reducidos en `Content` (16→12), `Hero` (14→10) y filas de Movimientos (14→10) para acomodar el contenido nuevo sin overflow.
- **Cuándo se muestra:** solo si hay presupuesto destacado (automático o manual) con progreso visible. Sin presupuesto destacado, el hero sigue mostrando el selector de mes calendario (chip + hoja, ver "Interacciones y sub-pantallas" abajo) — **no** cae a un total estático sin navegación.
- **Interacción:** tocar el hero completo (cuando hay presupuesto destacado) navega al detalle de ese presupuesto — no a una lista de movimientos filtrados.
- **Nodo IDs de referencia:** frame claro `xBv3N` ("Inicio — Hero Period Stepper (Final, tema claro)"), kicker `zoZcf`/`Pi7t6`, stepper `diOFU`, chevrones `a09pi`/`A11npZ`, texto de estado `b9eQy`. Frame oscuro `oMXhw` (paridad estructural 1:1, misma jerarquía de nodos recoloreada por variable — sin overrides manuales, no había sombra ni skeleton que ajustar por tema en este frame). Ambos frames viven físicamente en la zona de Presupuestos del canvas (`ItgUN`), no en la zona de Inicio — decisión de organización del canvas, no cambia a qué pantalla pertenece en la app.
- **Estado:** tema claro y oscuro **aprobados** (2026-08-07).
- **Pendiente de portar:** los ajustes de gap y el stepper completo aún no están portados a los frames canónicos de Inicio (`aOhoY`/`A9v7s` desactualizados; `LktTm`/`AVgUv` son los V2 vigentes con la tira "Mis cuentas" — deuda de fidelidad ya anotada, este cambio la extiende).

> **Nota:** este stepper reemplaza el selector de mes solo cuando hay presupuesto destacado con progreso visible (`progress != null`). Sin presupuesto destacado, el chip + hoja documentados en "Interacciones y sub-pantallas" (`k7kv4`/`iGwrg`, `Month Cell` `DB3bz`) siguen siendo el diseño **vigente**, no histórico — es el fallback activo del hero, ver nota de "Cuándo se muestra" arriba.

## Etiqueta de presupuesto destacado en el Hero (aprobado, tema claro)

**Contexto:** hallazgo de producto sobre discoverability — el usuario no tenía forma de saber, mirando el hero de Inicio, qué presupuesto específico alimentaba el monto/progreso mostrado (ver `pages/presupuestos.md` § "Destacar presupuesto en Inicio" → "Discoverability"). Primer intento: un kicker tipo pill/botón tocable con chevron ("★ Mercado del mes ›"). Descartado por `ui-ux-reviewer` y el usuario: en `aOhoY`/`LktTm` competía con el chip de mes viejo, y en `xBv3N` el chevron sugería un destino de navegación distinto al del resto del hero (que ya es tocable en su totalidad hacia el mismo lugar) — confuso.

**Solución aprobada:** texto plano informativo, mismo tratamiento tipográfico que el resto del texto secundario del hero (12px/600, `$on-primary`), sin fondo/ícono/chevron — no es un control independiente, es una etiqueta.

- `aOhoY`: nuevo nodo `ZnfMf` ("Featured Budget Label", "Mercado del mes") como primer hijo de `Hero` (`IVytg`), encima de "Gastado en julio".
- `LktTm`: nuevo nodo `c4q4mY`, mismo tratamiento, en `Hero` (`wl9OW`).
- `xBv3N` (ya tiene el stepper de período): no se agregó línea nueva — se reutilizó el kicker "Gastado" existente (`zoZcf`), cuyo contenido pasó de `"Gastado"` a `"Gastado en Mercado del mes"`, para no competir en espacio vertical con el stepper de abajo.
- **Cuándo se muestra:** solo cuando hay presupuesto destacado con progreso visible — mismo condicional que el resto del bloque de progreso/stepper.
- **Interacción:** ninguna propia — es texto informativo; tocar el hero (en su totalidad) sigue navegando al detalle del presupuesto destacado, sin ambigüedad de "dos controles".
- **Estado:** tema claro **aprobado** por el usuario (2026-08-07). Tema oscuro pendiente.

## Pendientes

- **Portar Hero Period Stepper a los frames canónicos:** el stepper aprobado en `xBv3N`/`oMXhw` (claro+oscuro, ver sección "Hero Period Stepper") reemplaza el chip de mes **solo cuando hay presupuesto destacado**; falta portarlo a `aOhoY`/`A9v7s`/`LktTm`/`AVgUv` (o al frame que quede como canónico tras resolver esa deuda de fidelidad) y generar la copia oscura de esos frames canónicos, solo después de que esta migración esté cerrada en claro. El caso sin presupuesto destacado no se toca — sigue usando el chip ya presente en esos mismos frames.
- ~~**Restaurar en Flutter el selector de mes para el caso sin presupuesto destacado**~~ — resuelto: `MonthSelectorChip`/`MonthPickerSheet`/`MonthCell` restaurados en `lib/features/home/presentation/widgets/`, cableados en `home_hero_card.dart`/`home_page.dart`/`home_cubit.dart` (commit `2f4ac2c`).
- **Acceso rápido — replicar a Vacío/Carga y a tema oscuro:** la fila `Quick Access A` solo existe hoy en `aOhoY` y `A9v7s` (tema claro). Falta insertarla en `DliNF`/`AmifS` (vacío/carga, mismo tratamiento chrome-fijo) y generar su copia oscura junto con el resto de la pantalla, al final del flujo de diseño (ver "Orden de lectura" en `CLAUDE.md`).
- **Orden de accesos configurable (futuro, fuera de alcance de este diseño):** el usuario quiere poder reordenar los 4 accesos directos desde Ajustes más adelante. No cambia el diseño visual del chip ni de la fila — es una feature de datos/preferencias de usuario. Ver nota en `docs/requirements/fase-1/04-inicio.md` § Pendiente.
- **Implementación en Flutter** (`flutter-dev`): el diseño está completo en Pencil (claro + oscuro); pasar a código con este doc + `docs/requirements/fase-1/04-inicio.md`, incluyendo el cableado de destinos y el comportamiento de scroll del FAB (documentado arriba en la estructura).
- ~~**Implementar la etiqueta de presupuesto destacado en el Hero** + el resto del paquete de discoverability de `pages/presupuestos.md` § "Discoverability"~~ — resuelto: etiqueta en `home_hero_card.dart` (`l10n.homeHeroSpentInFeaturedBudget`), fix del mismatch del badge en la lista, auto-selección del primer presupuesto, minitutorial al crear el segundo, y badge también en el hero del detalle de presupuesto (`budget_detail_page.dart`).
- **Override redundante:** el padding del chip de mes (`j6OObr` `[15,12]`) quedó como override de instancia en los 3 hero con contenido además de estar ya en el componente `Hero Compact` — cosmético, theme-agnóstico, sin impacto.
