# Unificar paginación "Ver más" en listas de movimientos (unify-ledger-load-more)

## Objetivo y criterios de aceptación

Unificar el patrón de paginación "Ver más" (widget, tamaño de página 8/+8, label) de la lista de
movimientos/pagos en las 4 features que la usan (Presupuestos, Pagos Programados, Deudas, Metas),
extrayendo un componente compartido en `lib/core/widgets/` y ajustando cada cubit/estado sin romper
el mecanismo propio de Pagos Programados (paginación real en BD vía offset/limit).

Tamaño: L | Review: deep, **APROBADO**.

1. `LoadMoreButton` genérico en `lib/core/widgets/`, visualmente idéntico al `BudgetLoadMoreButton`
   actual (pill `colors.muted`, chevron-down, label desde clave l10n compartida), con estado de
   carga opcional (`loading`) que muestra spinner y deshabilita el tap.
2. Clave l10n compartida `commonLoadMore` ('Ver más'/'See more') en `app_es.arb`/`app_en.arb`,
   generada en `AppLocalizations`, usada por las 4 features.
3. `BudgetDetailPage`/`BudgetLoadMoreButton` refactorizados al widget compartido sin cambiar el
   comportamiento observable (8/+8 en memoria, reset al cambiar de período).
4. `DebtDetailState`/`DebtDetailCubit` ganan `visibleLedgerCount`/`ledgerPageSize`/`hasMoreLedger`
   siguiendo el patrón de `BudgetDetailState`; `DebtDetailReadyView` recorta `ledger` y
   `runningBalances` al mismo índice y muestra el botón compartido cuando corresponde.
5. `GoalDetailState`/`GoalDetailCubit` reemplazan `movementsExpanded` (peek-de-2) por
   `visibleMovementsCount`/`movementsPageSize` (8/+8); `GoalDetailBody` elimina `_peekCount`.
6. `ScheduledPaymentDetailState`/`ScheduledPaymentDetailCubit` mantienen la consulta real vía
   `GetScheduledPaymentHistory(offset, limit)` (sin cargar todo a memoria) con tamaño de página 8
   tanto en la carga inicial como en `loadMoreHistory`; botón compartido con spinner en
   `loadingMoreHistory`, label "Ver más" en vez de "Ver historial completo (N)".
7. Claves l10n huérfanas (`goalMovementsSeeAll`, `scheduledPaymentDetailHistorySeeAll`,
   `budgetLoadMore`) eliminadas de los 4 archivos generados y de los `.arb`, sólo tras confirmar con
   `grep` cero referencias restantes en `lib/`.
8. `flutter analyze` sin errores/warnings nuevos en los archivos tocados.
9. `flutter test` en verde para budgets/debts/goals/scheduled_payments + el nuevo widget test de
   `LoadMoreButton`, con casos explícitos de "hay más" (revela 8 más) y "no hay más" (botón ausente).
10. `design-system/billetudo/pages/{deudas,pagos-programados,metas}.md` actualizados en prosa con
    el nuevo patrón 8/+8 y el componente compartido.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/widgets/load_more_button.dart` (nuevo) | `LoadMoreButton` compartido: pill `$muted`, chevron-down, label `commonLoadMore`, parámetro `loading` (spinner 16px + `onTap: null`). |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` + `gen/*` | Clave `commonLoadMore` agregada; `budgetLoadMore`, `goalMovementsSeeAll`, `scheduledPaymentDetailHistorySeeAll` eliminadas (0 referencias confirmadas por grep). |
| `lib/features/budgets/presentation/widgets/budget_load_more_button.dart` (eliminado) | Reemplazado por el widget compartido. |
| `lib/features/budgets/presentation/pages/budget_detail_page.dart` | Usa `LoadMoreButton`; comportamiento 8/+8 en memoria intacto. |
| `lib/features/debts/presentation/cubit/debt_detail_state.dart`, `debt_detail_cubit.dart`, `pages/debt_detail_page.dart` | `visibleLedgerCount`/`ledgerPageSize`(8)/`hasMoreLedger`; `DebtDetailReadyView` recorta `ledger` y `runningBalances` al mismo índice (riesgo de dinero mitigado: recorte, no recálculo). |
| `lib/features/goals/presentation/cubit/goal_detail_state.dart`, `goal_detail_cubit.dart`, `pages/goal_detail_page.dart` | `movementsExpanded` reemplazado por `visibleMovementsCount`/`movementsPageSize`(8); `GoalDetailBody` sin `_peekCount`. |
| `lib/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart` | `historyPageSize` default 3 → 8. |
| `lib/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart`, `pages/scheduled_payment_detail_page.dart` | `loadMoreHistory` default de página 10 → 8; botón compartido con `loading: state.loadingMoreHistory`; consulta real offset/limit sin cambios. |
| `test/core/widgets/load_more_button_test.dart` (nuevo) | 4 casos: label, tap, loading→spinner+tap deshabilitado, sin loading→sin spinner. |
| Tests + goldens de debts/goals/scheduled_payments (ver lista completa abajo) | Actualizados/agregados para el nuevo patrón; goldens viejos de "expandir todo" en Metas eliminados y reemplazados. |

Archivos tocados completos (código + tests):
`lib/core/widgets/load_more_button.dart` (nuevo), `lib/core/l10n/arb/app_es.arb`, `app_en.arb`,
`lib/core/l10n/gen/app_localizations{,_es,_en}.dart`,
`lib/features/budgets/presentation/widgets/budget_load_more_button.dart` (eliminado),
`lib/features/budgets/presentation/pages/budget_detail_page.dart`,
`lib/features/debts/presentation/cubit/{debt_detail_state,debt_detail_cubit}.dart`,
`lib/features/debts/presentation/pages/debt_detail_page.dart`,
`lib/features/goals/presentation/cubit/{goal_detail_state,goal_detail_cubit}.dart`,
`lib/features/goals/presentation/pages/goal_detail_page.dart`,
`lib/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart`,
`lib/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart`,
`lib/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart`,
`test/core/widgets/load_more_button_test.dart` (nuevo),
`test/features/debts/presentation/debt_detail_cubit_test.dart`,
`test/features/debts/presentation/pages/debt_detail_page_test.dart`,
`test/features/debts/presentation/golden/debt_detail_page_golden_test.dart` (+2 goldens nuevos),
`test/features/goals/presentation/goal_detail_cubit_test.dart`,
`test/features/goals/presentation/pages/goal_detail_page_load_more_test.dart` (nuevo),
`test/features/goals/presentation/golden/goal_detail_page_golden_test.dart` (+2 goldens nuevos, -2 obsoletos),
`test/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit_test.dart`,
`test/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page_test.dart`,
`test/features/scheduled_payments/presentation/golden/scheduled_payment_detail_page_golden_test.dart` (+2 goldens nuevos).

## Tests

Resultado: `flutter analyze` limpio (repo completo, "No issues found!"), suite completa en verde,
e2e Patrol en skip (fuera de alcance de este cambio de UX de listas).

Comandos para re-correr:

```bash
flutter analyze
flutter test test/core/widgets/load_more_button_test.dart
flutter test test/features/budgets/
flutter test test/features/debts/
flutter test test/features/goals/
flutter test test/features/scheduled_payments/
flutter test  # suite completa
```

Cobertura AC 1-9: cerrada en su totalidad — ver detalle punto por punto en las notas de build de
la corrida (cada AC mapeado a su test concreto, incluido el gap cerrado en esta misma corrida: no
existía ningún widget test a nivel página para `GoalDetailPage`, solo goldens+cubit; se agregó
`test/features/goals/presentation/pages/goal_detail_page_load_more_test.dart` con tap real).

AC 10: `design-system/billetudo/pages/{deudas,pagos-programados,metas}.md` ya estaban actualizados
con el patrón 8/+8 y nodeIds reales (`oadHE`, `sOq5v`, `IONts`/`OY2Kj`, `YP2xX`/`QBTVl`) por un
workflow de sincronización de Pencil corriendo en paralelo el mismo día — verificado por grep, no
tocado por esta corrida (fuera del alcance de escritura de `flutter-dev`, que sólo toca
`lib/**`/`test/**`/`integration_test/**`/`pubspec.yaml`).

## Fidelidad visual vs Pencil

No se corrió `/design-fidelity-check` sobre las 4 features en esta corrida. El widget compartido se
construyó fiel al `BudgetLoadMoreButton` ya aprobado (no contra un frame nuevo), y los 3 `.md` de
diseño llegaron ya actualizados por el workflow de sincronización paralelo de Pencil con nodeIds
concretos — sin placeholder "pendiente de nodeId" pendiente.

Fidelidad de la feature "core" (donde vive el nuevo `LoadMoreButton` compartido): **N/A**. No
existe `design-system/billetudo/pages/core.md` (verificado con Glob), por lo que no hay spec por
pantalla que mapee goldens a nodeId de Pencil, ni tampoco existe
`test/features/core/presentation/golden/goldens/` con `.png` generados (Glob sin resultados) — no
hay nada contra qué comparar todavía. No es un fallo de fidelidad: "core" no tiene pantallas
diseñadas en Pencil documentadas por página ni goldens corridos por `qa-automator`. Para poder
auditarla se necesita primero el spec `pages/core.md` y que `qa-automator` genere los goldens
correspondientes. Se registró en `docs/fidelidad-visual-tracking.md`.

## 👤 Verifica a mano

- [ ] Confirmar visualmente en un dispositivo real que el spinner de `LoadMoreButton` (16x16,
      `strokeWidth` 2) se ve proporcionado dentro del pill en las 4 features, no solo en el golden
      estático.
- [ ] Verificar con datos reales de PowerSync/Supabase que `loadMoreHistory` de Pagos Programados
      no genera un parpadeo perceptible al pasar de 8 a 16 registros reales vía red (los tests usan
      un repo mockeado, no latencia real).
- [ ] Revisar que el comentario de clase en `goal_detail_page.dart` ("the movement peek that
      expands in-place (p6g6S)") y el docstring del caso de uso de historial de pagos programados
      ("Ver historial completo (N)") quedaron desactualizados tras el refactor — son solo
      comentarios Dart, no bugs de comportamiento, pero conviene que `flutter-dev` los limpie en
      una pasada futura (fuera de alcance de edición en `test/`).
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- Gaps de cobertura: ninguno dentro del alcance de esta corrida.
- Blockers sin resolver: ninguno.
- Observaciones no bloqueantes: ninguna.
- Riesgos del plan (mitigados en la implementación, dejar registrados):
  - En Deudas, `runningBalances` está alineado índice-a-índice con `ledger` completo; al recortar
    el ledger visible se recortó `runningBalances` al mismo `visibleLedgerCount` (no se recalculó)
    — evita saldos corridos incorrectos en filas visibles.
  - El widget compartido se construyó fiel al `BudgetLoadMoreButton` ya aprobado, no a un frame
    nuevo, porque el `.pen` estaba siendo actualizado en paralelo por otra corrida — re-sincronizar
    goldens si esa corrida paralela termina difiriendo.
  - `goal_detail_page_movements_expanded_{light,dark}.png` (golden viejo, comportamiento
    expandir-todo-de-un-toque) fue reemplazado, no solo regenerado con el mismo nombre engañoso.
  - Pagos Programados es la única de las 4 con latencia real de red/BD; se verificó que
    `LoadMoreButton` deshabilita `onTap` durante `loading` (no sólo muestra el spinner) para evitar
    doble-tap disparando dos `loadMoreHistory` concurrentes.
  - Sin riesgo de Nivel 0/monetización/legal: cambio puramente de UX de listas ya existentes en
    features gratuitas.
- Fidelidad de "core": N/A por falta de `pages/core.md` y de goldens — ver sección de arriba.

## Mensaje de commit sugerido

```
refactor(ui): unificar paginación "Ver más" en Presupuestos, Deudas, Metas y Pagos Programados

Extrae LoadMoreButton compartido a lib/core/widgets/ con label l10n
commonLoadMore y estado de carga opcional. Deudas y Metas adoptan el
mismo patrón 8/+8 que Presupuestos; Pagos Programados conserva su
paginación real offset/limit pero homologa el tamaño de página a 8 y
usa el spinner compartido en vez de "Ver historial completo (N)".
```
