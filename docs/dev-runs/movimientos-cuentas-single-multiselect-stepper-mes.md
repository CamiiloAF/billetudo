# Dev run: Movimientos — cuentas single/multi-select + stepper de mes

Fecha: 2026-11-07. Fuente: dos pedidos directos del usuario sobre la pantalla Movimientos (`/movimientos`).

## Cambios

| # | Pedido | Implementación |
|---|---|---|
| 1 | El selector de cuentas debe elegir **una** cuenta con un tap; el long press entra a multi-selección y desde ahí cada tap suma/quita cuentas | `AccountFilterChipRow` pasa a `StatefulWidget` con un modo `_multiSelect` local. Tap = emite `{accountId}` (reemplaza); long press = entra en multi **conservando la selección y sumando** `{accountId}` (p. ej. «Nequi» + long press «TC Nu» → ambas activas) y los taps siguientes togglean. Refinamiento 2026-11-07: al volver a 1 cuenta seleccionada el modo se desactiva solo, y un long press con el modo activo no hace nada. El chip «Todas»/«Limpiar» sale del modo. Pills seleccionadas muestran `check` en modo multi. Hints de long press vía `Semantics.hint` (`FilterChipPill.semanticHint` + `onLongPress`). |
| 2 | Con filtro por **mes**, faltaba la tarjeta para moverse entre meses (Semana y Año sí la tenían) | `TransactionFilter.hasNavigablePeriod` ahora es verdadero para todo periodo granular (incluido el mes default); el rango personalizado sigue sin barra. `DatePeriodFilter.thisMonth()` / `TransactionsListCubit.stepPeriod` / `TransactionsPage` usan `clock.now()` para poder fijar «hoy» en goldens. |
| 3 | Quitar el último chip (Chip Fecha) de la fila de chips de Cuentas | Eliminado de `TransactionsFilterBar`; la fila queda solo con `AccountFilterChipRow`. El periodo ya lo nombra el `PeriodStepper` y el sheet se abre desde `Filtros`. |
| 4 | Con varias cuentas seleccionadas, deshabilitar el filtro por Presupuesto | `UnifiedFiltersState.accountIds` + `isBudgetLockedByAccounts`; la sección Presupuesto del sheet se muestra bloqueada (lock + leyenda + `opacity:0.4`, mismo patrón que Fecha↔Presupuesto) y `UnifiedFiltersCubit.selectBudget`/`buildResult` la ignoran. `TransactionsListCubit.updateFilter` limpia el `budgetPeriod` aplicado cuando la selección de cuentas pasa a 2+ (único funnel de filtros). Con 1 cuenta/«Todas» sigue habilitado. |

## Archivos

- `lib/features/transactions/domain/entities/transaction_filter.dart` — `hasNavigablePeriod`.
- `lib/features/transactions/domain/entities/date_period_filter.dart` — `clock.now()` en el default.
- `lib/features/transactions/presentation/cubit/transactions_list_cubit.dart` y `pages/transactions_page.dart` — `clock.now()` para el bound de «Siguiente».
- `lib/features/transactions/presentation/widgets/account_filter_chip_row.dart` — dos modos de selección.
- `lib/features/transactions/presentation/widgets/filter_chip_pill.dart` — `onLongPress` + `semanticHint` opcionales.
- `lib/core/l10n/arb/app_es.arb` / `app_en.arb` — `accountFilterMultiSelectHint`, `accountFilterMultiSelectActiveHint` (+ `flutter gen-l10n`).
- `design-system/billetudo/pages/transacciones.md` — sección «Adición 2026-11-07» con ambas reglas de interacción.

## Tests

- `test/.../widgets/account_filter_chip_row_test.dart` — reescrito para los dos modos (tap reemplaza, long press siembra y togglea, salida del modo, «Todas» resetea, checks, nunca cero).
- `test/.../domain/entities/transaction_filter_test.dart` — `hasNavigablePeriod`: mes default/semana/año/presupuesto = sí; rango personalizado = no.
- `test/.../pages/transactions_page_period_stepper_test.dart` — nuevo: el mes default muestra el stepper, «Siguiente» deshabilitado, «Anterior» navega; rango personalizado no lo muestra.
- Tests nuevos: `UnifiedFiltersCubit` (bloqueo/no-op/`buildResult`/`clearAll`), sheet (candado y leyenda con 2+ cuentas, sin bloqueo con 1), `TransactionsListCubit` (2+ cuentas limpia Presupuesto, 1 cuenta lo conserva).
- Goldens de `transactions_page_*` regenerados bajo `pumpWithFixedClock` + filtro default anclado a `goldenReferenceNow` (el label del mes lo hacía dependiente del reloj real) y por el Chip Fecha retirado; nuevo golden `unified_filters_sheet_budget_locked_by_accounts_{light,dark}.png`.
- `integration_test/transactions_patrol_test.dart` — escenario de Period Nav Bar actualizado (mes default + navegación entre meses) y el de filtro por cuenta a la semántica single-select.

## Verificación

`flutter analyze` limpio; suite completa de `flutter test` en verde (ver cierre de la corrida). Los tests Patrol no se ejecutaron en dispositivo en esta corrida (requieren emulador), pero el archivo compila y el escenario quedó actualizado al comportamiento nuevo. `dart run build_runner` no aplica: no hubo cambios de esquema ni de código generado de Drift.
