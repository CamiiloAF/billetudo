# Página: Gráficas e informes

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras tres rondas de corrección y tres auditorías de `ui-ux-reviewer`. Requisitos en `docs/requirements/10-graficas-informes.md`. Vive en el hub "Más" y tiene chip de acceso rápido en Inicio. Cross-link a Deudas. **Ampliación 2026-07-29/30:** 6 pantallas nuevas (5 estados de carga/vacío que faltaban + destino de "Ver subcategorías") aprobadas en claro y oscuro, auditadas por `ui-ux-reviewer` (3 hallazgos IMPORTANTE corregidos en la variante "Con dona"). **Excepción (2026-07-30, en revisión):** la interacción del donut de Categorías cambió (ver "Interacción del donut de Categorías" más abajo) — `A3zxf` fue modificado y lleva marca `🔖 EN REVISION` en el canvas junto con sus dos nuevas variantes (`tCOi4`, `d2bv47`), solo en tema claro hasta que el usuario apruebe explícitamente; `Zyd8k` (oscuro) no se toca todavía.

## Tesis (norte del diseño)

Cuatro vistas del set esencial, **una a la vez a pantalla completa**, con un control de tabs arriba. No es un dashboard que apila gráficos pequeños: cada pregunta tiene su pantalla y su gráfico grande.

El norte es **honestidad sin castigo**. Todas las cifras se muestran completas y con signo; ningún estado maquilla un mal mes ni finge datos que no existen. El color nunca emite un juicio: el balance positivo se celebra en `$income-text`, pero el negativo va en `$text-primary` — nunca en `$expense`. La asimetría es deliberada (ver "Balance negativo").

Cada gráfico **responde una pregunta**: Resumen "¿cómo voy en conjunto?", Flujo "¿gané más de lo que gasté?", Patrimonio "¿estoy creciendo?", Categorías "¿en qué se me va?".

## Frames

Todas las piezas existen en Claro y en su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido y estructura, solo recolorea).

### Vistas (los 4 tabs)
| Pantalla | Claro | Oscuro |
|---|---|---|
| Resumen — presupuestos + metas + cross-link (HU-04) | `xZvir` | `FGzgC` |
| Flujo — ingresos vs. gastos mes a mes (HU-01) | `o8uzbT` | `BmKsK` |
| Patrimonio — líquido vs. total (HU-02) | `kgM3u` | `bX4is` |
| Categorías — dona + desglose (HU-03) | `A3zxf` | `Zyd8k` |
| Categorías — dona, con selección (Vivienda) | `tCOi4` | **no construido** (solo claro, ver "en revisión" abajo) |
| Categorías — dona, pill "Atrás" (subcategorías) | `d2bv47` | **no construido** (solo claro, ver "en revisión" abajo) |

### Estados (HU-06)
| Estado | Claro | Oscuro |
|---|---|---|
| Flujo — vacío (cero movimientos en el rango) | `NPXSP` | `TWoDk` |
| Flujo — carga (skeleton) | `ITx4K` | `caHER` |
| Flujo — historial insuficiente | `o5887` | `l7cQj` |
| Flujo — fallo de sync (no bloqueante) | `ZhpWo` | `k4SZI` |
| Flujo — balance negativo | `V1PNE` | `p3C3D8` |
| Resumen — vacío (sin presupuestos ni metas) | `XQVQe` | `SsnL0` |
| Resumen — carga (skeleton) | `Mvjzq` | `a7rxu` |
| Patrimonio — carga (skeleton) | `iWBYq` | `bzqEm` |
| Patrimonio — vacío (sin cuentas) | `OZvwz` | `Nl2Mk` |
| Categorías — carga (skeleton) | `s28FH` | `G8log5` |
| Categorías — vacío (sin movimientos) | `wQcSY` | `CIUzC` |

Las 5 filas nuevas (Resumen/Patrimonio/Categorías) siguen el mismo lenguaje ya validado en Flujo — mismo criterio de altura uniforme en los skeletons, mismo `Empty State`. CTA de cada vacío: Patrimonio → "Agregar cuenta" (pide cuentas, no movimientos); Categorías → "Agregar movimiento".

### Sheets
| Pieza | Claro | Oscuro |
|---|---|---|
| Selector de Periodo | `Sy92N` | **no construido** (hueco conocido) |
| Selector de Periodo — rango personalizado activo | `c3gyor` | `XkFWg` |

**Estado "rango personalizado activo" del Selector de Periodo** (`c3gyor`, frame separado del base `Sy92N` — mismo patrón que Transacciones usa con `mi0hB` separado de su sheet base): se muestra cuando `ReportsPeriodSelection.kind == custom`, es decir, cuando el usuario ya aplicó un rango de fechas personalizado como filtro activo.

Tratamiento:
- La fila **"Rango personalizado"** (`qiXGl`) queda resaltada: fill `$primary-soft`, borde `$primary-on-soft-strong`, ícono de check, y el texto muestra el rango real aplicado (ej. "mar – ago 2026") en vez del label genérico.
- El segmentado Mes/Año (`RArsH/JipTk`) y el stepper (`RArsH/P3Fyb`) permanecen en su **estado normal habilitado** (opacity:1, sin fondo activo en ningún segmento) — **no** se deshabilitan ni atenúan, porque siguen siendo interactivos: tocar Mes o Año reemplaza el rango personalizado por ese filtro (cambia `kind` de `custom` a `month`/`year`).

### Ver Subcategorías (destino de "Ver subcategorías")
| Pantalla | Claro | Oscuro |
|---|---|---|
| Ver Subcategorías — variante C, con dona | `BfdaF` | `fqc0X` |

## Componentes propios de la feature

| Componente | ID | Nota |
|---|---|---|
| Chart Tabs | `I1Jgk` | 4 tabs, 84×46 cada uno. No se reusó `Segmented Control` (`hFu41`): es de 3 opciones. |
| Chart Period Row | `c2u8DB` | Period Selector + caption de rango. **No existe en Resumen** (ver D2). |
| Period Selector | `lxWG8` | 179×44, abre `Sy92N`. |
| Chart Legend Item | `DyQfQ` | Contrato: **color = serie graficada**. No usarlo como etiqueta de sección. |
| Cashflow Bar Column | `lbZWZ` | Columna de Flujo (ingreso/gasto/deuda). |
| Net Worth Bar Column | `VBliq` | Columna de Patrimonio. Su serie "total" usa `$primary-data`. |
| Cashflow Net Hero | `hLmoN` | Hero de Flujo. Explicación y enlace de salida **apagados por defecto**. |
| Report Card | `dflhE` | Tarjeta contenedora, padding 16. |
| Chart Cross-link Card | `wvAKu` → **Cross-link Deudas Card** | Renombrado: icono y label están horneados, es de un solo caso. |
| Goal Summary Row | `He7JZ` | Fila de meta en Resumen (anida `q1qGr`). |
| Card Empty | `S27V2` | Vacío dentro de una tarjeta, CTA reemplazable por slot. |
| Chart Drill Pill | `OiM6E` | Pill de drill-down del donut (44px, borde superior). 3 estados vía overrides: inerte (`$segment-inactive-text`), habilitado "Ver subcategorías" (`$primary-on-soft`, chevron-right), "Atrás" (`$primary-on-soft`, chevron-left a la izquierda vía slot `enabled:false`/`true`, no reordenando hijos). Reemplaza 3 copias inline (`guwa6`→`gbZI4`, `kjLPg`→`Ok2bd`, `FK2qi`→`Fkwo3`). Renombrado a "Profundizar" y reposicionado (ver "Categorías — interacción de la dona y drill-down"). |

Reusados sin modificar: `Dtm0X` Page Header, `vYZJT` Status Bar, `FSL69` Budget Line, `DRc5X` Category Row, `gZyEC` Toggle Field, `hIbs3` Menu Row, `jmQO5` Empty State, `j7Zvt`/`pNjOz` botones, `q1qGr` Goal Ring/Mini.

## Chrome común (los 10 frames)

- `Page Header` **sin** Tab Bar: es pantalla apilada desde "Más".
- Acción derecha del header = **ícono `image-down`** → exportar la vista como imagen (HU-05). No hay botón de export al fondo.
- Wrapper `Content`: padding `[10,20,12,20]`, gap **8** — **excepto Resumen, que usa 14** (ver D2-bis).
- Heroes: padding `[12,16]`, gap 6. Tarjetas `Report Card`: padding 16.
- **Regla del Label Row:** el hero lleva Label Row **solo cuando hay una cifra protagonista**. Con dos figuras (Resumen, Patrimonio) cada una trae su propio rótulo y un Label Row global sería redundante.

## Decisiones cerradas

### Navegación y rango

**Resumen es el tab por defecto** y el primero: es la respuesta de 3 segundos. Orden: Resumen · Flujo · Patrimonio · Categorías.

**D1 — Los tabs quedan fijos al hacer scroll.** El `Content` de los 4 frames de Resumen está partido en dos hijos y **esa partición es la especificación**:
- `Zona fija — NO scrollea` (`zGEVW` claro / `R0yz4I` oscuro / `Y0ZMT` vacío claro / `Djmmg` vacío oscuro): solo los Chart Tabs.
- `Zona scrolleable` (`jMg1w` / `aFkcw` / `wVZrk` / `W8ro0o`): hero + cards + cross-link.

En Flutter: Status Bar + Page Header + Chart Tabs van **fuera** del scrollable. Aplica a los 4 tabs — los tabs nunca se van de pantalla. Se implementa **quepa o no** el contenido: 972 es el viewport, no el techo. En Flujo/Patrimonio/Categorías el Period Row viaja **con** el contenido (no está pinneado).

**Rango compartido entre los 4 tabs.** Cambiar de tab conserva el periodo; el default es "Últimos 6 meses". **D2 — En Resumen no hay Period Row**: era un control de 44px cuyo efecto ocurría en otra pantalla, desmentido por una nota de 12px debajo. El rango vive en los tres tabs donde aplica y **se conserva** al salir y volver a Resumen (no se resetea).

**D2-bis:** al quitar el Period Row, Resumen volvió a **972** (48px de holgura). No hay ninguna pantalla scrolleable-por-altura en el deck.

### Color

**`$primary-data`** es el violeta que **grafica un dato**; `$primary` es identidad de marca. Claro `#6C5CE7` (idéntico a `$primary`, cero cambio visual); oscuro `#8F7BF2` en vez de `#6D4FE0`, porque `$primary` oscuro medía **exactamente 3.00:1** sobre `$surface` — el mínimo de WCAG 1.4.11 sin margen. Aplicado en: arco de "Vivienda y servicios", su barra de desglose, la serie "Patrimonio total" y los puntos de leyenda que la keyean.

> **Migración pendiente de aprobación** (nota `p1t42T`): `FSL69`, `q1qGr` y `EB2TX` siguen en `$primary` y tienen el mismo problema (2.57:1 contra el track en oscuro). Son los únicos elementos de dato del deck por debajo de 3:1. La migración debe hacerse **en el componente** o no hacerse: el mismo presupuesto se ve en Resumen y en su pantalla propia, y migrar un solo lado lo pintaría con dos violetas distintos.

**Identidad de categoría vs. estado de presupuesto** (nota `w437bF`): en Resumen la identidad viaja en el **ícono** (`$mint`/`$sky`/`$peach`, iguales a `Category Row`) y el estado en la **barra** (`$primary`, con `$primary-light` reservado al tramo programado de HU-12). Se hizo por override de instancia; `FSL69` quedó intacto y Presupuestos no cambió. **Si alguna vez el ícono tuviera que señalar estado, habría colisión — no hacerlo.**

**"Sin categoría" se pinta con `$text-secondary` a propósito** (nota `YGtpe`): no es una categoría, es la ausencia de una; darle color propio la ascendería al rango de Mercado o Transporte. Regla general: **se crea un token de dato cuando el token prestado falla contraste en algún tema, no cuando solo incomoda por su nombre.**

**Stats Row del hero va neutro** (nota `TvFBN`): ingresos y gastos ambos en `$text-primary`. El verde ya está tomado por la cifra protagonista; los subs son dato de respaldo. Divergencia consciente con `Transaction Row`, donde el color distingue tipo de movimiento en una lista mixta.

### Balance negativo (lo más sensible del deck)

Regla dura: **nunca avergonzar al usuario por sus gastos**. Cómo se resolvió (nota `h7J4f`):

1. **Color neutral**: el monto negativo en `$text-primary`, nunca `$expense`. El positivo sí en `$income-text`. Si el negativo fuera rojo, el color estaría juzgando un dato que el signo ya comunica.
2. **Sin ícono de alarma**: `scale` (balanza) en `$text-secondary`. Describe la operación, no emite veredicto.
3. **El número es honesto**: signo menos y cifra completa; las barras dejan ver el gasto por encima del ingreso.
4. **La jerarquía hace lo que haría el color**: el label pasa de "Ahorraste…" a "Balance de los últimos 6 meses", y debajo entra la explicación. Copy vigente: *"Salió $1.180.000 más de lo que entró en estos 6 meses. Abajo puedes ver qué meses pesaron más."* Lo que hace el trabajo es la **segunda frase**: devuelve al usuario a la evidencia que ya tiene delante. El dato se explica con dato, no con consuelo ni con reproche.
5. **Salida hacia adelante**: fila tocable de 44px "Ver en qué se fue" → tab Categorías.

Descartadas: fondo `$expense-soft` (tiñe la pantalla de alarma), badge "Mes en rojo" (etiqueta al usuario, no al dato), ocultar el signo (deshonesto), y *"Suele pasar en meses con gastos grandes"* (normaliza asumiendo una causa que la app no conoce).

**Variantes de copy para l10n** (nota `Ojbfk`): la primera frase es constante en forma, la segunda depende del rango — mes único (agregación por día), varios meses, rango personalizado, historial corto. **Prohibido en estas cadenas:** "suele pasar"/"no te preocupes" (excusa), "te pasaste"/"gastaste de más" (juzga). El monto siempre con signo y cifra completa.

### Categorías — interacción de la dona y drill-down (reemplaza el tap-and-hold)

**Decisión del usuario, ya implementada** (reemplaza cualquier mención previa de "mantener presionado para revelar" en esta pantalla, y reemplaza también la exploración alterna "Category Switch Chip"/`SspER` de destino en pantalla propia — nunca se implementó, ver más abajo):

- **Tap simple con selección persistente**, no tap-and-hold: tocar un arco lo deja seleccionado (radio mayor) hasta que se toque otro arco (cambia la selección) o se vuelva a tocar el mismo (deselecciona). Nunca dos arcos resaltados a la vez.
- **Centro de la dona**: con selección activa, muestra el **nombre de la categoría** sobre el monto gastado en ella (acotado en ancho con ellipsis, para que nombres largos no se desborden del círculo); sin selección, vuelve a mostrar solo el total (como hoy).
- **Botón "Profundizar"** (antes "Ver subcategorías"): reposicionado arriba de la dona, alineado a la derecha, estilo compacto (reemplaza la fila full-width de 44px con borde superior). **Solo aparece cuando está habilitado** (hay una sección seleccionada con subcategorías) — reserva su espacio (`Visibility(maintainSize: true)`) para no desplazar el resto del contenido al aparecer/desaparecer.
- **Drill-down in-place, no pantalla nueva**: al tocar el botón con una categoría seleccionada, la misma dona y el desglose se re-renderizan con las subcategorías de esa categoría, y la selección se limpia al entrar al nuevo nivel. Esto resuelve el pendiente "destino de 'Ver subcategorías'" — nunca hubo que diseñar un destino, es el mismo frame con otro nivel de datos.
- **Botón "Atrás"**: mismo componente que "Profundizar", pero en el nivel de subcategorías cambia su copy/ícono a "Atrás" (chevron hacia atrás) y regresa al nivel de categorías raíz sin selección activa (componentizado en `Chart Drill Pill` `OiM6E`, ver tabla de componentes).
- **Tap en una card de categoría o subcategoría** (fuera de la dona, en el desglose) navega a Movimientos preseleccionando el filtro por esa categoría y el rango de fechas activo en Gráficas, y el back (botón o gesto del sistema) vuelve a esta pantalla en la pestaña Categorías, no a Inicio.

### Estados

- **Vacío**: `Empty State` centrado + CTA "Agregar movimiento". Nunca un gráfico de ceros.
- **Carga**: skeleton con la **geometría real** del gráfico (plot de 330px reservando la nota de mes en curso, para que no salte al cargar) y barras de altura **uniforme** — si variaran, insinuarían datos. Los tabs y el selector siguen visibles y usables; el chrome no entra en carga.
- **Historial insuficiente**: la vista **no finge** una serie larga. Acota el rango a lo que existe y **cambia la agregación de meses a días**. Un día sin ingresos dibuja un stub de 3px: cero ≠ sin dato.
- **Fallo de sync**: **no** es error a pantalla completa. La gráfica se ve entera con todos sus datos y el fallo es una tira discreta en `$amber` (no `$expense`) que lleva al Estado de sincronización. Hay cambios esperando, no algo roto. Mismo criterio que `04-inicio.md` HU-10. Es una presentación distinta al mismo evento de dominio que en Inicio muestra `Sync Indicator` (`saRZW`) en el header: divergencia deliberada, documentada en el `context` de la tira.
- **Resumen vacío**: cada tarjeta lleva su vacío con su CTA en el lugar. **Un solo CTA primario por pantalla** (nota `FR1Gz`): "Crear presupuesto" Primary, "Crear meta" Secondary — dos primarios apilados compiten y ninguno gana. Patrón reusable: dos `Card Empty` hermanas apiladas → la primera Primary, las siguientes Secondary.

### Destino de "Ver subcategorías" (pendiente #3, resuelto 2026-07-29)

**Variante "Con dona" (`BfdaF`)**: el link "Ver subcategorías" de la tarjeta de Categorías (`A3zxf`/`guwa6`) navega a una pantalla propia con `Page Header · Con subtítulo` (`s9gXs`, título = nombre de la categoría, subtítulo = rango vigente) y una `Report Card` (`dflhE`) con dona + desglose de subcategorías, mismo lenguaje que la dona de Categorías.

**Switcher horizontal de categorías, no un link por fila**: el link real en `Card Categorías` es único, al final de la tarjeta — no hay un "ver subcategorías" por cada fila del desglose. Por eso el destino no asume que se llegó desde una categoría fija: trae un `Category Switcher` horizontal (`Category Switch Chip` × N, componente nuevo `SspER`) para cambiar de categoría sin volver atrás. Contrato de selección: 3 señales (stroke + color de ícono + color de texto), nunca el fill solo.

Descartadas en esta ronda (borradas del canvas al elegir C): variante A "lista simple" (página completa sin gráfico) y variante B "hoja/bottom sheet" (mismo contenido en `Bottom Sheet Base`).

## Notas para implementación

- **Patrimonio se implementa como `LineChart`**, no barras (nota `khZjH`). El `.pen` usa barras **solo** porque Pencil no puede dibujar líneas; es una aproximación declarada, no la especificación. El resto del frame (hero de dos cifras, nota del interés, toggle de archivadas, jerarquía, colores) sí es especificación.
- **La 7ª columna "ene" del gráfico de patrimonio** no es decorativa: el neto de caja del periodo **es** el cambio del patrimonio líquido, y con solo 6 columnas esa identidad es aritméticamente imposible (el delta feb→jul solo puede valer el neto de mar–jul). La columna de partida es lo que permite que endpoints y pasos mensuales cuadren a la vez.
- **Las figuras del hero de Resumen no usan `Chart Legend Item`** a propósito: son etiquetas de sección, no leyendas de serie. Ese componente reserva el color para keyear una serie graficada.
- **Lectura de valores**: los gráficos no tienen ejes ni escala, así que **deben poder tocarse** para leer la magnitud (tap en barra, punto o segmento → valor y periodo). Sin eso el gráfico es decorativo y todo el peso informativo queda en el hero. **No está diseñado todavía**, salvo en Categorías, donde ya se resolvió con selección persistente (ver "Categorías — interacción de la dona y drill-down").
- **Accesibilidad**: cada gráfico expone un resumen textual vía `Semantics` — un lector de pantalla no puede recorrer las barras. En la dona, `peach` y `coral` son el par adyacente más cercano (~36° de matiz): cada arco está keyeado por su fila con ícono y nombre, así que el color no es el único canal.
- **Multimoneda está fuera de este entregable** (nota `O91yc8`): no hay rótulo de "cifra aproximada" ni segmentación por moneda. Se asume moneda única.
- **Datos de mockup no son especificación**: son coherentes dentro de cada plantilla y entre frames que comparten hero, no globalmente.

## Pendientes conocidos

1. **Migración de `FSL69`/`q1qGr`/`EB2TX` a `$primary-data`** — requiere aprobación del usuario; toca Presupuestos y Metas, ya aprobadas.
2. **Variante oscura del sheet Selector de Periodo base (`Sy92N`)** — no construida (el estado "rango personalizado activo" ya tiene su oscuro en `XkFWg`, aprobado).
3. **Sin diseñar**: tooltip de lectura de valor al tocar (salvo Categorías, ver arriba), share sheet del sistema tras el ícono de export, hoja de rango personalizado más allá del caso base, variante ON del toggle "Incluir cuentas archivadas". ~~Destino de "Ver subcategorías"~~ — resuelto, ver "Categorías — interacción de la dona y drill-down".
4. ~~Tema oscuro pendiente para las 6 pantallas nuevas de 2026-07-29~~ — resuelto 2026-07-30, ver nodeIds oscuros en "Frames".

## Apéndice — detalle archivado del canvas (aseo 2026-08-04)

Contenido de notas cerradas del `.pen` que no estaba tejido en la prosa de arriba; se archiva aquí antes de borrarlas del canvas.

- **Export en el header, ícono (nota `jeEeC`)**: se eligió `image-down` sobre `share-2` porque la acción que el usuario reconoce es "guardar la imagen de esta gráfica" — el share sheet del sistema es solo el vehículo, no la intención. Los ~60px que se liberaron del footer de tabs al remover una barra redundante se repartieron al gráfico en Flujo/Patrimonio, y en Categorías los absorbió la barra de `Category Row`.
- **Estados propios de Resumen (nota `lmvPQ`)**: de los tres estados (vacío/carga/error), solo el **vacío** es propio de Resumen y aprobado con HU-06 (ver "Resumen vacío" arriba). Carga y error se heredan del mismo lenguaje ya validado en Presupuestos y Metas — no se diseñaron variantes nuevas para Resumen.
- **Rango compartido no se resetea en el cross-link (nota `Jqrol`)**: al tocar "Ver en qué se fue" desde Flujo/balance negativo hacia Categorías, el rango de fechas activo (ej. "Últimos 6 meses") **no cambia** — se conserva porque Categorías necesita mostrar el mismo total de gastos que motivó el salto. Pendiente sin resolver, y posiblemente ya superado: la hoja del Period Selector (elegir mes / últimos N meses / rango personalizado) fuera del caso base — verificar si `Sy92N` ya lo cubre antes de tratarlo como hueco real.
