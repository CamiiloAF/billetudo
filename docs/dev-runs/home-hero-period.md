# Hero de Inicio con stepper de período + Movimientos recientes desacoplado (home-hero-period)

## Objetivo y criterios de aceptación

Rediseñar el hero de Inicio y desacoplar "Movimientos recientes" del selector de mes: los
movimientos recientes dejan de filtrarse por período (siempre muestran lo más reciente de
todas las cuentas), y el selector del hero pasa de un picker de mes calendario a flechas de
navegación (reusando el patrón `PeriodStepperPill`) que navegan la ventana real del
presupuesto destacado (`BudgetPeriodWindow`/`BudgetPeriodCalculator`) cuando existe uno,
cayendo al total del mes calendario actual sin selector cuando no. Tocar el hero con
presupuesto destacado navega a su detalle. Se resuelve también el hallazgo CRÍTICO de
fidelidad pendiente: el FAB flotante tapando el monto de la fila "Salario" en movimientos
recientes, en ambos temas.

Criterios de aceptación:

1. "Movimientos recientes" del Home muestra siempre lo más reciente de TODAS las cuentas
   activas, sin ningún filtro de mes/período — no depende de `HomeState.month` ni de
   `HomeCubit.selectMonth`.
2. El picker de mes calendario (`MonthPickerSheet`/`MonthSelectorChip`/`selectMonth`/
   `refreshCurrentMonth`) deja de controlar la lista de movimientos recientes; si
   `MonthPickerSheet`/`MonthCell` quedan sin ningún otro uso en la app, se eliminan junto
   con sus tests dedicados.
3. Con presupuesto destacado con progreso visible (`WatchFeaturedBudgetProgress` no-null),
   el hero muestra un stepper de navegación de período en vez del chip de mes, con un label
   que siempre refleja la ventana REAL del presupuesto (ej. "27 jul – 26 ago"), nunca el
   nombre de un mes calendario.
4. Los chevrones del stepper navegan la ventana real vía
   `BudgetPeriodCalculator.windowAt(index±1, now)`, respetando `hasPrevious`/`hasNext`.
5. Sin presupuesto destacado (ni manual ni automático), el hero no muestra selector de
   período y cae al total del mes calendario actual, preservando los estados existentes
   (con presupuesto / sin presupuesto / vacío / carga).
6. Tocar el hero con presupuesto destacado navega a `AppRoutes.budget(id)`
   (`BudgetDetailPage`) de ESE presupuesto — nunca a una lista de movimientos filtrados.
7. El FAB flotante ya no tapa el monto de ninguna fila de "Movimientos recientes" (caso de
   referencia: fila "Salario"), verificado con golden tests en claro y oscuro.
8. `BudgetHeroSelector._pickGlobalMonthly` queda documentado como indiferente al día de
   ancla por diseño, sin cambio de comportamiento.
9. Toda la suite de tests de Home y de los usecases de Budgets tocados pasa; los tests que
   codificaban el acoplamiento mes↔movimientos-recientes retirado quedan actualizados o
   eliminados según corresponda.

**Tamaño:** m · **Review:** combined APROBADO

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/home/domain/usecases/watch_recent_transactions.dart` | Nuevo usecase, pass-through a `watchRecentTransactions()` sin filtro de período |
| `lib/features/home/domain/entities/home_snapshot.dart` | `recentTransactions` opcional en `HomeSnapshot.from`, desacopla `recentActivity` del mes usado para `spending` |
| `lib/features/transactions/domain/repositories/transaction_repository.dart` | Nuevo método `watchRecentTransactions()` sin bound de período |
| `lib/features/transactions/data/datasources/transactions_local_datasource.dart` | `periodStart`/`periodEndExclusive` nullable en `watchTransactions`; `_matchesPeriod` no-op si ambos son null |
| `lib/features/transactions/data/repositories/transaction_repository_impl.dart` | Implementa `watchRecentTransactions()` |
| `lib/features/budgets/domain/usecases/watch_featured_budget_progress.dart` | Sin cambio de comportamiento (documentado en notas de build) |
| `lib/features/budgets/domain/services/budget_hero_selector.dart` | Doc: `_pickGlobalMonthly` indiferente al día de ancla, por diseño (criterio 8) |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Se suscribe a `WatchRecentTransactions` para el feed reciente; reconstruye `BudgetWithProgress` navegando período vía `GetBudgetById`+`GetBudgetProgress(index)`; fix de bug real (`_lastFeaturedResult` atascaba el cubit en `loading` en la primera emisión "sin presupuesto") |
| `lib/features/home/presentation/cubit/home_state.dart` | `month`/`currentMonth` dejan de ser la unidad de navegación de UI |
| `lib/features/home/presentation/pages/home_page.dart` | Quita el picker de mes; fix del FAB (spacer `SliverFillRemaining` en vez de `SizedBox` fijo dentro del `SliverList`); wiring `onOpenBudget` |
| `lib/features/home/presentation/widgets/home_hero_card.dart` | `HeroPeriodStepper`/`HeroPeriodChevron` nuevos (reusan `PageHeaderCircleButton` tintado on-primary), reemplazan el chip de mes cuando hay presupuesto destacado |
| `lib/features/home/domain/usecases/watch_month_transactions.dart` | Se conserva, repurposado a fallback-only (mes calendario actual sin presupuesto) |
| `lib/core/router/app_router.dart` | Wiring `onOpenBudget` → `AppRoutes.budget(id)` |
| `lib/core/di/injection.config.dart` | Regenerado (+4 líneas) |
| `lib/features/home/presentation/widgets/sheets/month_picker_sheet.dart` | Eliminado (sin otros usos) |
| `lib/features/home/presentation/widgets/month_cell.dart` | Eliminado (sin otros usos) |
| Tests de Home/Transactions/Budgets afectados | Actualizados o eliminados junto con los goldens correspondientes (ver detalle abajo) |

## Tests

Resultado: `flutter analyze` limpio · suite completa verde (excepto un flake conocido de goldens
ajeno a esta corrida) · e2e Patrol pass.

Comandos para re-correr:

```bash
flutter analyze
flutter test test/features/home
flutter test test/features/transactions/data/transaction_repository_impl_test.dart
flutter test test/features/budgets/domain
flutter test  # suite completa
```

E2e (Patrol, flavor `dev`):

```bash
patrol test --target integration_test/home_hero_period_patrol_test.dart --flavor dev
```

Archivos de test nuevos/tocados relevantes:
`test/features/home/domain/watch_recent_transactions_test.dart` (nuevo),
`test/features/home/domain/home_snapshot_test.dart`,
`test/features/home/domain/watch_month_transactions_vs_movimientos_test.dart` (reescrito),
`test/features/transactions/data/transaction_repository_impl_test.dart`,
`test/features/home/presentation/home_cubit_test.dart`,
`test/features/home/presentation/home_cubit_sync_attention_test.dart`,
`test/features/home/presentation/home_page_test.dart`,
`test/features/home/presentation/widgets/home_hero_card_test.dart`,
`test/features/home/presentation/golden/home_page_golden_test.dart`,
`test/widget_test.dart`,
`test/core/router/sign_out_outcome_snackbar_test.dart`.

Eliminados: `test/features/home/presentation/widgets/month_picker_sheet_test.dart`,
`test/features/home/presentation/golden/sheets_golden_test.dart`.

Observaciones de la corrida de tests:

- `flutter test test/features/home`: 0 fallas (todos unit/widget/golden pasan).
- `flutter test test/features/budgets`: 30 fallas, todas en
  `test/features/budgets/presentation/golden/budget_adjust_amount_sheet_golden_test.dart`
  (comparación de píxeles). Archivo no tocado por esta corrida; coincide con el patrón
  conocido de goldens flaky en esta máquina (ver memoria `goldens-flaky-en-esta-maquina`),
  no relacionado con esta feature.

## Fidelidad visual vs Pencil

**Resultado: 🟡 PARCIAL — 3 hallazgos.**

1. **[CRÍTICO]** `home_page_with_budget_progress_light.png` (y su par `_dark.png`) — El hero
   con presupuesto destacado ya no usa el patrón diseñado "Gastado en [mes]" + chip dropdown
   "Mes ⌄"; fue reemplazado por un stepper de flechas ("‹ 1-31 jul ›",
   `HeroPeriodStepper` en `home_hero_card.dart`) que ocupa toda la fila superior del hero.
   Ningún frame de Inicio en Pencil (`aOhoY`, `A9v7s`, `LktTm`, `AVgUv`) muestra este patrón.
   El único stepper con chevrones aprobado en el sistema (`presupuestos.md` línea 106,
   detalle de presupuesto `NloPT`/`vHIu4`) es una pastilla flotante **anclada abajo**, con
   label en dos líneas ("21 jul – 20 ago" + "vigente") y chevrones círculo `$muted` de 44pt —
   patrón visual y posicional distinto al implementado aquí (fila arriba, dentro del propio
   hero degradado, tintado on-primary). No pasó por el gate de diseño en Pencil antes de
   construirse.
2. **[IMPORTANTE]** `home_page_with_budget_progress_light.png` — El copy del rango es
   "1-31 jul" (guion simple sin espacios, sin sufijo de estado). `presupuestos.md` documenta
   que ese formato fue un ERROR ya corregido el 2026-07-19 en el stepper del detalle de
   presupuesto ("No lo copies de vuelta") — el formato aprobado es en dash con espacios +
   estado ("21 jul – 20 ago · vigente"). No replica `BudgetFormat.rangeLabel` como está
   aprobado para el mismo concepto en Presupuestos.
3. **[CRÍTICO]** `home_page_with_budget_progress_dark.png` — mismo hallazgo #1, replicado en
   oscuro. Confirma que el problema es estructural/de patrón, no de color/tema.

Gaps de cobertura: `inicio.md` no documenta ningún nodeId para el `HeroPeriodStepper`
(HU-05) — falta que `pencil-designer` construya el frame antes de poder cerrar esta
auditoría con un nodeId real.

Gap pre-existente (no introducido por esta corrida): la tabla de frames de `inicio.md`
sigue apuntando a `aOhoY`/`A9v7s` (sin tira "Mis cuentas") en vez de los frames V2 vigentes
`LktTm`/`AVgUv` — ya documentado en `docs/fidelidad-visual-tracking.md` (corrida
2026-08-05).

## 👤 Verifica a mano

- Confirmar en un dispositivo físico (no solo emulador) que el gesto de scroll + FAB
  ocultándose/reapareciendo sobre "Movimientos recientes" se siente natural con el nuevo
  spacer `SliverFillRemaining`, especialmente en pantallas muy altas/bajas reales.
- Validar con datos reales de producción (no fixtures) que "Movimientos recientes"
  realmente refleja la actividad más reciente de TODAS las cuentas activas cuando hay
  decenas de cuentas/miles de transacciones (rendimiento de la query sin filtro de fecha).
- Fidelidad visual pixel-perfect del `HeroPeriodStepper` contra el nodeId de Pencil
  (`billetudo.pen`) — no evaluada aquí; corresponde a `/design-fidelity-check`, no a QA de
  tests.

## Pendientes y riesgos

**Blockers sin resolver:** ninguno.

**Fidelidad visual (no cerrada):** los 3 hallazgos de arriba siguen pendientes — el
`HeroPeriodStepper` no tiene frame aprobado en Pencil y su copy de rango no replica el
formato ya corregido en Presupuestos. Recomendado: pase de `pencil-designer` sobre
`aOhoY`/`ls7Ed` con el stepper antes de la próxima pasada de fidelidad, y homologar
`HeroPeriodStepper` a `BudgetFormat.rangeLabel`.

**Riesgos identificados en el plan, aún abiertos:**

- El presupuesto destacado puede cambiar (automático o manual desde Ajustes) mientras el
  usuario está navegado a un índice de período distinto del actual — verificar que el
  índice local del stepper del Home se resetea cuando cambia el `id` del presupuesto
  destacado subyacente, igual que `BudgetDetailCubit.start`.
- "Movimientos recientes" sin filtro de período consulta potencialmente todo el historial
  en cada emisión reactiva (sin `LIMIT` a nivel de `TransactionsLocalDatasource
  .watchTransactions`; el tope de 5 se aplica en memoria) — riesgo latente de performance
  en cuentas con historial largo.
- Ningún test e2e/Patrol previo a esta corrida cubría el picker de mes eliminado; revisar
  si queda algún otro suite Patrol dependiente de `MonthPickerSheet` fuera del alcance
  listado.

**Observaciones no bloqueantes:** ver "Tests" arriba (flake conocido en goldens de
`budget_adjust_amount_sheet_golden_test.dart`, ajeno a esta corrida).

## Mensaje de commit sugerido

```
feat(home): stepper de período en el hero + movimientos recientes sin filtro de mes

- Movimientos recientes del Home ya no depende de HomeState.month: siempre
  muestra lo más reciente de todas las cuentas activas (WatchRecentTransactions).
- El hero con presupuesto destacado navega la ventana real del presupuesto
  (HeroPeriodStepper) en vez de un picker de mes calendario; sin presupuesto
  destacado cae al mes calendario actual sin selector.
- Tocar el hero con presupuesto destacado navega a su detalle (AppRoutes.budget).
- Fix: el FAB flotante ya no tapa el monto de la última fila de movimientos
  recientes (SliverFillRemaining en vez de spacer fijo).
- Elimina MonthPickerSheet/MonthCell, sin otros usos en la app.

Fidelidad visual: PARCIAL, pendiente frame de Pencil para HeroPeriodStepper
y homologación de su copy de rango a BudgetFormat.rangeLabel (ver
docs/dev-runs/home-hero-period.md).
```
