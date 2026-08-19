# HU-16: aporte recurrente de Metas vía Pagos Programados (goals-scheduled-payment-recurring-contribution)

## Objetivo y criterios de aceptación

Permitir enlazar una meta a un aporte recurrente vía Pagos Programados: columna exclusiva `goalId` en `ScheduledPayments` (análoga a `debtId`), lógica de dominio de exclusividad `debtId`/`goalId`, y la UI ya aprobada en Pencil (sheet de decisión enlazar/crear, config de aporte recurrente clon de la cuota de Deudas, picker de PP existente, card "Meta Enlazada" en el detalle de PP).

1. `ScheduledPayments` gana `goalId` nullable, `schemaVersion` incrementado con bloque `if (from < N)` en `onUpgrade` (mismo patrón que `debtId`); `powersync_schema.dart` declara `goal_id`; migración SQL en `supabase/migrations` agrega `goal_id` a `public.scheduled_payments`.
2. `ScheduledPaymentDraft.validated()` rechaza con `ValidationFailure` un draft con `debtId` y `goalId` simultáneos, en ambas direcciones.
3. Crear meta nueva desde "Aporte recurrente" > "crear nuevo" persiste `ScheduledPayments` con `goalId` y `debtId` null, mismos campos que la cuota de Deudas (cuenta origen, toggle presupuesto+categoría "Ahorros" preseleccionada, frecuencia, monto fijo).
4. "Enlazar existente" abre un picker que solo lista PP activos sin `debtId`/`goalId`, y al seleccionar asigna `goalId` vía `UpdateScheduledPayment` sin duplicar la plantilla.
5. El detalle de un PP con `goalId` muestra la card "Meta Enlazada" (eyebrow + "Aporte a `<meta>`" + deep-link), análoga a "Deuda Enlazada", mutuamente excluyente.
6. Tap en "Meta Enlazada" navega al detalle de la meta (deep-link real).
7. Se confirma contra el gate de Pencil si el Detalle de Meta debe reflejar el aporte enlazado; solo se implementa si existe frame.
8. `flutter analyze` y suite de tests de `goals`/`scheduled_payments` pasan sin regresiones; goldens claro/oscuro para las pantallas nuevas.

Tamaño: L. Review: deep, APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` (+`.g.dart`) | Columna `goalId` nullable en `ScheduledPayments`, `schemaVersion` 27→28, bloque `if (from < 28)` en `onUpgrade` (documentado, sin `addColumn` porque la tabla es vista de PowerSync) |
| `lib/core/database/powersync_schema.dart` | Declara `goal_id` en la tabla `scheduled_payments` |
| `supabase/migrations/20260817000000_scheduled_payments_add_goal_id.sql` | `ALTER TABLE public.scheduled_payments ADD COLUMN goal_id` (paridad Postgres) |
| `lib/features/scheduled_payments/domain/entities/{scheduled_payment,scheduled_payment_draft,scheduled_payment_detail,scheduled_payment_linked_goal}.dart` | `goalId` en entidad/draft, exclusividad `debtId`/`goalId` en `validated()`, value object `ScheduledPaymentLinkedGoal` |
| `lib/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart` + `usecases/get_linkable_scheduled_payments.dart` | `watchLinkableScheduledPayments`, `linkScheduledPaymentToGoal` |
| `lib/features/scheduled_payments/data/{models/scheduled_payment_mapper,datasources/scheduled_payments_local_datasource,repositories/scheduled_payment_repository_impl}.dart` | Mapeo de `goalId`, query de PP enlazables, companion mínimo `linkScheduledPaymentToGoal` (solo toca `goalId`+`updatedAt`, no reusa `UpdateScheduledPayment` completo — ver Pendientes) |
| `lib/features/goals/domain/usecases/{create_goal_recurring_contribution,link_scheduled_payment_to_goal,get_linkable_scheduled_payments}.dart` | Casos de uso cross-feature del lado de Metas |
| `lib/features/goals/presentation/{cubit/goal_recurring_contribution_*,pages/goal_recurring_contribution_decision_page,pages/goal_recurring_contribution_form_page,widgets/goal_scheduled_payment_picker_sheet}.dart` | Cubit + sheet de decisión + form "crear nuevo" (reusa `ScheduledPaymentFormCubit`/`ScheduledPaymentFormPage` vía `loadForDebtCuota`, patrón ya usado por Deudas) + picker |
| `lib/features/scheduled_payments/presentation/{widgets/scheduled_payment_linked_goal_card,pages/scheduled_payment_detail_page}.dart` | Card "Meta Enlazada" mutuamente excluyente con "Deuda Enlazada", `onOpenGoal` |
| `lib/core/router/app_router.dart` | Ruta `/metas/<id>/aporte-recurrente` + `onOpenGoal` → `context.push(AppRoutes.goal(goalId))` |
| `lib/core/l10n/arb/{app_es,app_en}.arb` (+ gen) | Claves nuevas de HU-16 |
| `lib/core/di/injection.config.dart` | Cubit nuevo cableado vía `@injectable`/codegen |
| Tests unit/data/cubit/widget/golden bajo `test/features/{goals,scheduled_payments}/` | Ver sección Tests |

**Desviación del change map:** el flujo "enlazar existente" no reusa `UpdateScheduledPayment` con draft completo (habría exigido resolver `categoryKind` sin necesidad); se agregó `linkScheduledPaymentToGoal` como companion mínimo.

**No implementado (deliberado):** el radio Automático/Manual, etiquetas y "Eliminar cuota" del frame `ebcqG` no se replicaron en `GoalRecurringContributionFormPage` — el caso de uso ya fija `requiresConfirmation: false` por defecto, así que el resultado funcional es correcto pero el radio no es editable en UI todavía.

**No cableado (deliberado, ver AC7 abajo):** ningún call site real en `goal_detail_page.dart` abre este flujo — no existe frame de Pencil que autorice el entry-point en esta iteración.

## Tests

Resultado: `flutter analyze` limpio (solo 4 infos preexistentes en `import_export`, no relacionados). `flutter test test/features/goals test/features/scheduled_payments`: 26 fallos, todos pixel-diffs <0.3% preexistentes en `confirmation_sheet`/`snooze`/`detail_and_delete_sheets_golden_test.dart` (no tocados por esta HU, consistente con la flakiness ya documentada en memoria). Ningún golden nuevo de esta corrida está entre los fallos. e2e: skip.

Comandos para re-correr:
```bash
flutter analyze
flutter test test/features/goals test/features/scheduled_payments
flutter test test/core/database/
```

Tests nuevos escritos:
- `test/features/scheduled_payments/domain/entities/scheduled_payment_draft_test.dart` (exclusividad `debtId`/`goalId`, 4 casos)
- `test/features/scheduled_payments/data/scheduled_payment_repository_impl_test.dart` (persistencia `goalId`, `watchLinkableScheduledPayments`, `linkScheduledPaymentToGoal`)
- `test/features/scheduled_payments/domain/usecases/get_linkable_scheduled_payments_test.dart`
- `test/features/goals/domain/usecases/{link_scheduled_payment_to_goal,create_goal_recurring_contribution,get_linkable_scheduled_payments}_test.dart`
- `test/features/goals/presentation/cubit/goal_recurring_contribution_cubit_test.dart`
- `test/features/goals/presentation/golden/goal_recurring_contribution_golden_test.dart` (6 goldens: sheet decisión, form, picker × claro/oscuro)
- `test/features/scheduled_payments/presentation/widgets/scheduled_payment_linked_goal_card_test.dart` (+ 2 goldens claro/oscuro)
- `test/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page_test.dart` (incluye caso "si trae `linkedDebt` y `linkedGoal` a la vez, muestra solo la card de deuda")
- `test/features/goals/presentation/pages/goal_recurring_contribution_decision_page_test.dart`
- `test/features/goals/presentation/widgets/goal_scheduled_payment_picker_sheet_test.dart`

`test/core/database/schema_parity_test.dart` falla por causa ajena a este cambio (columna `app_settings.quick_access_order`, ya presente antes de esta corrida) — no menciona `scheduled_payments`/`goal_id`.

## Fidelidad visual vs Pencil

**BLOQUEADO sin acceso a Pencil.** El spec existe (`design-system/billetudo/pages/metas.md`, sección "Integración con Pagos Programados (aporte recurrente, HU-16)", líneas 51-57 y 165-166) y cubre exactamente esta corrida: sheet decisión (`HOdfO`/`XB4rS`), config de aporte recurrente (`ebcqG`/`G2AfJ`), picker de PP existente (`RX8C9`/`LSwr8`), card "Meta Enlazada" en detalle de PP (`a2yR8P`/`tnaj3`). Los 6 goldens correspondientes existen en `test/features/goals/presentation/golden/goldens/`.

En esta sesión el único tool de Pencil disponible fue `get_app_state` (confirmó `.pen` activo y lista de nodos); no hubo acceso a `execute` (Get/Print/GetVariables) ni a `get_screenshot`, ambos requeridos para traer contenido real o captura visual de los nodeId. No se reportan hallazgos de fidelidad porque compararía a ciegas contra el `.md` solo — exactamente lo que el gate prohíbe.

Nota observada solo desde los goldens (sin poder confirmarla contra el `.pen`): `goal_recurring_contribution_decision_light/dark.png` no muestra Page Header con botón atrás, lo cual contradice `metas.md` línea 87 ("Page Header" esperado en estas pantallas) — **no confirmado**, requiere re-verificación con `execute`/`get_screenshot`.

Recomendación: re-correr `/design-fidelity-check goals` (o `pencil-fidelity-reviewer`) en una sesión donde el harness exponga `mcp__pencil__execute` y `mcp__pencil__get_screenshot`.

## 👤 Verifica a mano

- Cablear en la UI real el punto de entrada a "Aporte recurrente" (menú de acciones de Meta u otro lugar que el equipo decida) — sin esto, HU-16 no es alcanzable por un usuario real pese a estar completamente implementada y testeada en aislamiento; una vez cableado, correr manualmente el flujo completo en un device (crear nuevo / enlazar existente / tap en "Meta Enlazada" → detalle de meta).
- Aplicar `supabase/migrations/20260817000000_scheduled_payments_add_goal_id.sql` al proyecto Supabase dev (y luego prod) y refrescar `test/core/database/fixtures/postgres_schema.json` con `dart run tool/check_schema_parity.dart --refresh` — de lo contrario la cola de subida de PowerSync se atasca en el primer write con `goalId`.
- Confirmar contra el `.pen` (`pencil-fidelity-reviewer`) si el Detalle de Meta debe reflejar el aporte recurrente enlazado (AC7) — no verificado de forma independiente en esta corrida de QA.
- Revisión de fidelidad visual píxel-a-píxel de los 3 goldens nuevos (sheet de decisión, form, picker) y de la card "Meta Enlazada" contra sus nodeId en Pencil (fuera del alcance de `qa-automator`).
- El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- **Gap de cobertura AC7**: no verificado de forma independiente si el Detalle de Meta debe reflejar el aporte recurrente enlazado; `goal_detail_page.dart` no fue tocado, consistente con "no existe frame, no se agrega" pero sin confirmación real contra Pencil en esta corrida.
- **Migración Supabase sin aplicar**: `supabase/migrations/20260817000000_scheduled_payments_add_goal_id.sql` existe en el repo pero no se aplicó a Supabase dev/prod en esta corrida — `schema_parity_test.dart` seguirá sin fallar por esto porque el fixture de paridad tampoco fue refrescado; aplicar antes de que cualquier device sincronice `goalId`.
- ~~**Sin entry-point real**~~ — **desactualizado; verificado el 2026-08-19**: el punto de entrada YA está cableado. `goal_detail_page.dart` renderiza `GoalRecurringContributionEntryCard` para toda meta no archivada, y su tap abre `GoalRecurringContributionDecisionPage` (crear nueva / enlazar existente). HU-16 es alcanzable por un usuario real.
- **Exclusividad solo en dominio**: `debtId`/`goalId` se valida únicamente en `ScheduledPaymentDraft.validated()`, sin CHECK constraint SQL — una escritura que evite el draft (ej. un futuro import) podría romper la invariante silenciosamente. Fuera de alcance salvo pedido explícito.
- **Riesgo de sync ya mitigado**: la columna se agregó documentando (no ejecutando) `addColumn` porque `ScheduledPayments` es vista administrada por PowerSync desde v12 — mismo patrón ya usado por `debtId` (v14). `powersync_schema.dart` ya declara `goal_id`, así que la vista se recreará correcta cuando el device sincronice el schema nuevo.
- **Fidelidad visual bloqueada**: ver sección arriba — requiere re-corrida con acceso completo a Pencil (`execute` + `get_screenshot`).

## Mensaje de commit sugerido

```
feat(goals,scheduled_payments): enlazar meta a aporte recurrente vía Pagos Programados (HU-16)

- ScheduledPayments gana columna goalId nullable (schemaVersion 28),
  exclusiva con debtId (validada en ScheduledPaymentDraft.validated())
- powersync_schema.dart + migración Supabase para paridad de goal_id
- Sheet de decisión enlazar/crear, form de aporte recurrente (clon de
  cuota de Deudas), picker de PP existente sin debtId/goalId asignado
- Card "Meta Enlazada" en detalle de PP con deep-link al detalle de meta
- Pendiente: cablear entry-point real desde goal_detail_page.dart,
  aplicar migración a Supabase dev/prod, re-verificar fidelidad visual
  con acceso completo a Pencil (execute + get_screenshot)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
