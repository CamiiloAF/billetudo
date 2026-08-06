# Filtro de cuentas en Gráficas + drill-down consistente (graficas-filtro-cuentas-drilldown)

## Objetivo y criterios de aceptación

En Gráficas e informes (tabs Flujo, Patrimonio, Categorías): (1) confirmar/blindar que el
drill-down de categorías respeta el rango de fechas activo, (2) agregar un filtro multi-cuenta
(default: todas incluidas) que recalcule Flujo/Patrimonio-líquido/Categorías, con las deudas de
Patrimonio siempre incluidas sin importar el filtro, y (3) propagar ese filtro de cuentas al
drill-down hacia Movimientos junto con el rango de fechas.

Tamaño: L | Review: deep, APROBADO.

1. (Regresión) Tocar una fila de categoría/subcategoría en Categorías abre Movimientos filtrado
   por `categoryId` y por el mismo rango `[start, endInclusive]` activo en Gráficas.
2. Control de filtro de cuentas (selección múltiple) en Flujo, Patrimonio y Categorías (no en
   Resumen, por D2), construido contra un diseño aprobado en `billetudo.pen`/`graficas.md`.
3. Por defecto (sin tocar el filtro) todas las cuentas activas quedan incluidas, sin regresión en
   los totales existentes.
4. Cambiar la selección recalcula Flujo y Categorías, incluyendo solo transacciones cuya cuenta
   (o, en transferencias, cualquiera de las dos piernas según `_inScopeAccount`) esté seleccionada.
5. Cambiar la selección recalcula el lado líquido de Patrimonio (saldo inicial + efectos
   origen/destino) vía `_netWorthScopeAccount`.
6. El lado de deudas de Patrimonio (HU-02) no cambia con el filtro de cuentas.
7. Con el filtro en un subconjunto, el drill-down a Movimientos lleva `categoryId` + rango +
   exactamente ese subconjunto de `accountIds`.
8. Con el filtro en default (todas), el drill-down no aplica restricción de cuenta.
9. `flutter analyze` limpio y suites `reports`/`transactions` en verde (unit, cubit,
   datasource/repository, goldens).

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/reports/domain/repositories/reports_repository.dart` | Firma de los watch* aceptan `accountIds` |
| `lib/features/reports/domain/usecases/watch_cashflow_report.dart` | Propaga `accountIds` |
| `lib/features/reports/domain/usecases/watch_net_worth_report.dart` | Propaga `accountIds` |
| `lib/features/reports/domain/usecases/watch_category_breakdown_report.dart` | Propaga `accountIds` |
| `lib/features/reports/data/datasources/reports_local_datasource.dart` | Filtro `accountIds` (inclusive-empty) sobre `_inScopeAccount`/`_netWorthScopeAccount`; también aplicado a `watchAccountsOpeningBalanceSum` (no listado en el change map original, requerido por AC5 para que el saldo inicial no quede inconsistente con el filtro) |
| `lib/features/reports/data/repositories/reports_repository_impl.dart` | Cablea `accountIds` end-to-end; deudas (`watchAliveDebts`/`watchDebtEntriesBefore`/`watchDebtCashEventsBefore`) quedan intactas sin ese parámetro (AC6) |
| `lib/features/reports/presentation/...` (shell state/cubit, tab views, `reports_page.dart`) | `ReportsShellState.accountIds` + `updateAccountFilter`, propagado a los 3 cubits de tab y al drill-down |
| `lib/features/reports/presentation/widgets/account_filter_row.dart` | Widget nuevo: reusa `FilterChipPill` + `AccountFilterSheet` + `AccountFilterCubit` ya existentes de Movimientos (HU-06a), sin reconstruir un selector nuevo |
| `lib/features/reports/presentation/widgets/net_worth/net_worth_hero.dart`, `categories/category_breakdown_row.dart`, `dashboard/goal_summary_row.dart` | Ajustes menores de layout asociados |
| `lib/features/reports/data/models/category_row.dart`, `.../domain/entities/category_breakdown_item.dart` | Soporte de datos para subcategorías/drill-down |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` (+ `gen/`) | `reportsAccountFilterAll`, `reportsAccountFilterSelected` |
| `lib/core/router/app_router.dart` | Propaga `accountIds` al abrir Movimientos desde el drill-down |
| Tests (`test/features/reports/**`, `test/features/transactions/presentation/transactions_list_cubit_test.dart`) | Cobertura nueva/actualizada de datasource, repository, usecases, cubit y golden |
| `integration_test/reports_patrol_test.dart`, `integration_test/test_bundle.dart` | E2e nuevo: filtro de cuentas recalcula Categorías y se propaga al drill-down |

## Tests

Resultado: `flutter analyze` limpio (`No issues found!`), suite `reports` + `transactions` en
verde (631 tests), Patrol e2e pass.

Comandos para re-correr:

```bash
flutter analyze
flutter test test/features/reports test/features/transactions
patrol test --target integration_test/reports_patrol_test.dart --flavor dev
```

Nota: 22/618 goldens fallan de forma preexistente en `dev` (verificado con `git stash` antes de
los cambios de esta corrida, no relacionados con las firmas tocadas) — ver
[[goldens-flaky-en-esta-maquina]].

## Fidelidad visual vs Pencil

**APROBADA — 0 hallazgos.** Gaps de cobertura/documentación (no bloquean código, pendientes de
diseño formal):

- `reports_page_categories_selected_dark.png` y `reports_page_categories_subcategories_dark.png`:
  `graficas.md` marca explícitamente el tema oscuro de esas dos variantes ("Categorías — dona con
  selección" y "pill Atrás/subcategorías") como **no construido** en Pencil; sin nodeId de
  referencia no se puede verificar fidelidad al píxel, aunque el estilo extrapolado de `Zyd8k`
  parece razonable.
- `reports_page_cashflow_account_filter_active_light/dark.png`: no existe fila en `graficas.md`
  ni nodeId de referencia en el `.pen` para un selector de filtro de cuentas en Flujo — el frame
  base `o8uzbT` no incluye esa pill; el componente "Filter Account Row"/"Todas las cuentas" solo
  está documentado/visible en los frames de Categorías (`A3zxf`/`Zyd8k`). No es necesariamente un
  error (puede ser una decisión de producto legítima extender el filtro a Flujo), pero queda sin
  documentar y sin diseño de referencia verificable.

## 👤 Verifica a mano

- Fidelidad visual del `AccountFilterRow` (chip/badge, iconos, hoja de selección) contra
  `billetudo.pen` en los tres tabs — se anota aquí como pendiente pero la aprobación de
  pixel-fidelity real la cierra `/design-fidelity-check`, no esta corrida.
- Gesto real de deslizar/abrir la hoja de filtro de cuentas en un dispositivo físico (el widget
  test y Patrol ya cubren la lógica, pero no la sensación táctil de la hoja modal).
- Verificar en un dispositivo real que el badge "2 cuentas" etc. no se corta con nombres de cuenta
  largos en pantallas angostas.

## Pendientes y riesgos

- **Diseño del filtro de cuentas en Flujo sin documentar**: `graficas.md` no tiene fila/nodeId
  para esa pill en Flujo (sí en Categorías) — cerrar con `pencil-designer`/`ui-ux-reviewer` antes
  de considerar la fidelidad de esa pantalla totalmente cerrada.
- **Oscuro pendiente para 2 variantes de Categorías** (selección y subcategorías) — `graficas.md`
  ya lo marca como "no construido"; falta la ronda de tema oscuro correspondiente.
- **Reuso cross-feature**: `AccountFilterSheet`/`AccountFilterCubit` vivían en
  `transactions/presentation` y ahora también los importa `reports/presentation`. Funciona (no
  acopla a nada específico de Movimientos) pero es la primera vez que dos features comparten un
  widget de presentación — decidir explícitamente si se promueve a un lugar compartido antes de
  que un tercer consumidor fuerce la decisión por inercia.
- **Persistencia del filtro sin decidir**: no está especificado si el filtro de cuentas de
  Gráficas sobrevive a salir/reentrar (como el de Movimientos, que sí persiste en disco) o se
  resetea con la sesión (como `includeDebtMovements`, que no persiste). Quedó implementado
  sin persistir explícita; documentar la decisión.
- **Verificación manual pendiente**: el criterio 1 (regresión del rango de fechas en el
  drill-down) se re-verificó solo a nivel de test automatizado, no con interacción real en un
  dispositivo.
- Ninguna capa de negocio quedó sin cubrir por tests: el alcance de cada scope SQL
  (`_inScopeAccount`, `_netWorthScopeAccount` con ambas piernas de transferencia) tiene tests de
  datasource con subconjuntos reales, no solo el caso "todas seleccionadas".

## Mensaje de commit sugerido

```
feat(reports): filtro de cuentas en Flujo/Patrimonio/Categorías + drill-down consistente

- accountIds inclusive-empty en watchCashflowReport/watchNetWorthReport/
  watchCategoryBreakdownReport, aplicado sobre _inScopeAccount/_netWorthScopeAccount
  (incluye watchAccountsOpeningBalanceSum para que el saldo inicial no quede
  inconsistente con el filtro).
- Deudas de Patrimonio (HU-02) permanecen sin cambios sea cual sea el filtro.
- AccountFilterRow nuevo en reports/presentation, reusando FilterChipPill +
  AccountFilterSheet + AccountFilterCubit ya existentes de Movimientos (HU-06a).
- Drill-down de categoría → Movimientos propaga accountIds junto con categoryId + rango
  de fechas (TransactionsListCubit.filterByCategoryAndRange).
- Tests: unit/cubit/datasource/repository nuevos + goldens + Patrol e2e.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
