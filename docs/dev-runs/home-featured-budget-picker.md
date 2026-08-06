# Presupuesto destacado en el hero del Home (home-featured-budget-picker)

## Objetivo y criterios de aceptación

Dejar que el usuario elija manualmente, desde Ajustes > Presupuesto, cuál de sus presupuestos
activos (de cualquier alcance/periodo) se destaca en el hero card del Home, en vez de depender
solo de la detección automática de un presupuesto global-mensual. Sin selección, o si el
elegido se archiva/borra, el Home cae de vuelta al comportamiento automático actual.

1. Con `AppSettings.featuredBudgetId` nulo (default, incluye instalaciones existentes tras la
   migración), el hero muestra el activo más reciente que sea global y mensual, o "sin
   presupuesto" si ninguno califica. ✅
2. En Ajustes > Presupuesto, un nuevo campo "Presupuesto destacado" abre una hoja con
   "Automático" + todos los presupuestos activos; tocar uno persiste `featuredBudgetId` vía un
   nuevo caso de uso y el campo refleja la selección vigente. ⚠️ GAP (sin UI)
3. Con `featuredBudgetId` apuntando a un presupuesto activo, el hero muestra ESE presupuesto
   exacto aunque su alcance/periodo no sea global-mensual. ✅
4. Si el presupuesto destacado se archiva o se borra, el hero cae automáticamente al criterio 1
   en la siguiente emisión del stream, sin reabrir Ajustes. ✅
5. En la misma sesión, el selector de Ajustes deja de mostrar el presupuesto
   archivado/borrado como seleccionado y refleja "Automático". ⚠️ GAP (sin UI)
6. `featuredBudgetId` persiste en Drift (`AppSettings`, singleton `id='app'`), sobrevive un
   reinicio, y cada escritura actualiza `updatedAt`. ✅
7. `schemaVersion` sube de 22 a 23 y la migración agrega la columna nullable
   `featuredBudgetId` sin perder datos existentes. ✅
8. El control de selección está diseñado en `billetudo.pen` contra `MASTER.md`, tema claro,
   documentado en `design-system/billetudo/pages/ajustes.md`, y aprobado por el usuario antes
   de implementarse. ⚠️ GAP (bloqueado por gate de Pencil)

**Tamaño:** L · **Review:** deep, APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | `AppSettings.featuredBudgetId` (`TextColumn.nullable()`), `schemaVersion` 22→23, migración v22→v23 sin `addColumn` (la tabla es una VIEW gestionada por PowerSync). |
| `lib/core/database/powersync_schema.dart` | Agrega `featured_budget_id` a la tabla `app_settings` para que PowerSync recree la view con la columna antes de que Drift la lea. |
| `lib/features/settings/domain/entities/app_settings.dart` | Campo `featuredBudgetId` nullable, default `null`. |
| `lib/features/settings/domain/repositories/app_settings_repository.dart` | Contrato para persistir el destacado. |
| `lib/features/settings/domain/usecases/set_featured_budget.dart` | Nuevo caso de uso. |
| `lib/features/settings/data/datasources/app_settings_local_datasource.dart`, `.../repositories/app_settings_repository_impl.dart` | Escritura en Drift, actualiza `updatedAt`. |
| `lib/features/budgets/domain/services/budget_hero_selector.dart` | Regla compartida: intenta el destacado entre activos, si no está cae al pick automático global+mensual. |
| `lib/features/budgets/domain/usecases/watch_featured_budget_progress.dart` | Combina `watchActiveBudgets()` + `watchSettings()` (patrón `combineLatest` manual, sin `rxdart`, igual que `WatchReportsDashboard`). |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Inyecta `WatchFeaturedBudgetProgress` en vez de `WatchGlobalMonthlyBudgetProgress`. |
| `lib/features/settings/presentation/cubit/app_settings_cubit.dart`, `app_settings_state.dart` | Expone `activeBudgets` y `featuredBudgetId`; `setFeaturedBudget(String?)` delega en el caso de uso. |
| `lib/core/di/injection.config.dart` | Regenerado (`build_runner --force-jit`). |
| Tests unit correspondientes a cada archivo de arriba, `test/features/home/**`, `test/features/settings/presentation/cubit/**` | Actualizados/nuevos. |
| `lib/features/home/presentation/widgets/balance_mini_card.dart`, `mini_type_icon.dart` + goldens `home_page_*` | Ajustes de presentation ya existentes que quedaron cubiertos en esta corrida. |

**No se tocó** (bloqueado por el gate de diseño de Pencil, ver abajo): `settings_page.dart`,
ningún widget nuevo bajo `lib/features/settings/presentation/widgets/`, l10n nuevo en
`app_es.arb`/`app_en.arb`, ni goldens de Ajustes.

**Pendiente real fuera de alcance de esta etapa:** migración Postgres/Supabase para
`app_settings.featured_budget_id` (`supabase/migrations/`) — ver sección de tests.

## Tests

- `flutter analyze`: limpio.
- Suite unit/widget: verde (sin tests nuevos escritos en esta corrida; se actualizaron
  mecánicamente los existentes).
- Golden: verde salvo flakiness de pixel-diff (~0.26%) ya documentada como propia de esta
  máquina (no relacionada con este cambio).
- e2e (Patrol): skip.
- **Rojo esperado y fuera de alcance:** `test/core/database/schema_parity_test.dart` — falla
  porque Postgres (dev y prod) aún no tiene la columna `app_settings.featured_budget_id`.

Re-correr:
```bash
flutter analyze
flutter test
flutter test test/core/database/schema_parity_test.dart   # rojo esperado hasta migrar Postgres
```

## Fidelidad visual vs Pencil

**APROBADA — 0 hallazgos.** Corrida de fidelidad general de Home (no específica de esta
feature, que no llegó a tener UI). Gaps registrados, no bloqueantes de pixel:

- `inicio.md` documenta `home_page_error` como estado inexistente por diseño, pero el golden
  `home_page_error_{light,dark}.png` sí existe con un mensaje de error de pantalla completa.
  Discrepancia de alcance .md↔código a revisar (actualizar el .md o retirar el golden).
- Los frames canónicos `aOhoY`/`A9v7s` de la tabla principal de `inicio.md` no incluyen la tira
  "Mis cuentas" (deuda de fidelidad ya anotada); los goldens actuales sí la incluyen, así que la
  comparación correcta fue contra los frames V2 `LktTm`/`AVgUv`. La tabla de `inicio.md`
  debería apuntar a esos como vigentes.
- `home_page_error_*`, `more_page_signed_in/out_*` y `home_shell_page_*_active_*` no tienen fila
  de nodeId propia en `inicio.md` (algunos por diseño, otros por falta de documentación).

## 👤 Verifica a mano

- Fidelidad visual de la futura fila "Presupuesto destacado" + hoja de selección contra
  `billetudo.pen`, una vez implementada en Flutter (`pencil-fidelity-reviewer`, fuera de
  alcance aquí).
- En un dispositivo real: tras archivar/borrar el presupuesto destacado desde otra pantalla, el
  hero del Home cae a automático sin fricción visual perceptible (la lógica de stream ya está
  probada en unit, no el "feel" en vivo).
- Confirmar en Supabase (dev y prod) que la migración para `app_settings.featured_budget_id` se
  aplicó y que `test/core/database/fixtures/postgres_schema.json` quedó refrescado antes de
  liberar esta feature — **bloqueante**, ver `schema_parity_test.dart`.
- El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

- **Bloqueo de gate de diseño (no resuelto):** el acceso MCP a Pencil falló consistentemente
  (`get_app_state`/`get_screenshot` → "MCP error -32603 ... you are probably referencing the
  wrong .pen file"). `design-system/billetudo/pages/ajustes.md` no tiene sección "Presupuesto
  destacado". Siguiendo CLAUDE.md ("si Pencil no es accesible, el desarrollo de esa UI se
  detiene"), no se implementaron `featured_budget_field.dart`,
  `featured_budget_select_sheet.dart`, el wiring en `settings_page.dart`, ni el l10n/golden
  correspondiente. Esto deja los AC 2, 5 y 8 sin cumplir en Flutter, y el AC 3 solo cumplido a
  nivel de dominio (el hero sí funciona si `featuredBudgetId` se setea por otro medio, p. ej.
  tests).
- **Migración Postgres pendiente y bloqueante:** falta el archivo en `supabase/migrations/`
  para `app_settings.featured_budget_id`, aplicarlo a dev y prod, y refrescar
  `test/core/database/fixtures/postgres_schema.json` con
  `dart run tool/check_schema_parity.dart --refresh`. Sin esto, cualquier build con esta
  columna no sincroniza contra Postgres real.
- **Sin FK explícita** de `featuredBudgetId` a `Budgets.id`, a propósito: un presupuesto
  destacado archivado/borrado simplemente deja de calificar en el selector, sin necesidad de
  limpiar la columna.
- Riesgo de duplicación de regla de negocio si `BudgetHeroSelector` no se hubiera extraído
  (ya se extrajo, mitigado).
- Riesgo de asunciones "mensual" implícitas en `HomeHeroBudgetProgress`/l10n al permitir
  cualquier alcance/periodo — revisar cuando se retome la parte visual.
- Próxima etapa (ya en el change map, bloqueada por el gate de Pencil): recuperar acceso a
  Pencil, `pencil-designer` diseña fila + hoja contra `MASTER.md`, documentar y aprobar
  `design-system/billetudo/pages/ajustes.md`, y recién ahí implementar
  `FeaturedBudgetField`/`FeaturedBudgetSelectSheet` + wiring + l10n + golden.

## Mensaje de commit sugerido

```
feat(budgets,settings): permitir presupuesto destacado manual en el hero del Home

- AppSettings.featuredBudgetId (schemaVersion 22->23, columna nullable via PowerSync
  view, sin backfill)
- BudgetHeroSelector: regla compartida destacado > automatico global-mensual
- WatchFeaturedBudgetProgress combina presupuestos activos + settings, cae a
  automatico si el destacado se archiva o borra
- HomeCubit y AppSettingsCubit cableados (activeBudgets, setFeaturedBudget)

Pendiente: UI de Ajustes (fila + hoja de seleccion) bloqueada por gate de diseno
en Pencil sin acceso; migracion Postgres de app_settings.featured_budget_id
todavia no aplicada (dev/prod).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
