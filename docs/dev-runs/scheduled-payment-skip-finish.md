# Pagos programados: omitir y deuda cerrada terminan la plantilla (scheduled-payment-skip-finish)

## Objetivo y criterios de aceptación

Un `ScheduledPayment` `once` (o la última cuota pendiente de uno recurrente con `endDate`) que se
**omite** debe pasar a "Terminado" (revivible vía el "Recuperar" ya existente), en vez de seguir
mostrándose como activo. Y un `ScheduledPayment` vinculado a una `Debt` (`debtId`) debe pasar a
"Terminado" automáticamente cuando esa `Debt` se cierra (`CloseDebt`), sin tocar la feature
`debts` ni el esquema Drift — ambos casos se derivan de columnas ya existentes
(`ScheduledPaymentOccurrences.status`, `Debts.closedAt`).

Tamaño: **m** · Review: **combined APROBADO**

1. `once` con única ocurrencia `skipped` (ninguna `confirmed`) → `isActive == false`, aparece en
   `watchFinishedScheduledPayments()` / desaparece de `watchActiveScheduledPayments()`.
2. Ese mismo pago sigue mostrando "PAGO EJECUTADO" como **no** ejecutado (`onceAlreadyGenerated`
   sigue atado solo a `confirmed`, sin cambios de comportamiento); la ficha muestra "Terminada",
   no "Activa".
3. "Recuperar" (`UndoSkipScheduledOccurrence`, ya existente del fix de issue #20) vuelve la
   ocurrencia a `pending`, el `ScheduledPayment` vuelve a `isActive == true` y reaparece en
   `watchActiveScheduledPayments()`, sin generar transacción duplicada.
4. Recurrente con `endDate`: omitir la última cuota pendiente antes de `endDate` hace que
   `nextDate` avance más allá de `endDate` y el template quede `isActive == false` (regresión:
   confirma que `_advanceCursorPast` + `_activeExpr` ya lo resuelven, sin tocar ese código).
5. Recurrente **sin** `endDate`: omitir una ocurrencia deja `isActive == true` y sigue
   proyectando/generando la siguiente normalmente.
6. `ScheduledPayment` con `debtId` a una `Debt` activa es `isActive == true`; al cerrar esa
   `Debt` (`CloseDebt`) pasa a `isActive == false` y aparece en `watchFinishedScheduledPayments()`,
   **sin ninguna escritura** sobre la fila de `ScheduledPayments` (se deriva leyendo
   `Debts.closedAt`, no se persiste bandera nueva).
7. Varios `ScheduledPayments` vinculados a la misma `Debt` cerrada quedan todos
   `isActive == false`.
8. Cerrar una `Debt` sin ningún `ScheduledPayment` vinculado no falla, no altera otras plantillas
   y no cambia `watchActiveScheduledPayments()`/`watchFinishedScheduledPayments()` para templates
   no relacionados.
9. `ScheduledPaymentDetail.isActive` para un template vinculado a deuda refleja
   `linkedDebt.isClosed` (campo derivado del join ya existente a `Debts` en
   `watchScheduledPaymentRow`), consistente con el criterio 6 a nivel de lista.
10. `flutter analyze` limpio y toda la suite de `scheduled_payments` y `debts` pasa (existente +
    nueva), incluidos los 6 casos de borde del issue.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/scheduled_payments/data/datasources/scheduled_payments_local_datasource.dart` | `_activeExpr()` ahora exige `onceAlreadyResolved` (confirmed OR skipped, antes solo confirmed) para `once`, y `debtId IS NULL OR EXISTS(debt abierta)` para pagos vinculados a deuda. Nuevo `countResolvedOccurrences()` (confirmed+skipped), separado de `countGeneratedTransactions()` (solo confirmed, única fuente del label "PAGO EJECUTADO"). |
| `lib/features/scheduled_payments/domain/entities/scheduled_payment.dart` | `isActive({required bool onceAlreadyResolved})` — parámetro renombrado desde `onceAlreadyGenerated`, misma lógica interna. |
| `lib/features/scheduled_payments/domain/entities/scheduled_payment_linked_debt.dart` | Gana `closedAt`/`isClosed` derivados. |
| `lib/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart` | Gana `resolvedOccurrenceCount` (alimentado por `countResolvedOccurrences`); `isActive` combina `scheduledPayment.isActive(onceAlreadyResolved: ...)` con `linkedDebt?.isClosed != true`, sin que `ScheduledPayment` (entidad pura) dependa de `Debt`. `onceAlreadyGenerated` (label) queda intacto, keyed solo en `generatedTransactionCount`. |
| `lib/features/scheduled_payments/data/repositories/scheduled_payment_repository_impl.dart` | Mapea `closedAt`/`isClosed` desde el join ya existente a `Debts` (ninguna query nueva). |

`CloseDebt` (feature `debts`) **no se tocó** — sigue siendo una escritura pura de `Debts.closedAt`;
se agregó un test de regresión que verifica (`verifyNoMoreInteractions`) que no gana ningún hook
cross-feature hacia `ScheduledPayments`.

Diseño: se evitó a propósito el hook `debts → scheduled_payments` vía interfaz de dominio
inyectada; `isActive` se deriva leyendo `Debts.closedAt` directamente desde el datasource de
`scheduled_payments`, mismo patrón ya usado en `watchScheduledPaymentRow`/`getDebtStartDate`. Más
simple, sin coupling nuevo de dominio ni migración, y "revivible" gratis si algún día existe
"reabrir deuda" — pero `lib/features/debts/**` queda intacto.

## Tests

- `dart analyze` → 0 issues.
- `flutter test test/features/scheduled_payments test/features/debts` → 864/864 passed.
- e2e: `integration_test/scheduled_payments_patrol_test.dart` (escenario nuevo
  `bugfix scheduled-payment-skip-finish`) escrito pero **no corrido** — bloqueo de infra de
  emulador en esta máquina (MIUI).

Comandos para re-correr:

```bash
dart analyze lib/features/scheduled_payments lib/features/debts test/features/scheduled_payments test/features/debts
flutter test test/features/scheduled_payments test/features/debts
patrol test --target integration_test/scheduled_payments_patrol_test.dart --flavor dev
```

Tests nuevos:
- `test/features/scheduled_payments/domain/entities/scheduled_payment_detail_test.dart` (7 casos: skip de `once`, deuda abierta/cerrada).
- `test/features/scheduled_payments/data/scheduled_payment_repository_impl_test.dart` (6 grupos con `NativeDatabase.memory()`, grupo nuevo "omitir/deuda-cerrada terminan una plantilla", uno por criterio 1-9).
- `test/features/debts/domain/usecases/close_debt_test.dart` (1 test de regresión, `verifyNoMoreInteractions`).
- `test/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page_test.dart` (caso "once omitido, resuelto pero no generado").
- `integration_test/scheduled_payments_patrol_test.dart` (escenario e2e nuevo, sin correr).

Fuera del change map pero necesario, dentro de `test/**`: se actualizaron 2 builders de fixtures
en `scheduled_payment_detail_page_test.dart` y `scheduled_payment_detail_page_golden_test.dart`
que construían `ScheduledPaymentDetail` sin pasar el nuevo `resolvedOccurrenceCount` (defaultea a
0 y calculaba mal `isActive` para "once ya generado"); se igualó al mismo total que ya usaban para
`generatedTransactionCount`/`historyRows.length`, sin cambiar ninguna aserción existente.
`resolve_ai_tool_call_test.dart` no necesitó cambios.

## Fidelidad visual vs Pencil

N/A — feature sin superficie de UI nueva en esta corrida. Los 5 archivos tocados en `lib/` son
capas `data`/`domain` puras (datasource, dos entidades, repositorio): ninguno contiene un widget
ni construye UI. No se generaron goldens nuevos.

## 👤 Verifica a mano

- [ ] Confirmar en el dispositivo físico (fuera de este entorno, bloqueado por MIUI) el flujo
      Patrol nuevo `bugfix scheduled-payment-skip-finish` en
      `integration_test/scheduled_payments_patrol_test.dart`: crear un `once`, Confirmar ahora →
      Omitir → verificar ficha "Terminada" sin "PAGO EJECUTADO" → Recuperar → verificar
      "Pendiente de confirmar", sin transacción duplicada.
- [ ] Validar visualmente en dispositivo que el label "Terminada" vs "Activa" en la ficha se ve
      correcto (color/tono) para el caso nuevo de `once` omitido — no hay golden nuevo para este
      escenario (esta corrida no incluyó fase de goldens).
- [ ] Confirmar en un flujo real con Deudas que cerrar una deuda con cuotas vinculadas activas
      efectivamente saca esas plantillas de la lista "Activos" visible al usuario en la UI
      (cubierto a nivel Drift+entidad en esta corrida, no a nivel widget de la lista).
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisar por qué antes de
      confiar en el escenario sin haberlo corrido al menos una vez.

## Pendientes y riesgos

- **Sin blockers.**
- Riesgo financiero real (no bloqueante, pero exigió tests fuertes antes de mergear): esta
  feature redefine cuándo una obligación programada deja de contar como activa, lo que afecta
  qué se muestra como "próximo pago" y qué aparece en Terminados — cubierto por los 6 casos de
  borde del issue, todos en verde.
- `onceAlreadyGenerated` (label "PAGO EJECUTADO") y la nueva señal "resuelto" (para `isActive`)
  se mantuvieron estrictamente separadas — reusar la misma cuenta para ambas reintroduciría el
  bug que `ec268319`/`117cbbf8`/`5268d43f` ya corrigieron en el área de labels de la ficha.
  Verificado con tests dedicados, no solo lectura de código.
- Gap de cobertura: el e2e Patrol nuevo no se corrió (infra de emulador bloqueada en esta
  máquina) — queda como verificación manual pendiente arriba.
- No se tocó `debts` (esquema ni feature), ni `schemaVersion` de Drift — todo se deriva de
  columnas existentes.

## Mensaje de commit sugerido

```
fix(scheduled-payments): omitir once y cerrar deuda vinculada terminan la plantilla

- once con única ocurrencia skipped pasa a Terminado (isActive false),
  revivible vía Recuperar sin duplicar transacción
- recurrente con endDate: omitir la última cuota antes de endDate también
  termina el template (regresión verificada sobre _advanceCursorPast/_activeExpr)
- ScheduledPayment vinculado a una Debt pasa a Terminado cuando esa Debt
  se cierra (CloseDebt), derivado de Debts.closedAt sin escribir en
  ScheduledPayments ni tocar la feature debts

Cierra los 6 casos de borde del issue. flutter analyze limpio,
864/864 tests verdes en scheduled_payments + debts.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_013tmJW9fTQBXdnEymJjfNT8
```
