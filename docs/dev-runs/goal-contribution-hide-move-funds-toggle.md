# Ocultar el toggle "mover dinero" en Aportar/Retirar sin cuenta vinculada (goal-contribution-hide-move-funds-toggle)

## Objetivo y criterios de aceptación

En la hoja "Aportar/Retirar" de Metas, cuando la meta no tiene cuenta vinculada
(`!state.hasLinkedAccount`), ocultar por completo el `ToggleField` "¿Mover dinero de una
cuenta?" y su bloque condicional de selector de cuenta, en vez de mostrarlo deshabilitado con
un hint explicativo — la funcionalidad de mover dinero no aplica a esa meta, así que el control
no debe existir en pantalla.

Tamaño: S. Review: quick, APROBADO.

1. Con `hasLinkedAccount == false`, el `ToggleField` (icon `arrowLeftRight`) no está en el
   árbol de `GoalContributionSheetBody` (`findsNothing`).
2. Con `hasLinkedAccount == true`, comportamiento visible sin cambios (toggle habilitado,
   selector de cuenta + toggle de presupuesto si `moveMoney == true`).
3. `_moveFundsHint` ya no tiene la rama `!hasLinkedAccount` (código muerto eliminado), resto de
   ramas intactas.
4. `goalMoveFundsGateHint` eliminada de ambos `.arb` y sin referencias huérfanas tras
   `flutter gen-l10n`.
5. `ToggleField.enabled` se conserva sin cambios, sigue siendo API pública genérica.
6. Golden nuevo para `hasLinkedAccount: false` (claro/oscuro); goldens existentes de
   `hasLinkedAccount: true` sin cambios de píxel.
7. `flutter analyze` y `flutter test` (unit + widget + golden de goals) limpios.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart` | El `ToggleField` "mover dinero" y su bloque condicional ahora viven dentro de `if (state.hasLinkedAccount) ...`; se quitó `enabled: state.hasLinkedAccount` (ya innecesario); `_moveFundsHint` perdió la rama `!hasLinkedAccount` y su doc comment desactualizado. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` | Se eliminó la clave `goalMoveFundsGateHint`. |
| `lib/core/l10n/gen/app_localizations*.dart` | Regenerados por `flutter gen-l10n`, sin el getter `goalMoveFundsGateHint`. |
| `test/features/goals/presentation/golden/goals_sheets_golden_test.dart` | Nuevo caso "aportar: sin cuenta vinculada, sin toggle mover dinero" (claro+oscuro), assert `find.byIcon(LucideIcons.arrowLeftRight)` → `findsNothing`; helper `contributionState` extendido con `hasLinkedAccount`. |
| `test/.../golden/goldens/sheet_goal_contribute_no_linked_account_{light,dark}.png` | Goldens nuevos del caso anterior. |
| `test/.../golden/goldens/goal_detail_page_quick_amount_prefilled_{,_custom_}sheet_{light,dark}.png` | Actualizados con `--update-goldens`: el sheet real (meta sin cuenta vinculada) ahora oculta el toggle en vez de mostrarlo deshabilitado — es el comportamiento pedido, no una regresión. |
| `lib/core/di/injection.config.dart` | Regenerado con `build_runner` para destrabar la compilación de un cambio ajeno no commiteado en el árbol (ver "Pendientes y riesgos"); no se tocó a mano. |

## Tests

- `flutter analyze` → sin issues.
- `flutter test test/features/goals/presentation/golden/goals_sheets_golden_test.dart` → 48/48 OK, incluido el caso nuevo.
- `flutter test` (suite completa): fallos presentes pero **ninguno atribuible a este cambio**:
  (a) `goal_quick_amount_row_golden_test.dart` falla por compilación, por otro cambio en curso
  no relacionado; (b) el resto son goldens de otras features (accounts, budgets, categories,
  debts, scheduled_payments, sync, transactions, y también `goal_form_page`/`goal_detail_page`/
  `goals_sheets` "detalle de movimiento") con diffs de 0.3%–20% que solo aparecen corriendo la
  suite completa y desaparecen en archivo aislado — coincide con el flakiness ya documentado en
  memoria (`goldens-flaky-en-esta-maquina`). Ninguna prueba de mover-dinero/`hasLinkedAccount`
  falló.
- e2e: skip (no aplica a este cambio de tamaño S).

Para re-correr:
```bash
flutter analyze
flutter test test/features/goals/presentation/golden/goals_sheets_golden_test.dart
```

## Fidelidad visual vs Pencil

N/A — feature sin UI nueva (cambio de lógica de visibilidad sobre una pantalla ya aprobada;
no se tocó ningún frame de Pencil). Ver fila "Metas" en `docs/fidelidad-visual-tracking.md`.

## 👤 Verifica a mano

- [ ] Confirmar en un dispositivo/emulador real que al ocultar el `ToggleField` no queda un
      salto de espaciado visualmente extraño entre el botón "Usar máximo" (retiro) o el campo
      de monto y el siguiente campo (fecha) — el golden ya lo captura mockeado pero vale una
      mirada humana rápida.
- [ ] Correr `/design-fidelity-check goals` si se quiere la garantía de que el layout sin el
      toggle sigue fiel a Pencil (fuera del alcance de esta corrida de QA).
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- **Sin blockers.** Todos los AC se cumplen.
- Hallazgo colateral ajeno a esta corrida: el árbol ya traía trabajo no commiteado de otra
  sesión (`CreateGoal` con parámetro `_createQuickAmount`, caso de uso `UpdateGoalMovement`,
  cambios en `goal_repository.dart`/`goal_repository_impl.dart`/`goals_local_datasource.dart`)
  sin que `injection.config.dart` estuviera regenerado — rompía la compilación de TODOS los
  tests de goals. Se corrió `build_runner` para destrabarlo; no se tocó nada más de ese trabajo
  ajeno.
- Gap de flakiness pre-existente en la suite completa (no introducido aquí), ver sección Tests.
- Fuera del alcance estricto pero presente en el mismo working tree: claves l10n de otra
  feature en curso ("editar movimiento": `goalQuickAmountOther` eliminada, `goalMovementEditTitle`
  agregada) — generadas/consistentes, no tocadas a mano, no violan convenciones críticas
  revisadas (dinero en centavos, UUID, `updatedAt`, sin fuga de tipos Drift, comillas simples).
  Conviene confirmar que están dentro del alcance esperado del commit final antes de commitear.
- Nota de diseño: el separador `' · '` en `goal_contribution_sheet.dart` (~línea 191, dentro
  de un argumento `value:` de `GoalMovementSelectorBox`) es puntuación decorativa, no texto en
  idioma — no se marca como bloqueo de `avoid_hardcoded_ui_strings`.

## Mensaje de commit sugerido

```
fix(goals): ocultar el toggle de mover dinero si la meta no tiene cuenta vinculada

El ToggleField "¿Mover dinero de una cuenta?" y su selector condicional ya no
se muestran deshabilitados con un hint cuando la meta no tiene cuenta enlazada:
se ocultan por completo, porque la funcionalidad no aplica. Elimina la clave
goalMoveFundsGateHint (código y copy muertos) y agrega cobertura golden para
el caso hasLinkedAccount: false en claro y oscuro.
```
