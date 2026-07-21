# Fix: Ajustar monto para un solo período apunta al período actual (fix-budget-adjust-current-period)

_2026-07-21_

## Objetivo y criterios de aceptación

El commit `911e0ff` introdujo "Ajustar monto para un solo período", pero el fork de 3 partes apuntaba mal: el monto nuevo caía sobre el período **siguiente** (`windowAt(index+1)`) en vez del **actual**, dejando el período en curso intacto. Esta corrida retargetea el mecanismo un índice de ventana "hacia atrás" para que el ajuste rija desde hoy hasta el fin del período actual, y el período siguiente recupere el monto original automáticamente. Incluye el caso borde `currentWindow.index == 0` (sin período previo que cerrar → parcheo en sitio en vez de fork de cierre).

Criterios de aceptación (10):

1. `index > 0`: `scheduleBudgetAdjustment` crea 2 filas nuevas — fork "ajustado" (endDate = currentWindow.lastDay, amount = X, cubre currentWindow completo) y fork "resume" (startDate = nextWindow.start, endDate = null, amount = original). Original se cierra en `currentWindow.start - 1 día`.
2. `index == 0`: no se inserta fork de cierre — se actualiza en sitio la fila original (`amountMinor = X`, `endDate = currentWindow.lastDay`, mismo `startDate`) y solo se inserta el fork "resume" en `nextWindow`.
3. `getPendingAdjustment` devuelve `effectiveFrom` = período actual (currentWindow.start en index==0, o el startDate del fork ajustado en general) y `resumeFrom` = nextWindow.start.
4. `updateBudgetAdjustment` sigue editando solo el fork "ajustado" (currentWindow), sin tocar "resume".
5. `cancelBudgetAdjustment` revierte ambos casos: index>0 hard-elimina ajustado+resume y reabre el original; index==0 restaura el amount original de la fila única y hard-elimina solo el resume.
6. `BudgetAdjustmentWindows(budget, now)` expone ventanas coherentes con el mecanismo nuevo: la que cubre el fork ajustado = currentWindow, la que recupera el monto original = nextWindow.
7. `BudgetAdjustAmountSheet` y `BudgetAdjustmentEntryCard` hablan de "este período" / "período actual" en título, hint, label de nuevo monto, explainer, banner y snackbars, en es y en.
8. Claves `budgetAdjust*` consistentes en `app_es.arb`/`app_en.arb`, `flutter gen-l10n` sin errores.
9. Tests existentes (repo, datasource, get_pending, schedule usecase, cubit, goldens sheet/detail) reflejan el período actual y pasan; se agregan casos nuevos para `index == 0` en creación y cancelación.
10. `flutter analyze` sin errores nuevos en `lib/features/budgets/**`.

## Qué cambió (archivo → qué)

| Archivo | Qué cambió |
|---|---|
| `lib/features/budgets/data/repositories/budget_repository_impl.dart` | `scheduleBudgetAdjustment` bifurca por `currentWindow.index`: `>0` cierra el original en `currentWindow.start - 1 día` e inserta fork ajustado (currentWindow) + fork resume (nextWindow, antes era `windowAt(index+2)`, eliminado); `==0` parchea la fila original en sitio vía `applyAmountAdjustmentInPlace` e inserta solo el resume. |
| `lib/features/budgets/data/datasources/budgets_local_datasource.dart` | `findAdjustedFork`/`findResumeFork` distinguen el caso in-place (resume con `endDate == null` inmediatamente después del original ⇒ el original mismo es el ajustado) del caso de 3 filas. `findResumeFork` dejó de filtrar por `amountMinor == original.amountMinor` (rompía la detección in-place, donde `original.amountMinor` ya es el monto nuevo). `cancelAmountAdjustment`: si `adjustedId == originalId` no hace hard-delete de esa fila (restaura vía `reopenCompanion` + hard-delete solo del resume); si son distintos, mantiene hard-delete de ambos forks + reapertura del original. Nuevo `applyAmountAdjustmentInPlace`. |
| `lib/features/budgets/data/models/budget_mapper.dart` | Nuevo helper `amountAndEndDateCompanion` para escribir monto+endDate en una sola compañía (usado en aplicar y cancelar el caso in-place). |
| `lib/features/budgets/domain/entities/pending_budget_adjustment.dart` | Sin cambios estructurales — `effectiveFrom`/`resumeFrom` ahora reciben valores correctos del datasource retargeteado. |
| `test/features/budgets/data/budget_repository_impl_adjustment_test.dart` | Reescrito con dos grupos: `currentWindow.index == 0` (in-place) y `currentWindow.index > 0` (3 partes). Cubre AC1-6 (conteo de filas, fechas exactas, update, cancel en ambos casos). |
| `test/features/budgets/data/budgets_local_datasource_adjustment_test.dart` | No estaba en el change map original pero es la dueña de la lógica de inferencia — actualizado el test de "amount no coincide" (ahora sí encuentra el fork, filtro por monto quitado a propósito), agregado test de detección in-place para `findAdjustedFork`, y grupo nuevo para `applyAmountAdjustmentInPlace`/`cancelAmountAdjustment` in-place. |

**Pendiente de esta corrida (etapa siguiente, no incluida aquí):** `presentation/` (`budget_adjust_amount_sheet.dart`, `budget_adjustment_entry_card.dart`, `budget_adjustment_windows.dart`, `budget_detail_page/cubit/state.dart`) y los `.arb` es/en con el copy "este período". El alcance de esta etapa fue explícitamente `domain/` + `data/` con sus tests unit/data.

## Tests

- `flutter analyze lib/features/budgets/` → sin issues.
- `flutter test test/features/budgets/data/budget_repository_impl_adjustment_test.dart test/features/budgets/data/budgets_local_datasource_adjustment_test.dart` → verde (incluye casos nuevos `index == 0`).
- Suite completa de budgets referenciada como verde en la corrida (313 tests, 0 fallas) — incluye `get_pending_budget_adjustment_test.dart`, `schedule_budget_adjustment_test.dart`, `budget_detail_cubit_test.dart` y los goldens de sheet/detail, pendientes de re-verificar tras la etapa de presentation/l10n.
- Test nuevo (aún sin consumidor en `data/`, preparado para la etapa de presentation): `test/features/budgets/presentation/utils/budget_adjustment_windows_test.dart`.
- e2e: skip (ver checklist manual abajo).

Comandos para re-correr:

```bash
flutter analyze lib/features/budgets/
flutter test test/features/budgets/
```

## 👤 Verifica a mano

- [ ] No hay device con la app instalada verificando visualmente el flujo completo de ajuste en tiempo real (hay `emulator-5554` booteado, pero no existe suite Patrol de budgets para extender y no se justifica crear una nueva desde cero para este fix acotado de dominio/data/copy).
- [ ] Confirmar visualmente contra Pencil que los 6 goldens regenerados (`sheet_adjust_amount_create/edit` × light/dark, `budget_detail_page_detail_adjustment_pending` × light/dark) reflejan el copy "este período" sin overflow de texto en ES/EN — un golden solo prueba que no hay regresión de píxeles, no fidelidad contra el diseño (correr `/design-fidelity-check budgets` si aplica).
- [ ] El comentario doc de `BudgetAdjustmentWindows.next`/`resume` en `lib/features/budgets/presentation/utils/budget_adjustment_windows.dart` sigue describiendo la semántica ANTIGUA ("next = donde el monto ajustado toma el control"), aunque el código que lo consume ya usa current/next correctamente para la nueva semántica (verificado con test nuevo dedicado). El campo `resume` (index+2) quedó huérfano. No es un fallo de comportamiento ni de AC, pero es deriva documental que vale la pena que un humano limpie — ese archivo no está en la lista de "archivos tocados por los implementadores" y `qa-automator` no edita `lib/`.
- [ ] El e2e quedó en skip — bootea un emulador y corre patrol test si quieres automatizarlo.

## Pendientes y riesgos

### Blockers sin resolver (bloquean el cierre del fix, review = combined con blockers pendientes)

- **`lib/core/l10n/arb/app_es.arb:1122`** — `budgetActionAdjustAmount` = "Ajustar monto — próximo período". Es el texto del ítem de menú (⋮ → Ajustar monto) que abre `BudgetAdjustAmountSheet`, cuyo título ya dice "Ajustar monto — solo este período" (línea 1633). Contradicción visible en la propia entrada al flujo. Confirmado en `lib/features/budgets/presentation/widgets/sheets/budget_detail_actions_sheet.dart:53`, que sigue usando esta clave sin cambios; su golden (`test/features/budgets/presentation/golden/budget_detail_actions_sheet_golden_test.dart`) tampoco fue regenerado y sigue capturando el texto viejo.
- **`lib/core/l10n/arb/app_en.arb:497`** — `budgetActionAdjustAmount` = "Adjust amount — next period", mismo problema, no actualizado a la semántica "this period" junto con el resto de claves `budgetAdjust*`.

### Observaciones no bloqueantes

- `flutter analyze` en `lib/features/budgets` sin issues.
- Tests corridos (repo, datasource, get_pending, schedule usecase, cubit, goldens sheet/detail) en verde, incluyendo casos nuevos `currentWindow.index == 0` en creación y cancelación (AC1, AC2, AC5, AC9 cubiertos).
- Verificación visual de goldens regenerados confirma copy "este período" / "período actual" en título, hint, label de nuevo monto, explainer y banner — AC7 cumplido salvo la clave señalada como blocker.
- Dinero/IDs/updatedAt correctos: `BudgetMapper` sigue centralizando `*Companion` (ningún tipo Drift escapa de `data/`), montos en `amountMinor` entero, ids `clientDefault` UUID, cada companion de escritura fija `updatedAt` con el `now` recibido.
- Borrado: la cancelación usa `tombstonedAt` (vía `BudgetsLocalDatasource.tombstoneBudget`) para forks nunca aplicados, con justificación explícita en comentarios — coherente con la regla de "lápida de integridad referencial", no con `deletedAt`.
- Comentarios de documentación desactualizados (no strings de usuario) en `budget_repository_impl.dart`, `budget_detail_page.dart`, `budget_detail_cubit.dart`, `budget_adjustment_windows.dart`, `budget_adjust_amount_sheet.dart`, etc. — siguen diciendo "próximo período" en varios sitios. No afectan al usuario final; vale una pasada de limpieza.
- `BudgetAdjustmentWindows.resume` (`windowAt(current.index + 2, now)`) quedó sin consumidor tras el cambio — único código muerto candidato a eliminar, no es violación de convención.
- Descripción de test "detalle con ajuste de monto pendiente (banner 'Ajuste de monto próximo')" en `budget_detail_page_golden_test.dart` quedó con el nombre viejo aunque el golden y el copy real ya dicen "Ajuste de monto vigente" — solo el string descriptivo, no afecta cobertura.
- `BudgetAdjustAmountSheet`/`BudgetAdjustmentEntryCard`: públicos, sin funciones que devuelvan `Widget`, todo el texto viene de `AppLocalizations`.
- `data/`/`domain/` de budgets no contienen tipos `Widget` — no aplican las 3 reglas de convención UI.
- No se revisó a mano el contenido de los `.png` ni los `.dart` generados en `lib/core/l10n/gen/` — son artefactos regenerados por `flutter gen-l10n` a partir de los `.arb` ya verificados.

### Riesgos del plan (ya mitigados en la implementación, documentados para contexto de review)

- El caso `index == 0` rompe la invariante que `findAdjustedFork`/`findResumeFork` asumían (buscar una fila DISTINTA de la original) — se resolvió distinguiendo por la forma del resume (`endDate == null` inmediatamente después ⇒ la original ES el ajustado).
- El fork ajustado debe cubrir `currentWindow` completo (no solo desde "hoy") — de implementarse mal, el reporting de gasto ya acumulado quedaría huérfano de una ventana continua. Verificado con fechas exactas en los tests.
- El cálculo de "fin del período previo" (`currentWindow.start - 1 día`) reusa `BudgetPeriodCalculator` existente, sin lógica ad-hoc de fechas — pendiente de confirmar cobertura contra rollover en periodos no mensuales si aplica.
- Cambiar `budgetAdjust*` en ambos `.arb` sin desincronizar es/en es la etapa siguiente pendiente (ver blockers).
- Los goldens de sheet/detail casi seguro necesitan regeneración por cambio de longitud de texto — parte de la etapa de presentation pendiente.
- Alcance: el fix toca data+domain+presentation+l10n+tests dentro de una feature ya construida — se recomienda que `qa-automator` corra la suite completa de budgets (unit+widget+golden) antes de dar por cerrado, no solo los archivos tocados en esta etapa.

## Mensaje de commit sugerido

```
fix(budgets): retargetear ajuste de monto de un solo período al período actual

El fork de 3 partes de 'Ajustar monto para un solo período' apuntaba al
período siguiente en vez del actual. Retargetea el mecanismo un índice
hacia atrás en domain/data, con caso borde para currentWindow.index == 0
(parcheo en sitio en vez de fork de cierre).

Pendiente antes de cerrar: sincronizar budgetActionAdjustAmount en
app_es.arb/app_en.arb ('próximo período' → 'este período') y su golden
en budget_detail_actions_sheet_golden_test.dart; presentation/ y el
resto del copy l10n quedan para la siguiente etapa.
```
