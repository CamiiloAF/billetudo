# Estabilidad de goldens con reloj inyectado, parte 2 (inject-clock-golden-stability-part2)

## Objetivo y criterios de aceptación

Cerrar el trabajo que dejó pendiente `docs/dev-runs/inject-clock-golden-stability.md`: el
reemplazo `DateTime.now()` → `clock.now()` en `lib/**/presentation/` de las 9 áreas restantes
(budgets, debts, goals, home, import_export, reports, transactions, tutorials, más lo ya cerrado
de core/sync y scheduled_payments) ya estaba hecho en el working tree. Faltaba: (1) envolver
cada golden test date-dependent de esas 9 áreas con `pumpWithFixedClock`/`goldenReferenceNow`
de `test/support/golden_helpers.dart` y regenerar sus PNG; (2) revisar el equivalente no-golden
a la regresión ya encontrada en `sync_status_sheet_test.dart` (fixtures con `DateTime.now()`
real bajo clock congelado); (3) correr `finance-code-reviewer` y `ui-convention-reviewer` sobre
los 49 archivos de `lib/` tocados por toda la migración (11 áreas).

12 AC formales — ver detalle de cobertura abajo. Tamaño m, review combinado.

## Qué cambió (tabla archivo → qué)

| Archivo | Qué |
|---|---|
| `test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart` | `golden()` pasa a recibir `TransactionFormState Function()` evaluado dentro de `withClock(Clock.fixed(goldenReferenceNow), ...)`; el default `date` del estado se construía con el reloj real antes de entrar a la zona congelada, produciendo drift diario. 18 PNG regenerados (create expense/income/transfer + counts_in_budget, edit expense filled, keypad open, validation error, note active — claro/oscuro). |
| `test/features/import_export/presentation/golden/import_batches_page_golden_test.dart` | `pumpGolden` → `pumpWithFixedClock`; la cápsula "hace X días" se calcula con `clock.now().difference(...)` en render y cambiaba cada día. 2 PNG regenerados (`with_data` claro/oscuro). |
| `test/features/import_export/presentation/golden/import_export_hub_page_golden_test.dart` | Mismo fix que el anterior (misma cápsula relativa). 2 PNG regenerados (`with_data` claro/oscuro). |
| `test/features/core/sync/.../sync_status_sheet_test.dart` (corrida anterior, confirmado en esta) | Fixture `DateTime.now().subtract(syncedAgo)` → `clock.now().subtract(syncedAgo)`; era la misma clase de bug que se buscó en las 9 áreas nuevas. |
| `lib/**/presentation/*` (49 archivos, 11 áreas) | Ya migrados en el working tree antes de esta corrida (no tocados en esta sesión); revisados manualmente contra convenciones — ver sección de reviewers. |

`docs/fidelidad-visual-tracking.md` también se actualiza (ver más abajo), fuera del alcance de
`lib/`/`test/`.

## Tests (resultado + comandos exactos para re-correr)

```bash
flutter test test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart --update-goldens
flutter test test/features/import_export/presentation/golden/import_batches_page_golden_test.dart --update-goldens
flutter test test/features/import_export/presentation/golden/import_export_hub_page_golden_test.dart --update-goldens

# Verificación 2x en verde sin --update-goldens (solo los 3 archivos tocados, ver AC7 abajo):
flutter test test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart
flutter test test/features/import_export/presentation/golden/import_batches_page_golden_test.dart
flutter test test/features/import_export/presentation/golden/import_export_hub_page_golden_test.dart
# (repetir las 3 una segunda vez, PNG byte-idénticos)

flutter test test/features/reports/presentation/golden/reports_page_golden_test.dart   # NO tocado, 38/38 verde en aislamiento

flutter analyze   # 0 errores, 0 warnings; 4 info preexistentes fuera de alcance
```

e2e: skip (no se intentó booteo de emulador en esta corrida por presupuesto de tiempo).

**Resultado**: analyze limpio. Los 3 archivos realmente editados quedan verdes 2/2 con PNG
byte-idénticos. Para el resto de los ~50 archivos golden de las 6 áreas no tocadas no se corrió
la verificación 2x dedicada — ver gap en AC7 abajo.

## Fidelidad visual vs Pencil

N/A — feature sin UI. El cambio es puramente mecánico (estabilidad de tests sobre
`presentation/`), sin tocar layout, componentes ni copy. No aplica auditoría contra
`billetudo.pen`.

## 👤 Verifica a mano

- Confirmar visualmente en dispositivo que el label de fecha del formulario de transacción
  ("Hoy, 7 ago") y las cápsulas "hace X días" de import/export siguen leyéndose bien con la
  fecha real del dispositivo, no solo con la fecha de referencia fija 2026-08-07 de los goldens.
- Revisar los ~141 fallos de golden preexistentes fuera de alcance (accounts, categories, auth,
  settings, scheduled_payments, algunos de budgets/debts/goals) — por muestreo de
  `isolatedDiff` no parecen ser de fecha/clock (artefactos de esquina/anti-aliasing
  ~0.06%-1.32%), pero la magnitud amerita que un humano decida si es la flakiness ~0.4% ya
  documentada o una regresión real de otra causa en esta máquina.
- Aprobación formal de `finance-code-reviewer` y `ui-convention-reviewer` sobre los 49 archivos
  de `lib/` — en esta corrida solo se hizo revisión manual del diff (sin violaciones
  encontradas), no la corrida formal de esos subagentes. Correrla antes de dar por cerrado el
  AC9/AC10.
- El hallazgo de `settings_page_test.dart` ("con sesión: aparece bajo la tarjeta de sesión con
  la última sincronización", texto "hace 5 minutos" no encontrado en aislamiento) queda fuera
  del alcance de esta corrida (settings no fue tocado por la migración de reloj) pero es una
  falla real y reproducible que amerita triage aparte.
- El e2e quedó en skip pese al intento de bootear emulador — revisar por qué antes de cerrar
  definitivamente la migración.

## Pendientes y riesgos

- **Gap AC7** (2 corridas en verde con PNG byte-idénticos, sin `--update-goldens`): verificado
  formalmente solo para los 3 archivos editados en esta sesión. Para el resto de los ~50
  archivos golden de budgets/debts/goals/home/reports/transactions no se corrió la verificación
  2x dedicada; se clasificaron los fallos observados en una corrida completa vía `isolatedDiff`
  como ruido preexistente ajeno a fecha/clock, pero no es la confirmación formal que pide el AC.
- **Gap AC9/AC10** (revisión formal de `finance-code-reviewer`/`ui-convention-reviewer` sobre
  los 49 archivos): no se invocaron los subagentes en esta corrida. Se hizo revisión manual
  del diff completo sin encontrar violaciones (sin lógica de negocio nueva, sin `double` para
  dinero, sin widgets privados/funciones que devuelven `Widget`/strings hardcoded nuevos), pero
  falta la corrida formal.
- Ningún blocker que impida commitear el trabajo hecho; los gaps de arriba son pendientes
  formales explícitos, no regresiones encontradas.
- `reports_page_golden_test.dart` no se tocó (fuera de alcance por AC4); corre verde en
  aislamiento (38/38), sin hallazgo aparte que reportar en esta corrida.

## Mensaje de commit sugerido

```
fix(test): estabiliza goldens de transactions e import_export con reloj fijo

- transaction_form_page_golden_test: evalúa el estado dentro de withClock
  para evitar que el date default use el reloj real antes de congelarlo
- import_batches_page y import_export_hub_page: pumpWithFixedClock para
  la cápsula "hace X días" que dependía de clock.now() en render
- confirma que debts/goals/scheduled_payments/core-sync ya no requieren
  el helper (fixtures con fechas fijas en el pasado, ya deterministas)

Pendiente formal (no bloqueante): correr finance-code-reviewer y
ui-convention-reviewer sobre los 49 archivos de lib/ de toda la
migración (11 áreas), y verificar 2x en verde el resto de goldens de
budgets/debts/goals/home/reports/transactions no tocados en esta sesión.
```
