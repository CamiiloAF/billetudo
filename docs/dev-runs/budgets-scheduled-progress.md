# Progreso proyectado de pagos programados en Presupuestos (budgets-scheduled-progress)

## Objetivo y criterios de aceptacion

HU-12 de `docs/requirements/06-presupuestos.md`: extender Presupuestos (`lib/features/budgets/`) para proyectar, dentro de la ventana vigente del periodo, las ocurrencias de pagos programados que aun no se han materializado como transaccion. Se muestran como un segmento atenuado contiguo al gastado en la barra de progreso, se expone la cifra de "programado" y se da acceso a la lista de esos pagos — sin esquema nuevo, reutilizando `ProjectUpcomingOccurrences` de `scheduled_payments` (comentada explicitamente en ese archivo como construida para esta HU) en vez de duplicar la logica de recurrencia.

Criterios de aceptacion:

1. Un pago programado activo (expense, misma currency, `tombstonedAt IS NULL`, dentro del alcance con expansion de raices) proyecta ocurrencias que suman a `scheduledMinor` sin afectar `spentMinor`.
2. Una ocurrencia ya materializada como `Transaction` (`source=scheduled`) no se duplica en `scheduledMinor`.
3. Una plantilla semanal en ventana mensual aporta multiples ocurrencias proyectadas, acotadas por `windowEndInclusive` y por `endDate` de la plantilla.
4. Una ocurrencia `pending` ya registrada (modo manual, catch-up generator) cuenta en `scheduledMinor` combinada sin doble conteo con las proyectadas desde `nextDate`.
5. `BudgetProgressBar` renderiza tres tramos contiguos (gastado solido, programado en variante atenuada de `$primary`, resto) cuando `scheduledMinor > 0`.
6. `gastado + programado > 100%` NO activa `isOverspent` (sigue siendo exclusivo de `spentMinor > amountMinor`).
7. En periodos pasados `scheduledMinor` es 0 y el segmento no se renderiza; en futuros con gasto real 0, `scheduledMinor` lleva el peso informativo.
8. El detalle muestra la cifra "programado" junto al hero y un punto de entrada que abre una lista/sheet con los pagos programados especificos (plantilla + fecha + monto).
9. El calculo es 100% local/sincrono sobre Drift stream, sin red ni IA, recalculado en tiempo real ante cambios de transacciones, plantillas u ocurrencias.
10. Sigue siendo Nivel 0: sin gating de Modo anuncios ni Premium.

Tamano: **m** · Review: **combined APROBADO**

## Que cambio

| Archivo | Que |
|---|---|
| `lib/features/budgets/domain/entities/budget_progress.dart` | `scheduledMinor` (default 0) + getters `committedFraction`/`scheduledFraction` (clampado al espacio libre de `fraction`); `isOverspent` sigue dependiendo solo de `spentMinor`. |
| `lib/features/budgets/domain/entities/budget_scheduled_item.dart` | Nueva entidad, espejo de `BudgetActivityItem` para lo "programado". |
| `lib/features/budgets/domain/entities/budget_period_view.dart` | Expone `scheduledItems`. |
| `lib/features/budgets/domain/entities/budget_detail_data.dart` | Nuevos `scheduledTemplates` (`BudgetScheduledTemplateDetail`) y `pendingScheduledOccurrences` (reusa `PendingScheduledOccurrence` de `scheduled_payments/domain` tal cual). |
| `lib/features/budgets/domain/services/budget_progress_calculator.dart` | `matchesTemplateScope`/`matchesProjectedOccurrence`/`matchesPendingScheduledOccurrence` + `scheduledItemsIn`, combinando proyectadas (`ProjectUpcomingOccurrences`) y pendientes sin doble conteo. |
| `lib/features/budgets/domain/usecases/get_budget_progress.dart` | Inyecta `ProjectUpcomingOccurrences`; fuerza `scheduledMinor=0`/`scheduledItems=[]` en ventanas `past`. |
| `lib/features/budgets/data/datasources/budgets_local_datasource.dart` | `watchScheduledExpenseTemplates()` (excluye plantillas `once` ya confirmadas, patron `existsQuery` reimplementado localmente) + query de ocurrencias pendientes. |
| `lib/features/budgets/data/repositories/budget_repository_impl.dart` | Mapea manualmente `ScheduledPayment`/`ScheduledPaymentOccurrence` (Drift → dominio) para no importar `data/` de otra feature. |
| `lib/core/di/injection.config.dart` | Diff manual de una linea (build_runner no compilo en este entorno, ver Pendientes). |
| `lib/features/budgets/presentation/widgets/budget_progress_bar.dart` | Reimplementado con `LayoutBuilder`+`Stack` para 2 segmentos con precision de pixel; acepta `scheduledFraction` (default 0). |
| `lib/features/budgets/presentation/pages/budget_detail_page.dart` | Fila "Programado" (visible solo si `scheduledMinor>0`) que abre el sheet. |
| `lib/features/budgets/presentation/widgets/budget_scheduled_row.dart` | Fila de item programado (plantilla + fecha + monto). |
| `lib/features/budgets/presentation/widgets/sheets/budget_scheduled_sheet.dart` | Sheet con la lista de pagos programados del periodo. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` + `gen/*` | 4 claves nuevas: `budgetScheduledLabel`, `budgetScheduledSheetTitle`, `budgetScheduledSheetHint`, `budgetScheduledSheetEmpty`. |
| `test/features/budgets/**` (domain, data, presentation) | Cobertura nueva de los 10 AC — ver tabla de abajo. |

## Tests

Resultado: `flutter analyze` limpio (0 errores/warnings en los archivos tocados), suite verde, e2e en skip. No se escribieron tests "nuevos" fuera de los ya listados arriba en esta corrida (los archivos de test listados SON el aporte de esta corrida).

Comandos para re-correr:

```bash
flutter analyze lib/features/budgets test/features/budgets lib/core/l10n lib/core/di
flutter test test/features/budgets
```

Cobertura por criterio:

- **AC1**: `budget_progress_calculator_test.dart::'HU-12: scheduledItemsIn' criterion 1` + `get_budget_progress_test.dart::'a future window with no spend still reports scheduledMinor'`
- **AC2**: `budget_progress_calculator_test.dart::'criterion 2: a date already materialized (confirmed) is not re-projected'`
- **AC3**: `budget_progress_calculator_test.dart::'criterion 3: ...bounded by the window and by endDate'` (5 ocurrencias sin limite, 2 con `endDate`)
- **AC4**: `budget_progress_calculator_test.dart::'criterion 4: ...without double-counting a projected date'` + `get_budget_progress_test.dart::'combines projected and pending sources...'`
- **AC5**: `budget_progress_bar_test.dart` (conteo de `Container`, colores primary/primarySoft/expense, anchos en px)
- **AC6**: `budget_progress_test.dart::'isOverspent (criterion 6)'` + `budget_progress_bar_test.dart` (tramo programado recortado a 0 sin espacio)
- **AC7**: `get_budget_progress_test.dart::'a past window always reports scheduledMinor 0...'` + `'a future window with no spend still reports scheduledMinor'`
- **AC8**: `budget_detail_page_test.dart` (fila condicional + tap abre sheet) + `budget_scheduled_sheet_test.dart` + `budget_scheduled_row_test.dart`
- **AC9**: `budgets_scheduled_local_datasource_test.dart` (Drift en memoria, dos `watch*`) + `budget_repository_impl_scheduled_test.dart` (combina streams en `BudgetDetailData`)
- **AC10**: inspeccion de codigo (grep sin resultados de gating ads/Premium en `budget_detail_page.dart`/`budget_scheduled_sheet.dart`) — ausencia de feature, sin test dedicado

## 👤 Verifica a mano

- Confirmar visualmente en Pencil que el tono `primarySoft` usado para el tramo "programado" corresponde a la variante atenuada de `$primary` definida en `billetudo.pen` (no un hex nuevo) — fuera del alcance de un test automatizado.
- Verificar en un dispositivo real que el gesto de tap sobre la fila "Programado" y el sheet resultante se sienten bien (animacion de apertura, alto del sheet) — los widget tests ya prueban que abre y lista los items correctos, pero no la fidelidad visual/gestual.
- `pencil-fidelity-reviewer`: no hay golden test dedicado al estado "con programado" de `budget_detail_page` (los goldens existentes no cubren `scheduledMinor > 0`); si se quiere el mismo nivel de auditoria visual que el resto de la pantalla, conviene agregar un caso golden aparte — hoy AC5 ya esta cubierto por widget test puro, asi que no es un gap de aceptacion, solo un hueco de cobertura golden.
- El e2e quedo en skip — bootea un emulador y corre Patrol si quieres automatizarlo.

## Pendientes y riesgos

- **Bloqueante potencial (no bloquea esta corrida):** `build_runner` fallo en este entorno ("Failed to compile build script", problema de toolchain de native-asset hooks preexistente del sandbox). Se aplico manualmente el unico diff necesario en `injection.config.dart` (una linea, por el nuevo parametro `ProjectUpcomingOccurrences` en `GetBudgetProgress`). **Pendiente real:** regenerar con build_runner en un entorno donde el build script compile, para confirmar que el diff manual coincide byte a byte.
- Sin migracion de esquema Drift: HU-12 reutiliza `ScheduledPayments`/`ScheduledPaymentOccurrences` tal cual, sin tocar `schemaVersion`.
- Gate de Pencil: no existe ningun frame para el segmento "programado" en `billetudo.pen` (busque el patron `[Pp]rogramad` en la zona PRESUPUESTOS y en el resto del archivo) ni mencion en `design-system/billetudo/pages/presupuestos.md`. No hay deriva de un diseno existente que ignorar, pero tampoco un frame que verificar: se construyo siguiendo tokens/patrones ya aprobados en la misma pantalla (`$primary-soft`, `Bottom Sheet Base`+`SheetHead`+`SheetListViewport`, estructura de `BudgetActivityRow`/`ScheduledPendingRow`). Queda abierto si `pencil-designer`/`ui-ux-reviewer` quiere formalizar un frame real despues.
- Hallazgo no listado explicitamente en los AC: una plantilla `once` ya disparada (`confirmed`) nunca avanza su `nextDate` por diseno de `scheduled_payments`, asi que sin filtro se volveria a proyectar la misma fecha ya materializada. Se agrego esa exclusion en `watchScheduledExpenseTemplates()`.
- Riesgo de reloj/zona: `BudgetPeriodWindow`/`BudgetPeriodCalculator` usan `DateTime` naive en varios sitios existentes; el filtro "ocurrencia <= now" que separa "ya procesada" de "aun futura" debe usar el mismo reloj/zona que `BudgetPeriodCalculator`, o dos ocurrencias equivalentes podrian contarse dos veces o perderse en el borde exacto de "hoy" — revisado en review, sin hallazgo confirmado, pero queda como punto de atencion para cambios futuros.
- No golden dedicado al estado "con programado" (ver seccion de verificacion manual).
- Cruce de dominio nuevo: `budgets/domain` importa `scheduled_payments/domain` (`ScheduledPayment`, `ScheduledPaymentType`, `ProjectUpcomingOccurrences`). Hay precedente valido en el repo (`scheduled_payments/domain` ya importa `transactions/domain`); confirmado en review que el import es domain→domain, sin ciclo (`scheduled_payments` no importa `budgets`).

## Mensaje de commit sugerido

```
feat(presupuestos): proyectar pagos programados como segmento en la barra de progreso (HU-12)

Suma scheduledMinor a BudgetProgress reutilizando ProjectUpcomingOccurrences
de scheduled_payments (proyectadas + pendientes ya registradas, sin doble
conteo), sin afectar isOverspent ni requerir esquema nuevo. La barra de
progreso gana un tercer tramo atenuado y el detalle expone la cifra y un
sheet con los pagos que la componen.
```
