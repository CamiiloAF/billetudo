# Fidelidad visual — Transacciones

Corrida `/design-fidelity-check transacciones` (2026-07-20), ítem 2 de `docs/bugfixes.md`.
3 pasadas de `pencil-fidelity-reviewer`, con fixes de `flutter-dev` entre cada una.

## Ronda 1 — auditoría inicial (64 goldens)

4 hallazgos **CRÍTICO**, 4 **IMPORTANTE**, 3 **MENOR**:

1. Chips "Cuenta"/"Fecha" sin estado por defecto documentado (se renderizaban grises/sin
   ícono cuando no había filtro) — Pencil los especifica siempre activos (3 estados de cuenta,
   "Este mes" de fecha).
2. Formato de dinero `"45.000 COP"` (`.format()`) en vez de `"$45.000"` (`.formatSymbol()`) en
   Lista y Detalle.
3. Filas seleccionables (Filtro de Cuenta, Filtro de Tipo) usaban `Checkbox` de Material en vez
   del patrón "fila completa" (fill+borde+check) ya decidido para la feature.
4. Calendario de "Rango Personalizado" sin golden — no se podía verificar si el componente real
   estaba implementado.
5. Category Quick Picker sin categorías en el fixture de test (no auditable).
6. Formato de fecha del stepper mensual ("1 jul 2026" en vez de "Julio 2026").
7. Ícono ámbar en el Aviso de Impacto (debía ser violeta informativo, no warning).
8. Íconos genéricos ("sparkles") en el Filtro de Categoría — resultó ser solo el fixture de
   test, el mapeo de producción ya era correcto.

Pedido adicional del usuario: quitar el botón "Ninguna" del filtro de cuentas (`b4EMA`→ nodos
reales `dbsUh`/`HIsKp`), en Pencil y en código — decisión de producto aprobada sin necesidad de
revisión visual.

## Ronda 1 — fixes

- `pencil-designer`: botón "Ninguna" eliminado en ambos temas de `jpARf`/`RcVAD`.
- `flutter-dev`: los 7 hallazgos de código corregidos (chips siempre activos, `formatSymbol`,
  `AccountSelectRow`/`TypeFilterRow` con patrón fila completa, formato "Julio 2026", ícono
  `primarySoft`/`primaryOnSoft` en Aviso de Impacto). El mapeo de íconos de categoría no se tocó
  (ya era correcto).
- **Bug adicional encontrado por el usuario, no por la auditoría**: `TransactionRow` (`ua7j7`)
  mostraba `categoryName` como título principal; Pencil documenta ese campo como "la descripción
  del movimiento" y las 7 instancias de mockup ("Cafe Juan Valdez", "Uber a la oficina",
  "Transferencia a Ahorros"...) confirman que debe ser la nota/descripción libre del usuario, con
  la categoría representada solo por ícono+color. Corregido: `_title()` prioriza `note`, fallback
  a `categoryName`/cuentas; `_subtitle()` ya no repite la nota.
- `qa-automator`: 64 goldens regenerados + 10 nuevos (cobertura de chips "N cuentas"/"Todas",
  orden por monto, "Nota activa", snackbar de undo).

## Ronda 2 — re-verificación + 2 gaps de implementación reales

Los 9 hallazgos + el bug de nota/categoría: **todos resueltos**, confirmados nodo por nodo.

Pero `qa-automator` reportó 2 gaps de implementación (no solo visuales) al intentar cubrir
"Rango Personalizado" y "Menú de Orden":

- El sheet de rango personalizado usaba `showDateRangePicker` **nativo de Material**, no el
  componente `MonthCalendar` propio que especifica Pencil (`OFdj4`/`Oa2o2`).
- El botón de orden no tenía ningún menú/popover — alternaba directo fecha↔monto, sin el menú de
  4 opciones en 2 secciones que `transacciones.md` ya documentaba como "construido" en el diseño
  (`xXWi0`/`dbTXb`, `tigaH`/`Q8gSaB`).

Usuario decidió implementar ambos en el mismo ítem:

- `flutter-dev`: `DateRangePickerSheet` nuevo en `lib/core/widgets/`, extendiendo `MonthCalendar`
  con un parámetro `rangeEnd` (sin romper los usos existentes de fecha única en `DatePickerSheet`/
  `SnoozeSheet`). Reemplazó el picker nativo en `date_filter_sheet.dart`.
- `flutter-dev`: `TransactionsSortButton` reescrito como `PopupMenuButton` (popover 226px, 2
  secciones FECHA/MONTO, 4 opciones). `TransactionSortOrder` extendido de 2 a 4 valores
  (`dateDesc, dateAsc, amountDesc, amountAsc`) en domain/data. Botón activo (`primary-soft`/
  `primary`) cuando el orden no es el default; lista plana + label "Ordenado por monto" para
  órdenes por monto.
- `qa-automator`: goldens nuevos para ambos (popover abierto, botón activo, calendario de rango
  con selección), + regeneración completa de la carpeta (20 goldens preexistentes rotos por la
  extensión del enum de 2→4 valores).

Re-verificación (`pencil-fidelity-reviewer`): ambos gaps resueltos, calcados a Pencil. Pero
aparecieron 3 hallazgos nuevos (no vistos en ronda 1 porque las piezas no tenían golden todavía):

- **IMPORTANTE**: sheet "Filtrar por tipo" sin header "Todas"/"Ninguna" (sí lo tienen los otros 3
  sheets de selección múltiple).
- **MENOR**: orden de filas en ese mismo sheet (Ingreso→Gasto→Transferencia en vez de
  Gasto→Ingreso→Transferencia).
- **IMPORTANTE**: sheet "Aviso de Impacto Edición" con título+bullets en vez del párrafo único de
  Pencil, y botón "Guardar de todas formas" en vez de "Continuar" (decisión ya confirmada por el
  usuario y documentada en `transacciones.md`).

## Ronda 3 — últimos 3 fixes + cierre

- `flutter-dev`: header "Todas"/"Ninguna" agregado a `type_filter_sheet.dart` (reusando
  `CategoryFilterHeaderAction`), orden de filas explícito (`_typeOrder`, sin tocar el enum de
  dominio), `edit_impact_warning_sheet.dart` reescrito a párrafo único dinámico + botón
  "Continuar" (`l10n.commonContinue`).
- `qa-automator`: goldens regenerados, 323 tests pasando.
- `pencil-fidelity-reviewer` (pasada acotada a las 2 piezas): **sin hallazgos**.

## Veredicto final

**✅ Aprobada.** Los 9 hallazgos de la ronda 1 + el bug de nota/categoría + los 2 gaps de
implementación + los 3 hallazgos de la ronda 2 quedaron todos cerrados y re-verificados.

### Gaps de cobertura conocidos, no bloqueantes (piezas sin frame en Pencil)

- `sheet_future_date_scheduled_payment_prompt_*`: puente funcional real hacia Pagos Programados,
  nunca pasó por diseño.
- `sheet_date_filter_custom_range_*` (el resumen colapsado, no el calendario): estado sin nodo de
  referencia.
- `transaction_form_page_validation_error_account_*`: estado de error de validación sin frame.
- `transactions_sort_button_active_*` (orden `dateAsc`): Pencil no documenta ningún estado de
  lista para "Más antiguos primero" — el código llena el vacío manteniendo agrupación
  cronológica, decisión razonable sin contradecir el diseño.
- `transaction_detail_page_loading_*`/`error_*`: sin frame documentado.
- `sheet_tag_filter_empty_*`: sin nodo dedicado (existe el análogo de categorías).

Ninguno bloquea el cierre — son piezas donde el diseño nunca se maquetó, no divergencias contra
un diseño existente.
