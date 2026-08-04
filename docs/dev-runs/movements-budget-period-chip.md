# Chip "Presupuesto" en Movimientos (movements-budget-period-chip)

## Objetivo y criterios de aceptación

Agregar en Movimientos un 6to `FilterChipPill` "Presupuesto", independiente del chip Fecha existente, que filtre transacciones por la ventana del período activo de un presupuesto elegido por el usuario — mismo patrón arquitectónico que el filtro de Cuenta (cubit propio + hoja de selección + presentation de Movimientos consumiendo domain de Presupuestos).

1. Existe un 6to `FilterChipPill` "Presupuesto" en `TransactionsFilterBar`, visualmente independiente del chip Fecha (coexisten, ninguno excluye al otro), siguiendo el lenguaje visual de `billetudo.pen` para chips/hojas de filtro.
2. Tocar el chip abre una hoja con los presupuestos activos (`GetActiveBudgets`, nombre/ícono/ventana vía `BudgetPeriodWindow`); al aplicar, Movimientos filtra por esa ventana en intersección AND con cualquier otro filtro activo, sin mutar el chip Fecha.
3. El chip muestra estado activo (primary-soft/primary) con el nombre del presupuesto elegido, y neutro sin selección (paralelo a `hasAccountFilter`/`hasCategoryFilter`).
4. `TransactionFilter` expone un campo `budgetPeriod` propio (no reutiliza `datePeriod`), con `hasBudgetPeriodFilter` y limpieza explícita a `null`.
5. Si el presupuesto seleccionado se archiva o deja de existir, `TransactionsListCubit` lo detecta y limpia el filtro automáticamente (`_pruneStaleBudgetPeriodFilter`, análogo a `_pruneStaleAccountFilter`).
6. Reabrir la hoja con un presupuesto ya seleccionado re-resuelve su ventana vigente (no una ventana congelada).
7. `flutter analyze` limpio y `flutter test` en verde (unit + widget + goldens claro/oscuro).

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/transactions/domain/entities/date_period_filter.dart` | Nuevo shape interno `.budget()` con `budgetId`/`budgetStart`/`budgetEndExclusive`/`isBudgetPeriod`. |
| `lib/features/transactions/domain/entities/transaction_filter.dart` | Campo `budgetPeriod` propio + `hasBudgetPeriodFilter` + `clearBudgetPeriod` en `copyWith`. |
| `lib/features/transactions/domain/entities/budget_period_option.dart` | Entidad ligera (budgetId/name/icon/start/endExclusive) para no exponer `BudgetWithProgress` en Movimientos. |
| `lib/features/transactions/domain/usecases/watch_budget_period_options.dart` | Caso de uso stream sobre `GetActiveBudgets`, ventana siempre vigente. |
| `lib/features/transactions/data/repositories/transaction_repository_impl.dart` | Intersección AND de `datePeriod`/`budgetPeriod` vía `_periodStart`/`_periodEndExclusive`. |
| `lib/features/transactions/presentation/cubit/budget_period_filter_cubit.dart` (nuevo) | Cubit de la hoja, calca `AccountFilterCubit`; re-suscribe a `WatchBudgetPeriodOptions` en cada `start()`. |
| `lib/features/transactions/presentation/widgets/sheets/budget_period_filter_sheet.dart` (nuevo) | Hoja de selección única (radio), fila icono+nombre+rango, botones Limpiar/Aplicar, estado vacío. |
| `lib/features/transactions/presentation/utils/budget_period_label.dart` (nuevo) | Util de formateo de rango de período para la fila/chip. |
| `lib/features/transactions/presentation/cubit/transactions_list_cubit.dart` | `_pruneStaleBudgetPeriodFilter`, suscripción a `WatchBudgetPeriodOptions`. |
| `lib/features/transactions/presentation/cubit/transactions_list_state.dart` | Campo `budgetOptions` (paralelo a `accounts`). |
| `lib/features/transactions/presentation/pages/transactions_page.dart` | 6to `FilterChipPill` "Presupuesto" en `TransactionsFilterBar`. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` + gen | Claves `budgetPeriodFilterSheetTitle`, `budgetPeriodFilterEmptyMessage`, `transactionsFilterBudget`. |
| `lib/core/di/injection.config.dart` | Registro del nuevo cubit/caso de uso. |
| Tests domain/data/presentation (ver sección Tests) | Cobertura unit/widget/golden/e2e del filtro nuevo. |

## Tests

Resultado: `flutter analyze` limpio ("No issues found!"), `flutter test` verde (102/102 en los 8 archivos relevantes de esta corrida), e2e Patrol pass en emulador `dev`.

```bash
flutter analyze
flutter test test/features/transactions/domain/entities/date_period_filter_test.dart \
  test/features/transactions/domain/entities/transaction_filter_test.dart \
  test/features/transactions/domain/usecases/watch_budget_period_options_test.dart \
  test/features/transactions/data/transaction_repository_impl_test.dart \
  test/features/transactions/presentation/transactions_list_cubit_test.dart \
  test/features/transactions/presentation/budget_period_filter_cubit_test.dart \
  test/features/transactions/presentation/widgets/sheets/budget_period_filter_sheet_test.dart \
  test/features/transactions/presentation/pages/transactions_page_budget_chip_test.dart
flutter test test/features/transactions/presentation/golden/transactions_page_golden_test.dart
flutter test test/features/transactions/presentation/golden/sheets_golden_test.dart
# Patrol e2e (flavor dev, nunca prod):
patrol test --target integration_test/transactions_patrol_test.dart --flavor dev
```

Cobertura AC: los 7 criterios de aceptación tienen test dedicado (unit de entidad/caso de uso, cubit, repositorio, widget del chip/hoja, goldens claro+oscuro y un escenario e2e nuevo — ver detalle en el change map de la corrida).

## Fidelidad visual vs Pencil

**N/A — no auditable en esta corrida.** `design-system/billetudo/pages/transactions.md` no existe todavía, así que no hay tabla "Pantalla/pieza → Node ID (Claro/Oscuro)" contra la cual mapear los goldens nuevos ni el resto de los 102 archivos ya existentes en `test/features/transactions/presentation/golden/goldens/`. Comparar a ciegas contra el `.pen` violaría la regla de no evaluar sin esa fuente de verdad documentada; no se llegó a llamar Pencil porque el gap de documentación ya bloquea la auditoría antes de necesitarlo.

Esto no es un fallo de fidelidad de esta pieza: es que la feature Transacciones nunca tuvo su `pages/transactions.md`, pese a tener ya un volumen grande de goldens (`transactions_page_*`, `transaction_form_page_*`, `transaction_detail_page_*`, `movements_balance_carousel_*`, `transactions_sort_*`, varios `sheet_*`). El chip y la hoja se construyeron reutilizando estrictamente componentes/tokens ya aprobados del sistema (`FilterChipPill`, `BottomSheetBase`, `SheetHead`, `SheetButtonsRow`, fila estilo `AccountSelectRow`), sin inventar estructura nueva.

Recomendación: que `pencil-designer`/`ui-ux-reviewer` produzcan `design-system/billetudo/pages/transactions.md` con la tabla de nodeId claro/oscuro por pantalla/pieza, igual que existe para otras features ya auditadas, antes de poder correr `/design-fidelity-check transactions` de forma real.

## 👤 Verifica a mano

- [ ] Fidelidad visual pixel-perfect del chip Presupuesto y de la hoja contra `billetudo.pen` (Pencil) — corresponde a `/design-fidelity-check`, no a esta corrida de QA.
- [ ] Gesto real de arrastre/scroll horizontal del filter bar en un dispositivo físico (el e2e ya lo ejercitó en el emulador Android vía `dragUntilVisible`, pero vale una pasada táctil real).
- [ ] Comportamiento cuando hay 10+ presupuestos activos simultáneos en la hoja (scroll interno del `ConstrainedBox` `maxHeight:360`) — no cubierto por golden ni e2e con ese volumen.

## Pendientes y riesgos

- **Gap de diseño documentado**: falta `design-system/billetudo/pages/transactions.md` — bloquea auditoría de fidelidad de esta y cualquier pieza futura de Transacciones (ver sección anterior).
- **Decisión de UX no explícita confirmada en build**: intersección AND estricta entre Fecha y Presupuesto cuando ambos están activos (puede dar 0 resultados si las ventanas no se solapan); se implementó así por ser la lectura más literal, sin mensaje de estado vacío específico para ese caso.
- Selección de presupuesto es única (radio), no multi-selección — coherente con "el período de un presupuesto" siendo singular.
- Estado vacío de la hoja (usuario sin presupuestos activos) implementado sin CTA a crear presupuesto; no bloqueante para Nivel 0.
- Sin blockers activos para el cierre de código de esta corrida.

## Mensaje de commit sugerido

```
feat(transactions): agregar chip Presupuesto para filtrar movimientos por período

Nuevo 6to FilterChipPill "Presupuesto" en Movimientos, independiente del
chip Fecha, con hoja de selección de presupuesto activo y filtrado por
la ventana de su período vigente (BudgetPeriodCalculator/GetActiveBudgets),
en intersección AND con el resto de filtros. Poda automática si el
presupuesto se archiva o desaparece mientras el filtro está aplicado.
```
