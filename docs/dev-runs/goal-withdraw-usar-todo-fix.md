# Retirar de una meta: separar "Usar todo" del texto informativo (goal-withdraw-usar-todo-fix)

## Objetivo y criterios de aceptación

En la hoja de Retirar de una meta (`isWithdrawal=true`), el texto "Disponible en la meta: {amount}"
y el CTA "Usar todo" vivían dentro de un único `TextButton`, así que todo el bloque era tapeable y
tocar cualquier parte de él disparaba `cubit.useMax()`. Además, al tocar "Usar todo" el campo de
monto visible (`GoalAmountHeroField`) no se actualizaba — solo cambiaba el `state.amountMinor` del
cubit, porque `didUpdateWidget` solo resincronizaba el controller cuando cambiaba la moneda, nunca
cuando cambiaba `initialAmountMinor`.

Criterios de aceptación:

1. "Disponible en la meta: {amount}" se renderiza como texto pasivo (no tapeable); "Usar todo" es un
   elemento tapeable distinto y visualmente diferenciado (subrayado + color de acción), ambos en la
   misma fila.
2. Tocar solo "Usar todo" dispara `cubit.useMax()`; tocar el texto informativo no dispara nada.
3. Tras tocar "Usar todo", el `TextField` del monto muestra el monto máximo formateado (no `$0`).
4. Mientras el usuario escribe manualmente, el controller no se re-formatea ni mueve el cursor
   (sin regresión de UX de tipeo).
5. Los demás callers de `GoalAmountHeroField` (prefill de chips de aporte rápido, cambio de
   currency) siguen funcionando igual que antes.
6. `app_es.arb`/`app_en.arb` quedan con las claves correctas, sin huérfanas; `flutter gen-l10n` sin
   errores.
7. Existe un widget test que reproduce el flujo real (cubit real, tap en "Usar todo", verifica el
   texto visible del `TextField`, no solo el state).
8. Los goldens existentes de la hoja se regeneran y quedan verdes; `flutter analyze` y
   `flutter test` sin fallas nuevas.

Tamaño: s. Review: quick, APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart` | El `TextButton` único que envolvía "Disponible en la meta: {amount} · Usar todo" se reemplazó por una `Row` con un `Text` pasivo (`goalWithdrawAvailableLabel`, color `textSecondary`) y un `GestureDetector` separado (key `goal-withdraw-use-max`) con `Text` subrayado en `colors.primaryOnSoftStrong` para "Usar todo" (`goalWithdrawUseMaxCta`), que llama a `cubit.useMax()`. |
| `lib/features/goals/presentation/widgets/goal_amount_hero_field.dart` | `didUpdateWidget` ahora también resincroniza el controller cuando `initialAmountMinor` cambia **y** difiere del valor ya parseado del controller — evita interferir con el tipeo normal (cada `onChanged` deja controller e `initialAmountMinor` iguales, así que es un no-op). |
| `lib/core/l10n/arb/app_es.arb`, `lib/core/l10n/arb/app_en.arb` | `goalWithdrawAvailable` se separó en `goalWithdrawAvailableLabel` (con placeholder `amount`) y `goalWithdrawUseMaxCta`. Sin claves huérfanas (grep confirma cero referencias a `goalWithdrawAvailable` tras el cambio). |
| `lib/core/l10n/gen/app_localizations*.dart` | Regenerados por `flutter gen-l10n`, sin errores. |
| `test/features/goals/presentation/widgets/sheets/goal_contribution_sheet_use_max_test.dart` | Nuevo: cubit real (no mock) vía `BlocProvider.value`, tap en "Usar todo" verificando el texto visible del `TextField`, y tap en el texto pasivo verificando que no dispara `useMax()`. |
| `test/features/goals/presentation/widgets/goal_amount_hero_field_test.dart` | Nuevo: tipeo por teclas sin re-formateo/salto de cursor, cambio externo de `initialAmountMinor` sí reformatea, cambio de currency sigue resincronizando. |
| Goldens de `sheet_goal_withdraw_*` (error, move_on, move_on_budget, completed — claro/oscuro) y `goal_detail_page_quick_amount_prefilled_*` (sheet, sheet custom — claro/oscuro) | Regenerados con `--update-goldens`. |

## Tests

Resultado: `flutter analyze` limpio, suite completa de `test/features/goals` en verde (303/303), e2e en skip (no se corrió emulador en esta corrida).

Comandos para re-correr:

```bash
flutter analyze lib/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart \
  lib/features/goals/presentation/widgets/goal_amount_hero_field.dart

flutter test test/features/goals/presentation/widgets/sheets/goal_contribution_sheet_use_max_test.dart \
  test/features/goals/presentation/widgets/goal_amount_hero_field_test.dart

flutter test test/features/goals
```

Para regenerar los goldens tocados (solo si cambia algo visual de nuevo):

```bash
flutter test test/features/goals/presentation/golden/goals_sheets_golden_test.dart \
  test/features/goals/presentation/golden/goal_detail_page_quick_amount_prefilled_sheet_golden_test.dart \
  --update-goldens
```

## Fidelidad visual vs Pencil

N/A en esta corrida. `design-system/billetudo/pages/goals.md` no existe en el repo (confirmado con
`Read`: "File does not exist"). Sin ese archivo no hay tabla de correspondencia Pantalla/pieza →
Node ID (claro/oscuro) contra la cual mapear los goldens de
`test/features/goals/presentation/golden/goldens/*.png`, y el playbook de fidelidad es explícito en
que no se debe inventar ese mapeo. Según la nota de memoria del proyecto
(`metas-rediseno-en-curso.md`), el rediseño de Metas está cerrado y aprobado en Pencil (claro+oscuro)
con spec en `pages/metas.md` — es probable que el spec real viva bajo ese nombre en español en vez de
`goals.md`, o que aún no se haya escrito. No se verificó acceso al `.pen` (`get_editor_state`) porque,
sin el `.md` que sirva de mapeo nodeId↔golden, cualquier comparación sería a ciegas.

Recomendación: relanzar esta auditoría apuntando al nombre correcto del spec (posiblemente
`design-system/billetudo/pages/metas.md`) si existe, o completar/crear `pages/goals.md` antes de
re-solicitar el chequeo de fidelidad.

Decisión de estilo tomada sin ese spec disponible: subrayado + `primaryOnSoftStrong` para el CTA
"Usar todo" (mismo token que "Enlazar un movimiento" más abajo en el mismo archivo, por consistencia
interna) en vez de inventar un token nuevo.

## 👤 Verifica a mano

- [ ] Confirmar visualmente (dispositivo/emulador) que "Usar todo" se percibe como claramente
      tapeable frente al texto pasivo en ambos temas — el golden capta píxeles pero la intención
      táctil final la valida un humano o `pencil-fidelity-reviewer`.
- [ ] Verificar en un dispositivo real que el área tapeable de "Usar todo" (`GestureDetector` ceñido
      al texto) tiene suficiente target size/padding para el dedo; no se testea hit-target mínimo en
      widget tests.
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisa por qué.

## Pendientes y riesgos

- Gap de cobertura: no hay `design-system/billetudo/pages/goals.md` (ni, aparentemente,
  `pages/metas.md` verificado en esta corrida) para auditar fidelidad visual de este fix contra
  Pencil. Ya estaba abierto en corridas previas del 2026-07-29 sobre Metas; sigue abierto.
- Riesgo mitigado en el propio fix: la condición de resincronización en `didUpdateWidget` compara
  `initialAmountMinor` contra el valor ya parseado del controller (no solo si cambió el prop), para
  no romper el tipeo en medio del número — cubierto por AC4 y su test.
- Sin blockers sin resolver.
- Sin violaciones de convenciones críticas detectadas (dinero en `amountMinor` entero, IDs UUID,
  sin fuga de tipos Drift, comillas simples, sin widgets privados/funciones que devuelven `Widget`,
  todo el texto vía `AppLocalizations`).

## Mensaje de commit sugerido

```
fix(goals): separar 'Usar todo' del texto informativo y sincronizar el campo de monto

La hoja de Retirar mezclaba el texto pasivo 'Disponible en la meta' con el CTA
'Usar todo' en un solo TextButton, y tocar 'Usar todo' no actualizaba el
TextField visible del monto (solo el state del cubit). Ahora son dos
elementos separados y GoalAmountHeroField resincroniza cuando
initialAmountMinor cambia por fuera del tipeo del usuario.
```
