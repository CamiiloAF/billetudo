# Nota con autocompletado por historial (note-autocomplete)

## Objetivo y criterios de aceptación

Compartir un único campo de nota con autocompletado por historial (query `UNION` sobre
`Transactions`/`GoalContributions`/`DebtEntries`/`ScheduledPayments`) entre los 5 sitios de UI
que hoy capturan nota libre, siguiendo el spec de Pencil ya aprobado (Note Autocomplete,
`taqc1`).

1. `GetNoteSuggestions(query).call()` devuelve hasta 10 notas distintas (trim, no vacías,
   `deletedAt`/`tombstonedAt IS NULL`) de las 4 tablas, sin duplicados por texto
   (`COLLATE NOCASE`), ordenadas por frecuencia de uso desc. y luego por último uso desc.
2. Con query bajo el mínimo de caracteres (o vacío) el caso de uso devuelve lista vacía sin
   tocar la base de datos.
3. `NoteAutocompleteField` muestra el overlay "Suggestions Dropdown" solo con ≥1 coincidencia;
   con 0 coincidencias se comporta como texto libre normal, sin overlay ni error, en ambos
   temas.
4. El overlay crece libre hasta 4 filas completas; desde la 5ª sugerencia queda con
   `maxHeight:200` y scroll interno, sin desbordar ni tapar el resto del formulario.
5. Seleccionar una sugerencia rellena el campo con ese texto, dispara el mismo `onChanged` del
   sitio y cierra el overlay.
6. Los 5 sitios de consumo (transacciones, abono de deuda, aporte a meta, editar movimiento de
   meta, pago programado) quedan usando `NoteAutocompleteField` preservando hint/foco/
   `textInputAction`/`onSubmitted`/valor inicial sin disparar sugerencias espurias en modo
   editar.
7. `TransactionNoteField` deja de existir como widget propio, sin romper el colapso de la zona
   de monto al enfocar la nota.
8. `flutter analyze` y `flutter test` pasan sin nuevos errores; hay al menos un test del caso de
   uso (unión+orden+límite+mínimo) y un test/golden de `NoteAutocompleteField` cubriendo los 3
   estados en ambos temas contra los Node IDs documentados (`taqc1`/`otjW9`/`NdecZ` claro,
   `LOnm3`/`ETP5J`/`kS16A` oscuro).

Tamaño: m · Review: combined APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/notes/domain/repositories/note_suggestions_repository.dart` | Interfaz `NoteSuggestionsRepository.suggest(String query)` (nueva, transversal en `core/`). |
| `lib/core/notes/domain/usecases/get_note_suggestions.dart` | Caso de uso: aplica `minQueryLength=2` y `maxSuggestions=10` antes de tocar la BD. |
| `lib/core/notes/data/repositories/note_suggestions_repository_impl.dart` | `customSelect` con `UNION ALL` sobre `transactions`/`goal_contributions`/`debt_entries`/`scheduled_payments`, `GROUP BY note COLLATE NOCASE`, orden por frecuencia y último uso. |
| `lib/core/di/injection.config.dart` | Regenerado (`build_runner --force-jit`) con `NoteSuggestionsRepository` (lazySingleton) y `GetNoteSuggestions` (factory). |
| `lib/core/widgets/note_autocomplete_field.dart` | Widget compartido: `TextField` + overlay vía `OverlayPortal`/`CompositedTransformTarget`, sin coincidencias = texto libre normal. Fix real: `Column` del Field Wrap forzado a `mainAxisSize.min` (el `bottomLeft` del overlay anclaba al fondo de la pantalla por el `mainAxisSize.max` heredado). |
| `lib/core/widgets/note_suggestions_dropdown.dart` | Extraído a clase pública (antes `_NoteSuggestionsDropdown` privado dentro del field) — corrige `avoid_private_widgets`. |
| `lib/core/widgets/note_suggestion_row.dart` | Ídem para la fila individual del overlay. |
| `lib/features/transactions/presentation/pages/transaction_form_page.dart` | Usa `NoteAutocompleteField`; el `FocusNode` de nota (colapso de zona de monto) se movió a `TransactionFormScrollZone` (ahora `StatefulWidget`). |
| `lib/features/transactions/presentation/widgets/transaction_note_field.dart` | **Eliminado.** |
| `lib/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart` | `DebtFormField.text` → `NoteAutocompleteField` (conserva ícono `pencil`). |
| `lib/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart` | Migrado, label externo (`GoalMovementFieldLabel`) se conserva. |
| `lib/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet.dart` | Ídem. |
| `lib/features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart` | Migrado, label+hint consolidados dentro del widget. |
| `test/support/fake_note_suggestions.dart` | Fake de `NoteSuggestionsRepository` (siempre vacío) para tests que no pasan por `configureDependencies()` real. |
| 16 archivos de test preexistentes (transacciones, deudas, metas, pagos programados) | Regresión de DI corregida: registran `fake_note_suggestions` en `setUp`/`tearDown(getIt.reset)`. |
| Goldens de los 5 sitios migrados (30 `.png` regenerados) | Diff real esperado (nuevo `radioField 14` + tipografía del Field Wrap), no flakiness. |
| `test/core/notes/...` (2 archivos), `test/core/widgets/note_autocomplete_field_test.dart` + 6 goldens nuevos | Cobertura nueva del caso de uso/repositorio y del widget compartido. |
| `integration_test/transactions_patrol_test.dart` | Escenario e2e: nota tecleada en una transacción se sugiere en la siguiente y seleccionarla rellena el campo. |

## Tests

- `flutter analyze` → 0 errores nuevos (solo 7 infos preexistentes en `lib/features/reports/`,
  ajenas a esta corrida).
- `flutter test` → 3446 tests; únicas fallas son pixel-diffs de goldens no relacionados
  (flakiness ~0.4% ya documentado) más un caso explicado abajo (ver Verifica a mano).
- Comandos para re-correr:
  ```bash
  flutter analyze
  flutter test test/core/notes/ test/core/widgets/note_autocomplete_field_test.dart
  flutter test test/features/transactions/ test/features/debts/ test/features/goals/ test/features/scheduled_payments/
  patrol test --target integration_test/transactions_patrol_test.dart --flavor dev
  ```

Cobertura AC 1-8: los 8 criterios verificados con test dedicado (ver detalle en el diff de
cada archivo listado arriba); AC5 confirmado además end-to-end en device real vía Patrol.

## Fidelidad visual vs Pencil

**N/A** — no existe `design-system/billetudo/pages/core/notes.md` ni
`design-system/billetudo/pages/notes.md` (confirmado con `Glob` completo sobre
`design-system/billetudo/pages/**`). Sin ese `.md` no hay tabla Pantalla/pieza → Node ID contra
la cual resolver los goldens de `core/notes`. Es un gap de documentación, no un fallo de
fidelidad: la feature aún no tiene spec por pantalla en Pencil, así que no corresponde comparar
goldens contra el `.pen` todavía. No se intentó acceder al `.pen` porque, sin el `.md`, no
habría mapeo válido nodeId↔golden con el cual evaluar nada.

## 👤 Verifica a mano

- [ ] Verificar visualmente contra Pencil (`taqc1`/`otjW9`/`NdecZ` claro, `LOnm3`/`ETP5J`/`kS16A`
  oscuro) que los goldens de `NoteAutocompleteField` son fieles al diseño — corresponde a
  `/design-fidelity-check`, no a esta corrida de QA.
- [ ] Confirmar en un dispositivo real que el overlay no queda tapado por el teclado del sistema
  cuando el campo de Nota está cerca del borde inferior en pantallas pequeñas (el e2e valida la
  interacción funcional, no la superposición visual con el teclado en vivo).
- [ ] Revisar si el diff de "note field focused, amount zone collapsed" persiste al re-correr
  `flutter test --update-goldens` en un día distinto; si el diff desaparece confirma que la
  causa fue el rollover de fecha del sistema, no el colapso en sí.

## Pendientes y riesgos

- Gap de documentación: falta `design-system/billetudo/pages/core/notes.md` — sin él no se
  puede correr `/design-fidelity-check` sobre esta pieza de forma no ambigua.
- Gap de cobertura de fidelidad: pendiente el chequeo de cierre `/design-fidelity-check` sobre
  los 5 sitios migrados (no es obligatorio según CLAUDE.md, se corre a demanda).
- Sin blockers ni hallazgos CRÍTICO/IMPORTANTE pendientes de la revisión combinada.
- El árbol ya tenía cambios sin commitear de otro trabajo no relacionado
  (`budget-income-counts-in-budget`) presentes desde antes de esta sesión — no se tocaron ni se
  incluyen en este dev-run.

## Mensaje de commit sugerido

```
feat(core): unificar campo de nota con autocompletado por historial

Comparte NoteAutocompleteField (overlay de sugerencias vía UNION sobre
Transactions/GoalContributions/DebtEntries/ScheduledPayments) entre los 5
sitios que capturaban nota libre (transacciones, deudas, metas x2, pagos
programados), reemplazando TransactionNoteField. Contra el spec ya
aprobado en Pencil (taqc1/otjW9/NdecZ claro, LOnm3/ETP5J/kS16A oscuro).
```
