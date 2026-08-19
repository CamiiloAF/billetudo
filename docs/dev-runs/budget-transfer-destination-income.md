# Lado destino de la transferencia presupuestable (budget-transfer-destination-income)

## Objetivo y criterios de aceptación

Completar el lado "ingreso" de la transferencia presupuestable (`countsInBudget=true`): que
reduzca el gasto de todo presupuesto cuyo alcance incluya la cuenta destino, reusando el
mecanismo `isIncome` ya existente en `BudgetExpense`/`BudgetProgressCalculator` (construido
originalmente para income presupuestable), en vez de crear un mecanismo de dominio nuevo.
Incluye el neteo automático cuando origen y destino caen en el mismo presupuesto.

Tamaño: **s** · Review: quick, **APROBADO**.

Criterios de aceptación (9):

1. `BudgetsLocalDatasource.watchExpenses()` produce, para una transferencia con
   `countsInBudget=true`, una fila adicional `isIncome=true` con `accountId=transferAccountId`
   (cuenta destino), mismo `categoryId`/`currency`/`date`/`amountMinor` que la fila origen, e
   `id` distinto (evita colisión de `Key` en listas de actividad).
2. Un presupuesto cuyo alcance de cuentas incluye SOLO la cuenta destino ve reducido su
   `spentMinor` (mecanismo `isIncome` ya existente en `BudgetProgressCalculator`, sin cambios).
3. Un presupuesto cuyo alcance incluye SOLO la cuenta origen sigue viendo la transferencia como
   gasto — sin regresión.
4. Alcance con origen Y destino en el mismo presupuesto → neteo a cero.
5. Presupuesto global (`BudgetAccounts` vacío = todas las cuentas) también netea automáticamente.
6. Transferencia NO presupuestable (`countsInBudget=false`) sigue sin generar ninguna fila.
7. `BudgetDetailData.expenses` refleja la fila destino como ítem `isIncome=true` en la lista de
   actividad del detalle, sin widget ni pantalla nueva.
8. `watchZeroBasedSummary()`/`ZeroBasedSummary` no cambia: solo suma `type=income` real
   (`watchIncome()`), la fila sintética de transferencia no se cuela ahí.
9. El docstring desactualizado de `watchExpenses()` (describía el lado destino como
   `pending`/gap) se corrige para reflejar que ambos lados ya están implementados.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/budgets/data/datasources/budgets_local_datasource.dart` | `watchExpenses()` emite, para cada `type=transfer & countsInBudget=true`, una fila adicional (id sufijado `-dest`, solo en memoria, nunca persistida) con `accountId=transferAccountId`, `isIncome=true` y mismos `categoryId/currency/date/amountMinor/note` que la fila origen. Se agregó un `leftOuterJoin` con `_db.alias(_db.accounts, 'transfer_accounts')` para que la fila destino traiga el nombre real de la cuenta destino en `accountName` (alimenta el subtítulo de `BudgetActivityRow`). Docstring corregido: ya no describe el lado destino como pendiente. |
| `test/features/budgets/data/budgets_local_datasource_transfer_test.dart` | Tests de la fila destino: id distinto, mismos campos que origen, y no-regresión de `countsInBudget=false` (ninguna fila). |
| `test/features/budgets/data/budget_repository_impl_transfer_test.dart` | Grupo nuevo "transferencia presupuestable — lado destino (isIncome)": alcance=solo destino reduce `spentMinor`, alcance=solo origen sin regresión, alcance=origen+destino netea a cero, presupuesto global netea automáticamente, `BudgetDetailData.expenses` incluye el ítem destino, `watchZeroBasedSummary` sin doble conteo. El test existente "presupuesto global..." se actualizó de `expect(...,50000)` a `expect(...,0)` — comportamiento correcto nuevo, no regresión. |

## Tests

Resultado: `analyze` limpio, suite de los archivos tocados en verde, e2e skip (no aplica, sin UI
nueva).

```bash
flutter analyze
flutter test test/features/budgets/data/budgets_local_datasource_transfer_test.dart
flutter test test/features/budgets/data/budget_repository_impl_transfer_test.dart
```

Cobertura por criterio de aceptación: los 9 AC quedan cubiertos por los tests de arriba (AC1/AC6
en `budgets_local_datasource_transfer_test.dart`; AC2-5, AC7, AC8 en
`budget_repository_impl_transfer_test.dart`; AC9 verificado por lectura directa del docstring
corregido, no aplica test automatizado a un comentario).

No relacionado con esta tarea: `flutter test test/features/budgets` (suite completa) reporta
~32 fallos en goldens de `presentation/golden/` — no tocan el datasource ni usan `AppDatabase`,
son fallos de pixel-diff preexistentes en esta máquina (ver nota de memoria "Goldens flaky en
esta máquina"). También hay un fallo de compilación preexistente en
`test/features/budgets/presentation/pages/budget_detail_page_test.dart` por un método faltante
en `AppSettingsRepositoryImpl.setQuickAccessOrder`, de trabajo en curso de otra sesión sobre
Settings/Quick Access (confirmado con `git stash` que compila limpio sin esos cambios ajenos).
Ninguno de los dos es atribuible a este cambio.

## Fidelidad visual vs Pencil

N/A — feature sin UI en esta corrida. Los 3 archivos tocados son capa `data` y tests, sin
widgets ni pantallas nuevas.

## 👤 Verifica a mano

- Verificar visualmente en un emulador que el ítem de "ingreso presupuestable" de la fila
  destino se distingue claramente (signo +, color) en la lista de actividad del detalle de
  presupuesto cuando la transferencia cae en su alcance — `BudgetActivityRow` ya tiene golden
  pero no fue tocado en esta corrida (no hay UI nueva).
- Confirmar con el usuario que el criterio de negocio de `06-presupuestos.md` sobre neteo
  automático coincide con la expectativa de producto al ver dos entradas separadas (gasto +
  ingreso) en vez de una sola fila neta en la lista de actividad — es decisión de UX, no solo
  de cálculo.
- El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- El id sintético `-dest` (string concatenado sobre un UUID) es una fila en memoria del
  datasource, nunca persistida ni usada como PK de tabla Drift — no viola la regla de UUID del
  proyecto, pero vale documentarlo explícito si a futuro alguien intenta persistir esa fila.
- No se corrió `flutter analyze`/`flutter test` completo en la revisión rápida (S); se
  recomienda que `qa-automator` confirme verde antes de mergear si no se hizo ya.
- Fuera de alcance por regla dura de esta corrida: el change map pedía también actualizar
  `docs/requirements/06-presupuestos.md`, pero las reglas de esta corrida prohibían tocar
  `docs/**` salvo este único archivo — queda pendiente para quien tenga permiso de escribir en
  `docs/`. Nota: `git status` ya mostraba ese archivo modificado por otro proceso/sesión antes de
  empezar esta corrida; no se tocó.
- AC7 y AC8 se validan con tests que ejercitan `BudgetRepositoryImpl.watchBudgetDetail` y
  `watchZeroBasedSummary`, pero esos archivos de implementación no estaban en el alcance de esta
  revisión — no se auditó su código fuente directamente, solo se confirmó que los tests pasan
  conceptualmente contra el docstring/mecanismo descrito.
- Sin blockers sin resolver.

## Mensaje de commit sugerido

```
feat(budgets): completar lado destino de transferencia presupuestable

Reusa el mecanismo isIncome de BudgetExpense/BudgetProgressCalculator
para que una transferencia countsInBudget=true reduzca el gasto de
todo presupuesto cuyo alcance incluya la cuenta destino, con neteo
automatico cuando origen y destino caen en el mismo presupuesto.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
