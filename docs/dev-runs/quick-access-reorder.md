# Orden configurable del acceso rápido en Home (quick-access-reorder)

## Objetivo y criterios de aceptación

Hacer configurable el orden de los 3 chips de `QuickAccessRow` en Home (Pagos programados,
Deudas, Gráficas e informes — no incluye Cuentas, ver riesgo abajo): persistir la preferencia
en la fila singleton de `AppSettings` (Drift), que `HomeCubit`/`QuickAccessRow` lean para
ordenar los chips, y dar una pantalla en Ajustes con una lista reordenable para cambiarlo.

Tamaño: m · Review: combined APROBADO.

1. `AppSettings` gana una columna nueva para el orden (lista de claves de los 3 chips
   existentes); `schemaVersion` sube y hay migración `from < N` que rellena el default para
   filas existentes, sin romper install limpio.
2. `AppSettingsRepository`/entidad exponen el orden como `List<QuickAccessItem>`, con default
   cuando la columna está vacía/null o es una permutación inválida.
3. Nuevo caso de uso `SetQuickAccessOrder` valida permutación exacta de los 3 items antes de
   persistir; si no lo es, no escribe.
4. `QuickAccessRow` renderiza en el orden persistido (vía `HomeCubit`/`AppSettingsCubit`), sin
   reiniciar la app.
5. Pantalla nueva en Ajustes (`/mas/ajustes/acceso-rapido`) con lista reordenable del sistema
   de diseño, persiste al soltar con `SetQuickAccessOrder`.
6. Entry point (`SettingsField`) en Ajustes ▸ Preferencias, con `AppLocalizations` es+en.
7. Test de datasource/repositorio: orden válido persiste/relee igual; inválido no corrompe y
   usa default.
8. Test de widget: `QuickAccessRow` con orden distinto renderiza en ese orden.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | Columna `quickAccessOrder` en `AppSettings` (CSV de `QuickAccessItem.name`); `schemaVersion` 26→27→28; migración `from < 27` con backfill del orden actual fijo |
| `lib/core/database/powersync_schema.dart` | `Column.text('quick_access_order')` en la vista `app_settings` (patrón PowerSync-managed) |
| `lib/features/home/domain/entities/quick_access_item.dart` | Entidad nueva: enum de los 3 items, `defaultOrder`, `isValidOrder` |
| `lib/features/settings/domain/entities/app_settings.dart` | Campo `quickAccessOrder` |
| `lib/features/settings/domain/repositories/app_settings_repository.dart` | Contrato para leer/escribir el orden |
| `lib/features/settings/domain/usecases/set_quick_access_order.dart` | Caso de uso nuevo: valida permutación exacta antes de persistir |
| `lib/features/settings/data/datasources/app_settings_local_datasource.dart` | Serializa/lee CSV, `updatedAt` estampado en cada escritura |
| `lib/features/settings/data/repositories/app_settings_repository_impl.dart` | `_toQuickAccessOrder`: único lugar que decide confiable/no confiable, cae a `defaultOrder` |
| `lib/features/settings/presentation/cubit/app_settings_cubit.dart` / `app_settings_state.dart` | `setQuickAccessOrder(...)`, getter `quickAccessOrder` |
| `lib/features/home/presentation/widgets/quick_access_row.dart` | Ya no hardcodea el orden; recibe `order: List<QuickAccessItem>` |
| `lib/features/home/presentation/pages/home_page.dart` | `BlocBuilder<AppSettingsCubit, AppSettingsState>` alimenta `QuickAccessRow` |
| `lib/features/settings/presentation/pages/quick_access_order_page.dart` | Pantalla nueva, `ReorderableListView` estilo `SettingsField` |
| `lib/features/settings/presentation/pages/settings_page.dart` | Entry point nuevo en Preferencias ("Orden del acceso rápido") |
| `lib/core/router/app_router.dart` | Ruta `/mas/ajustes/acceso-rapido`; `/inicio` ahora provee `AppSettingsCubit` junto a `HomeCubit` vía `MultiBlocProvider` |
| `lib/core/l10n/arb/app_es.arb` / `app_en.arb` + `gen/` | Strings nuevas: `settingsQuickAccessOrder`, `settingsQuickAccessOrderSubtitle`, `settingsQuickAccessOrderTitle`, `settingsQuickAccessOrderHint` |
| `lib/core/di/injection.config.dart` | Regenerado: registra `SetQuickAccessOrder` y el nuevo parámetro de `AppSettingsCubit` |
| Tests (ver sección Tests) | Datasource, usecase, widget `QuickAccessRow`, `home_page`, `settings_page`, `quick_access_order_page`, goldens, Patrol |

## Tests

Resultado: `analyze` limpio sobre lo tocado, suite verde, e2e pass.

```bash
flutter analyze
flutter test test/features/settings/ test/features/home/
flutter test --update-goldens test/features/settings/presentation/golden/ test/features/home/presentation/golden/  # solo si hace falta regenerar
flutter test integration_test/settings_patrol_test.dart -d <device_id>  # Patrol, flavor dev
```

Tests escritos/tocados: `test/features/settings/data/datasources/app_settings_local_datasource_test.dart`,
`test/features/settings/domain/usecases/set_quick_access_order_test.dart`,
`test/features/home/presentation/widgets/quick_access_row_test.dart`,
`test/features/home/presentation/home_page_test.dart`,
`test/features/home/presentation/golden/home_page_golden_test.dart`,
`test/features/settings/presentation/cubit/app_settings_cubit_test.dart` (+ `usecase_mocks.dart`),
`test/features/settings/presentation/pages/settings_page_test.dart`,
`test/features/settings/presentation/pages/quick_access_order_page_test.dart`,
`test/features/settings/presentation/golden/settings_page_golden_test.dart` (4 PNG regenerados),
`test/features/settings/presentation/golden/quick_access_order_page_golden_test.dart` (2 PNG nuevos),
`integration_test/settings_patrol_test.dart` (drag real en emulador).

Notas: `envelope_info_sheet_golden_test.dart` falla en aislamiento con 0.26% de diff — ya
documentado como flaky en esta máquina, no relacionado. Hubo además, en el árbol de trabajo,
cambios ajenos en curso de otros procesos (`auth`, `budgets`, `scheduled_payments`, `goals`,
`docs/`) que no se tocaron ni se revisaron en esta corrida.

## Fidelidad visual vs Pencil

**APROBADA — 2 hallazgos MENOR** (ninguno introducido por este cambio, ambos deuda ya
documentada):

1. `home_shell_page_inicio_active_*`: el Tab Bar mantiene "Metas" en el slot 4. `inicio.md` §
   "Cambios de bugfixes-0.0.1.md" (línea 37) todavía documenta la decisión vieja ("Pagos
   Programados reemplazó a Metas"), pero esa decisión fue revertida después (nota de memoria
   `nav-metas-slot4-mas-parqueado`). El código es fiel a la decisión vigente; el `.md` quedó
   desactualizado y debería corregirse.
2. `home_page_loading_*`: el estado de carga no muestra skeleton para "Mis cuentas" (salta de
   "Acceso rápido" a los skeletons de movimientos) — coincide con la deuda ya anotada en
   `inicio.md` (la tira "Mis cuentas" solo vive en los frames V2 `LktTm`/`AVgUv`, aún sin
   portar a los canónicos).

**Gaps de cobertura reconfirmados** (documentación, no defecto de código): los 3 estados extra
de `SyncStatusSheet` (`stalled`, `too_long`, `stale`, claro+oscuro) sin fila en `inicio.md`;
`home_page_error_*` sin frame/copy propio; `more_page_signed_in/out_*` y
`home_shell_page_mas_active_*` sin fila en `inicio.md`; `home_shell_page_inicio_active_*` es un
stub de prueba, no contenido real.

`QuickAccessRow` y `quick_access_order_page.dart` (la pieza nueva de esta corrida) no tienen
frame propio en `billetudo.pen` — se construyeron siguiendo el patrón visual ya aprobado de
`SettingsField` en Ajustes y el `ReorderableListView` ya usado en Categorías/Cuentas, sin
inventar tokens ni componentes nuevos.

## 👤 Verifica a mano

- Sensación real del gesto de arrastre (long-press-drag) en un dispositivo físico distinto al
  emulador Pixel_9a — el Patrol test ya prueba el drag mecánicamente, pero la fluidez/feedback
  háptico real solo la valida un humano.
- Verificar que la migración de Supabase (`ALTER TABLE app_settings ADD COLUMN
  quick_access_order`) exista en prod y dev antes de sincronizar: no hay ningún archivo bajo
  `supabase/migrations/` que agregue esta columna — subir solo `schemaVersion` en Drift no
  migra Postgres. Sin el `ALTER TABLE` explícito el sync quedaría en cuarentena (`PGRST204`)
  en cuanto un dispositivo intente sincronizar esta columna.
- Confirmar contra Pencil (`pencil-fidelity-reviewer` / `/design-fidelity-check`) que el diseño
  de `QuickAccessOrderPage` y la fila nueva en Ajustes coincidan pixel a pixel con el `.pen` —
  esta corrida solo generó/validó goldens, no comparó contra un nodeId (no existe frame
  dedicado todavía).

## Pendientes y riesgos

- **Riesgo de discrepancia con la fuente de la petición**: el pedido original menciona 4 chips
  (incluye Cuentas), pero el código real de `QuickAccessRow` solo tiene 3 (Pagos programados,
  Deudas, Gráficas e informes) — Cuentas fue excluido a propósito porque la tira "Mis cuentas"
  ya lo cubre. El plan siguió el código real; si de verdad se quiere agregar Cuentas al set
  reordenable, es una decisión de producto/diseño aparte a confirmar antes de construir.
- ~~**Falta migración SQL en Supabase** (dev y prod) para `app_settings.quick_access_order`~~ —
  **resuelto el 2026-08-19**: existe `supabase/migrations/20260817010000_add_quick_access_order_to_app_settings.sql`
  y la columna está verificada en dev **y** prod. Queda pendiente refrescar el snapshot de
  paridad (`dart run tool/check_schema_parity.dart --refresh`, requiere `DATABASE_URL`), que
  es lo único que mantiene rojo a `test/core/database/schema_parity_test.dart`.
- **AC1 sin test dedicado del backfill SQL en sí**: la columna es nullable en Dart, así que un
  valor `NULL` no crashea el mapper (a diferencia de `onboardingCompleted`), solo cae en el
  mismo fallback que ya prueba el test del datasource — no se consideró necesario duplicar.
- Sin frame de Pencil para `QuickAccessOrderPage` — recomendado que `pencil-designer` diseñe
  esta pantalla en un futuro pase y se corra `/design-fidelity-check` después.
- Si en el futuro se agregan más items a `QuickAccessItem` (ej. Cuentas), el parser debe seguir
  tolerando items desconocidos (los ignora y cae al default) para no romper filas ya guardadas
  con 3 items.
- Nota de convención no bloqueante: `quick_access_order_page.dart` y `quick_access_row.dart`
  definen dos clases públicas de widget por archivo — patrón preexistente en
  `quick_access_row.dart` antes de este cambio, no es una regresión introducida aquí.

## Añadido el 2026-08-19: entrada a la pantalla desde Home

La pantalla de orden solo era alcanzable por Ajustes ▸ Preferencias, lejos de donde se ve el
efecto. Ahora la tira de acceso rápido en Home la cierra con una **ruedita circular**
(`QuickAccessSettingsButton`, archivo propio) que abre `AppRoutes.quickAccessOrder`.

Decisiones y por qué:

- **No es un chip más.** Un cuarto pill idéntico se leería como un cuarto destino, cuando
  configura la tira en vez de navegar a una sección. Conserva el cromo de la fila (`$surface`,
  `$border`, 44pt) pero toma la forma circular del botón de 44x44 del sistema (`MASTER.md`:
  "Radio de icon-wrap circular: mitad de su alto") y pierde el label.
- **Va anclada fuera del `SingleChildScrollView`, no dentro.** Dentro no se veía nunca: los 3
  chips miden ~507pt contra los 390pt de un teléfono, así que el botón se renderizaba pasado el
  borde. El síntoma fue que **ningún golden cambió** al agregarlo. Hay test de regresión que
  fija el viewport en 390 y exige que el botón caiga dentro de la pantalla.
- **Icon-only ⇒ el nombre accesible viene del `Tooltip`** (`homeQuickAccessCustomize`, es+en),
  que Flutter también expone a lectores de pantalla.

Sin cambio de esquema ni de dominio: solo un `VoidCallback` nuevo (`onCustomize` en
`QuickAccessRow`, `onOpenQuickAccessOrder` en `HomePage`) cableado en `app_router.dart` a la
ruta que ya existía. 12 goldens de Home regenerados.

## Mensaje de commit sugerido

```
feat(home,settings): orden configurable del acceso rápido

- AppSettings gana columna quickAccessOrder (schemaVersion 26->28,
  migración con backfill del orden actual)
- SetQuickAccessOrder valida permutación exacta antes de persistir
- QuickAccessRow renderiza en el orden persistido, sin reiniciar la app
- Pantalla nueva /mas/ajustes/acceso-rapido con lista reordenable
- Entry point en Ajustes > Preferencias

Pendiente: ALTER TABLE app_settings ADD COLUMN quick_access_order en
Supabase (dev+prod) antes de sincronizar en producción.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
