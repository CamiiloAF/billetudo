# Página: Metas de ahorro

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras el rediseño bajo la tesis "tablero de aspiraciones con momentum" y varias rondas de `ui-ux-reviewer`. Requisitos en `docs/requirements/fase-1/07-metas.md`. Cross-link con Pagos Programados (aporte recurrente) y Transferencias presupuestables (flag `countsInBudget`).

## Tesis (norte del diseño)

Metas NO es Deudas: una deuda es una obligación que quieres que baje (sobria, administrativa); una meta es una aspiración que quieres que suba (cálida, motivadora, que jala). Reusa la **plomería** de Deudas (ledger, sheets, pickers, archivado) pero **no** su registro visual. Cuatro palancas: **arco de progreso como héroe** (no barra), **encuadre hacia adelante** ("Te faltan $X · a tu ritmo, en marzo"), **celebración a pantalla completa** en el 100%, y **momentum** (racha + próximo hito) en vez de conteo frío. **Sin imágenes/portadas** (decisión cerrada): la identidad la dan el ícono expresivo + el arco + el copy. **Sin color por meta** (HU-01); el color es solo semántico (progreso; cumplida en `$income-text`).

## Frames

Todas las piezas existen en tema Claro y en su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido/estructura, solo recolorea).

### Lista y estados
| Pantalla | Claro | Oscuro |
|---|---|---|
| Lista con datos (momentum + cards con arco) | `TNx20` | `zQj6Z` |
| Lista — carga (skeleton) | `M4m7C` | `xhZmu` |
| Lista — error (local-first) | `pmcDQ` | `lWwQF` |
| Lista — señal de coherencia (HU-12) | `XqcH1` | `zXxzA` |
| Lista filtrada por cuenta (destino de coherencia) | `qFX42` | `CnkG9` |
| Lista — momentum con racha rota (HU-15) | `zJQwe` | `olvAt` |
| Empty-state (vende con plantillas, HU-13) | `qzBkN` | `jIcK0` |

### Detalle y estados
| Pantalla | Claro | Oscuro |
|---|---|---|
| Detalle — en curso (arco héroe + "faltan · cuándo") | `QBTVl` | `B7uhw` |
| Detalle — cumplida (encuadre invertido) | `ApfDj` | `E1KRCN` |
| Detalle — sin historial suficiente | `xEqbd` | `q2zQv` |
| Detalle — sin fecha objetivo | `E4jMdn` | `Y3d7wu` |
| Detalle — fecha vencida (sin fracaso) | `Mnc0Q` | `Vk5Hj` |
| Detalle — historial vacío | `Zbsyb` | `ZOfmE` |
| Detalle — carga (skeleton) | `uJ7NE` | `ArLgN` |
| Detalle — archivada (read-only) | `A1mgou` | `FzP7Z` |
| Detalle — cuenta con lápida | `XoGzx` | `Kossf` |

### Sheets Aportar / Retirar (modelo de aportes revisado, HU-03/04)
| Pantalla | Claro | Oscuro |
|---|---|---|
| Aportar — mover OFF (seguimiento puro / cajita) | `ZgR6U` | `M23BHR` |
| Aportar — mover ON · presupuestable OFF | `BETeo` | `c3H9jF` |
| Aportar — mover ON · presupuestable ON (categoría) | `GK69y` | `qLw7V` |
| Retirar — mover OFF | `jFfBT` | `teoIl` |
| Retirar — mover ON · presupuestable OFF | `CpLy8` | `D2UGHX` |
| Retirar — mover ON · presupuestable ON | `DiDwa` | `e9QOrp` |
| Retirar — meta cumplida (copy propio) | `gw4XS` | `L19Z0` |
| Enlazar un movimiento (modo enlazar) | `jc77R` | `j1Zdco` |

### Integración con Pagos Programados (aporte recurrente, HU-16)
| Pantalla | Claro | Oscuro |
|---|---|---|
| Punto de entrada — card en Detalle (tras Aportar/Retirar) | `H86Ed` / `hWrGw` | `hDZ6K` / `D3Apm1` |
| Elegir: enlazar existente / crear nuevo | `HOdfO` | `XB4rS` |
| Config de aporte recurrente (clon cuota Deudas) | `ebcqG` | `G2AfJ` |
| Picker de pago programado existente | `RX8C9` | `LSwr8` |
| Detalle de PP con card "Meta Enlazada" | `a2yR8P` | `tnaj3` |

**Punto de entrada del Detalle (aprobado 2026-08-17, `H86Ed`/`hWrGw`).** Entre 3 variantes construidas (A: card prominente tras Acciones; B: card al final tras Historial; C: fila en el Sheet acciones ⋮), se aprobó la **Variante A**: una card fija justo **después de Aportar/Retirar y antes de "Aporte rápido"**, siempre visible sin abrir ningún menú. Variantes B y C descartadas y borradas del canvas.

Geometría idéntica al patrón `DebtConfigureInstallmentCard` de Deudas (`f0vDl` en `cUzp6`): icon-wrap 40px `$primary-soft` + ícono `repeat` en `$primary-on-soft`, título 15/600 + subtítulo 12/500 en el bloque medio, chevron-right, `fill:$surface` + `stroke:$border`. Reusa el mismo lenguaje visual que ya usa Deudas para "configurar algo recurrente ligado a este registro", sin inventar un componente nuevo.

**Estructura zona fija / zona scrolleable (decisión 2026-08-17).** La card nueva hacía crecer `H86Ed` de 972 a 1054px sin clipear el historial. Se resolvió con el mismo patrón que ya usa Gráficas · Resumen (`zGEVW`/`jMg1w`): dentro de `Content` se separó en **Zona fija — NO scrollea** (Hero + Acciones Aportar/Retirar, ancladas bajo el Page Header) y **Zona scrolleable — el contenido se desplaza** (`height:fill_container`, contiene la card de Aporte Recurrente + Aporte rápido + Historial). El frame recupera su alto fijo estándar de 972px; en Flutter la zona scrolleable es el único `SingleChildScrollView`/`ListView` de la pantalla. **Alcance:** esta estructura se aplicó solo a `H86Ed` (la variante con aporte recurrente). Migrar `QBTVl` (Detalle base, sin aporte recurrente) al mismo patrón es una decisión aparte, aún sin confirmar por el usuario.

**Excepción — peek de Movimientos a 3 filas en `H86Ed` (fix 2026-08-17, hallazgo IMPORTANTE de `ui-ux-reviewer`).** Con la card nueva, el peek estándar de 4 filas de Movimientos (el que sí usa `QBTVl`) no cabía en la zona scrolleable sin recortar el botón "Ver más" (`Load More · Ver más`, `oadHE`). Se bajó a **3 filas** solo en esta variante, junto con gaps internos reducidos de 12-18px a 8-12px (dentro del rango de MASTER para "gap entre items relacionados"). Verificado sin ningún nodo `partially/fully clipped` en el subárbol. Es una excepción puntual de `H86Ed`, no un cambio al peek estándar de 4 filas que sigue usando `QBTVl`.

Auditado por `ui-ux-reviewer` (2026-08-17): aprobado con una observación IMPORTANTE (el clipping de arriba), ya corregida. Sin hallazgos de jerarquía, contraste, tono de marca ni accesibilidad.

**Estado:** ambos temas cerrados y aprobados (claro `H86Ed`/`hWrGw`, oscuro `hDZ6K`/`D3Apm1`, generado 2026-08-17 vía `Copy()`+`theme:{mode:"dark"}` sin ajustes manuales, sin clipping). Listo para implementar en Flutter.

### Gestión (sheets)
| Pantalla | Claro | Oscuro |
|---|---|---|
| Sheet acciones ⋮ — en curso | `W5gXNE` | `YnQX8` |
| Sheet acciones ⋮ — cumplida | `tKk1Y` | `xWPAp` |
| Sheet acciones ⋮ — archivada | `uGtaB` | `xsN19` |
| Sheet detalle del movimiento | `N8Dv2e` | `opOuE` |
| Sheet editar movimiento | `REkBO` | `Ml0re` |
| Sheet eliminar meta | `Iytov` | `LMTXI` |
| Sheet archivar meta | `j2L43` | `eDx3b` |
| Sheet desarchivar meta | `Yl5sf` | `jnnQW` |
| Sheet eliminar movimiento — con transferencia | `arr2T` | `iRS8G` |
| Sheet eliminar movimiento — manual | `H2ND7O` | `d4FV8s` |
| Sheet eliminar movimiento — meta cumplida | `xCNxM` | `GGsHk` |

### Formularios y archivadas
| Pantalla | Claro | Oscuro |
|---|---|---|
| Nueva meta | `PjBCt` | `vssGa` |
| Editar meta | `M2f3R` | `yE5vp` |
| Nueva meta — moneda desbloqueada | `j4wasJ` | `cjyMI` |
| Nueva meta — desde plantilla (prefill HU-13) | `edrJz` | `jFa5t` |
| Sheet elegir ícono (set expresivo) | `cwj6B` | `bqA8H` |
| Metas archivadas — lista | `owwhT` | `YfcFn` |
| Metas archivadas — vacío | `aekkM` | `DAeXI` |

**Celebraciones:** hito 25% `E2RRw`/`i3lk2`, 50% `YUwKy`/`ZsL5f`, 75% `CFFdo`/`e08eCT`; **100% a pantalla completa** `HH46w`/`ngIya`.

**Navegación:** "Metas" es el **4º destino del bottom nav** (ícono `target`, ver `04-inicio.md` nota de navegación 2026-07-24). El Detalle es una subsección apilada con `Page Header` (atrás + ⋮), sin Tab Bar. Los aportes/retiros/gestión son bottom sheets (`Bottom Sheet Base`). Formularios, config de recurrente y elegir-ícono son pantallas apiladas / sheets con `Page Header`.

## Componentes creados para Metas

- **`EB2TX` — Goal Ring/Hero** (arco 168px): dos `ellipse` (track + fill). Track = token **`track`**; fill = `$primary` (cumplida `$income-text`). El progreso se overridea con `sweepAngle` (−pct·3.6°). Héroe del detalle y de las celebraciones.
- **`q1qGr` — Goal Ring/Mini** (arco 56px): mismo patrón para las cards de lista y el row de archivadas.
- **`dRg7r` — Goal Card/Ring** (lista): mini-arco + ícono + nombre (`$text-primary`, maxLines:1) + "Te faltan $X" dominante + meta line ("a tu ritmo, en marzo · 40%") + chevron.
- **`ollx8` — Goal Card/Cumplida · Capítulo cerrado** (lista): compacta, medallón de check `$income-text`, "Cumplida · lograda …". De-énfasis: la gran celebración vive en el 100% a pantalla completa, no repetida en la lista.
- **`vjTZR` — Goal Template Row** (empty-state): plantilla de arranque de un toque con monto sugerido derivado.
- **`I6sFES` — Goal Skeleton Card**, **`wXkOU` — Goal Movement Row**, **`bAkEK` — Goal Movement Skeleton Row**, **`G8lQvl` — Archived Goal Row** (con mini-arco), **`HnEKw` — Goal Milestone Panel** (arco lleno al hito), **`RcCXl` — Goal Coherence Row** (fila informativa, ícono `info`).

## Token de sistema `track` (corregido 2026-07-28)

Color del **surco** de arcos/barras de progreso. **Claro `#EEECFB`** (sin cambios). **Oscuro `#2A2A3D`** (mismo hex que `$border` dark) — el valor original (`#101018`) estaba mal calibrado: más oscuro que `$background`/`$surface` oscuros, dando un surco invisible (~1:1 de contraste, bug real reportado en producción). Con el `$primary` oscuro actual (`#6D4FE0`), es matemáticamente incompatible que `track` sea a la vez más claro que `$surface`/`$background` (necesario para que el surco se vea) y ≥3:1 más oscuro que `$primary`; se priorizó la visibilidad del surco (`track` vs `$surface` ~1.17:1, mismo criterio que ya usa `$border` como divisor visible) sobre el ratio exacto contra el fill, que igual se mantiene ~3.0:1 por sí solo. Reemplaza el uso de `$muted`/`$border` como track, que en oscuro quedaba ~2.2–2.75:1. **Pendiente de sistema:** documentar `track` en `MASTER.md` y que `Budget Line` `FSL69` (Presupuestos) lo adopte en su propio flujo.

## Reglas por pantalla

### Lista (`TNx20`)
Header de **momentum** (racha "Llevas N semanas aportando" + próximo hito "50% — te faltan $X"), **nunca un total monetario agregado** (multi-moneda). Cards con mini-arco por meta. Orden: en curso primero (targetDate más próxima arriba, luego sin fecha), cumplidas al final. Racha rota (`zJQwe`): tono neutro que **invita a retomar**, sin culpa ni `$expense`. Coherencia (`XqcH1`): fila `RcCXl` **encima** de la lista (no dentro de cada card), ícono `info`, navega a la lista filtrada por cuenta (`qFX42`).

**Botón "Archivadas" en el header (movido y aprobado 2026-07-29):** antes el acceso a "Metas archivadas" vivía como una fila al final del cuerpo de la lista (con nodeId distinto por cada estado, divergente de lo implementado en Flutter). Se reubicó siguiendo el mismo patrón que ya usa Cuentas (`pages/cuentas.md`, botón "Archivadas" del header, ícono `archive` + `$muted`, siempre visible en los 4 estados): ahora vive en el `Header` propio de cada pantalla de Metas (no es una instancia de `Page Header`, ya que Metas usa Tab Bar), en un wrapper `Actions` junto al botón `+` de crear meta existente, **en los 6 estados de la lista y en ambos temas**:

| Estado | Claro | Oscuro |
|---|---|---|
| Con datos | `TNx20` | `zQj6Z` |
| Carga | `M4m7C` | `xhZmu` |
| Error | `pmcDQ` | `lWwQF` |
| Señal de coherencia | `XqcH1` | `zXxzA` |
| Racha rota | `zJQwe` | `olvAt` |
| Vacío | `qzBkN` | `jIcK0` |

Ícono `archive` en `$text-primary` sobre `$muted`, frame 44×44 `cornerRadius:22` — mismo par de tokens que `TjQOL`/`muLwF` en Cuentas.

### Empty-state (`qzBkN`)
Es la pantalla más decisiva (la ve quien aún no ahorra). **Vende**: hero con gradiente `$primary-deep→$primary` + copy aspiracional + 3 `Goal Template Row` con monto derivado ("3 meses de tus gastos ≈ $X") + "Crear meta personalizada". Nunca el Empty State genérico.

### Detalle (`QBTVl`)
**Arco héroe** con % dentro (`$primary-on-soft-strong`, no `$primary` crudo). El **nombre en `$text-primary`** (ancla de identidad), y **"Te faltan $X" (36/800) domina** sobre el acumulado. Proyección positiva ("a tu ritmo, llegas en marzo"). **Aporte rápido** (ver sección propia "Aporte rápido" más abajo — chips personalizables). El ledger ya no es un peek-de-2-y-expandir-todo-de-un-toque (ver nota "Historial: de 'Ver todos (N)' a 'Ver más' incremental" más abajo). La **cumplida** (`ApfDj`) invierte el encuadre (celebra "Ahorraste $X", arco lleno `$income-text`, acción principal "Archivar meta").

**Historial: de "Ver todos (N)" a "Ver más" incremental (sincronizado 2026-07-29, ambos temas, frame `QBTVl`/`B7uhw`).** El patrón viejo —peek de 2 filas + link "Ver todos (N)" que expandía TODO el historial de un toque, materializado en un frame aparte `p6g6S` ("movimientos expandidos in-place")— se reemplazó por el mismo patrón incremental que ya usan Presupuestos/Deudas/Pagos Programados:

- El header de la sección "Movimientos" ya no lleva un link tocable: el nodo `ig0kJ` pasó de "Ver todos (N)" (`$primary-on-soft-strong` 14/700) a un contador pasivo "N movimientos" (`$text-secondary` 12/600, mismo tratamiento que el `Count` de `Budget Line`/`Nv04I` en Presupuestos).
- Debajo de `Rows` se agregó un wrapper `Más` con una instancia del componente reusable **`Load More · Ver más`** (`oadHE`, definido en `presupuestos.md`/`NloPT`).
- El peek pasó de 2 a 4 filas visibles en el mockup (el `.pen` no dibuja literalmente 8 — mismo criterio que el resto de las pantallas: el conteo real de "8 iniciales + 8 por carga" lo controla el código).
- **`p6g6S` fue eliminado** del `.pen`: representaba el estado "todo expandido con Ver menos" del patrón viejo, que ya no existe (el nuevo comportamiento es incremental, sin un botón de colapsar). Su copia oscura `v6yh8` también fue eliminada.
- Sincronizado en ambos temas (2026-07-29): oscuro `B7uhw` actualizado con el mismo contador pasivo, peek de 4 filas y `Load More · Ver más`.

### Aporte rápido (fila en el Detalle, agregado 2026-07-28)

Fila horizontal scrolleable (`Scroll Row`, `clip:true`, mismo patrón que `Quick Access` de Inicio) bajo el eyebrow "APORTE RÁPIDO": los dos chips $50.000 / $100.000 (sembrados como filas `GoalQuickAmount` reales al crear la meta, ver "Eliminar un chip" abajo) + chips personalizados creados por el usuario + `Add Chip` ("+ Nueva") siempre al final. **Ya no existe un chip fijo "Otro monto"**: el CTA "+ Aportar" del encabezado ya abre el mismo sheet Aportar sin monto prefijado, así que el chip era redundante (corregido 2026-07-29, código como fuente de verdad — `billetudo.pen` aún puede mostrar el diseño viejo, ver nota al final de esta sección). **Sin límite de chips** — la fila es scrolleable, no se trunca ni se pagina; el chip de creación queda siempre visible al final del scroll. Frame de referencia: `Qi3aR` (claro) / `HKc12` (oscuro).

**Crear un chip:** sheet minimal (`urHlG` / `MqLys` oscuro) — solo campo Monto + CTA "Crear chip", sin los demás campos del sheet Aportar completo (fecha, nota, enlazar).

**Prefill al aportar con un chip de monto ($50k/$100k/personalizados):** el sheet Aportar se abre prefilled con el monto del chip, **sin ningún indicio visual de que viene de un chip rápido** — se ve idéntico a un aporte manual (`e9nrdh` / `W6Kijx` oscuro), decisión que evita la sensación de "modo distinto" para una acción que ya era transparente en la fila.

**Eliminar un chip:** patrón **X inline junto al label**, dentro del mismo chip — mismo patrón que `Tag Chip` (`nM9ea`, Transacciones), NO corner-badge ni mantener-presionado (`Vspnx` / `tst9V` oscuro; ícono `Owsx0`/`Remove`). Decisión de framework: **no** se usa mantener-presionado porque ese gesto ya significa "reordenar" en Cuentas/Categorías — reusarlo para eliminar rompería esa convención. **Tap directo en la X → eliminación instantánea + `Snackbar` con "Deshacer"**, sin sheet de confirmación: es una acción reversible y de bajo riesgo (el chip no es dinero, es un atajo). **Los chips $50k/$100k sí llevan X** (corregido 2026-07-29): al ser filas `GoalQuickAmount` reales sembradas por `CreateGoal` en vez de valores hardcodeados en el widget, toda la fila es una sola lista uniforme sin chips indistinguibles ni indelebles — solo "+ Nueva" queda fuera de esta lista, por ser la acción de creación, no un monto.

**Sincronizado con `billetudo.pen` (2026-07-29):** `Qi3aR`/`HKc12` y los chips dentro del propio Detalle (`Q7ezq`/`XMYvI`, en `QBTVl`/`B7uhw`) ya reflejan el fix — X inline en los chips $50k/$100k (y en el personalizado $200k de `Qi3aR`/`HKc12`), sin chip "Otro monto". `Vspnx` (demo aislada del patrón X-inline, previa a la decisión de que $50k/$100k también llevan X) queda desactualizado a propósito fuera de este alcance — no es un frame de referencia activo.

### Sheets Aportar / Retirar — modelo de aportes (HU-03/04)
Reemplazan los sheets binarios viejos por **uno con toggle** (patrón abono de Deudas). **Toggle 1 "¿Mover dinero de una cuenta?"**: OFF = seguimiento puro (cajita, cero efectos); ON = transferencia real (revela cuenta origen/destino). **Toggle 2 "¿Incluir en tu presupuesto?"** (solo aparece con toggle 1 ON): ON revela `Category Quick Picker` con **"Ahorros" preseleccionada**, y colapsa la zona de monto (`ofg07`) para que la categoría no quede tapada. Copy del toggle 2 unificado con el form de transferencia. Retirar: **tope duro** ("Disponible en la meta: $X · Usar todo"); variante **cumplida** (`gw4XS`) con copy propio ("ya está cumplida; sacar dinero no cambia eso"). **Enlazar un movimiento** (`jc77R`): modo enlazar sobre Movimientos (banner "Enlazar a &lt;meta&gt;" + "Elige un movimiento que ya registraste; lo atribuimos a esta meta, no creamos uno nuevo"), paridad Deudas.

### Sheet editar movimiento (`REkBO`, agregado 2026-07-29)

Variante **A "Consistente"** elegida entre 3 propuestas (B "banner de contexto" y C "badge de tipo + estado de error" descartadas y borradas del canvas). Habilita editar (no solo eliminar) un movimiento de **solo seguimiento** (sin cuenta/transferencia vinculada) desde el Sheet detalle del movimiento (`N8Dv2e`) — antes ese caso solo ofrecía "Eliminar" aunque el subtítulo prometía "corregir o eliminar". Estructura, de arriba a abajo, dentro de `Bottom Sheet Base` (`PqTUt`):

- **Head**: título "Editar movimiento" (17/700, `$text-primary`) + hint explicando que corrige monto/fecha/nota sin crear ni eliminar el movimiento (12/500, `$text-secondary`).
- **Field Monto**: mismo patrón compacto (label "Monto" + Input Box 52px, `cornerRadius:14`, `$surface`/`$border`) que ya usan las hojas Aportar/Retirar — reaplicado, no es un componente nuevo.
- **Field Fecha**: instancia de `Form Field` (`wOlOA`) con ícono `calendar` y chevron; abre el `Date Picker Sheet` (`zMqxt`) ya existente, sin cambios.
- **Field Nota**: instancia de `Form Field` (`wOlOA`) con ícono `notebook-pen`, opcional.
- **CTA**: instancia de `Button/Primary` (`j7Zvt`), "Guardar" + ícono `check`.

**Sin componentes nuevos**: reutiliza `Bottom Sheet Base`, `Form Field` y `Button/Primary` ya existentes en el sistema. No lleva banner de contexto ni badge de estado (esas eran las variantes B/C, descartadas por ruido visual frente al caso simple).

**Estado:** ambos temas cerrados, incluida la variante de error del campo Monto. Copy del hint corregido a neutral respecto a dirección (era "...de este aporte", ahora "...de este movimiento" — la hoja edita cualquier dirección, confirmado contra el código que ya parametriza `state.isWithdrawal`).

**Estado de error — tope duro al editar un retiro** (`vvxXn` claro / `qJ48G` oscuro, agregado y aprobado 2026-07-29): el campo Monto de esta hoja es una caja a medida (no una instancia de `Form Field`), así que no heredaba el slot de error `$expense-text`. Se agregó reusando el patrón ya existente en el sistema: `Input Box` con `stroke:$expense` 2px + mensaje de error en `$expense-text` 12/500 debajo (mismo criterio que `Form Field`/`wOlOA` y que el tope duro de las hojas Aportar/Retirar). Variante nueva de frame (copia del sheet base con el campo Monto reemplazado), no una prop de estado dentro del mismo frame. Sin variante de estado "guardando" (aceptado como no bloqueante por precedente de otras hojas del sistema).

### Integración con Pagos (`HOdfO`/`ebcqG`/`RX8C9`/`a2yR8P`)
Aporte recurrente = pago programado con `goalId`. Sheet de decisión (enlazar existente / crear nuevo); config clon de la cuota de Deudas (banner cross-link, cuenta origen, toggle presupuesto + categoría, freq, monto fijo); picker de PP existente; card **"Meta Enlazada"** en el detalle del PP (eyebrow "META ENLAZADA" + "Aporte a / &lt;meta&gt;" + deep-link), análoga a "Deuda Enlazada". Enlace exclusivo `debtId` **o** `goalId`.

### Celebraciones
Hitos 25/50/75 (`E2RRw`/`YUwKy`/`CFFdo`): bottom sheet con **arco lleno hasta el hito** (sin barra redundante) + copy hacia adelante. **100% (`HH46w`): pantalla completa** festiva/trofeo — fondo `$mint-soft`, confeti, badge "META CUMPLIDA", medallón de trofeo, copy de logro permanente, y CTA hacia adelante ("Crear la próxima meta" primary + "Archivar meta" secondary), sin rótulo.

## Notas de accesibilidad (verificadas por `ui-ux-reviewer`)

- El **`%` del anillo** en `$primary-on-soft-strong`, nunca `$primary` crudo (regla de las Notas de diseño de `07-metas.md`).
- El arco **cumplido** en `$income-text` (6.12:1), nunca `$income` (1.96:1 sobre track).
- El **track** de progreso usa el token `track` (≥3:1 con el fill en ambos temas).
- Coherencia con ícono `info` neutro, **nunca** `triangle-alert` ni familia `$expense`.
- **Switch OFF** (`bWezV`) con override a `$text-secondary` + knob distinguible del track (cumple 3:1, primera corrección aplicada al componente base — anotar en `MASTER.md`).
- Los montos **nunca truncan**; solo el nombre hace ellipsis (una línea en lista, dos en detalle).
