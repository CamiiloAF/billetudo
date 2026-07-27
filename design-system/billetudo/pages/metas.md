# Página: Metas de ahorro

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras el rediseño bajo la tesis "tablero de aspiraciones con momentum" y varias rondas de `ui-ux-reviewer`. Requisitos en `docs/requirements/07-metas.md`. Cross-link con Pagos Programados (aporte recurrente) y Transferencias presupuestables (flag `countsInBudget`).

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
| Detalle — movimientos expandidos in-place | `p6g6S` | `v6yh8` |
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
| Elegir: enlazar existente / crear nuevo | `HOdfO` | `XB4rS` |
| Config de aporte recurrente (clon cuota Deudas) | `ebcqG` | `G2AfJ` |
| Picker de pago programado existente | `RX8C9` | `LSwr8` |
| Detalle de PP con card "Meta Enlazada" | `a2yR8P` | `tnaj3` |

### Gestión (sheets)
| Pantalla | Claro | Oscuro |
|---|---|---|
| Sheet acciones ⋮ — en curso | `W5gXNE` | `YnQX8` |
| Sheet acciones ⋮ — cumplida | `tKk1Y` | `xWPAp` |
| Sheet acciones ⋮ — archivada | `uGtaB` | `xsN19` |
| Sheet detalle del movimiento | `N8Dv2e` | `opOuE` |
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

## Token de sistema `track` (nuevo)

Color del **surco** de arcos/barras de progreso, calibrado ≥3:1 con el fill `$primary` en ambos temas (WCAG 1.4.11). **Claro `#EEECFB`** (`$primary` da 4.19:1) · **Oscuro `#101018`** (surco casi-negro; el fill "brilla" encima, 3.46:1). Reemplaza el uso de `$muted`/`$border` como track, que en oscuro quedaba ~2.2–2.75:1. **Pendiente de sistema:** documentar `track` en `MASTER.md` y que `Budget Line` `FSL69` (Presupuestos) lo adopte en su propio flujo.

## Reglas por pantalla

### Lista (`TNx20`)
Header de **momentum** (racha "Llevas N semanas aportando" + próximo hito "50% — te faltan $X"), **nunca un total monetario agregado** (multi-moneda). Cards con mini-arco por meta. Orden: en curso primero (targetDate más próxima arriba, luego sin fecha), cumplidas al final. Racha rota (`zJQwe`): tono neutro que **invita a retomar**, sin culpa ni `$expense`. Coherencia (`XqcH1`): fila `RcCXl` **encima** de la lista (no dentro de cada card), ícono `info`, navega a la lista filtrada por cuenta (`qFX42`).

### Empty-state (`qzBkN`)
Es la pantalla más decisiva (la ve quien aún no ahorra). **Vende**: hero con gradiente `$primary-deep→$primary` + copy aspiracional + 3 `Goal Template Row` con monto derivado ("3 meses de tus gastos ≈ $X") + "Crear meta personalizada". Nunca el Empty State genérico.

### Detalle (`QBTVl`)
**Arco héroe** con % dentro (`$primary-on-soft-strong`, no `$primary` crudo). El **nombre en `$text-primary`** (ancla de identidad), y **"Te faltan $X" (36/800) domina** sobre el acumulado. Proyección positiva ("a tu ritmo, llegas en marzo"). **Aporte rápido** (chips $50k/$100k/Otro; "Otro" abre el sheet Aportar completo). El ledger recede a un peek de 2 filas con "Ver todos (N)" que **expande in-place** (`p6g6S`), patrón Presupuesto/PP. La **cumplida** (`ApfDj`) invierte el encuadre (celebra "Ahorraste $X", arco lleno `$income-text`, acción principal "Archivar meta").

### Sheets Aportar / Retirar — modelo de aportes (HU-03/04)
Reemplazan los sheets binarios viejos por **uno con toggle** (patrón abono de Deudas). **Toggle 1 "¿Mover dinero de una cuenta?"**: OFF = seguimiento puro (cajita, cero efectos); ON = transferencia real (revela cuenta origen/destino). **Toggle 2 "¿Incluir en tu presupuesto?"** (solo aparece con toggle 1 ON): ON revela `Category Quick Picker` con **"Ahorros" preseleccionada**, y colapsa la zona de monto (`ofg07`) para que la categoría no quede tapada. Copy del toggle 2 unificado con el form de transferencia. Retirar: **tope duro** ("Disponible en la meta: $X · Usar todo"); variante **cumplida** (`gw4XS`) con copy propio ("ya está cumplida; sacar dinero no cambia eso"). **Enlazar un movimiento** (`jc77R`): modo enlazar sobre Movimientos (banner "Enlazar a &lt;meta&gt;" + "Elige un movimiento que ya registraste; lo atribuimos a esta meta, no creamos uno nuevo"), paridad Deudas.

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
