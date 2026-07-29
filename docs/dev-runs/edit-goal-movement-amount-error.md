# Anclar error de guardado al campo de Monto en Editar movimiento (edit-goal-movement-amount-error)

## Objetivo y criterios de aceptación

Anclar el error de guardado de "Editar movimiento" de Metas al campo de Monto
(borde + mensaje vía `GoalAmountHeroField.errorText`) cuando la causa es el
propio monto (retiro que supera lo ahorrado, o monto inválido), en vez de un
texto genérico suelto sin relación visual con el campo que lo origina. El
texto genérico se conserva solo para fallas no relacionadas con el monto.

1. `EditGoalMovementSheetBody` pasa el mensaje como `errorText` a
   `GoalAmountHeroField` cuando `ValidationFailure.field ==
   GoalContributionDraft.fieldAmountMinor` — mismo patrón que
   `GoalContributionSheet`.
2. El texto genérico suelto (`l10n.goalMovementError`) deja de mostrarse para
   ese caso; sigue mostrándose solo cuando la falla es de otro tipo
   (`DatabaseFailure`/`NetworkFailure`/`NotFoundFailure`).
3. El mensaje de "retiro supera lo ahorrado" reutiliza
   `l10n.goalWithdrawErrorExceedsSaved` cuando se puede distinguir sin
   llamada adicional al repositorio; si no, se acepta `l10n.goalMovementError`
   como `errorText` genérico anclado al campo, documentado en código.
4. No se agrega validación local temprana con `maxWithdrawableMinor` en esta
   pasada — decisión explícita, documentada, no omisión silenciosa.
5. `edit_goal_movement_cubit_test.dart` cubre failure de campo Monto vs.
   failure de otro tipo.
6. Golden test actualizado en `goals_sheets_golden_test.dart`
   (`sheet_edit_goal_movement_error_light/dark.png`) muestra el borde
   `$expense` + mensaje en el campo de Monto.
7. `flutter analyze` limpio y `flutter test test/features/goals/` en verde.

Tamaño: s · Review: quick, APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/goals/presentation/cubit/edit_goal_movement_state.dart` | Nuevo getter derivado `isAmountFailure` (true si `ValidationFailure.field == GoalContributionDraft.fieldAmountMinor`); docstring documenta por qué no se agregó `maxWithdrawableMinor` al cubit (AC4). |
| `lib/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet.dart` | `GoalAmountHeroField` recibe `errorText` cuando `state.isAmountFailure`, usando `l10n.goalWithdrawErrorExceedsSaved` si `state.isWithdrawal` o `l10n.goalMovementError` como fallback (comentario in-code documenta la decisión, AC3). El texto suelto al final de la hoja ahora es `if (state.failure != null && !state.isAmountFailure)` — solo para fallas no atribuibles al Monto (AC2). |
| `test/features/goals/presentation/edit_goal_movement_cubit_test.dart` | Caso de retiro-excede-ahorrado ahora arma el `ValidationFailure` con `field: GoalContributionDraft.fieldAmountMinor` (como el usecase real) y verifica `isAmountFailure == true`; caso nuevo con `DatabaseFailure` verifica `isAmountFailure == false`. |
| `test/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet_test.dart` | Nuevo — verifica el wiring end-to-end: `errorText` anclado al campo para `ValidationFailure` de monto, texto suelto ausente en ese caso y presente para otras fallas. |
| `test/features/goals/presentation/golden/goals_sheets_golden_test.dart` + goldens `sheet_edit_goal_movement_error_light/dark.png` | Fixture "con error de guardado" arma el `ValidationFailure` con el `field` real; goldens regenerados con `--update-goldens` — borde + mensaje en el campo de Monto, sin texto suelto debajo de la hoja. |

No se tocó `update_goal_movement.dart` (AC3 lo dejaba opcional; el `field`
existente ya alcanzaba). El caso "monto <= 0" nunca llega a `submit()` porque
`canSubmit` ya lo bloquea (`amountMinor > 0`), así que el único
`ValidationFailure` de campo Monto que puede ocurrir en la práctica es
"retiro supera lo ahorrado" — de ahí que la distinción barata sea
`state.isWithdrawal`, sin nueva llamada al repositorio.

## Tests

- `dart analyze` → sin issues.
- `flutter test test/features/goals/` → 308/308 en verde (306 preexistentes +
  2 nuevos).
- Desglose: `edit_goal_movement_cubit_test.dart` (33 casos),
  `edit_goal_movement_sheet_test.dart` (2 casos nuevos),
  `goals_sheets_golden_test.dart` (66 casos, incluye los 2 goldens
  regenerados x2 brightness).
- e2e: skip (no aplica a este fix).

Re-correr:

```bash
flutter analyze
flutter test test/features/goals/
flutter test test/features/goals/presentation/edit_goal_movement_cubit_test.dart
flutter test test/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet_test.dart
flutter test test/features/goals/presentation/golden/goals_sheets_golden_test.dart
```

## Fidelidad visual vs Pencil

**APROBADA — 0 hallazgos.** Gaps: ninguno. El fix compone `GoalAmountHeroField`
con `errorText`, patrón ya aprobado y en uso en `GoalContributionSheet`; no
introduce estructura nueva fuera de spec.

## 👤 Verifica a mano

- [ ] Confirmar visualmente en dispositivo/emulador que el borde `$expense` y
      el mensaje bajo el campo de Monto se ven correctamente alineados y
      legibles en ambos temas al intentar un retiro que supera lo ahorrado.
- [ ] Confirmar que el teclado numérico y el foco del campo de Monto se
      comportan bien cuando aparece/desaparece el `errorText` tras un submit
      fallido (transición visual, no solo el frame final que captura el
      golden).
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisa por
      qué.

## Pendientes y riesgos

- Sin blockers.
- `design-system/billetudo/pages/goals.md` sigue sin existir (pendiente ya
  registrado en `docs/fidelidad-visual-tracking.md`), así que la fidelidad de
  esta pieza se evalúa por consistencia de patrón (`GoalAmountHeroField` ya
  aprobado en `GoalContributionSheet`), no contra un nodeId propio.
- Árbol queda sucio a propósito, sin commits.

## Mensaje de commit sugerido

```
fix(goals): anclar error de guardado al campo de Monto en editar movimiento

Cuando el guardado falla por un ValidationFailure de fieldAmountMinor
(retiro que supera lo ahorrado), el mensaje ahora se muestra como
errorText en GoalAmountHeroField (borde $expense + mensaje bajo el
campo), igual al patrón de GoalContributionSheet, en vez de un texto
genérico suelto al final de la hoja. Ese texto suelto se conserva solo
para fallas no atribuibles al monto (DatabaseFailure/NetworkFailure/etc).
```
