# Fix cursor de snooze y undo de skip pospuesto (fix-snooze-cursor-and-undo-skip)

## Objetivo y criterios de aceptación

Corregir el bug de fondo que comparten los issues #15 y #20-punto2: `snoozeOccurrence` nunca
avanzaba el cursor (`nextDate`) de la plantilla como sí hacen `confirmOccurrence` y
`skipOccurrence`, dejando fechas fantasma en el card de presupuesto y subestimando el disponible
comprometido hasta que el usuario confirma. Además corregir el bug aislado de #20-punto1:
`undoSkipCompanion` no limpiaba `snoozedToDate`, por lo que "Recuperar" un pago omitido-tras-pospuesto
restauraba en la fecha pospuesta vieja en vez de la fecha real. Ambos son fixes puros de lógica en
`data`/`domain`, sin tocar esquema ni UI.

Tamaño: m | Review: combined APROBADO

1. `snoozeOccurrence`, en ambas ramas (inserción y actualización), llama a `_advanceCursorPast` con
   la plantilla y la `occurrenceDate` original, igual que `confirmOccurrence`/`skipOccurrence`.
2. Plantilla `once` pospuesta: `_advanceCursorPast` sigue siendo no-op, sin excepción; el "Fix 6" de
   `budget_progress_calculator` sigue siendo necesario para este caso.
3. Snooze recurrente que cruza de periodo A a B: sin fantasma en A, disponible de B refleja el
   compromiso de inmediato.
4. Re-snooze de una ocurrencia recurrente no duplica avances (guard idempotente).
5. Confirmar una ocurrencia ya pospuesta no vuelve a avanzar el cursor una segunda vez.
6. `undoSkipCompanion` limpia `snoozedToDate` (`Value(null)`) además de volver `status` a `pending`.
7. Omitir una ocurrencia ya pospuesta y luego recuperarla vía `undoSkipOccurrence` restaura la fecha
   real (`occurrenceDate`), no la `snoozedToDate` vieja.
8. `flutter analyze` y `flutter test` de `scheduled_payments` y `budgets` pasan sin fallos.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart` | `snoozeOccurrence` obtiene la plantilla y llama a `_advanceCursorPast(template, occurrenceDate, now)` en la rama de inserción y en la de actualización, igual que `confirmOccurrence`/`skipOccurrence`. Se apoya en el guard idempotente ya existente (`occurrenceDate < template.nextDate` → no-op) para que re-snooze y snooze-luego-confirm no dupliquen el avance. |
| `lib/features/scheduled_payments/data/models/scheduled_payment_occurrence_mapper.dart` | `undoSkipCompanion` agrega `snoozedToDate: const Value(null)`. Además, por higiene de datos, `skipCompanion` también limpia `snoozedToDate` (una fila `skipped` con `snoozedToDate` residual es un estado inconsistente, aunque hoy nada lo lea directamente). |
| `test/features/scheduled_payments/data/scheduled_payment_repository_impl_test.dart` | Actualizado el test preexistente "mueve solo la ocurrencia sin tocar la cadencia de la plantilla" (su assert de `nextDate` sin cambios codificaba el bug). 4 tests nuevos: snooze de plantilla `once` no avanza cursor, re-snooze consecutivo idempotente, confirm-tras-snooze no doble-avanza, skip sobre occurrence ya-snoozed + `undoSkipOccurrence` restaura la fecha real sin `snoozedToDate` residual. |
| `test/features/budgets/domain/budget_progress_calculator_test.dart` | Test de regresión nuevo: ocurrencia recurrente pospuesta cruzando límite de periodo A→B — sin fantasma en A, disponible de B con el compromiso inmediato. |

`budget_progress_calculator.dart` **no se tocó**: una vez que `snoozeOccurrence` avanza el cursor
recurrente de inmediato, `projected` (que arranca en `template.nextDate`) deja de reproyectar la
fecha original en el periodo A, y la fila `pending`/`snoozed` aparece correctamente solo en B —
sin duplicados ni huecos, sin tocar el "Fix 6" existente.

## Tests

Resultado: `dart analyze` limpio (0 issues en los 2 archivos de `lib/` tocados) · suite verde
(`scheduled_payments` + `budgets`: 922 tests, 0 fallos) · e2e: skip (ver checklist abajo).
Sin tests nuevos fuera de los 5 descritos en la tabla de arriba (4 en scheduled_payments, 1 en budgets).

```bash
flutter analyze lib/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart lib/features/scheduled_payments/data/models/scheduled_payment_occurrence_mapper.dart
flutter test test/features/scheduled_payments test/features/budgets
```

## Fidelidad visual vs Pencil

N/A (feature sin UI en este cambio) — fix puro de lógica en `data/`, sin widgets ni pantallas
tocadas. Ver fila "Pagos programados" en `docs/fidelidad-visual-tracking.md` (nota de esta corrida
agregada, estado se mantiene ✅ Aprobada por la auditoría real ya cerrada el 2026-07-20).

## 👤 Verifica a mano

- [ ] Confirmar visualmente en la app real que, al posponer un pago programado recurrente hacia un
      mes distinto, la tarjeta de presupuesto del mes original deja de mostrar la fecha fantasma y
      la del mes destino muestra el monto comprometido de inmediato (sin esperar a confirmar).
- [ ] Confirmar que "Recuperar" sobre un pago omitido-tras-pospuesto muestra en la UI la fecha
      original correcta, no la fecha pospuesta vieja, en el detalle y en el historial.
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisa por qué.

## Pendientes y riesgos

- **Gap conocido, fuera de alcance:** plantillas `once` pospuestas a una fecha distinta de la
  original tienen un hueco preexistente en "Fix 6" (su clave usa `effectiveDate`, que ya no coincide
  con la fecha proyectada original) — no pedido por el change map de esta corrida (solo pedía el
  cruce recurrente A→B), documentado aquí para decidir después si se aborda.
- `undoSnoozeOccurrence` no revierte el avance de `nextDate` que ahora hace `snoozeOccurrence`
  (simétrico con que `undoSkipOccurrence` tampoco revierte el de `skipOccurrence` hoy); el guard
  idempotente evita que esto produzca un avance incorrecto observable, pero si un test de regresión
  futuro muestra una fecha de proyección inconsistente en el card, sería un tercer bug relacionado a
  reportar aparte.
- `_advanceCursorPast` compara contra `template.nextDate`, no contra la ocurrencia más reciente
  conocida; en flujos concurrentes con reintentos (poco probable en local-first single-user) el
  guard podría no ser suficiente — fuera de alcance, documentado como límite conocido.
- Sin blockers. Sin hallazgos de convenciones (dinero/UUID/capas, ui-convention-reviewer, tier0)
  aplicables — el diff es lógica interna de `data/` sin contacto con monetización ni widgets.

## Mensaje de commit sugerido

```
fix(scheduled_payments): avanzar cursor al posponer y limpiar snoozedToDate al recuperar omitido

- snoozeOccurrence ahora avanza template.nextDate en ambas ramas, igual que
  confirmOccurrence/skipOccurrence (issues #15, #20-punto2)
- undoSkipCompanion limpia snoozedToDate al restaurar (issue #20-punto1)
- test de regresión en budget_progress_calculator para snooze cruzando periodo

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_013tmJW9fTQBXdnEymJjfNT8
```
