# Fix de campo de nombre y chips de aporte rápido en Metas (goals-name-field-and-quick-amount-chips-fix)

## Objetivo y criterios de aceptación

Corregir dos bugs de UI en Metas:

1. El campo de nombre en Nueva/Editar meta no queda centrado verticalmente ni alinea bien con el ícono cuando hay error, a diferencia de Presupuestos.
2. La fila de chips de "Aporte rápido" del detalle tenía un chip fijo "Otro monto" redundante con el CTA "+ Aportar" ya existente, y los chips fijos ($50.000/$100.000) no se podían eliminar por estar hardcodeados en el widget en vez de ser filas reales en BD. Se convierten en filas `GoalQuickAmount` sembradas al crear la meta, para que toda la fila sea una sola lista uniforme de `customAmounts` con X en todos los chips.

12 criterios de aceptación, todos cumplidos:

1. `GoalIconAndNameRow` envuelve el `TextFormField` en un `Container` con `alignment: Alignment.center` (patrón `BudgetNameField`).
2. `InputDecoration` usa `isCollapsed: true` + `counterText: ''` en vez de `isDense: true` + `buildCounter`.
3. El error de nombre se muestra en un `Text` aparte bajo la caja (no vía `errorText`); el `Row` exterior usa `crossAxisAlignment.start` para que el ícono no se desplace.
4. Test que verifica que el ícono no se mueve verticalmente con/sin error de nombre.
5. `GoalQuickAmountRow` sin `onOther`/chip "Otro monto"; `goalQuickAmountOther` eliminado de los `.arb`.
6. `GoalQuickAmountRow` sin `amountsMinor`; todos los chips vienen de `customAmounts` con `onRemoveCustom`.
7. `CreateGoal` siembra dos `GoalQuickAmount` (5.000.000 / 10.000.000 centavos) al crear una meta exitosa, sin backfill retroactivo.
8. `DeleteGoalQuickAmount` se reutiliza sin cambio de firma.
9. `GoalDetailPage` deja de pasar `onOther`/`amountsMinor`; sin código muerto remanente.
10. `flutter analyze` limpio en `lib/features/goals/**`.
11. Goldens de `goal_form_page` (campo nombre) y `goal_detail_page`/`goal_quick_amount_row` regenerados; `flutter test` pasa.
12. `design-system/billetudo/pages/metas.md` actualizado (sin chip "Otro monto", chips $50k/$100k con X); divergencia con `billetudo.pen` señalada, sin editar el `.pen`.

Tamaño: m. Review: combined APROBADO.

## Qué cambió

| Archivo | Qué cambió |
|---|---|
| `lib/features/goals/domain/usecases/create_goal.dart` | Siembra dos `GoalQuickAmount` ($50k/$100k) tras crear la meta exitosamente, vía `CreateGoalQuickAmount` (nueva dependencia). |
| `lib/features/goals/domain/usecases/create_goal_quick_amount.dart` | Doc comment actualizado (reutilizado sin cambios de firma para el seeding). |
| `lib/features/goals/domain/usecases/delete_goal_quick_amount.dart` | Doc comment: ahora borra cualquier fila `GoalQuickAmount` (sembrada o de usuario), firma sin cambios. |
| `lib/features/goals/domain/entities/goal_quick_amount.dart` | Doc comment actualizado (todos los chips son ahora filas reales). |
| `lib/features/goals/domain/repositories/goal_quick_amounts_repository.dart` | Doc comment actualizado. |
| `lib/core/di/injection.config.dart` | Regenerado (`build_runner`) por la nueva dependencia de `CreateGoal`. |
| `lib/features/goals/presentation/pages/goal_form_page.dart` | `GoalIconAndNameRow` reescrito: `Container` con `alignment: Alignment.center`, `isCollapsed`+`counterText: ''`, error como `Text` separado, `Row` exterior con `crossAxisAlignment.start`. |
| `lib/features/goals/presentation/widgets/goal_quick_amount_row.dart` | Quita `onOther`/`amountsMinor`; solo renderiza `customAmounts` con `onRemoveCustom` en todos. |
| `lib/features/goals/presentation/pages/goal_detail_page.dart` | Deja de pasar `onOther`/`amountsMinor` a `GoalQuickAmountRow`. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` (+ `.g.dart` regenerados) | Elimina `goalQuickAmountOther`. |
| `design-system/billetudo/pages/metas.md` | Documenta ambos fixes y la divergencia pendiente con `billetudo.pen`. |
| `test/features/goals/domain/usecases/create_goal_test.dart` | Test nuevo: siembra en éxito, nada en fallo. |
| `test/features/goals/presentation/pages/goal_form_page_test.dart` | Test nuevo: ícono no se mueve con/sin error de nombre. |
| `test/features/goals/presentation/golden/goal_quick_amount_row_golden_test.dart` | Casos actualizados a la lista uniforme de chips. |
| `test/features/goals/presentation/golden/goal_detail_page_quick_amount_prefilled_sheet_golden_test.dart` | Fixture con chip sembrado explícito. |
| ~30 goldens bajo `test/features/goals/presentation/golden/goldens/` | Regenerados; `goal_quick_amount_row_fixed_only_*.png` eliminados (ya no aplica). |

## Tests

- `dart analyze lib/features/goals` → sin issues. `dart analyze` completo del repo → limpio.
- `flutter test test/features/goals` → 297 tests, todos en verde.
- e2e: skip (no se corrió Patrol en esta corrida).

Comandos para re-correr:

```bash
dart run build_runner build --force-jit
flutter gen-l10n
flutter analyze
flutter test test/features/goals
```

## Fidelidad visual vs Pencil

**N/A** — `design-system/billetudo/pages/goals.md` no existe (confirmado: `Read` arroja "File does not exist"). Sin ese spec no hay tabla Pantalla/pieza → Node ID (Claro)/(Oscuro) que sirva de fuente de verdad para mapear los 124 goldens en `test/features/goals/presentation/golden/goldens/` a nodeIds concretos del `.pen`.

Se confirmó acceso real al `.pen` (`get_editor_state` respondió con el frame activo y el listado de 130 componentes `reusable:true`, incluyendo Goal Card/D, Goal Ring/Hero, Goal Milestone Panel, Goal Movement Row, etc.), así que el bloqueo no es de acceso sino de documentación: sin el `.md` no se puede resolver de forma no ambigua qué nodeId (tema claro/oscuro) le corresponde a cada golden, especialmente a los dos pares señalados en la tarea (`goal_detail_page_quick_amount_prefilled_sheet_light/dark` y `goal_detail_page_quick_amount_prefilled_custom_sheet_light/dark`), por lo que no se pudo verificar si la corrección de la ronda 1 quedó resuelta contra su referencia real en Pencil.

Recomendación: antes de poder cerrar el loop de fidelidad para goals, se necesita generar `design-system/billetudo/pages/goals.md` (debería ser un paso de `pencil-designer`/`ui-ux-reviewer`, no de esta auditoría de solo lectura) mapeando cada pantalla/pieza de goals (`goals_list_page`, `goal_detail_page`, `goal_form_page`, `archived_goals_page`, `goal_completed_celebration_page`, y las ~15 sheets `sheet_goal_*`) a sus nodeId claro/oscuro en `billetudo.pen`.

## 👤 Verifica a mano

- [ ] Verificar visualmente en dispositivo/simulador que el campo de nombre en Nueva/Editar meta queda centrado verticalmente y el ícono no salta al mostrar el error (los goldens headless no capturan renderizado real de fuentes/DPI).
- [ ] Verificar con gesto real de scroll horizontal que la fila de chips "Aporte rápido" se desplaza correctamente en un dispositivo cuando hay muchos chips personalizados.
- [ ] Confirmar con `pencil-fidelity-reviewer` o `pencil-designer` si `billetudo.pen` (frames `Qi3aR`/`HKc12`) debe actualizarse para quitar el chip "Otro monto" y agregar la X a los chips $50k/$100k, tal como quedó anotado en `design-system/billetudo/pages/metas.md`.
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisa por qué.

## Pendientes y riesgos

- El seeding de los dos montos por defecto ocurre dentro de `CreateGoal` tras el INSERT de la meta: si la app se cierra o falla justo entre crear la meta y sembrar los dos `GoalQuickAmount`, la meta queda sin sus chips por defecto (no hay transacción atómica cross-repositorio) — aceptable para v1, no bloqueante.
- Metas ya existentes (creadas antes de este cambio) no reciben backfill de las dos filas `GoalQuickAmount`: verán su fila de chips vacía salvo los que el usuario ya haya creado con "+ Nueva", hasta que ellas mismas creen chips nuevos — decisión de alcance (sin migración de datos), cambia el comportamiento visible para usuarios actuales.
- `billetudo.pen` puede seguir mostrando el chip "Otro monto" y los chips fijos sin X (no se editó el `.pen` en esta corrida, solo el `.md`) — divergencia pendiente de decidir. Además el `.pen` muestra un tercer chip fijo "$200.000" que ni el `.md` original ni el código contemplaban — no se tocó, fuera de esta corrida.
- Gap de fidelidad visual sin cerrar: falta `design-system/billetudo/pages/goals.md` para poder auditar contra Pencil de forma no ambigua (ver sección de fidelidad arriba).
- Nota sobre el árbol de trabajo: al hacer `git status` se encontraron cambios preexistentes sin commitear, no relacionados con esta corrida (feature `UpdateGoalMovement` en progreso: `lib/features/goals/domain/usecases/update_goal_movement.dart` nuevo, cambios en `goal_repository.dart`, `goal_repository_impl.dart`, `goals_local_datasource.dart`, `goal_contribution_sheet.dart`, y una entrada `goalMoveFundsGateHint` borrada de los `.arb`). No se tocaron ni revirtieron.
- Pre-existentes, no tocados por esta corrida: `goals_sheets_golden_test.dart` (feature "editar movimiento" en curso) y los goldens `sheet_goal_movement_detail_manual_*.png`.
- Sin violaciones detectadas de las convenciones críticas de `CLAUDE.md` (dinero como `amountMinor` entero, IDs UUID, `updatedAt` estampado, `deletedAt`/`tombstonedAt` no tocados, las 3 reglas de widgets/UI, sin gating de Premium/anuncios en Nivel 0).

## Mensaje de commit sugerido

```
fix(goals): centrar campo de nombre y unificar chips de aporte rápido

- GoalIconAndNameRow replica el patrón de BudgetNameField: Container
  con alignment:center, isCollapsed+counterText, error como Text
  separado y Row con crossAxisAlignment.start para que el ícono no
  se desplace.
- GoalQuickAmountRow deja de tener el chip fijo "Otro monto" y los
  montos hardcodeados; todos los chips ahora vienen de filas reales
  GoalQuickAmount (customAmounts) con X uniforme.
- CreateGoal siembra $50.000/$100.000 como GoalQuickAmount al crear
  una meta nueva, sin backfill para metas existentes.
- goalQuickAmountOther eliminado de los .arb; metas.md actualizado
  con la divergencia pendiente contra billetudo.pen.
```
