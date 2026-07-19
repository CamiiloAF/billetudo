# Página: Presupuestos

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`. Requisitos: `docs/requirements/06-presupuestos.md`.

**Estado:** **aprobado** (tema claro + tema oscuro). Diseño cerrado tras múltiples rondas de refinamiento y auditoría con `ui-ux-reviewer` (paridad claro↔oscuro verificada, contrastes AA, sin hex hardcodeados). Listo para `flutter-dev`.

## Frames

Cada pantalla tiene su par claro→oscuro. El tema oscuro vive en la banda `Zona — Presupuestos (Oscuro)` (`Q9o9pz`), separada abajo del canvas claro.

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Lista — con datos | `s833Gk` | `vfPbV` |
| Lista — vacío | `Zqsi1` | `zIijv` |
| Lista — carga (skeleton) | `L8A868` | `QiUJe` |
| Formulario — Nuevo presupuesto | `a3gGPM` | `AHGQc` |
| Ref. bloque "Repetir → Una única vez" | `C6SRE` | `c13OZ` |
| Ref. estado "Todo" (global) | `yfy35` | `u6RBA9` |
| Detalle — recurrente sano | `NloPT` | `vHIu4` |
| Detalle — sobregasto | `DN0GV` | `zW1s4` |
| Detalle — una única vez | `QLn6w` | `A5O26l` |
| Histórico de presupuestos cerrados | `KfPyk` | `g2qP7` |
| Modo sobres (base-cero) | `D1G5hl` | `YiBcF` |
| Sheet — acciones del detalle (⋮) | `G26c4T` | `f1WviW` |
| Sheet — umbral de alerta | `m3jomu` | `GNQ49` |
| Sheet — elegir ícono | `XsnnD` | `Al6tQ` |
| Sheet — info "¿Qué es el modo sobres?" | `eBwb0` | `gAetG` |
| Menú lista (⋮ header) | `TmOGV` | `cOcbC` |
| Menú modo activo | `tFZyK` | `qJAka` |
| Fila en Ajustes ("Modo sobres") | `r5aVv` | `GZUqi` |
| Sheet — eliminar presupuesto | `hxkUC` | _pendiente (tema oscuro aún no existe)_ |

**Componentes reutilizables** (temáticos, sin variante oscura separada):
- `Budget Line` (`FSL69`) — fila de presupuesto en la lista.
- `Budget Skeleton Row` (`iVri4`) — placeholder de carga; usa token `$skeleton` (NO `$border`, invisible en oscuro).
- `Archived Budget Row` (`Ote7d`) — fila del histórico.

## Navegación

Presupuestos es **destino de `Tab Bar`** (uno de los 5 ítems). La lista lleva **header custom** ("Presupuestos" + botón `+`) **+ `Tab Bar`**, SIN `Page Header`. El detalle, el formulario y el histórico (subsecciones) usan `Page Header` con botón atrás, sin `Tab Bar` (mismo patrón que Cuentas).

## Lenguaje visual (aplica a TODAS las pantallas de la feature)

Norte de limpieza: **Inicio** (`aOhoY`) — casi todo blanco/superficie, un solo acento, mucho aire. De obligado cumplimiento.

### Modelo de color — SOBRIO (no semáforo)
- **Un solo acento de marca:** el progreso "sano" SIEMPRE en **violeta `$primary`**. Prohibido verde/ámbar/semáforo por cercanía al límite (se probó y ensució).
- **Rojo solo en sobregasto (>100%)**, con la familia **semántica `expense`** (nunca `$coral` decorativo): barra `$expense`, icon-wrap `$expense-soft`, monto y `%` en `$expense-text`. Solo la tarjeta/hero excedido se vuelve rojo → el rojo es **señal con significado**, no color ambiental. Nunca pintar el fondo de la tarjeta de rojo.
- **Nunca un badge/pill de color** para el `%` ni chips de color para el alcance (ambos se probaron y ensuciaron). El color vive en la barra/indicador y, en sobregasto, en el texto.
- **Icon-wrap neutro `$muted`** idéntico en todas las tarjetas (sin arcoíris de categorías). Única excepción: `$expense-soft` en sobregasto. Por eso `Budgets` guarda `icon` pero **no** `color`.

### Copy y tono (positivo, nunca punitivo — CLAUDE.md)
- Dato primario del restante: **"Te quedan $X"** (sano) / **"Excedido por $X"** (sobregasto). **Prohibido "Te pasaste"** (en es-CO se lee como reproche).
- **Ancla temporal del periodo** (línea meta), según recurrencia:
  - **Recurrente:** "se reinicia el [fecha]" (ej. "se reinicia el 21") — el borrón y cuenta nueva.
  - **Una única vez (no recurrente):** "termina el [fecha]" — no se reinicia, se acaba en `endDate`.

## Lista de presupuestos (`s833Gk` / `vfPbV`)

Componente `Budget Line` (`FSL69`): **3 datos + barra**, no más.
- **Línea 1:** icono (icon-wrap `$muted`) + **nombre** (izq) + stack **"Te quedan / $X"** o **"Excedido por / $X"** (der).
- **Línea 2 (meta, 12px `$text-secondary`):** **alcance corto · ancla temporal · %** en una sola línea. El `%` va gris (`$text-secondary`) en sano y rojo (`$expense-text`) en sobregasto.
- **Barra** de progreso delgada (`$primary` sano / `$expense` sobregasto).
- **Al detalle, NO a la lista:** gastado, total, periodicidad, umbral, desglose. La lista es para decidir "¿puedo seguir gastando?".
- Aire: padding de card ~18, gap ~18, borde `$border` 1px, radio 20, fondo `$surface` dominante.
- **Sin resumen agregado permanente** ("$X presupuestado este mes" sumando todos): es engañoso porque los presupuestos tienen periodos distintos, se solapan (doble conteo) y son multi-moneda. Solo válido en Modo sobres (HU-06). No usarlo como hero de la lista.

**Punto de entrada a crear:** fila-CTA **"+ Nuevo presupuesto"** al final de la lista (círculo `$surface` + `plus`, fondo `$primary-soft`, borde `$primary-light`, label `$primary-on-soft-strong` para pasar contraste AA). Reemplaza al FAB en esta pantalla.

## Detalle de presupuesto (`NloPT` / `vHIu4`; sobregasto `DN0GV`/`zW1s4`; única vez `QLn6w`/`A5O26l`)

Orden vertical: `Page Header` (atrás + **"⋮"**) → **hero de progreso** → **actividad del periodo** → **pastilla flotante de periodo** (abajo).

- **Hero de progreso — patrón compacto:** dato primario **"Te quedan $X"** + barra, y **debajo de la barra una sola caption de 2 partes** al estilo del Hero de Inicio (`HC Prog Row`): izq **"82% · $492.000 de $600.000"**, der **"Restan 18 días"**. **Prohibido** desglosar esas cifras en varios `Info Row`/chips apilados (se probó y saturó). Sobregasto → familia semántica `expense` (hero rojo).
- **Stepper de periodo (HU-05) — pastilla flotante inferior:** NO es una fila arriba ni una barra de ancho completo (evita confundirse con la `Tab Bar`). Es una **píldora centrada flotante anclada abajo**, con el rango explícito del ciclo del propio presupuesto + estado: `‹ 1–31 jul · vigente ›` (la tarjeta sería "21 jul – 20 ago"), NO un mes calendario global. Siempre visible mientras la actividad scrollea. Controla qué periodo reflejan el hero y la actividad. Chevron deshabilitado en los bordes (no antes de `startDate` ni después de `endDate`). Alinear con el `DatePeriodFilter` de Transacciones.
- **Actividad del periodo — expandir INLINE (no redirigir):** transacciones que cuentan para el presupuesto (reusa `Transaction Row`), excluye transferencias. El "ver más" **expande la lista in-place** con **"Cargar más"** (paginación perezosa) — **nunca** redirige a una lista global (rompería el contexto de periodo + alcance). Acceso secundario sutil **"Abrir en Movimientos ›"** para la lista global filtrada.
- **Acciones — en overflow "⋮" del header** (sheet `G26c4T`/`f1WviW`): **Editar** (→ form prellenado) · **Cerrar (guardar en histórico)** (HU-10) · **Eliminar** (→ papelera `deletedAt`, HU-11; sheet de confirmación `hxkUC`, tema oscuro pendiente). El sheet de confirmación usa tono **neutral `$primary`** (ícono `trash-2`), no rojo — es reversible vía papelera, mensaje: "Este presupuesto se eliminará. Podrás deshacerlo justo después de eliminar."
- **Variantes:** sobregasto (hero + caption en familia `expense`) y una única vez (ancla "termina el [fecha]", stepper acotado a `[startDate, endDate]`, chevron derecho deshabilitado en el último periodo).

## Formulario crear/editar (`a3gGPM` / `AHGQc`)

- **Ícono + Nombre en la primera sección:** selector de ícono (sheet `XsnnD`/`Al6tQ`, reusa el patrón de Cuentas/Categorías + `Icon Tile`). **Ícono solo, sin color** — icon-wrap neutro `$muted`. Guarda en `Budgets.icon`.
- **"Repetir" va ANTES de "Periodicidad"** y la condiciona (evita combos inválidos, HU-03):
  - **Periódico** (`recurring = true`) → muestra **Periodicidad** (Semanal / Quincenal / Mensual / Anual) + Inicio (anclaje libre) + "Repetir hasta" (Para siempre | fecha fin opcional).
  - **Una única vez** (`recurring = false`, ref. `C6SRE`/`c13OZ`) → NO muestra periodicidad; muestra **Inicio + Fin** (obligatorio). Este es el `custom` del enum `BudgetPeriod` — **en la UI no existe una pill "Personalizado"**, el caso custom ES la rama "Una única vez".
- **Alcance con progressive disclosure:** las filas "Cuentas ›" / "Categorías ›" se muestran **solo en "Personalizado"**; en **"Todo"** (global, ref. `yfy35`/`u6RBA9`) se ocultan (redundantes). Patrón **A1 · filas + bottom sheet**: reúsan las hojas de Transacciones — `jpARf` ("Filtrar por cuenta") y `q0CTl` ("Filtrar por categoría", maneja subcategorías) — instanciadas con título de contexto ("Elegir cuentas" / "Incluir categorías"), sin duplicar los frames de Transacciones. En cada hoja, **"Todas" = incluir todas**; ambas dimensiones en "Todas" = presupuesto **global**.
- **Umbral de alerta:** la fila "Avisarme al 80% del presupuesto ›" abre el sheet de umbral (`m3jomu`/`GNQ49`): presets **70/80/90 + Personalizado + No avisarme**, default 80. Persiste `alertThresholdPct` (HU-08).
- **CTA "Crear presupuesto" deshabilitado** hasta que Nombre (1-100) y Monto (> 0) sean válidos (HU-01).
- Editar = mismo form prellenado + acciones Cerrar/Eliminar desde el ⋮ del detalle.

## Histórico (`KfPyk` / `g2qP7`)

Lista de presupuestos **cerrados** (`archivedAt` no nulo), ordenados por fecha de cierre, con `Archived Budget Row` (`Ote7d`): nombre + periodo + **resultado real** (dentro/excedido; excedido en `$expense-text` con `circle-minus`). **No** incluye eliminados (papelera es aparte). Acceso desde el ⋮ de la lista (menú `TmOGV`/`cOcbC`). Reactivar = limpiar `archivedAt`.

## Modo sobres (base-cero, HU-06) (`D1G5hl` / `YiBcF`)

Nombre de UI: **"Modo sobres"** (no "base-cero"/"YNAB"/"zero-based" — jerga que el usuario no reconoce). Ícono `target`.
- Hero propio: **ingreso del periodo − total asignado = sin asignar**; "Sin asignar" tiende a **cero** pero **no bloquea** ninguna acción (guía, no obstáculo).
- Reusa `Budget Line` (`FSL69`) para el listado de asignaciones.
- **Activación:** es opt-in a nivel de app desde **Ajustes → "Modo sobres"** (fila `r5aVv`/`GZUqi`, con link "¿Qué es?"). Persiste en `AppSettings.zeroBasedEnabled`. Estando activo, el ⋮ de la lista ofrece "Desactivar modo sobres" (menú `tFZyK`/`qJAka`).
- **Info sheet** (`eBwb0`/`gAetG`): bottom sheet accesible desde "¿Qué es?" que explica el método sobres en lenguaje llano, sin jerga.

## Estados

- **Vacío** (`Zqsi1`/`zIijv`): `Empty State` + copy neutral-positivo ("Aún no tienes presupuestos") + CTA "Crear presupuesto".
- **Carga** (`L8A868`/`QiUJe`): 4× `Budget Skeleton Row` (`iVri4`), token `$skeleton`.
- **Texto largo:** nombre/alcance a una línea con ellipsis (regla de contenido largo de MASTER).

## Tema oscuro — notas de implementación

- **Paridad estructural:** cada frame oscuro es idéntico en layout/contenido/tokens a su par claro (verificado en auditoría). No divergir.
- **Sombra de la pastilla flotante de periodo:** es un **override por tema**. En claro usa la sombra navy suave; en oscuro una **sombra negra con más alpha/blur** (`#00000066`, blur 28, offset y:8) porque una sombra oscura-tintada no eleva sobre `$background` oscuro. En código, la elevación de la pastilla debe resolver el color/alpha de sombra **por tema**, no reutilizar el del claro.
- **Skeleton:** token `$skeleton` (no `$border`, que es casi invisible sobre `$surface` en oscuro).
- **Contrastes verificados AA en oscuro:** familia `expense` sobre `$surface`, `$primary-on-soft`/`$primary-on-soft-strong` sobre `$primary-soft`, caption compacta y `%` gris (`$text-secondary`).
