# Página: Presupuestos

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`. Requisitos: `docs/requirements/06-presupuestos.md`.

**Estado:** **aprobado** (tema claro + tema oscuro). Diseño cerrado tras múltiples rondas de refinamiento y auditoría con `ui-ux-reviewer` (paridad claro↔oscuro verificada, contrastes AA, sin hex hardcodeados). Listo para `flutter-dev`.

## Frames

Cada pantalla tiene su par claro→oscuro. El tema oscuro vive en una banda separada abajo del canvas claro, con un offset de **7010px** respecto al frame claro equivalente. (La banda no tiene frame contenedor propio: es posicional. El `ID` `Q9o9pz` que citaba este documento no existe en el `.pen`.)

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
| Histórico — carga (skeleton) | `rI2bL` | `swPIt` |
| Modo sobres (base-cero) | `D1G5hl` | `YiBcF` |
| Sheet — acciones del detalle (⋮) | `G26c4T` | `f1WviW` |
| Sheet — umbral de alerta | `m3jomu` | `GNQ49` |
| Sheet — elegir ícono | `XsnnD` | `Al6tQ` |
| Sheet — info "¿Qué es el modo sobres?" | `eBwb0` | `gAetG` |
| Menú lista (⋮ header) | `TmOGV` | `cOcbC` |
| Menú modo activo | `tFZyK` | `qJAka` |
| Fila en Ajustes ("Modo sobres") | `r5aVv` | `GZUqi` |
| Sheet — eliminar presupuesto | `hxkUC` | `T7pTgh` |

**Componentes reutilizables** (temáticos, sin variante oscura separada):
- `Budget Line` (`FSL69`) — fila de presupuesto en la lista.
- `Budget Skeleton Row` (`iVri4`) — placeholder de carga; usa token `$skeleton` (NO `$border`, invisible en oscuro).
- `Archived Budget Row` (`Ote7d`) — fila del histórico. **Tarjeta de dos zonas**, no una fila plana: Body (icon-wrap + nombre + **alcance** + `"Cerrado <fecha>"` a la derecha, y debajo la fila de resultado con `circle-check-big` / `circle-minus` — el icono va en **ambos** resultados, no solo en sobregasto) y **Footer** separado por borde superior, alineado a la derecha, con `archive-restore` + "Reactivar".
- `Archived Budget Skeleton Row` (`ktlIa`) — placeholder de carga del histórico, con la geometría de dos zonas de `Ote7d`. No reusar `iVri4`: es el placeholder de `FSL69` y tiene otra geometría.

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
- **Línea 2 (meta, 12px `$text-secondary`):** es una **fila de ancho completo con dos nodos**, no una cadena: `k0TmF` = **alcance corto · ancla temporal** (`fill_container`, a la izquierda) y `vdyCS` = **el `%` anclado a la derecha**. **No concatenes el `%` dentro del texto de meta**: queda dentro de la columna elástica y el ellipsis se lo come siempre — pasó, y el porcentaje no se vio en ningún golden hasta el 2026-07-19. El `%` va gris (`$text-secondary`) en sano y rojo (`$expense-text`) en sobregasto.
  - **El ancla temporal es "se reinicia el [fecha]" / "termina el [fecha]"**, nunca "N días" (ver "Copy y tono").
- **Barra** de progreso delgada, track `$border` y altura **6** en la lista (8 en el hero del detalle); fill `$primary` sano / `$expense` sobregasto.
- **En sobregasto el rojo NO es ambiental:** se pinta el `%`, el stack derecho y la barra; **la meta se queda en `$text-secondary`**. El rojo es señal con significado.
- Icon-wrap de la fila: **40×40 radio 12** (no círculo), icono 20 en `$primary-on-soft` (`$expense` en sobregasto).
- **Al detalle, NO a la lista:** gastado, total, periodicidad, umbral, desglose. La lista es para decidir "¿puedo seguir gastando?".
- Aire: padding de card ~18, gap ~18, borde `$border` 1px, radio 20, fondo `$surface` dominante.
- **Sin resumen agregado permanente** ("$X presupuestado este mes" sumando todos): es engañoso porque los presupuestos tienen periodos distintos, se solapan (doble conteo) y son multi-moneda. Solo válido en Modo sobres (HU-06). No usarlo como hero de la lista.

**Punto de entrada a crear:** fila-CTA **"+ Nuevo presupuesto"** al final de la lista (círculo **40pt** `$surface` + `plus`, fondo `$primary-soft`, borde `$primary-light`, label **700** `$primary-on-soft-strong` para pasar contraste AA). Reemplaza al FAB en esta pantalla — **Presupuestos no lleva `AppFab`**, su acción de crear vive en el header y en esta fila. El copy es "Nuevo presupuesto", no el del estado vacío ("Crear presupuesto").

**Header** (`ymsmU`): dos botones **circulares de 44pt** en orden **`⋮` → `+`** (`HqZOy` con `ellipsis-vertical` sobre `$muted`; `QAY0j` con `plus` sobre `$primary`), gap 8. No son `IconButton` planos.

**El ⋮ abre un bottom sheet, no un `PopupMenu`** (`TmOGV`/`cOcbC`, instancia de `Bottom Sheet Base`): head "Presupuestos / Opciones" y **siempre tres** opciones con icon-wrap `$muted` 38/r12, título 15/600 y subtítulo 12/500 — "Ver histórico / Presupuestos cerrados", "Activar|Desactivar modo sobres" con sus dos subtítulos (`tFZyK`/`qJAka` es la variante con sobres activo), y "¿Qué es el modo sobres?" (sin subtítulo). El patrón de fila y head vive en `lib/core/widgets/sheet_action_row.dart`.

## Detalle de presupuesto (`NloPT` / `vHIu4`; sobregasto `DN0GV`/`zW1s4`; única vez `QLn6w`/`A5O26l`)

Orden vertical: `Page Header` (atrás + **"⋮"**) → **hero de progreso** → **actividad del periodo** → **pastilla flotante de periodo** (abajo).

- **Hero de progreso — patrón compacto:** dato primario **"Te quedan $X"** + barra, y **debajo de la barra una sola caption de 2 partes** al estilo del Hero de Inicio (`HC Prog Row`): izq **"82% · $492.000 de $600.000"**, der **"Restan 18 días"**. **Prohibido** desglosar esas cifras en varios `Info Row`/chips apilados (se probó y saturó). Sobregasto → familia semántica `expense` (hero rojo).
- **Stepper de periodo (HU-05) — pastilla flotante inferior:** NO es una fila arriba ni una barra de ancho completo (evita confundirse con la `Tab Bar`). Es una **píldora centrada flotante anclada abajo**, con el rango explícito del ciclo del propio presupuesto + estado: `‹ 21 jul – 20 ago · vigente ›`, NO un mes calendario global. (Este ejemplo decía `1–31 jul` y era justamente el error: un mes calendario. Estaba mal en el `.md` **y** en cuatro frames; se corrigió el 2026-07-19. No lo copies de vuelta.) El label va **partido en dos textos**, no en uno uniforme: rango 13/700 `$text-primary` + estado 12/600 `$text-secondary`. Los chevrons son **círculos `$muted` de 44pt**. En "una única vez" van **los dos** al 40%: hay un solo periodo, así que es índice 0 y último a la vez — no hay anterior ni siguiente. Siempre visible mientras la actividad scrollea. Controla qué periodo reflejan el hero y la actividad. Chevron deshabilitado en los bordes (no antes de `startDate` ni después de `endDate`). Alinear con el `DatePeriodFilter` de Transacciones.
- **Actividad del periodo — expandir INLINE (no redirigir):** transacciones que cuentan para el presupuesto (reusa `Transaction Row`), excluye transferencias. El "ver más" **expande la lista in-place** con **"Ver más"** (paginación perezosa) — **nunca** redirige a una lista global (rompería el contexto de periodo + alcance). El header de la sección es `"Movimientos del periodo"` + el **contador** `"N movimientos"` a la derecha (`Nv04I`: `K7yvL` + `qFH6T`).

> **No hay acceso "Abrir en Movimientos ›".** El spec lo pidió en prosa, pero no está dibujado en ninguna de las seis variantes del detalle y ocupaba en código el lugar que el frame da al contador. Se retiró (2026-07-19): el "ver más" ya despliega la lista completa ahí mismo, que es el objetivo; y el motivo por el que este mismo párrafo prohíbe redirigir —romper el contexto de periodo + alcance— aplica igual a un acceso secundario. Además, traducir un alcance compuesto ("2 cuentas · 3 categorías" + ventana del periodo) a los filtros de Movimientos no siempre es fiel, y un enlace que lleva a una lista distinta es peor que no tenerlo. Si alguna vez se quiere, se diseña en Pencil primero.
- **Acciones — en overflow "⋮" del header** (sheet `G26c4T`/`f1WviW`): **Editar** (→ form prellenado) · **Cerrar (guardar en histórico)** (HU-10) · **Eliminar** (→ papelera `deletedAt`, HU-11; sheet de confirmación `hxkUC` / `T7pTgh`). El sheet de confirmación usa tono **neutral `$primary`** (ícono `trash-2`), no rojo — es reversible vía papelera, mensaje: "Este presupuesto se eliminará. Podrás deshacerlo justo después de eliminar."
- **Variantes:** sobregasto (hero + caption en familia `expense`) y una única vez (ancla "termina el [fecha]", stepper acotado a `[startDate, endDate]`, chevron derecho deshabilitado en el último periodo).

## Formulario crear/editar (`a3gGPM` / `AHGQc`)

- **Ícono + Nombre en la primera sección:** selector de ícono (sheet `XsnnD`/`Al6tQ`, reusa el patrón de Cuentas/Categorías + `Icon Tile`). **Ícono solo, sin color** — icon-wrap neutro `$muted`. Guarda en `Budgets.icon`.
- **"Repetir" va ANTES de "Periodicidad"** y la condiciona (evita combos inválidos, HU-03):
  - **Periódico** (`recurring = true`) → muestra **Periodicidad** (Semanal / Quincenal / Mensual / Anual) + Inicio (anclaje libre) + "Repetir hasta" (Para siempre | fecha fin opcional).
  - **Una única vez** (`recurring = false`, ref. `C6SRE`/`c13OZ`) → NO muestra periodicidad; muestra **Inicio + Fin** (obligatorio). Este es el `custom` del enum `BudgetPeriod` — **en la UI no existe una pill "Personalizado"**, el caso custom ES la rama "Una única vez".
- **Alcance con progressive disclosure:** las filas "Cuentas ›" / "Categorías ›" se muestran **solo en "Personalizado"**; en **"Todo"** (global, ref. `yfy35`/`u6RBA9`) se ocultan (redundantes). Patrón **A1 · filas + bottom sheet**: reúsan las hojas de Transacciones — `jpARf` ("Filtrar por cuenta") y `q0CTl` ("Filtrar por categoría", maneja subcategorías) — instanciadas con título de contexto ("Elegir cuentas" / "Incluir categorías"), sin duplicar los frames de Transacciones. En cada hoja, **"Todas" = incluir todas**; ambas dimensiones en "Todas" = presupuesto **global**.
- **Umbral de alerta:** la fila "Avisarme al 80% del presupuesto ›" abre el sheet de umbral (`m3jomu`/`GNQ49`): presets **70/80/90 + Personalizado + No avisarme**, default 80. Persiste `alertThresholdPct` (HU-08).
- **CTA deshabilitado** hasta que Nombre (1-100) y Monto (> 0) sean válidos (HU-01). Va en una **barra inferior fija** (`l1wrUJ`): `$surface`, borde superior 1 `$border`, padding `[12,20,20,20]`, botón `fill_container`. **No** es el último item del scroll.
- Editar = mismo form prellenado + acciones Cerrar/Eliminar desde el ⋮ del detalle.

**Piezas del formulario que sí están en el `.pen` y es fácil omitir** (todas se implementaron el 2026-07-19 tras encontrarlas ausentes):

- **Label de la primera sección: "Ícono y nombre"** (`AceYL`), al margen (x=20), alineado con la columna de labels de toda la pantalla — no indentado para cuadrar con el input.
- **Badge de edición del ícono** (`oIyvH`): círculo 18×18 `$surface` con borde `$border`, sobrepuesto en la esquina inferior derecha del icon-button de 52×52.
- **Selector de moneda dentro del input de Monto** (`EA3R5`): pastilla `$muted` radio 10 con `"COP"` 13/700 + `chevron-down`. El monto se formatea **con símbolo y sin decimales** (`$4.500.000`), igual en placeholder y en valor escrito.
- **Periodicidad NO es un `Segmented Control`** (`Aj6Ly`): son **cuatro pastillas de ancho natural** (radio 12, padding `[9,14]`, gap 8; `$muted` en reposo, y la activa `$primary-soft` + borde `$primary` + label `$primary-on-soft-strong`).
- **Las filas de navegación son `Form Field` (`wOlOA`)** con icono líder, **texto inline `"Etiqueta: valor"`** y **`chevron-right`** — sin label de sección encima. El chevron distingue: `-down` es desplegar aquí, `-right` es abrir un selector. "Repetir hasta" es una de estas filas, **no** un segmented control.
- **Tira informativa del alcance "Todo"** (`yfy35/dd4X6`): `$primary-soft` radio 14 con icono `globe` y el texto "Incluye todo tu gasto: todas las cuentas y categorías."
- **Una fila de navegación con valor puesto cambia su `chevron-right` por una `×` de limpiar** (`LucideIcons.x` 16 en `$text-secondary`), no dibujada en el frame pero **aceptada**: obligar a abrir el selector solo para borrar una fecha es peor. Misma afordancia que Pagos programados, con una diferencia deliberada: allá el chevron de reposo es `chevron-down` (campo desplegable) y aquí `chevron-right` (abre hoja). **Lo compartido es la `×`, no el chevron.**
- **Placeholder del ícono sin elegir:** `shapes`, no `sparkles`. `sparkles` es el glifo de la familia IA/nudge del sistema (se usa en la tira `eZMPq` del hero de Modo sobres) y prometía "sugerencia IA" donde solo hay "elige un ícono". **Inconsistencia conocida:** Categorías sí usa `sparkles` en el mismo caso, pero ahí está dibujado y aprobado (`PZvWF/ZKIRA`) — unificarlo exige decidir cuál gana y editar Pencil.
- **Los estados de carga del detalle y del formulario usan esqueletos**, no un spinner: la feature ya usa esqueletos en la lista (`iVri4`) y en el histórico (`ktlIa`), y un spinner rompía ese idioma. No tienen frame propio; su geometría se derivó de `NloPT` y `a3gGPM/lBpTl`.
- **El hero omite la caption de días restantes fuera del periodo vigente.** `daysLeftFrom` clampa a 0, así que un periodo cerrado anunciaba "Último día" — falso. En `past` y `future` no se renderiza la caption; la píldora ya comunica el estado.

## Histórico (`KfPyk` / `g2qP7`)

Lista de presupuestos **cerrados** (`archivedAt` no nulo), ordenados por fecha de cierre, con `Archived Budget Row` (`Ote7d`, ver su anatomía de dos zonas en "Componentes reutilizables"): nombre + **alcance** (no la periodicidad) + `"Cerrado <fecha>"` + **resultado real** en su propia fila (dentro con `circle-check-big` en `$text-secondary` / excedido con `circle-minus` en `$expense-text` — el copy es **"Terminó dentro del presupuesto"** / "Excedido por $X"). **No** incluye eliminados (papelera es aparte). Acceso desde el ⋮ de la lista (menú `TmOGV`/`cOcbC`). Reactivar = limpiar `archivedAt`, desde el **footer** de la tarjeta.

Lleva **subheader** (`IMgeg`): "Presupuestos cerrados" (15/700) + "Los conservas sin borrar. Puedes reactivarlos cuando quieras." (12/500). Estado de carga con `Archived Budget Skeleton Row` (`ktlIa`), frames `rI2bL`/`swPIt`.

## Modo sobres (base-cero, HU-06) (`D1G5hl` / `YiBcF`)

Nombre de UI: **"Modo sobres"** (no "base-cero"/"YNAB"/"zero-based" — jerga que el usuario no reconoce). Ícono `target`.
- Hero propio (`w6P0W`): **ingreso del periodo − total asignado = sin asignar**; "Sin asignar" tiende a **cero** pero **no bloquea** ninguna acción (guía, no obstáculo). Es una **tarjeta `$surface` + borde `$border`** radio 24 padding 18 — **no** `$primary-soft`, que es el tratamiento de una fila-CTA; y el monto va 34/800 en **`$text-primary`**, no en violeta. Contiene cinco piezas que es fácil omitir: la pastilla **"Modo sobres"** (`Z2DJfz`, `target` sobre `$primary-soft`), el **botón info** circular de 28pt (`YXLex`, entrada al sheet `eBwb0`), el label **"Sin asignar este mes"**, la **barra de progreso** (`i9NQn`, track `$border`) y la **tira de nudge** (`eZMPq`, `$primary-soft` radio 14 con `sparkles` y copy motivacional). La caption son **dos anclas** en `space_between` ("Ingreso $X" izquierda / "Asignado $Y" derecha), no una línea envolvente.
- Reusa `Budget Line` (`FSL69`) para el listado de asignaciones, pero **el label cambia a "Asignado"** con el monto asignado (no "Te quedan"), y la densidad es más compacta: padding 16 por tarjeta y gap 12 entre ellas (la lista normal usa 18/18).
- **La lista de sobres no lleva fila-CTA** "+ Nuevo presupuesto": su única entrada es el `+` del header.
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
