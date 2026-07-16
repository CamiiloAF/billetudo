# Feature Categorías (categorias-feature)

**Fecha:** 2026-07-16
**Tamaño:** l | **Review:** deep APROBADO

## Objetivo y criterios de aceptación

CRUD jerárquico de categorías raíz/subcategoría por `kind` (income/expense), reordenamiento, seed set de onboarding y los 3 flujos de borrado (sin dependientes, con transacciones asociadas vía reasignar/dejar-sin-categoría, y raíz con subcategorías vía reasignar/cascada), sobre el esquema Drift existente y el diseño aprobado en `design-system/billetudo/pages/categorias.md`.

Criterios de aceptación cubiertos (17 en total, detalle de cobertura abajo):

1. `CreateCategory` crea raíz (parentId null): name 1-100 chars obligatorio, sortOrder al final del kind, `ValidationFailure` si name vacío o >100.
2. `CreateCategory` crea subcategoría con parentId de una raíz existente no tombstoned; hereda el kind del padre; falla si parentId no existe, está tombstoned, o el padre ya es subcategoría (máx. 2 niveles).
3. `UpdateCategory` renombra/cambia icon/color sin tocar `Transactions.categoryId`.
4. `UpdateCategory` mueve subcategoría a otro root del mismo kind; rechaza cambio de kind en subcategoría o en raíz con subcategorías activas.
5. `ReorderCategories` persiste sortOrder contiguo 0..n-1 por kind, en una sola transacción (mismo patrón que `reorderAccounts`).
6. `GetCategoryDeletionImpact` reporta subcategorías activas + conteo de transacciones activas referenciándola.
7. `DeleteCategory` sin dependientes: soft delete vía `deletedAt`, nunca `tombstonedAt`.
8. `DeleteCategory` con transacciones: reasignar a otra categoría del mismo kind o dejar sin categoría, luego soft delete.
9. `DeleteCategory` de raíz con subcategorías activas: rechaza sin resolución; soporta reasignar o cascada (todo en una transacción).
10. `RestoreCategory` limpia `deletedAt` sin tocar `tombstonedAt`, sin exigir parent vivo (caso huérfano documentado, no bloqueante).
11. `SeedDefaultCategories` (HU-06): inserta el set semilla completo (17 raíces de gasto + subcategorías, 9 raíces de ingreso) solo si el usuario no tiene categorías, con iconos/colores tomados de variables de `billetudo.pen`, editables sin marca especial.
12. `WatchCategories(kind)`: stream no tombstoned/deleted, agrupado raíz→subcategorías, ordenado por sortOrder.
13. `CategoriesListCubit`: estados vacío/loading/error/con datos por kind (toggle gasto/ingreso), 1:1 con frames vH7RI/QZAKU/oaBzm/bA51N.
14. `CategoryFormCubit`: 4 casos de formulario (crear raíz, crear subcategoría con parent prellenado, editar raíz, editar subcategoría con Tipo bloqueado).
15. Toda escritura actualiza `updatedAt`; toda categoría nueva recibe UUID vía `clientDefault`.
16. Ninguna funcionalidad de Categorías condicionada a anuncios o Premium (Nivel 0 completo).
17. `flutter analyze`, `dart run custom_lint` y `flutter test` en verde.

## Qué cambió (tabla archivo → qué)

| Archivo | Qué |
|---|---|
| `lib/features/categories/domain/entities/{category,category_node,category_draft,category_deletion_impact}.dart` | Entidades puras de dominio (Category, nodo jerárquico raíz→hijos, draft de creación/edición, impacto de borrado) |
| `lib/features/categories/domain/repositories/category_repository.dart` | Interfaz del repositorio |
| `lib/features/categories/domain/usecases/create_category.dart` | Alta de raíz/subcategoría con herencia de kind y validación de 2 niveles |
| `lib/features/categories/domain/usecases/update_category.dart` | Rename/reclasificación, bloqueo de cambio de kind |
| `lib/features/categories/domain/usecases/reorder_categories.dart` | Reorder contiguo por kind en una transacción |
| `lib/features/categories/domain/usecases/get_category_deletion_impact.dart` | Reporta subcategorías activas + conteo de transacciones |
| `lib/features/categories/domain/usecases/delete_category.dart` | Borrado con `TransactionResolution`/`SubcategoryResolution` (sealed classes), orden transacciones→subcategorías→soft delete |
| `lib/features/categories/domain/usecases/restore_category.dart` | Undo desde papelera |
| `lib/features/categories/domain/usecases/watch_categories.dart` | Stream agrupado raíz→subcategorías |
| `lib/features/categories/domain/usecases/watch_parent_candidates.dart` | Stream para el picker de categoría padre |
| `lib/features/categories/domain/usecases/seed_default_categories.dart` | Seed de onboarding (17 gasto + 9 ingreso) |
| `lib/features/categories/domain/usecases/get_category.dart` | Lectura por id — **desviación justificada**: no estaba en el change map original, pero `CategoryFormCubit.load(id)` la necesitaba y ningún usecase la exponía todavía |
| `lib/features/categories/data/datasources/categories_local_datasource.dart` | DAO Drift: CRUD, reorder, impacto de borrado, reasignación de transacciones, cascada |
| `lib/features/categories/data/datasources/default_categories_seed.dart` | Datos del set semilla (iconos lucide + tokens de color mint/sky/peach/coral/amber/teal/indigo, sin hex) |
| `lib/features/categories/data/models/category_mapper.dart` | Mapeo Drift ↔ entidad de dominio |
| `lib/features/categories/data/repositories/category_repository_impl.dart` | Implementación concreta del repositorio |
| `lib/features/categories/presentation/cubit/{categories_list,category_form,parent_category_picker}_{cubit,state}.dart` | Los 3 cubits de la feature (listado con toggle+acordeón, formulario con los 4 casos y flujo de borrado HU-04, picker de categoría padre compartido) |
| `lib/features/categories/presentation/pages/{categories_page,category_form_page}.dart` | Páginas |
| `lib/features/categories/presentation/widgets/**` | Acordeón, subrow, toggle Gasto/Ingreso, icon/color picker, delete link, skeleton, 3 bottom sheets de confirmación de borrado |
| `lib/core/router/app_router.dart` | Rutas `/categorias`, `/categorias/nueva`, `/categorias/:id`, `/categorias/:id/editar`, `/categorias/:id/subcategoria-nueva` |
| `lib/core/router/bootstrap_home_page.dart` | Botones temporales de acceso (mismo patrón que Cuentas, se retiran con el shell real) |
| `lib/core/l10n/arb/{app_es,app_en}.arb` + `lib/core/l10n/gen/*` | Claves nuevas de Categorías, validadas por `arb_parity_test.dart` |
| `lib/core/di/injection.config.dart` | Regenerado por build_runner: registra usecases, datasource, repositorio y los 3 cubits nuevos |
| `pubspec.yaml` | Revertida una línea que `dart fix --apply` agregó por error (el resto del diff ya estaba sucio antes de esta corrida) |
| `test/features/categories/**` (domain, data, presentation) | Ver sección Tests |

## Tests (resultado + comandos para re-correr)

```bash
flutter analyze              # limpio, sin issues
dart run custom_lint         # limpio, sin issues
flutter test                 # 416 passed
```

**Actualización post-cierre (2026-07-16):** el bug de `test/features/categories/presentation/pages/category_form_page_test.dart` (re-aparición de la hoja de confirmación de borrado tras cerrarla) ya está arreglado — `_finishDelete` limpia `deletePrompt` en el mismo emit que cambia `status`, cortando la re-invocación de `_handlePrompt`. Es el mismo mecanismo de bug que `AccountDetailCubit._runClosing` en Cuentas (un estado intermedio con un campo de prompt sin limpiar, que el listener reinterpreta como una petición nueva), disparado aquí por el propio `emit` intermedio en vez de por una emisión tardía de un stream. El test pasa en verde y queda como guardia de regresión permanente, no como rojo intencional. Confirmado además con Patrol real (`categories_patrol_test`: 2/2, incluyendo el escenario "HU-04 caso 1" que antes fallaba).

**Patrol / e2e:** `fail` — no se corrió en esta pasada por restricción de recursos: la corrida de Patrol de Cuentas seguía activa en este host. Unit/widget fueron la red de pruebas principal.

Cobertura por AC (✅ cubierto, ⚠️ gap):

- ✅ 1-2 `CreateCategory` → `test/features/categories/domain/usecases/create_category_test.dart`
- ✅ 3 `UpdateCategory` no toca `Transactions.categoryId` → `category_repository_impl_test.dart` + revisión de código (ningún archivo de la feature referencia la tabla Transactions)
- ✅ 4 `UpdateCategory` reclasificación/bloqueos → `update_category_test.dart`
- ✅ 5 `ReorderCategories` → `reorder_categories_test.dart` + `category_repository_impl_test.dart` + `categories_local_datasource_test.dart`
- ✅ 6 `GetCategoryDeletionImpact` → `get_category_deletion_impact_test.dart` + los mismos dos anteriores
- ✅ 7-9 `DeleteCategory` (3 casos) → `delete_category_test.dart` + `categories_local_datasource_test.dart`
- ✅ 10 `RestoreCategory` → `restore_category_test.dart` + `categories_local_datasource_test.dart`
- ✅ 11 `SeedDefaultCategories` → `seed_default_categories_test.dart` + `categories_local_datasource_test.dart` + revisión de código de `default_categories_seed.dart` contra el apéndice de `docs/requirements/02-categorias.md`
- ✅ 12 `WatchCategories` → `watch_categories_test.dart` + `category_repository_impl_test.dart` + `categories_local_datasource_test.dart`
- ✅ 13 `CategoriesListCubit` → `test/features/categories/presentation/cubit/categories_list_cubit_test.dart`
- ✅ 14 `CategoryFormCubit` → `test/features/categories/presentation/cubit/category_form_cubit_test.dart`
- ✅ 15 `updatedAt`/UUID → `category_repository_impl_test.dart` contra BD Drift real en memoria
- ⚠️ 16 Sin gate de anuncios/Premium → sin test automatizado; verificado por lectura de código (ningún usecase/cubit/widget referencia gates de Premium/ads). Queda como verificación manual / responsabilidad de `compliance-reviewer`.
- ✅ 17 analyze/custom_lint/test en verde (416/416, ver actualización post-cierre arriba)

Widget tests adicionales: acordeón (expandir/colapsar) en `category_accordion_row_test.dart`, toggle Gasto/Ingreso en `category_kind_toggle_test.dart`, los 3 bottom sheets de confirmación de borrado en `confirm_delete_sheets_test.dart`.

## 👤 Verifica a mano

- [x] Flujo completo HU-04 caso 1 confirmado en verde tanto por widget test como por Patrol real (`categories_patrol_test` 2/2, post-fix, 2026-07-16).
- [ ] Revisar visualmente los 3 bottom sheets de confirmación de borrado en tema claro contra `design-system/billetudo/pages/categorias.md` — el widget test valida texto/comportamiento pero no pixel-perfect del diseño.
- [ ] Verificar con gestos reales (drag) el reordenamiento de categorías en el acordeón; `ReorderCategories` está probado a nivel de datos/usecase pero no hay widget test de drag-and-drop.
- [ ] Confirmar en un dispositivo real el caso HU-02 (crear subcategoría con Tipo bloqueado) con teclado nativo abierto — ya cubierto en Patrol "HU-01 y HU-02" que sí pasó en verde.

## Pendientes y riesgos (gaps de cobertura, blockers, observaciones)

**Blockers sin resolver:** ninguno.

**Gaps de cobertura:**
- AC 16 (sin gate de monetización) solo verificado por lectura de código, sin test automatizado.
- Golden tests (`test/features/categories/presentation/golden/categories_golden_test.dart`) no se escribieron por presupuesto de tiempo; los widget tests funcionales sí cubren acordeón, toggle y los 3 sheets.
- No se creó página de "papelera": `RestoreCategory` queda sin consumidor en presentation, a la espera de esa feature.
- ~~Patrol/e2e no se corrió en esta pasada~~ — corrido post-cierre (2026-07-16) una vez liberado el host: `categories_patrol_test` 2/2 (HU-01 y HU-02, HU-04 caso 1). Cobertura sigue siendo parcial frente a las 17 HU (solo esos 2 escenarios existen); ampliarla al resto de los flujos de borrado y al reordenamiento queda como gap real, no de ejecución.

**Riesgos del plan:**
- El pendiente documentado en `categorias.md` sobre "segunda confirmación para Eliminar en cascada" no estaba resuelto en diseño (solo un tap); se resolvió con un `AlertDialog` de confirmación extra (fricción adicional), documentado como desviación justificada en el código. Puede requerir una ronda de `ui-ux-reviewer` si se considera un sheet nuevo no diseñado.
- El picker de "reasignar a otra categoría" desde los sheets de borrado (snXFk/w9ixr) no tenía bottom sheet propio diseñado; se resolvió reusando `ParentCategoryPickerSheet`/cubit sin el filtro de solo-raíz (`rootsOnly:false`), aplanando `WatchCategories`. Si se decide que necesita un layout distinto, requiere paso por diseño.
- El caso de subcategoría huérfana tras restaurar una categoría cuyo padre fue tombstoned queda fuera de alcance de UI (documentado en los criterios de aceptación); si se quiere resolver mejor (ej. promoverla a raíz automáticamente), es un cambio de alcance explícito, no algo a inferir después.
- Icon Tile usa un catálogo cerrado de 32 iconos lucide extraídos manualmente del canvas de Pencil (el `.pen` no exponía los nombres de forma legible vía `get_variables`/`get_layers`); riesgo de retrabajo si alguno quedó mal listado.

**Decisiones de diseño relevantes:**
- Categories nunca escribe `tombstonedAt` (a diferencia de Cuentas): cada flujo de borrado resuelve transacciones y subcategorías dependientes *antes* del soft delete vía `deletedAt`, así que no hace falta lápida de integridad referencial.
- `sortOrder` se escopa por `kind + parentId`: las raíces compiten entre sí dentro de un kind; las subcategorías compiten solo entre las hermanas de su propio padre.
- `DeleteCategory` resuelve `TransactionResolution` (none/reassign/clear) y `SubcategoryResolution` (none/reassign/cascade) en un mismo `call()` cuando una raíz tiene ambos impactos a la vez, en el orden: transacciones → subcategorías → soft delete final (cascada ya incluye el soft delete de la raíz).
- `UpdateCategory` prohíbe que una raíz se convierta en subcategoría y viceversa, para dejar el comportamiento bien definido aunque no estaba explícito en los criterios.
- El seed set usa nombres de icono estilo lucide y uno de los 7 tokens de color de `billetudo.pen` (mint/sky/peach/coral/amber/teal/indigo) ciclados deterministicamente, nunca hex.

**Otras desviaciones justificadas (documentadas en el código):**
- `CategoryFormState` ganó un campo `parentName` (además de `parentId`) para mostrar el nombre del padre en vez del id crudo; `ParentCategoryPickerSheet.show` ahora resuelve a `Category` completa.
- El toggle Gasto/Ingreso (`CategoryKindToggle`/`CategoryKindSegment`) se implementó embebido en `categories_page.dart` en vez de archivo aparte: el change map no lo listaba como componente independiente.
- La edición de una categoría raíz se dispara con un ícono de lápiz explícito en la fila del acordeón (`onEditRoot`), ya que tocar la fila completa está reservado para expandir/colapsar según el spec.
- `DeleteLink` se dejó local a Categories (no promovido a `core/widgets`) siguiendo la regla de promoción del proyecto: se necesita un segundo caller real conectado, no solo dos features con un widget parecido.

**Alcance de la primera pasada (solo domain/data):** no tocó `presentation/`, wiring manual de DI, router ni l10n — eso se completó en la segunda pasada documentada arriba. Se corrió build_runner porque `app_database.g.dart` no existía aún; esto regeneró `injection.config.dart` también para las entradas de Accounts, que estaban desincronizadas desde antes de esta sesión.

## Mensaje de commit sugerido

```
Implementar feature completa de Categorias (Nivel 0)

CRUD jerarquico raiz/subcategoria por kind, reordenamiento, seed de
onboarding y los 3 flujos de borrado (sin dependientes, con
transacciones via reasignar/dejar-sin-categoria, raiz con
subcategorias via reasignar/cascada). Incluye domain/data/presentation
completos, wiring de rutas y l10n, y suite de tests unit/widget/bloc.

Pendiente: golden tests, pagina de papelera. El bug de re-aparicion de
la hoja de confirmacion de borrado (category_form_page_test.dart) ya
quedo arreglado antes de este commit.
```
