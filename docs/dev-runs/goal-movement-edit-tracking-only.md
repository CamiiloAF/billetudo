# Editar movimientos de solo seguimiento en Metas (goal-movement-edit-tracking-only)

## Objetivo y criterios de aceptación

En la hoja "Detalle del movimiento" de Metas (`goal_movement_detail_sheet.dart`), permitir editar
**siempre** el movimiento — también cuando es de "solo seguimiento" (`GoalContribution.transactionId
== null`, sin cuenta vinculada) — para que "Editar" y "Eliminar" aparezcan juntos en todos los casos
y la promesa del subtítulo ("Puedes corregirlo o eliminarlo") se cumpla siempre. Para el caso sin
transacción, editar significa modificar monto/fecha/nota del propio `GoalContribution` sin borrarlo
y recrearlo, respetando el invariante de que un retiro editado nunca deja el `savedMinor` derivado en
negativo.

Tamaño: m | Review: combined APROBADO

1. ✅ `transactionId != null` sigue mostrando "Editar" que navega a la transacción vinculada, sin regresión.
2. ✅ `transactionId == null` muestra AMBAS acciones "Editar"/"Eliminar" vía `DetailActionsRow`; "Editar" abre hoja para modificar monto/fecha/nota.
3. ✅ Guardar persiste `amountMinor`/`date`/`note` en la fila `GoalContributions` existente (mismo id), sin crear/borrar filas, actualiza `updatedAt`.
4. ✅ `savedMinor` derivado refleja el nuevo monto; `milestoneCrossed`/`completedAt` se recalculan hacia adelante o atrás (mecanismo de `RemoveGoalMovement`).
5. ✅ Editar un retiro a un monto que dejaría `savedMinor` negativo se rechaza con `ValidationFailure` sin persistir, excluyendo el monto anterior del propio movimiento.
6. ✅ Editar un movimiento con `transactionId` por esta vía se rechaza con `ValidationFailure`.
7. ✅ `amountMinor` sigue siendo entero positivo de centavos; `<= 0` se rechaza sin persistir.
8. ✅ `l10n.goalMovementDetailHint` queda igual, ya no condicionado a `transactionId`.
9. ✅ `flutter analyze` sin issues nuevos, `flutter test` verde, goldens claro/oscuro nuevos/actualizados, tests de cubit/usecase para éxito/rechazo por invariante/rechazo por `transactionId`.

## Qué cambió (tabla archivo → qué)

| Archivo | Qué cambió |
|---|---|
| `lib/features/goals/domain/repositories/goal_repository.dart` | Agrega `getContribution(String)` y `updateContribution({contributionId, amountMinor, date, note})`; rechaza con `ValidationFailure` un movimiento con `transactionId != null`. |
| `lib/features/goals/domain/usecases/update_goal_movement.dart` | Nuevo usecase `@injectable`: valida `amountMinor > 0`, lee vía `getContribution`, rechaza si tiene `transactionId`, valida el invariante `savedMinor - signedMinor_anterior + signedMinor_nuevo >= 0`, normaliza nota vacía a `null`. |
| `lib/features/goals/data/datasources/goals_local_datasource.dart` | `updateContributionFields(id, {amountMinor, date, note, updatedAt})` — mismo patrón que `softDeleteContribution`, restringido a `transactionId IS NULL` y fila viva (defensa en profundidad). |
| `lib/features/goals/data/repositories/goal_repository_impl.dart` | Implementa `getContribution`/`updateContribution`; llama `_reconcileAfterHistoryRewrite` (mecanismo bidireccional, no forward-only) para recalcular `completedAt`/milestone. |
| `lib/core/di/injection.config.dart` | Regenerado (`build_runner`): registra `UpdateGoalMovement` como factory sobre `GoalRepository` y `EditGoalMovementCubit` sobre `UpdateGoalMovement`. |
| `lib/features/goals/presentation/cubit/edit_goal_movement_state.dart` / `edit_goal_movement_cubit.dart` | Nuevo cubit/estado para la hoja de edición; `start()` requiere `currency` explícito (la meta lo provee). |
| `lib/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet.dart` | Nueva hoja: monto/fecha/nota, reutiliza `GoalAmountHeroField`, `GoalMovementFieldLabel`, `DatePickerSheet` y campo de nota ya aprobados (sin frame propio en Pencil, ver Fidelidad visual). |
| `lib/features/goals/presentation/widgets/sheets/goal_movement_detail_sheet.dart` | Siempre renderiza `DetailActionsRow` (ya no la fila especial solo-ícono de eliminar); `_edit()` rama por `transactionId`: navega a transacción o abre `EditGoalMovementSheet` tras `pop()` con `context.mounted` como guardia. |
| `lib/core/l10n/arb/app_es.arb` + `app_en.arb` (+ `gen/`) | Nuevas claves para la hoja de edición (`goalMovementEditTitle`, etc.); `goalMovementDetailHint` queda sin condicionar a `transactionId`. |
| `test/features/goals/domain/usecases/update_goal_movement_test.dart` | Nuevo: 6 casos (amount ≤0, passthrough `NotFoundFailure`, rechazo por `transactionId`, edición exitosa de aporte, edición de retiro en el límite exacto, rechazo por dejar `savedMinor` negativo excluyendo el monto previo). |
| `test/features/goals/data/goal_repository_impl_test.dart` | Grupo `updateContribution` nuevo contra `NativeDatabase.memory()` (6 casos: reescritura in-place + `updatedAt`, `getContribution`, `NotFoundFailure` de lectura/escritura, reversión de `completedAt` al editar hacia abajo, rechazo de movimiento con `transactionId` sin persistir). |
| `test/features/goals/presentation/edit_goal_movement_cubit_test.dart` | Nuevo: tests del cubit. |
| `test/features/goals/presentation/goal_movement_detail_sheet_edit_test.dart` | Nuevo: rama money-moving (Editar navega a transacción) vs. solo-seguimiento (Editar abre `EditGoalMovementSheet`). |
| `test/features/goals/presentation/golden/goals_sheets_golden_test.dart` + 6 goldens nuevos/actualizados | `sheet_edit_goal_movement_{light,dark}.png`, `sheet_edit_goal_movement_error_{light,dark}.png`, `sheet_goal_movement_detail_manual_{light,dark}.png`. |

## Tests (resultado + comandos exactos para re-correr)

- `flutter analyze` sobre `lib/features/goals` + `lib/core/di` + `lib/core/l10n` → limpio, sin issues nuevos.
- `flutter test test/features/goals/` → 297/297 en verde, incluidos los goldens nuevos.
- No aplica Patrol e2e en esta corrida (feature sin flujo e2e dedicado tocado; ver checklist manual abajo).

```bash
flutter analyze
flutter test test/features/goals/
```

## Fidelidad visual vs Pencil (resultado de esta corrida)

**N/A** — No existe `design-system/billetudo/pages/goals.md` (confirmado con `Read` directo →
"File does not exist" y con `Glob design-system/billetudo/pages/goals*.md` → sin resultados). Sin
ese spec no hay tabla "Pantalla/pieza → Node ID (Claro/Oscuro)" que permita resolver a qué nodeId de
`billetudo.pen` corresponde cada uno de los 124 goldens ya generados en
`test/features/goals/presentation/golden/goldens/` (incluidos los 4 de esta corrida:
`sheet_edit_goal_movement_light.png`, `sheet_edit_goal_movement_dark.png`,
`sheet_edit_goal_movement_error_light.png`, `sheet_edit_goal_movement_error_dark.png`).

Por instrucción explícita del playbook, ante ausencia del `.md` se declara esto como gap en vez de
inventar un mapeo nodeId↔golden; no se llegó siquiera a intentar `get_editor_state` porque el
bloqueo es previo (paso 1 del playbook). No es un fallo de la feature ni de esta ronda de
correcciones — es que `goals` todavía no tiene el spec por pantalla documentado (a diferencia de
otras features como Metas/Gráficas, que sí lo tienen según la memoria del proyecto, aunque "Metas" y
"goals" podrían ser la misma feature con nombres distintos en docs vs. código; valdría la pena
confirmar el nombre correcto del `.md` antes de la próxima corrida).

**Recomendación:** antes de poder auditar fidelidad visual de `goals`, documentar
`design-system/billetudo/pages/goals.md` (o el nombre equivalente que use el equipo) con la tabla de
Node IDs claro/oscuro por pantalla/pieza.

Riesgo de diseño anotado en el plan: `design-system/billetudo/pages/metas.md` solo documenta `N8Dv2e`
(hoja de detalle) y `M2f3R` (editar meta) — no hay frame para "editar movimiento de solo
seguimiento". `EditGoalMovementSheet` se construyó componiendo únicamente componentes ya aprobados
(`GoalAmountHeroField`, `GoalMovementFieldLabel`, `DatePickerSheet`, campo de nota, `DetailActionsRow`)
sin inventar layout nuevo, según exige el gate de CLAUDE.md.

## 👤 Verifica a mano

- [ ] Verificar en dispositivo real que el teclado numérico y el date picker de `EditGoalMovementSheet` no tapan el CTA de guardar (gesto real, no capturable en widget test).
- [ ] Confirmar visualmente contra Pencil que `EditGoalMovementSheet` (nueva hoja) es fiel al sistema de diseño — este QA solo valida que los goldens existen y son estables, no la fidelidad visual (eso lo cierra `/design-fidelity-check` aparte, y hoy está bloqueado por la falta de `goals.md`).
- [ ] Probar el flujo completo en un dispositivo: abrir meta → historial → movimiento de solo seguimiento → Editar → guardar → confirmar que la fila y el saved/progreso de la meta se refrescan en la UI en vivo.
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- **Gap de cobertura de fidelidad:** `design-system/billetudo/pages/goals.md` no existe; bloquea auditar contra Pencil los 124 goldens de la feature, incluidos los 4 nuevos de esta corrida. Ver sección de Fidelidad visual arriba.
- **Riesgo de diseño:** `EditGoalMovementSheet` se compuso sin frame propio en Pencil, solo con componentes ya aprobados — pendiente de validación visual formal cuando exista `goals.md`.
- **Conflicto de archivos con corridas paralelas sobre Metas:** este plan evitó deliberadamente tocar `goal_contribution_sheet.dart`, `goal_contribution_cubit.dart` y `goal_contribution_state.dart` (otra corrida en curso toca el switch "mover dinero"). No se detectó necesidad de tocarlos. El diff de `injection.config.dart` regenerado también recoge, incidentalmente, un cambio de `CreateGoal` ajeno a esta corrida (constructor con `CreateGoalQuickAmount`) — no editado por esta corrida, solo reflejado al regenerar el archivo completo.
- **Invariante de negocio nuevo:** "un retiro editado no puede dejar el `savedMinor` derivado en negativo" no existía antes para ediciones (solo para altas nuevas vía `WithdrawFromGoal`) — implementado y testeado (AC5).
- **Riesgo menor de UX (no bloqueante):** editar un movimiento de solo seguimiento que ya cruzó un hito o completó la meta puede mover `completedAt`/`lastMilestonePct` hacia atrás (por diseño, igual que `RemoveGoalMovement`) — QA debe probarlo explícitamente.
- **Blockers sin resolver:** ninguno.
- Pendiente real dentro del alcance de esta corrida: ninguno.

## Mensaje de commit sugerido

```
feat(goals): permitir editar movimientos de solo seguimiento

Antes solo se podían editar movimientos que movieron dinero
(transactionId != null); los de solo seguimiento solo se podían
eliminar. Agrega UpdateGoalMovement (domain), updateContribution/
getContribution (repositorio) y EditGoalMovementSheet (presentation)
para modificar monto/fecha/nota del GoalContribution sin borrarlo,
respetando el invariante de que un retiro editado no deja el
savedMinor derivado en negativo.
```
