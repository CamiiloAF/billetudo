# Ingreso presupuestable sube el disponible de Presupuestos (budget-income-counts-in-budget)

## Objetivo y criterios de aceptación

Un ingreso presupuestable (por defecto, el repago recibido de un préstamo que el usuario dio;
opcionalmente cualquier income que el usuario marque manualmente) debe subir el disponible de
los presupuestos cuyo scope lo cubre, reusando la columna Drift ya existente
`Transactions.countsInBudget` también para `type=income` (sin migración de esquema), en vez de
que el disponible solo pueda bajar.

Tamaño: L | Review: deep, APROBADO.

1. `RegisterDebtCashEvent` con `direction=owedToMe` + `kind=payment` (Transaction `type=income`)
   persiste `countsInBudget=true` automáticamente.
2. El resto de combinaciones `direction×kind` sigue persistiendo `countsInBudget=false` por defecto.
3. `LinkTransactionToDebt` sobre una transacción `income` ya existente vinculada a `owedToMe`
   también termina con `countsInBudget=true` (misma semántica que el evento de caja), documentando
   la elección (forzar `true` vs. solo defaultear) en el código.
4. `BudgetProgressCalculator.spentIn` y `GetBudgetProgress` restan `amountMinor` (suben el
   disponible) por cada `income` con `countsInBudget=true` que matchea scope y ventana, reusando
   el mismo matching de cuenta/categoría que expense/transfer.
5. `BudgetsLocalDataSource.watchExpenses()` trae también filas `type=income AND countsInBudget=true`
   junto a expense y transfer presupuestable, todas con `deletedAt`/`tombstonedAt` NULL.
6. Un presupuesto que baja por un gasto y sube de vuelta por el income presupuestable vinculado
   vuelve a mostrar el disponible original (verificado con test).
7. El toggle "Incluir en tu presupuesto" (`ToggleField`) también es visible/editable para
   `type=income` en `TransactionFormPage`/`Cubit`.
8. `TransactionDraft.countsInBudget` deja de forzarse a `false` para `income`.
9. Al cambiar `typeSelected`, `countsInBudget` solo se resetea a `false` al salir tanto de
   `transfer` como de `income` (documentado en código).
10. En `BudgetActivityRow`/`BudgetActivityItem`, una fila de income presupuestable se muestra con
    `+` en vez de `-`, sin afectar el resto de filas.
11. `flutter analyze` y `flutter test` en verde para budgets, debts y transactions, incluidos los
    tests nuevos/actualizados.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/debts/domain/services/debt_event_rules.dart` | Regla pura `countsInBudgetFor(direction, type)`: `true` solo para `owedToMe + income`. |
| `lib/features/debts/domain/usecases/register_debt_cash_event.dart` | Usa `DebtEventRules.countsInBudgetFor` para setear `countsInBudget` al crear el evento de caja. |
| `lib/features/debts/domain/repositories/debt_repository.dart` | Documenta la semántica de `linkTransactionToDebt` (forzar `true` en `owedToMe+income`, nunca clobbear un `true` manual, sin tocar en el resto de casos). |
| `lib/features/debts/data/repositories/debt_repository_impl.dart` | `linkTransactionToDebt` lee la transacción vía `DebtsLocalDatasource.getTransaction` y fuerza `countsInBudget=true` cuando `owedToMe+income` (`Value.absent()` en el resto). |
| `lib/features/debts/domain/usecases/link_transaction_to_debt.dart` | Sin cambio de comportamiento; comentario apuntando a la lógica real en el repo impl. |
| `lib/features/budgets/domain/entities/budget_expense.dart`, `budget_activity_item.dart` | Nuevo campo `isIncome` (default `false`). |
| `lib/features/budgets/domain/services/budget_progress_calculator.dart` | `spentIn` resta `amountMinor` cuando `isIncome=true`, reusando `_matchesAccountId`/`_matchesCategoryId`. |
| `lib/features/budgets/domain/usecases/get_budget_progress.dart` | Replica el mismo signo en su fold (duplicación preexistente, documentada por qué no se elimina: necesita mantener `matched` ordenada para `activity`). |
| `lib/features/budgets/data/datasources/budgets_local_datasource.dart` | `watchExpenses()` agrega `type=income AND countsInBudget=true` al `WHERE`; puebla `isIncome` desde `transactions.type`. |
| `lib/features/budgets/data/repositories/budget_repository_impl.dart` | Propaga `isIncome` al mapear a entidades de dominio. |
| `lib/features/transactions/domain/entities/transaction_draft.dart` | `countsInBudget = (type==transfer \|\| type==income) && countsInBudget`; income no añade gating de categoría (ya la exige su propia rama). |
| `lib/features/transactions/presentation/cubit/transaction_form_cubit.dart` | `typeSelected`: `countsInBudget` sobrevive al alternar Ingreso↔Transferencia, solo se resetea al entrar a Gasto. `countsInBudgetChanged`: `clearCategory` solo aplica en transfer. |
| `lib/features/transactions/presentation/cubit/transaction_form_state.dart` | Soporte de estado para el toggle también en income. |
| `lib/features/transactions/presentation/pages/transaction_form_page.dart` | `ToggleField` "¿Incluir en tu presupuesto?" también se renderiza para `type=income`, reusando componente y copy genéricos (sin frame propio en Pencil, ver sección de fidelidad). |
| `lib/features/budgets/presentation/widgets/budget_activity_row.dart` | `_amountLabel` usa `+` cuando `item.isIncome`, `-` en el resto; comentario del código actualizado. |
| `test/features/debts/...`, `test/features/budgets/...`, `test/features/transactions/...` | Tests nuevos/actualizados por AC (ver Tests). |
| `test/features/debts/data/debt_detail_powersync_reactivity_test.dart` | Ajuste no listado en el change map original: agregado `countsInBudget: false` a 3 llamadas a `registerCashEvent` para que compilara tras el nuevo parámetro requerido. |

## Tests

Resultado: `analyze` limpio, suite verde (890/890 no-golden en las 3 features tocadas), e2e Patrol en verde (2/2).

```bash
dart analyze
flutter test test/features/budgets test/features/debts test/features/transactions
flutter test test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart --update-goldens  # solo si se re-generan goldens
patrol test --target integration_test/budget_income_counts_in_budget_patrol_test.dart --flavor dev
```

Tests nuevos/actualizados relevantes:
- `test/features/debts/domain/debt_event_rules_test.dart`
- `test/features/debts/domain/usecases/register_debt_cash_event_test.dart`
- `test/features/debts/domain/usecases/link_transaction_to_debt_test.dart`
- `test/features/debts/data/repositories/debt_repository_impl_test.dart` (nuevo, no listado en el change map original — necesario porque la lógica de `countsInBudget` en `registerCashEvent`/`linkTransactionToDebt` vive en el repo impl con Drift real, no ejercitable con un mock de `DebtRepository`)
- `test/features/debts/data/debt_detail_powersync_reactivity_test.dart`
- `test/features/budgets/domain/budget_progress_calculator_test.dart`
- `test/features/budgets/domain/usecases/get_budget_progress_test.dart`
- `test/features/budgets/data/budgets_local_datasource_transfer_test.dart`
- `test/features/budgets/data/budget_repository_impl_transfer_test.dart`
- `test/features/budgets/presentation/widgets/budget_activity_row_test.dart`
- `test/features/transactions/domain/entities/transaction_draft_test.dart`
- `test/features/transactions/presentation/transaction_form_cubit_test.dart`
- `test/features/transactions/presentation/pages/transaction_form_page_test.dart`
- `test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart` + goldens `transaction_form_page_create_income_counts_in_budget_{light,dark}.png`
- `integration_test/budget_income_counts_in_budget_patrol_test.dart` (e2e real: gasto baja el disponible, income vinculado lo restaura; assert visual de `+$300` en `BudgetActivityRow`)

## Fidelidad visual vs Pencil

N/A — `design-system/billetudo/pages/budgets.md` no existe en el repo. Sin ese spec por
pantalla no hay tabla de nodeId (claro/oscuro) contra la cual mapear los goldens de
`test/features/budgets/presentation/golden/goldens/*.png`, así que la auditoría de fidelidad no
es aplicable todavía (no es un fallo de acceso ni de código, es que la feature aún no tiene ese
documento de diseño). No se intentó acceso al `.pen` ni comparación de goldens porque el paso 1
del playbook detiene la revisión en este punto.

Nota aparte, de diseño: no existe ningún frame en `billetudo.pen`/`design-system/pages/transacciones.md`
para el toggle "Incluir en tu presupuesto" en un Ingreso (ese `.md` documenta explícitamente solo
la variante de Transferencia). Se reusó el componente `ToggleField` y su copy genérica tal cual,
sin inventar copy/hint distinto, documentado en un comentario en `transaction_form_page.dart`.
Recomendado que `pencil-designer`/`ui-ux-reviewer` agreguen el frame formal cuando se revise esta
feature en Pencil.

## 👤 Verifica a mano

- [ ] Verificar visualmente en device real que el toggle "Incluir en tu presupuesto" en un
      ingreso se ve/anima bien (mismo componente que transferencia, sin frame propio en Pencil).
- [ ] Confirmar con producto la semántica de `LinkTransactionToDebt` (forzar `true`, nunca
      clobbear un `true` manual, `false` en `iOwe`) documentada en el código.
- [ ] Revisar en tema oscuro que el `+` de `BudgetActivityRow` no genere confusión de
      tono/marca (el golden cubre píxeles, no la lectura subjetiva).

## Pendientes y riesgos

- El toggle "Incluir en tu presupuesto" hoy es transfer-only en el `.pen`
  (`design-system/billetudo/pages/transacciones.md` y `billetudo.pen`) — extenderlo a income sin
  frame formal puede producir deriva visual (mismo riesgo documentado para Pagos Programados).
  Queda pendiente que `pencil-designer`/`ui-ux-reviewer` confirmen/agreguen el frame.
- `get_budget_progress.dart` reimplementa el match+fold de `BudgetProgressCalculator.spentIn` en
  vez de reusarlo (duplicación preexistente, no introducida por este cambio) — hay que tocar la
  suma en los dos sitios o se desincroniza el disponible entre la lista de presupuestos y el
  detalle.
- El criterio 3 (auto-set de `countsInBudget` al vincular vía `LinkTransactionToDebt`) no estaba
  en el alcance explícito original del bugfix; se incluyó por ser el mismo escenario de negocio.
  Si en el futuro se decide revertirlo, el bug persiste para el flujo de vincular manualmente y
  debe documentarse como limitación conocida.
- Sin definir todavía: si `countsInBudget=true` seteado por el evento de deuda debe quedar
  bloqueado/oculto para el usuario cuando la transacción tiene `debtId`, o si debe ser
  sobrescribible libremente vía el nuevo toggle de income (riesgo de que el usuario lo desmarque
  por error sin entender el efecto en el disponible).
- Goldens: solo se regeneraron las 2 imágenes cuyo diff (11.2%) correspondía al cambio real
  (toggle nuevo en Ingreso vacío). El resto de fallas golden de la corrida completa (ruido
  0.1%-1.3%) no se regeneró, ver memoria "goldens-flaky-en-esta-máquina".
- Sin blockers sin resolver ni observaciones no bloqueantes adicionales.

## Mensaje de commit sugerido

```
feat(budgets): sumar ingresos presupuestables al disponible de un presupuesto

Reusa Transactions.countsInBudget (ya existente) también para type=income:
el repago de un préstamo que el usuario dio (RegisterDebtCashEvent
owedToMe+payment, o LinkTransactionToDebt sobre un income ya existente) lo
marca automáticamente; el usuario puede marcar cualquier otro ingreso a
mano desde el toggle "Incluir en tu presupuesto", ahora visible también en
type=income. BudgetProgressCalculator/GetBudgetProgress y watchExpenses()
suman esos ingresos al disponible en vez de solo restar gastos; el signo
'+' distingue esas filas en el detalle.
```
