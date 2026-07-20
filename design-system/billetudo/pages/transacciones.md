# Página: Transacciones

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** ✅ **FEATURE CERRADA — Las 8 HU de `docs/requirements/03-transacciones.md` tienen cobertura de diseño 100% en AMBOS temas (claro y oscuro), auditadas y corregidas.** Lista + 4 estados, Sheet de fecha, Formulario x3 tipos x2 estados, Detalle x3 tipos (con Nota y Etiquetas consistentes en los 3), Eliminar+Snackbar, y los 7 filtros/modales (cuenta, categoría con jerarquía raíz/subcategoría, tipo, etiqueta, rango personalizado, nueva etiqueta, aviso de impacto al editar) — todo construido, componentizado y reorganizado en el canvas al patrón de Cuentas (4 filas, sin banda decorativa, título "TRANSACCIONES"/"TRANSACCIONES — OSCURO").

**Auditoría de tema oscuro — hallazgo crítico corregido:** `ui-ux-reviewer` encontró que `$primary` usado como texto plano sobre `$surface`/`$background` daba ~4.86:1 en claro (pasaba raspando) pero caía a ~3.00:1 en oscuro (falla texto normal) — afectaba "Todas"/"Ninguna" en los 4 filtros y el label activo "Transferencia" del `Segmented Control` en 6 de las 24 pantallas oscuras, más el monto de Transferencia como hallazgo importante (margen insuficiente). Corregido reemplazando `$primary` por `$primary-on-soft` en las 18 instancias afectadas (idéntico visualmente en claro, ~6:1 en oscuro) — regla ahora documentada en `MASTER.md` como extensión del token (antes solo cubría texto sobre `primary-soft`, ahora también sobre `$surface`/`$background` planos). Recoloreo del resto de la feature (24 pantallas oscuras): **100% automático vía variables, sin ningún hex hardcodeado**, confirmando que la disciplina de usar solo `$token` se mantuvo en toda la sesión.

Interacciones aún sin especificar (apertura real de sheets desde sus chips, wrap de año en steppers, animación de expansión de la Zona Fija, estado activo del `Sort Button`) quedan documentadas como pendientes técnicos de comportamiento — no huecos de diseño visual, no bloquean implementación. El estado "N cuentas"/"Todas" del Account Chip ya está instanciado en pantallas reales (`XlXA8`/`s8uIq` claro, `idmDe`/`H3bGO` oscuro). El control de orden por monto (HU-06) ya está construido y auditado sin hallazgos en las 6 pantallas de Lista con datos. **✅ Feature 100% cerrada — lista para pasar a `flutter-dev`.**

## Frames

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Lista de transacciones — con datos | `B3GGa` | `xAk6Y` |
| Lista de transacciones — Account Chip "N cuentas" | `XlXA8` | `idmDe` |
| Lista de transacciones — Account Chip "Todas" | `s8uIq` | `H3bGO` |
| Lista de transacciones — Ordenado por Monto | `tigaH` | `Q8gSaB` |
| Lista de transacciones — Menú de Orden Abierto | `xXWi0` | `dbTXb` |
| Lista de transacciones — vacío | `q8jCfp` | `HljCo` |
| Lista de transacciones — carga | `i8D7d` | `GzDwu` |
| Lista de transacciones — error | `l2B4S8` | `OTzMD` |
| Lista de transacciones — vacío por periodo filtrado | `RcofQ` | `R0r3h` |
| Sheet — Selector de fecha — Final | `P5fSkK` | `R6U0i` |
| Formulario Gasto — Monto activo | `DVfuC` | `IsedO` |
| Formulario Gasto — Nota activa | `UcZSx` | `pk9II` |
| Formulario Ingreso — Monto activo | `QChpv` | `Tr48f` |
| Formulario Ingreso — Nota activa | `TVSuf` | `pTucO` |
| Formulario Transferencia — Monto activo | `ArvTJ` | `f4fC5k` |
| Formulario Transferencia — Nota activa | `h9DSSj` | `Te27A` |
| Componente — Zona Fija Monto Expandida | `Rslzk` | (mismo componente, tema automático) |
| Componente — Zona Fija Monto Colapsada | `ofg07` | (mismo componente, tema automático) |
| Detalle Transacción — Gasto | `Of2sW` | `U5k715` |
| Detalle Transacción — Ingreso | `s4Wsu5` | `dyUPv` |
| Detalle Transacción — Transferencia | `xNp8g` | `y60OQ` |
| Sheet — Confirmar Eliminar Transacción | `Bf4L8` | `iV8Gs` |
| Componente — Snackbar | `zSTlU` | (mismo componente, tema automático) |
| Movimientos — Snackbar Undo (referencia) | `lwvDp` | `IarUp` |
| Sheet — Filtro de Cuentas | `jpARf` | `RcVAD` |
| Sheet — Filtro de Categoría | `q0CTl` | `NZbsD` |
| Sheet — Filtro de Tipo | `rjjfw` | `haoOi` |
| Sheet — Filtro de Etiqueta | `FL1gK` | `a5PH7i` |
| Sheet — Rango Personalizado | `OFdj4` | `Oa2o2` |
| Sheet — Nueva Etiqueta | `NazyV` | `YHAWB` |
| Sheet — Aviso Impacto Edición | `L9DJI` | `j8W9a` |
| Componente — Button/FAB | `H5mzN` | (mismo componente, tema automático) |
| Componente — Detail Amount Hero | `npfLO` | (mismo componente, tema automático) |
| Componente — Detail Actions Row | `jt8dk` | (mismo componente, tema automático) |
| Componente — Tag Chip | `nM9ea` | (mismo componente, tema automático) |
| Componente — Filter Account Row | `X3tZG` | (mismo componente, tema automático) |

**Organización del canvas — tema oscuro:** zona "TRANSACCIONES — OSCURO" (label `h6URn`, `y:25760`, sin banda decorativa, mismo criterio que el bloque claro), 24 pantallas en el mismo patrón de 4 filas (`y:25910`/`27060`/`28210`/`29360`), generadas con `Copy()` + `theme:{mode:"dark"}` desde cada frame claro — **recoloreo 100% automático, cero hex hardcodeado encontrado**. (Las coordenadas exactas pueden variar si se reorganiza el canvas; el `.pen` manda — estos valores se re-verificaron contra él.) Verificado visualmente: contraste del Snackbar (`$snackbar-action` oscuro, 6.03:1), `primary-on-soft-strong` en categorías seleccionadas, `income-text` en monto de Ingreso, y el patrón de fila seleccionada en los filtros — todos legibles sin ajustes manuales.

**Navegación:** `B3GGa` es un **destino de Tab Bar** (item "Movimientos" activo) — usa header propio + `Tab Bar`, SIN `Page Header` (regla de exclusión de MASTER: Page Header y Tab Bar nunca conviven en la misma pantalla). El Formulario Nueva/Editar transacción SÍ lleva `Page Header` (pantalla apilada/modal) y no lleva Tab Bar.

**Organización del canvas — reorganizada al patrón de Cuentas** (sin banda decorativa con borde — se eliminó `AAqdS` porque ese tipo de contenedor daba problemas de interacción en el editor de Pencil, mismo criterio ya aplicado en Cuentas): etiqueta de texto simple "TRANSACCIONES" (`R8PtwO`, `x:50,y:7076`, `$text-primary` 24/700) + 24 pantallas en **4 filas** de columnas, pasos de 450px en x / 1150px en y (igual que Cuentas):
- **Fila A** (`y:7196` claro / `y:23200` oscuro, x:100→4150, 10 pantallas por tema): Lista base + variaciones de Account Chip/orden agrupadas justo al lado, luego los 4 estados y el Sheet de fecha — mismo orden en ambos temas:
  `B3GGa`/`xAk6Y` → `XlXA8`/`idmDe` ("N cuentas") → `s8uIq`/`H3bGO` ("Todas") → `tigaH`/`Q8gSaB` ("Ordenado por Monto") → `xXWi0`/`dbTXb` ("Menú de Orden Abierto") → `q8jCfp`/`HljCo` (vacío) → `i8D7d`/`GzDwu` (carga) → `l2B4S8`/`OTzMD` (error) → `RcofQ`/`R0r3h` (vacío periodo filtrado) → `P5fSkK`/`R6U0i` (sheet fecha).

  Reordenado a pedido del usuario: las variaciones de contenido de la Lista van junto a la pantalla base, separadas de los estados vacío/carga/error (que son estructuralmente distintos, no variaciones de datos). Solo fue reposicionamiento de coordenadas — las pantallas oscuras ya existían de rondas anteriores, no se regeneraron.
- **Fila B** (`y:8346`, x:100→2350): Formulario x3 tipos x2 estados — `DVfuC`, `UcZSx`, `QChpv`, `TVSuf`, `ArvTJ`, `h9DSSj`.
- **Fila C** (`y:9496`, x:100→1900): Detalle x3 + Eliminar — `Of2sW`, `s4Wsu5`, `xNp8g`, `Bf4L8`, `lwvDp`.
- **Fila D** (`y:10646`, x:100→2800): Filtros y modales — `jpARf`, `q0CTl`, `rjjfw`, `FL1gK`, `OFdj4`, `NazyV`, `L9DJI`.

Presupuestos/Metas/Deudas y todo lo que venía después en el canvas se corrió `+3350` en `y` para no colisionar con el bloque más alto de Transacciones (traslación pura, sin cambios de contenido). Todos los candidatos descartados de rondas anteriores (variantes de selector de fecha, formularios pre-rediseño, variantes de teclado, checkbox circular) siguen eliminados del canvas. Las notas de Pencil que documentaban decisiones/pendientes (teclado nativo, Info Card, jerarquía de subcategorías, accesibilidad del Sort Button) fueron retiradas del `.pen` una vez su contenido quedó capturado en este documento — ver las secciones correspondientes abajo.

**Bug corregido en esta ronda:** 3 piezas habían quedado anidadas como hijas reales de la banda decorativa `AAqdS` en vez de frames raíz del documento — sus coordenadas se interpretaban relativas al origen de `AAqdS`, dejándolas completamente fuera del área visible (`"fully clipped"`) pese a que su contenido interno era correcto. Se corrigió sacándolas a `document` preservando sus x/y absolutas. Si una pantalla nueva "desaparece" pese a construirse bien, verificar primero que su padre real sea `document` y no una banda de fondo.

## Lista de transacciones (`B3GGa`)

1. **Header**: título "Movimientos" (24px/700, `$text-primary`), sin botón de acción (no hay Page Header, la creación de transacción vive en el FAB).
2. **Search Bar**: icono `search` + placeholder "Buscar por nota o categoría", `$surface`, `cornerRadius:16`, alto 48.
3. **Chips Row** (scroll horizontal, `gap:8`):
   - **Account Chip** (mismo patrón de píldora en los 3 estados posibles): mismo tamaño/forma que los demás chips de la fila (altura 44, padding `[10,14]`, gap 6). Icono inline 14px + label 13px/700 + `chevron-down`, los tres en `$primary-on-soft-strong` (mismo token creado para `Category Chip`, da ~5.7:1 de contraste) — fondo `$primary-soft`, borde `$primary`. Refleja HU-06a con los 3 estados resueltos tras explorar 4 variantes y descartar 3 (patrón elegido: misma píldora activa para los 3 estados, se descartó el tratamiento neutral para "Todas" por no convencer al usuario):
     - **1 cuenta seleccionada**: icono de la cuenta real (ej. `wallet`/`$mint` para "Efectivo") + nombre de la cuenta — instanciado en `B3GGa`/`xAk6Y` con "Nequi".
     - **2+ cuentas seleccionadas**: icono genérico `layers` + "N cuentas" — instanciado en `XlXA8`/`idmDe` con ejemplo "3 cuentas".
     - **Todas seleccionadas (sin filtro)**: icono genérico `wallet` + "Todas" — instanciado en `s8uIq`/`H3bGO`.
     - El frame de referencia que documentaba los 3 estados aislados (`GSVWn`) fue eliminado tras quedar redundante frente a estas 6 pantallas reales.
   - **Chip Categoria** / **Chip Tipo** / **Chip Etiqueta**: pill simple `$surface` + stroke `$border`, label `$text-secondary` 12/700, sin icono. El chip de Etiqueta se agregó tras la auditoría (faltaba, HU-06 exige poder filtrar por etiqueta).
   - **Chip Fecha**: igual que los anteriores + icono `calendar`, label **"Este mes"** (refleja el nuevo default de HU-06b, antes decía genéricamente "Fecha"). Es el chip que abre el bottom sheet de selector de fecha (`P5fSkK`, ver sección propia).
   - **Control de orden (HU-06, "ordenar por monto") — construido.** `Search Bar` pasó a vivir dentro de una fila `Search Row` (`gap:8`) junto a un botón nuevo `Sort Button` (44x48, `cornerRadius:16`, icono `arrow-up-down` 20px `$text-secondary`, `fill:$surface`/`stroke:$border` en estado inactivo/default — mismo tratamiento que un chip de filtro sin seleccionar). Instanciado en las 6 pantallas de Lista con datos reales (los estados vacío/carga/error no lo llevan, no hay filas que ordenar):

     | Pantalla | Sort Button |
     |---|---|
     | `B3GGa` (claro) | `ch57V` |
     | `XlXA8` "N cuentas" (claro) | `LrWHe` |
     | `s8uIq` "Todas" (claro) | `qvCZS` |
     | `xAk6Y` (oscuro) | `hRAt6` |
     | `idmDe` "N cuentas" (oscuro) | `Kkjrh` |
     | `H3bGO` "Todas" (oscuro) | `HS4Yb` |

     **Auditado sin hallazgos bloqueantes** (contraste 5.30:1 claro / 5.89:1 oscuro, tap target 44x48, coherente con el `cornerRadius:16`/`height:48` de la `Search Bar` que lo acompaña). Único punto menor: falta `semanticLabel`/tooltip accesible para lectores de pantalla (es un ícono sin texto) — anotado para `flutter-dev`, no bloquea el diseño.

     **Menú de orden — ampliado a 4 opciones en 2 secciones** (`xXWi0` claro / `dbTXb` oscuro, "Movimientos - Final - Menú de Orden Abierto"): tocar el `Sort Button` abre un **popover pequeño anclado** (no un `Bottom Sheet Base` completo) — card `$surface`/borde `$border`/sombra (mismo tratamiento que `Snackbar`), 226px de ancho, alineado al borde derecho del botón y cayendo 8px debajo (card final ~257px de alto, verificado que sigue sin cortarse contra el borde del frame de 972px). Contenido agrupado en 2 secciones, cada una con un label agrupador no-tocable (11px/700, `$text-secondary`, `letterSpacing` sutil, uppercase) seguido de sus filas seleccionables (48px alto, patrón `Currency Row`, check `$primary-on-soft` en slot fijo 24x24, solo una opción activa a la vez):
     - **FECHA**: "Más recientes primero" (activa por defecto en el mockup) / "Más antiguos primero".
     - **MONTO**: "Mayor a menor" / "Menor a mayor".

     Un solo divisor `1px $border` separa ambas secciones. **Sin scrim** detrás — popover contextual, no un flujo que requiera foco total de pantalla.
     - **Corregido tras auditoría:** el `Sort Button` en estas 2 pantallas mostraba por error el estilo activo (violeta) aunque el check del menú seguía marcando "Más recientes primero" (fecha, el default) — engañoso, sugería que el orden ya había cambiado antes de elegir nada. Corregido a estilo inactivo (`$surface`/`$border`), coherente con que Fecha sigue siendo el criterio real mientras el popover está abierto sin haber tocado ninguna opción de Monto todavía.
     - `tigaH`/`Q8gSaB` (estado "Ordenado por Monto") siguen representando el caso "Mayor a menor" como ejemplo, sin cambios.

     **Estado activo — construido** (`tigaH` claro / `Q8gSaB` oscuro, "Movimientos - Final - Ordenado por Monto"): `Sort Button` en `fill:$primary-soft`/`stroke:$primary`/icono `$primary-on-soft-strong` (mismo patrón que un chip de filtro activo). **Decisión de diseño clave**: al ordenar por monto, la agrupación por `Date Head` ("Hoy"/"Ayer") deja de tener sentido (las filas ya no están en orden cronológico) — la `List` se vuelve **plana, sin headers de sección**, con las mismas instancias de `Transaction Row` una tras otra (`gap:16`) ordenadas por monto absoluto descendente (el ingreso "+$4.200.000" primero, luego los gastos de mayor a menor). Se agregó un label "Ordenado por monto" (`$text-secondary`, 12/600) arriba de la lista para dar contexto de que cambió el criterio, ya que se pierde la referencia temporal de los headers. **Pendiente:** interacción/transición real del toggle fecha↔monto sin definir, solo el estado visual final de cada uno.

   **Resuelto:** se agregó `Scroll Fade` (`ns58k`), un degradado absoluto de transparente a `$background` sobre los últimos 32px del borde derecho de la fila (`x:358-390`, mismo alto que los chips), superpuesto al corte de `Chip Fecha` (`q4uw5N`, ya queda parcialmente visible ahí de forma natural). La combinación chip-cortado + fade comunica que la fila continúa. `Chip Etiqueta` (`uIBNS`) sigue completamente fuera del área visible del mockup estático (no hay espacio físico para asomarlo sin comprimir demasiado los demás chips) — en Flutter esto se implementa como `ListView` horizontal real, así que sigue siendo alcanzable con scroll aunque el mockup no lo muestre.
4. **List**: agrupada por fecha.
   - **Date Head** (`justifyContent:"space_between"`): label del grupo ("Hoy"/"Ayer"/"12 de julio") en `$text-primary` 14/700 + contador "N movimientos" en `$text-secondary` 12/500 a la derecha.
   - Filas: instancias de `Transaction Row` (`DKJaf`), gap **16** entre filas dentro de un grupo, gap **24** entre grupos.
   - **Corregido:** `Name` (`ua7j7`, la descripción del movimiento) desbordaba sin límite con textos largos (ej. "Diseño freelance para agencia internacional de branding" tapaba el `Sub` de abajo). Ahora envuelto en `Name Wrap` (`XWfyu`, `clip:true`, `height:40` ≈ 2 líneas a 15px/1.3). Pencil no soporta ellipsis nativo — el clip a 2 líneas en el `.pen` es la aproximación visual; en Flutter implementar con `maxLines: 2` + `TextOverflow.ellipsis` en el widget real.
5. **FAB**: círculo 56px `$primary`, icono `plus` (`$on-primary`), `layoutPosition:"absolute"`, sombra `#6C5CE766`. **Construcción ad-hoc, NO es `reusable:true` todavía** — candidato a componentizar si se repite en otra pantalla (ej. si Presupuestos/Metas usan el mismo patrón de FAB).

**Decisión de diseño (variante ganadora):** se exploraron 4 variantes (V1 chips scroll + agrupado, V2 filtro único + lista continua, V3 chip cuenta protagonista + airy, V4 mezcla V1+V3). Se eligió **V4** (Chips Row de V1 combinado con el Account Chip protagonista de V3) por dar acceso de un toque a los filtros de HU-06/HU-06a sin sacrificar la jerarquía visual de la cuenta seleccionada. Variantes descartadas (V1 `vk9HA`, V2 `JJ90m`, V3 `KCh28`) eliminadas del `.pen` de inmediato tras la decisión.

### Estados — construidos

Siguiendo el patrón de Inicio: solo el área de contenido entre Chips Row y FAB cambia, Header/Search Bar/Chips Row/Tab Bar se mantienen iguales en los 4:
- **Vacío** (`q8jCfp`): `Empty State` (`jmQO5`) — icono `receipt`, "Aún no registras movimientos" (tono neutral, nunca punitivo), CTA "Agregar movimiento".
- **Carga** (`i8D7d`): 5x `Skeleton Row` (`CKnQC`), anchos variados, sin headers de fecha.
- **Error** (`l2B4S8`): icono `triangle-alert`, "No pudimos cargar tus movimientos", recordatorio local-first, botón "Reintentar" (`ref j7Zvt`).
- **Vacío de periodo filtrado** (`RcofQ`, HU-06b): variante de Vacío con icono `calendar-x`, mensaje "No hay movimientos en julio 2026", `Chip Fecha` de esta instancia actualizado a "Julio 2026" para dar contexto visual — se construyó como frame propio (no solo texto alternativo sobre el mismo Empty State) por el contraste visual que aporta ver el chip activo junto al mensaje.

## Bottom sheet — Selector de fecha (HU-06b) — decisión final: `P5fSkK` ("Sheet - Selector de Fecha - Final (Claro)")

Se exploraron 4 candidatos (original de grid de 12 meses + año, y 3 variantes: V-A lista vertical de presets, V-B stepper, V-C carrusel de meses + años). El usuario eligió **V-B (stepper)** por ser la mejor para navegación consecutiva hacia atrás sin perder contexto. Los otros 3 candidatos fueron eliminados del canvas.

Reutiliza `Bottom Sheet Base` (`PqTUt`) vía `ref` + `Replace()`/`descendants` del `Content Slot`. Estructura actual: Title "Filtrar por fecha" + `Stepper Group` (`q4bPna`: `Granularity Switch` ref `hFu41` con "Semana/Mes/Año" + `Stepper Row` con flechas 44x44) + `Rango Personalizado Row` (`vluy1`, ahora sí lleva a `OFdj4`, ver más abajo). Sin `Sheet Buttons Row`/botón "Aplicar" — los presets aplican al toque inmediato, solo "Rango personalizado" requiere confirmación aparte (por eso su pantalla destino sí la tiene).

- **Estado por defecto: "Este mes"** (granularidad Mes activa, stepper mostrando "Julio 2026" con aspecto plenamente activo — label y flechas en `$text-primary`).
- Sin divisores entre Title / Stepper Group / Rango Personalizado Row — solo `gap:16`, tratamiento simétrico en las 2 transiciones.
- `Rango Personalizado Row`: sin `justifyContent:space_between` (dejaba ~154px de espacio muerto en el centro, riesgo de tap-area no cubierta en Flutter); usa un spacer explícito `width:fill_container` entre el contenido y el chevron, dejando claro que el frame completo (350x52) debe ser el área tocable — nota técnica conservada en el `.pen` para `flutter-dev`.

**Resuelto — decisión de negocio confirmada:** no existe ni existirá una acción de "Todo"/histórico completo en este sheet. Es intencional: mostrar todo el histórico no aporta valor (ej. un usuario con 3 años de registros no gana nada viendo todo junto) — un periodo acotado es siempre el caso de uso correcto, coherente con "siempre hay un filtro de fecha activo" ya documentado en HU-06b. El toggle "Ver todo" que se había explorado y descartado en una ronda anterior no se reemplaza por nada; queda cerrado.

**Pendiente:** interacción real de navegación del stepper (wrap de años al pasar de enero a diciembre, feedback de transición) no está definida, solo representada estáticamente.

## Formulario Nueva/Editar transacción — patrón de Zona Fija anclada (6 pantallas: 3 tipos x 2 estados)

Patrón de captura unificado entre los 3 tipos del `Segmented Control` (Gasto/Ingreso/Transferencia), con todos los hallazgos de `ui-ux-reviewer` corregidos y un problema de ergonomía real resuelto (ver historial completo abajo).

### Estructura general (aplica a los 6 frames)

Cada pantalla tiene 2 zonas:
- **Scroll Zone** (arriba, crece según contenido): Segmented Control → **Cuenta(s) primero** (a pedido explícito del usuario, los 3 tipos siguen este orden) → Categoría (si aplica) → Fecha → Nota → Etiquetas (si aplica).
- **Zona Fija**: instancia `ref` de uno de los 2 componentes reusables nuevos (ver abajo) — anclada siempre al fondo de la pantalla, resuelve el problema de ergonomía de alcance del pulgar (la fila superior de teclas quedaba en zona de mal alcance cuando el `Keypad` vivía en medio del formulario).

### Componentización de la Zona Fija (`Rslzk` / `ofg07`)

El patrón se repetía 6 veces (3 tipos x 2 estados) construido a mano — se convirtió en 2 componentes `reusable:true` (regla de MASTER.md: componentes repetidos ≥2 instancias deben componentizarse), en la fila de componentes del canvas (`y:140`):
- **`Rslzk`** "Zona Fija - Monto Expandida": `Header` (label + `chevron-down` en wrap 44x44) + `Amount Value` centrado (40/800) + `Keypad` (ref `gHDTi`).
- **`ofg07`** "Zona Fija - Monto Colapsada": fila con `Spacer` invisible 44x44 + `Amount Block Mini` (`width:fill_container`, `alignItems:center`, centrado real) + `Expand Wrap` 44x44 `chevron-up`. El spacer replica el ancho del wrap del chevron para que el monto quede genuinamente centrado en el ancho total, no solo en el espacio que deja el chevron.

Las 6 pantallas usan `ref` a estos 2 componentes con overrides por tipo (label, contenido del valor, color): Gasto → `$text-primary`/label "Monto"; Ingreso → `$income-text`/label "Monto"; Transferencia → `$primary`/label "Monto a transferir".

**Regla de interacción — 2 estados por tipo (documentada en HU-01/02/03 de `docs/requirements/03-transacciones.md`, sección "Teclado numérico anclado"):**
- **"Monto activo"** (`DVfuC`/`QChpv`/`ArvTJ`, estado por defecto al abrir el formulario): Zona Fija expandida con una fila `Header` (label a la izquierda + `chevron-down` en wrap 44x44 a la derecha, mismo patrón que la barra colapsada) para poder colapsar manualmente, `Amount Value` centrado (`alignItems:"center"`) debajo, + `Keypad` visible.
- **"Nota activa"** (`UcZSx`/`TVSuf`/`h9DSSj`): en cuanto el usuario toca el campo Nota (único campo de texto libre — Cuenta/Categoría/Fecha son selectores, no disparan esto), la Zona Fija se colapsa y el campo Nota se muestra con estado de foco (`stroke:$primary`), cediendo el espacio inferior al teclado nativo del sistema operativo (no se dibuja, es UI del SO). Evita que el `Keypad` personalizado y el teclado nativo compitan por el mismo espacio al mismo tiempo.
- **El monto SIEMPRE debe ser visible — es el dato más importante de la pantalla.** Por eso el colapso NO es a `height:0` (así se hizo en una primera pasada, corregido después): es a una **barra angosta persistente** (`Zona Fija - Colapsada (Barra Monto)`, ~72px, `$surface` + borde superior `$border`, `padding:[14,20]`, `justifyContent:space_between`) con el label + valor del monto (20px/700, mismo color por tipo que el estado expandido) a la izquierda y un `chevron-up` en wrap 44x44 a la derecha. Tocar esta barra reabre el `Keypad` completo — es el **control manual** que le faltaba al mecanismo original (antes solo se abría/cerraba automáticamente por foco, sin forma de que el usuario lo hiciera a su antojo).
- Este comportamiento surgió de descartar una 4ª variante ("panel desplegable colapsado/expandido", V-D) que el usuario propuso — al aplicarle la misma corrección de "ocultarse cuando Nota tiene foco" que ya necesitaba la Zona Fija de V-A, ambas convergían en el mismo mecanismo, diferenciándose solo en el estado por defecto (abierto vs. cerrado). Se eligió el default abierto (menos toques para el caso más común: llenar el monto primero) — y al agregar la barra colapsada persistente, terminó incorporando también el control manual que tenía V-D, cerrando el círculo de esa comparación.

### Por tipo

- **Monto**: color del valor — **Gasto → `$text-primary`** (neutral, nunca rojo), **Ingreso → `$income-text`**, **Transferencia → `$primary`** — coherente con el mismo patrón que ya usa `Transaction Row` en toda la app. `$income` crudo (36px/800) daba solo ~2.07:1 sobre `$background`; corregido con el token `$income-text` (~6.46:1, mismo patrón que `$expense-text`, ver `MASTER.md`). El mismo problema apareció y se corrigió en 2 lugares más de esta feature: label "Ingreso" del `Segmented Control` activo, y el monto de ingreso en la fila de la Lista (`edGxB/a1Pwa` en `B3GGa`). Pendiente fuera de alcance: el mismo patrón de `$income` crudo existe en Deudas/Presupuestos (`Budget Category Row`/`XwBn7`), no corregido por no ser parte de esta feature.
- **Categoría** (Gasto e Ingreso): grid de `Category Chip`, label 13px/700 (subido desde 11px, era contenido primario no metadata), contraste del seleccionado con el token `primary-on-soft-strong`. Transferencia no lleva categoría (HU-03).
- **Transferencia**: dos campos de cuenta (origen/destino) + botón swap (44x44) agrupados en `Account Swap Group` (`gap:4`, más compacto que el `gap:8` general) para leerse como un bloque — corrige percepción de espacio sobrante entre los 2 selectores. Sin categoría ni etiquetas. Info Box informativo ("Las transferencias no cuentan como gasto ni ingreso").
- **Segmented Control**: padding interno ajustado para que el área tocable real de cada segmento sea 44px de alto (antes 36px) — fix a nivel de componente `hFu41`, se propaga a los 3 tipos automáticamente.

### Selector de categoría del formulario (chips "más usadas" + "Ver más" + sheet)

Aplica a Gasto e Ingreso (Transferencia no lleva categoría). Reemplaza el selector inline que mostraba todas las categorías. Componentizado (`reusable:true`) tanto en Pencil como en código, por decisión explícita del usuario.

- **Control de chips** (Pencil `EIoVx` "Category Quick Picker" / código `CategoryQuickPicker`): label "Categoría" + las **3 categorías más usadas** como `Category Chip` + un 4º chip **"Ver más"** con tratamiento outline (`$surface`+`$border`, icono `ellipsis`, para leerse como acción y no como una 4ª categoría). Tap en un chip de categoría = la elige directo; tap en "Ver más" = abre el sheet.
  - **"Más usadas"**: query en `data` (`mostUsedCategories(kind, limit)`) que cuenta transacciones vivas por categoría del `kind` y ordena por conteo desc. **Fallback sin historial** (usuario nuevo): raíces primero, luego `sortOrder`, luego `createdAt`. Caso de uso `GetMostUsedCategories`.
  - **Caso borde**: si la categoría seleccionada no está en el top-3, se antepone como chip adicional (marcado) sin ocultar las más usadas.
- **Sheet selector** (Pencil `SfSln` "Category Select Sheet" / código `CategorySelectSheet`, reusa `Bottom Sheet Base` `PqTUt` / `BottomSheetBase`): título "Elegir categoría" + **barra de búsqueda** (filtra por nombre) + lista jerárquica raíz/subcategoría de **selección simple** (un tap elige y cierra; **sin** "Aplicar" ni "Todas/Ninguna" — a diferencia del filtro de la lista `q0CTl`, que es multi-select).
  - **Raíces asignables**: una transacción puede ir a una categoría raíz (`TransactionDraft.validated()` solo exige que el `kind` coincida, no restringe a hojas).
  - **Doble zona de gesto** en la fila raíz con subcategorías (Pencil `SLfJW` "Category Select Row" / código `CategorySelectRow`): el **cuerpo** de la fila elige-y-cierra, el **`Chevron Wrap` 44×44** solo expande/colapsa. Raíz **sin** subcategorías: sin chevron (nada que expandir), la fila entera elige. En búsqueda, los matches se auto-expanden y se oculta el chevron.
  - **Estado vacío de búsqueda** (Pencil `RculR` / código `CategorySelectEmptyState`): icono `search-x` + "No encontramos categorías con ese nombre", manteniendo la Search Bar arriba.
- **Auditado** por `ui-ux-reviewer` (claridad del single-select sobre un patrón que viene del multi-select, chevron falso en raíz sin hijos corregido, estado vacío agregado). Componentes Pencil: `EIoVx`, `SfSln`, `SLfJW`; instancias/estado: `EOoXj`, `RculR`. **Tema oscuro generado y auditado** (zona `HXy6n` "SELECTORES DEL FORMULARIO — OSCURO"): sheet jerárquico `BobKK`, estado vacío `fz53P` — sin hallazgos de contraste (check `$primary-on-soft` sobre `$primary-soft` 5.52:1).
- **2026-07-19 — consolidación:** `EIoVx` era el único componente `reusable:true` correcto, pero convivía con 12+ instancias sueltas de "Categoria Chips" copiadas a mano (`Q4jM84`, `QGHO0`, `KUKji`, `z4ApD`, `hMdSY`, `H9voVG`, `CQt0H`, `ylHL4`, más las de Pagos Programados) con colores inconsistentes — algunas monocromáticas violeta/gris, otras ya con color propio por categoría. Se reemplazaron todas por refs de `EIoVx`. `xGqs4` ("Control Chips - Variante A", un duplicado exploratorio con hex hardcodeados) e `IYVRj` se borraron por redundantes. En código, `CategoryQuickPicker`/`CategoryPickerChip` (antes un pill horizontal que nunca coincidió con `EIoVx`) se reconstruyó como el tile vertical real, y `scheduled_payments` dejó de tener su propia copia (`ScheduledPaymentCategoryTiles`, borrado) — ambas features usan el mismo `CategoryQuickPicker` hoy.
  - **Colores de categorías de ingreso** (Salario `$teal`, Freelance `$indigo`, Inversiones `$mint`) se asignaron en esta consolidación — no había paleta documentada para categorías de ingreso antes de esto. **Aprobado por el usuario el 2026-07-19.**

### Selector de cuenta del formulario (sheet single-select)

El campo Cuenta (y las 2 cuentas de Transferencia) abre un sheet de **selección simple** — distinto del Filtro de Cuentas de la Lista (`jpARf`), que es multi-select con "Todas" y botón "Aplicar". Aquí un tap elige y cierra, sin confirmación.

- **Sheet** (Pencil `fcVZN` "Account Select Sheet", ref `a510v` / código `AccountPickerSheetBody` sobre `Bottom Sheet Base` `PqTUt` / `BottomSheetBase`): título centrado "Elegir cuenta" + lista viva de cuentas, cada fila la misma `Filter Account Row` (`X3tZG`) reusada del filtro pero en modo single-select (la cuenta elegida queda marcada con su `check`). Saldo en rojo (`$expense-text`) si es negativo.
- **Transferencia**: el sheet de cada campo excluye la cuenta ya elegida en el otro (`excludingId`) para no permitir origen == destino.
- **Fila reutilizable en código**: `AccountSelectRow` (`lib/features/accounts/presentation/widgets/`), pública y en su propio archivo — no incrustada en la página (regla de selectores como componentes reutilizables).
- **Tema oscuro generado y auditado** (pantalla oscura `Zsrnf`, zona `HXy6n`). **Corregido tras auditoría oscura:** el saldo negativo usaba `$expense` crudo (3.40:1 en oscuro, falla AA; en claro pasaba raspando a 4.83:1) — se cambió a `$expense-text` en `fcVZN` (fila `B5A2k`/`Li1oo`), que arregla clara y oscura a la vez (~5.9:1 en ambos). En código el widget ya usaba `expenseText`, el desajuste era solo en Pencil. **Consistencia:** el filtro de cuentas claro `jpARf` (HU-06a) arrastraba el mismo `$expense` crudo en su saldo negativo (~4.38:1, también fallaba AA por poco) — alineado a `$expense-text` en la misma pasada (aprobado por el usuario).

### Selector de fecha del formulario (calendario propio, no Material)

El campo Fecha del formulario **no** abre el `showDatePicker` de Material ni el stepper de fecha de la Lista (`P5fSkK`, que filtra por periodo). Abre un **calendario propio de fecha única** porque el diseño (Bottom Sheet Base, chip "Hoy", grilla que empieza en lunes, hoy como anillo) no mapea sobre el de Material.

- **Sheet** (Pencil `Date Picker Sheet` `zMqxt`, instancia `F5TDp` / código `DatePickerSheet` en `lib/core/widgets/`, sobre `BottomSheetBase`): header con título "Elegir fecha" (17/700) + chip **"Hoy"** a la derecha (`$primary-soft`, label `$primary-on-soft-strong` 13/700, alto 44 para tap target) que salta al mes actual y selecciona hoy.
- **Calendario** (Pencil `Month Calendar` `w4yuu` / código `MonthCalendar`, reutilizable en `core/widgets/`, basado en el grid de `OFdj4`): pill de Month Nav (`cornerRadius:16`, `$surface`+`$border`) con chevrons `‹`/`›` 44×44 (Lucide, con wrap de año dic→ene / ene→dic) y el mes centrado (15/700); Weekday Header "L M M J V S D" **empieza en lunes** (11/600 `$text-secondary`); grilla de celdas 44×44 circulares.
- **Estados de la celda**: seleccionado = `fill $primary`, número `$on-primary` 700; **hoy** (si no es el seleccionado) = **anillo** `stroke $primary` 1px sin fill, número `$text-primary` 600 (decisión: ring, no fill); resto = transparente, número `$text-primary` 500; fuera de mes = celda vacía.
- **Interacción**: tap en un día elige y cierra (patrón del form, sin botón "Aplicar"); el sheet resuelve el `DateTime`. Sin días deshabilitados. Nombres de mes/día vía `intl` (locale-aware); strings de UI "Elegir fecha"/"Hoy" desde `AppLocalizations`.
- **Tema oscuro generado y auditado** (pantalla oscura `nYFOZ`, zona `HXy6n`): día seleccionado `$primary`/`$on-primary` 5.47:1, header `$text-secondary` 5.88:1, chip "Hoy" 5.52:1. Nota menor no bloqueante: el anillo de "Hoy" (`stroke $primary` sobre `$surface` oscuro) queda a 3.00:1, justo en el mínimo de 3:1 para objeto gráfico (igual que en claro; el número interior es plenamente legible).

### Formato de monto — COP sin decimales (decisión app-wide)

El monto se muestra **sin decimales para COP** (`$140.000`, no `$140.000,00`) en toda la app — COP no maneja centavos en la práctica; USD conserva sus 2 decimales. Es solo de **display**: el almacenamiento sigue siendo entero en unidades menores (centavos), regla de oro del proyecto. En código lo centraliza `MoneyFormatter.currencyDecimals(code)` (COP→0, USD→2), usado por `format`/`formatSymbol`/`formatAmount`. La Zona Fija usa `formatSymbol` para mostrar el símbolo `$` (sin el código "COP"). La reconciliación general de unidades menores por moneda vive en `12-multi-moneda.md`.

### Animaciones de la Zona Fija

La transición expandida ↔ colapsada de la Zona Fija está definida (antes solo eran 2 estados estáticos): `AnimatedSize` para el alto + `AnimatedSwitcher` para el cruce de contenido, con `AppTheme.motionDuration` (220ms) y `AppTheme.motionCurve` (`easeInOut`). Tokens de motion nuevos en `app_theme.dart` para reusar en el resto de la feature.

### Historial de decisiones (por qué se llegó a este patrón)

1. Exploración inicial: 3 variantes por tipo con patrones de monto/categoría distintos entre sí (grid de chips vs. campo-selector, calculadora vs. campo discreto) — se unificó a "calculadora protagonista + grid de categoría" en los 3 tipos.
2. Auditoría encontró 6 hallazgos (gap roto de Ingreso, contraste, tap targets, etc.) — todos corregidos.
3. Usuario detectó que el `Keypad` en medio del formulario quedaba en mala zona de alcance del pulgar — se exploraron 4 variantes (V-A Zona Fija estática, V-B bottom sheet dedicado, V-C teclado nativo + accesorio, V-D panel desplegable). `ui-ux-reviewer` recomendó V-A por resolver el problema sin fricción extra y ser la más barata de implementar.
4. Usuario señaló que una Zona Fija permanente chocaría con el teclado nativo al enfocar "Nota" (dos teclados compitiendo por el mismo espacio) — se corrigió con el mecanismo de show/hide por foco descrito arriba, lo cual volvió V-A y V-D funcionalmente equivalentes salvo por el estado por defecto; se descartó V-D por redundante.
5. Aplicado el patrón final a Ingreso y Transferencia (antes solo existía para Gasto).

## Detalle de transacción (HU-08) — construido, tema claro

3 pantallas apiladas (`Page Header` con back `arrow-left`, sin acción a la derecha — se quitó el botón "más opciones" que duplicaba Editar/Eliminar, ya visibles abajo; se mantiene el espacio de 44x44 reservado transparente para no descentrar el título — y sin Tab Bar):

| Tipo | Node ID |
|---|---|
| Gasto | `Of2sW` |
| Ingreso | `s4Wsu5` |
| Transferencia | `xNp8g` |

Estructura común: `Detail Amount Hero` (ref `npfLO`, icon circle + monto grande coloreado por tipo) + card `$surface` con filas de campo (`Info Row`, ref `myfAc`, label arriba/valor abajo, separadas por divisores `$border` 1px: Cuenta(s) → Categoría (si aplica) → Fecha → **Nota** → Origen) + Etiquetas (Gasto e Ingreso, `Tag Chip` ref `nM9ea` con el ícono "x" desactivado; Transferencia no lleva) + `Detail Actions Row` (ref `jt8dk`: "Editar" + "Eliminar movimiento") al fondo. Transferencia muestra 2 filas de cuenta (origen/destino) en vez de Categoría. `Info Row`/`myfAc` no tiene slot de ícono — Cuenta/Categoría se muestran sin ícono inline (mejora futura si se quiere ese nivel de detalle, requeriría extender el componente). El "Info Card" (contenedor de las filas) sigue sin componentizar a propósito (solo 3 instancias con contenido variable, ver Pendientes técnicos).

**Corregido tras auditoría final:** Detalle de Ingreso (`s4Wsu5`) y Transferencia (`xNp8g`) no tenían campo Nota pese a que HU-08 lo exige y ambos formularios lo capturan — agregado en ambos. Detalle de Ingreso tampoco tenía sección de Etiquetas pese a que su formulario sí permite asignarlas — agregada.

**Pendiente:** Botón "Editar" no enlazado a ningún flujo — se asume reutiliza el formulario prellenado (ver HU-04 abajo).

## Eliminar transacción (HU-05) — construido, tema claro

- **`Bf4L8`** "Sheet - Confirmar Eliminar Transacción (Claro)": réplica del patrón "Confirmar Eliminar" de Cuentas (`oymM5`) — `Bottom Sheet Base` + icono `triangle-alert`/`$expense` + mensaje que aclara explícitamente que es reversible ("¿Eliminar este movimiento? Puedes deshacerlo justo después de confirmar." — texto simplificado tras revisión del usuario, la versión anterior sonaba enredada) + `Sheet Buttons Row` Cancelar/Eliminar (`$expense`).
- **Componente nuevo `Snackbar`** (`zSTlU`, fila de componentes `y:140`): barra flotante `cornerRadius:16`, fondo `$text-primary` (invertido), mensaje "Transacción eliminada" en `$background` + acción "Deshacer" en el token `$snackbar-action` (ver `MASTER.md`), sombra sutil, `layoutPosition:"absolute"`, margen lateral 16-20px (no full-width). **Primer componente Snackbar del sistema de diseño** — reusable para cualquier feature que necesite undo. **Corregido tras auditoría final:** el primer intento usaba `$primary-light` (hex fijo sin variante de tema) — daba buen contraste en claro pero se hubiera roto en oscuro al invertirse `$text-primary`. Se creó `$snackbar-action` con valores por tema (6.23:1 claro, 6.03:1 oscuro).
- **`lwvDp`** "Movimientos - Snackbar Undo (Claro)": copia de referencia de `B3GGa` con el Snackbar superpuesto. Posición ajustada tras feedback del usuario ("no me convence que se muestre tan arriba"): el Snackbar quedaba a solo 12px del FAB, flotando en la mitad-baja de la pantalla en vez de anclado al borde inferior real. Se movió a `y:758` (pegado arriba del Tab Bar) y el FAB se corrió a `y:690` (donde antes estaba el Snackbar) para que no se superpongan — swap de posiciones entre ambos. Se evaluó como alternativa un patrón de "fila fantasma" inline (la fila eliminada se queda en su lugar mostrando "Eliminado — Deshacer" antes de colapsar) en vez de un elemento flotante nuevo, pero el usuario prefirió mantener el Snackbar solo reposicionado.

**Nota técnica de Pencil:** `Copy()` de una instancia que ya trae `descendants` anidados en su fuente (como `oymM5`) no es confiable para volver a sobreescribirlos — falla con "Node not found for override path" tanto en el `Copy` como en `Update` post-hoc. Reconstruir con `Insert()` directo del `ref` + un solo nivel de override funcionó.

**Pendiente:** gesto de swipe-to-delete en la lista no diseñado (solo el resultado/snackbar). Temporizador/auto-dismiss y transición de entrada-salida del Snackbar sin especificar.

## Filtros, rango personalizado y modales — construido, tema claro

Las 7 piezas que cerraban el 100% de cobertura de HU. Todas reutilizan `Bottom Sheet Base` (`PqTUt`). **Ninguna tiene todavía la interacción real de apertura enlazada desde su chip/fila origen** (mockups estáticos, mismo criterio que el resto de sheets de la feature).

| Pieza | Node ID | HU |
|---|---|---|
| Sheet - Filtro de Cuentas | `jpARf` | HU-06a |
| Sheet - Filtro de Categoría | `q0CTl` | HU-06 |
| Sheet - Filtro de Tipo | `rjjfw` | HU-06 |
| Sheet - Filtro de Etiqueta | `FL1gK` | HU-06/HU-07 |
| Sheet - Rango Personalizado | `OFdj4` | HU-06b |
| Sheet - Nueva Etiqueta | `NazyV` | HU-07 |
| Sheet - Aviso Impacto Edición | `L9DJI` | HU-04 |

- **Filtro de cuentas** (`jpARf`): nuevo componente **`Filter Account Row`** (`X3tZG`) — icono circular + nombre/tipo + saldo, reusado en las 4 filas de ejemplo (Efectivo y Nequi marcadas). "Todas" en la cabecera (se quitó "Ninguna" 2026-07-20: no aporta valor, seleccionarla dejaría la lista sin movimientos) + `Button/Primary` "Aplicar" al fondo.
- **Filtro de categoría** (`q0CTl`): **lista expandible raíz + subcategorías**, no un grid plano (rediseñado — ver detalle abajo).
- **Filtro de tipo** (`rjjfw`): filas seleccionables (mismo patrón que cuentas, ver abajo) — no `Segmented Control`, decisión deliberada (HU-06 permite combinar tipos, no son mutuamente excluyentes).

**Corregido tras auditoría final:** los 4 sheets de selección múltiple (Cuentas, Categoría, Tipo, Etiqueta) ahora tienen el mismo header con acciones rápidas "Todas"/"Ninguna" — antes solo lo tenían Cuentas y Categoría. El patrón sigue sin ser un componente formal `reusable:true` (4 instancias ad-hoc), candidato a componentizar si se agrega un 5º filtro. Se corrigió también el typo "categoria"→"categoría" (sin tilde) en el placeholder de la Search Bar, repetido en las 6 pantallas de la Lista (5 estados + `lwvDp`).

### Filtro de categoría — jerarquía de subcategorías (rediseño)

HU-06 exige poder filtrar por categoría "incluye subcategorías si se elige la raíz" — el grid plano original de 4 `Category Chip` no lo permitía. Rediseñado como lista expandible, reusando el patrón visual `Root Row`/`Sub Row` que ya existe en la pantalla de gestión de Categorías (`jSNz7`) — reconstruido a mano (ese patrón no es `reusable:true` en origen, no había `ref` que instanciar):

- **Fila raíz**: icon-wrap + nombre + contador de subcategorías + `Chevron Wrap` 44x44 independiente (expande/colapsa, acción separada de seleccionar) + patrón de fila seleccionable (ver abajo). **Toggle simétrico** (documentado en HU-06 de `docs/requirements/03-transacciones.md`): tocar la raíz selecciona automáticamente todas sus subcategorías; volver a tocarla (ya seleccionada) las deselecciona todas junto con ella. El usuario también puede deseleccionar subcategorías individuales sin afectar a las demás ni a la raíz (selección granular parcial) — solo la acción sobre la raíz misma actúa en bloque sobre todo el árbol. Comportamiento de datos, no modelado como interacción real en el mockup estático.
- **Fila de subcategoría**: indentada (56px padding-left, mismo que `Sub Row`), también seleccionable individualmente con el mismo patrón — permite filtrar por una subcategoría puntual sin arrastrar toda la raíz.
- Mockup de ejemplo: 4 raíces (Comida y bebida/Transporte/Vehículo/Ocio), **Vehículo expandida** mostrando sus 5 subcategorías. **Comida y bebida** seleccionada como raíz completa; **Combustible** (subcategoría de Vehículo) seleccionada individualmente — demuestra ambos casos de uso en un solo mockup.
- Cabe completo en los 972px del sheet sin scroll con estos datos de ejemplo; con una lista de categorías más larga en producción, sí podría necesitarse `ListView` real en Flutter (no diseñado ese caso).

### Patrón de selección múltiple — fila completa (decisión final, reemplaza checkbox)

Tras explorar 2 variantes (checkbox circular vs. fila completa cambia de estado), el usuario eligió: **sin checkbox dedicado, toda la fila es el control.** Sin seleccionar: `fill:$surface` + `stroke:$border`. Seleccionada: `fill:$primary-soft` + `stroke:$primary` + ícono `check` 18px `$primary-on-soft` en un slot fijo de 24x24 a la derecha (slot siempre reservado, icono con `enabled:true/false`, para no desalinear el contenido al des/seleccionar). Aplicado a `Filter Account Row` (`X3tZG`, override de `fill`/`stroke` en el root de la instancia) y a las filas de `rjjfw`. Referencia de la decisión conservada en el canvas: `vzVjI` ("Referencia - Patron Fila Seleccionable"). El componente `Checkbox` circular explorado y descartado (`TVDE9`) fue borrado por quedar sin uso.
- **Filtro de etiqueta** (`FL1gK`): lista tipo `Currency Row` + search bar arriba (viaje-cartagena, deducible, trabajo, regalo de ejemplo). Header `Actions` (`IGeAG`): "Todas"/"Ninguna" para el filtro de lista; un 3er elemento **"+"** (ícono `plus`, `$primary-on-soft`, agregado 2026-07-19) para el contexto de selección-para-asignar (campo "Etiquetas" del formulario, HU-07) — el código decide cuál subconjunto mostrar según el título pasado. Tiene contraparte oscura `a5PH7i`, también con el "+" agregado.
- **Rango personalizado** (`OFdj4`): calendario visual completo (nav mes/año + grid de 35 celdas, rango 3–9 jul 2026 resaltado: extremos en `$primary` sólido, días intermedios en `$primary-soft`) + `Button/Primary` "Aplicar" — es la única pieza de HU-06b que sí requiere confirmación explícita.
- **Nueva etiqueta** (`NazyV` / oscuro `YHAWB`, ya existía y ya estaba documentado — confirmado 2026-07-19 tras descartar un duplicado creado por error): sheet compacto, un `Form Field` de texto + `Button/Primary` "Crear".
- **Aviso de impacto al editar** (`L9DJI`, HU-04): icono `link-2` en `$primary-soft`/`$primary-on-soft` (informativo, no destructivo — no usa `$expense`) + mensaje de ejemplo vinculado a una meta + `Sheet Buttons Row` "Cancelar"/"Continuar".
- **2026-07-19 — consolidación de `Tags Row`/`Tag Chip`:** igual que con las categorías, había 12+ instancias sueltas del patrón etiqueta-asignada + chip "Nueva" con colores inconsistentes (la mayoría con el chip "Nueva" en `$muted`/`$text-secondary` gris, desactualizado). Se consolidaron en un componente reusable único (`cDmhX`, compone `Tag Chip` `nM9ea` + "Add Chip" `r1Oh6`) con el esquema correcto de `rlnXj`: chip asignado `$primary-soft` sin borde; "Nueva" en `$surface`+borde `$border`+ícono/texto `$primary-on-soft-strong`. En código, `TransactionFormTagChip` (compartido, ya no duplicado en `scheduled_payments`) tenía además un bug real de layout — `Container(alignment: Alignment.center)` sin ancho explícito se estiraba a todo el ancho dentro del `Wrap` (bug clásico de Flutter, no de diseño); corregido envolviendo el chip en `IntrinsicWidth`.

### Decisiones ya confirmadas por el usuario

1. **Patrón de fila completa seleccionable (no checkbox)** en Filtro de Cuentas, Filtro de Tipo y Filtro de Categoría (raíz/subcategoría) — se exploraron variante circular y variante de fila completa, el usuario eligió fila completa (ver sección "Patrón de selección múltiple" arriba). Reemplaza la mención previa de "checkbox cuadrado".
2. **Filtro de Tipo con filas seleccionables, no `Segmented Control`** — confirmado: HU-06 permite combinar tipos (Gasto+Ingreso a la vez), y el `Segmented Control` del sistema siempre implica selección única.
3. **Search bar en el Filtro de Etiqueta** — se mantiene, sin objeción del usuario.
4. **Calendario completo en Rango Personalizado** — confirmado explícitamente por el usuario ("Sí, mantener calendario completo").
5. **Botón "Continuar" (no "Continuar de todas formas")** en el Aviso de Impacto — sin objeción, se mantiene.

## Componentes reutilizables usados

`Bottom Sheet Base`, `Transaction Row`, `Status Bar/Android`, `Tab Bar`, `Page Header`, `Segmented Control`, `Category Chip`, `Form Field`, `Empty State`, `Skeleton Row`, `Button/Primary`, `Button/Secondary`, `Info Row` (`myfAc`), `Delete Link` (`u0THG`), `Sheet Buttons Row` (`Ot4yI`), `Currency Row` (`Q6KVp`), `Day Cell` (`gVeaW`), `Keypad` (`gHDTi`), `Zona Fija - Monto Expandida` (`Rslzk`), `Zona Fija - Monto Colapsada` (`ofg07`), `Snackbar` (`zSTlU`), `Button/FAB` (`H5mzN`), `Detail Amount Hero` (`npfLO`), `Detail Actions Row` (`jt8dk`), `Tag Chip` (`nM9ea`), `Filter Account Row` (`X3tZG`, nuevo — icono+nombre/tipo+saldo+checkbox, usado en el Filtro de Cuentas y en el sheet de cuenta del formulario en modo single-select, disponible para futuras listas de selección múltiple con saldo visible), `Category Quick Picker` (`EIoVx`), `Category Select Sheet` (`SfSln`), `Category Select Row` (`SLfJW`), `Account Select Sheet` (`fcVZN`, ref `a510v`), `Date Picker Sheet` (`zMqxt`, instancia `F5TDp`), `Month Calendar` (`w4yuu`, base del calendario de fecha única del formulario). El "Info Card" del Detalle queda como construcción específica de cada pantalla (a propósito, ver pendientes técnicos).

**Variable nueva:** `primary-on-soft-strong` — `light:#5648C8` (= `primary-deep` claro), `dark:#A78BFA` (= `primary-on-soft` oscuro, sin cambio visual ahí). Excepción de contraste creada específicamente para el label del `Category Chip` en estado seleccionado (13px/700 sobre `$primary-soft`/`$background` no alcanzaba 4.5:1 con `primary-on-soft`; con este token da 6.04:1 en claro). Falta agregarla a la tabla de paleta de `MASTER.md`.

## Pendientes conocidos — huecos contra las HU

Solo quedan 2 huecos reales contra `docs/requirements/03-transacciones.md` (todo el resto de pantallas/modales ya están construidos):

- **Punto abierto de negocio**: el sheet de fecha (`P5fSkK`) ya no tiene forma de volver a "Todo"/histórico completo tras quitarse el toggle "Ver todo" — HU-06b sigue documentando esa acción, sin resolver.

## Pendientes técnicos (no bloquean, quedan anotados)

- **Interacción real de navegación del stepper** de fecha (wrap de años, feedback de transición): no definida, solo estado estático. Mismo pendiente en el nav mes/año del calendario de Rango Personalizado.
- **Interacción real de apertura de cada sheet nuevo** desde su chip/fila origen (Chips de la Lista, fila "Rango personalizado", chip "+ Nueva" del formulario): todos son mockups estáticos sin el enlace de navegación definido.
- **"Info Card" del Detalle** (`n1PgQ`/`P0qZJ3`/`BGgi4`): sin componentizar a propósito — solo 3 instancias con contenido variable, decisión explícita del reviewer de dejarlo ad-hoc.
- **Interacción real de mostrar/ocultar la Zona Fija**: la animación de colapso ya está definida en código (`AnimatedSize`+`AnimatedSwitcher`, 220ms `easeInOut`, ver "Animaciones de la Zona Fija"); queda por especificar el detalle de cómo se dispara el foco de "Nota" en Flutter (aún solo representada como 2 estados estáticos en Pencil).
- **Tema oscuro**: cerrado para toda la feature. Las 24 pantallas del resto (Lista + estados, 6 formularios, Detalle, Eliminar/Snackbar, Filtros y sheet de fecha) viven en la zona "TRANSACCIONES — OSCURO" (label `h6URn`) y fueron generadas con `Copy()` + `theme:{mode:"dark"}` desde cada frame claro y auditadas (ver "Auditoría de tema oscuro" arriba). Los **tres selectores del formulario** (categoría `BobKK`/`fz53P`, cuenta `Zsrnf`, fecha `nYFOZ`) tienen su copia oscura en la zona aparte `HXy6n`, también auditada. El recoloreo salió 100% por variables (cero hex hardcodeado), porque toda la estructura repetida está componentizada y las pantallas oscuras instancian los mismos componentes `reusable:true` que las claras — así el rework del formulario (teclado, selectores, Zona Fija) se propaga solo a ambos temas.
