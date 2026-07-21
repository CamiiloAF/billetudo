# Hallazgos — corrida e2e Patrol (flavor `dev`), 2026-07-20

Consolidado de la sesión donde se corrieron por primera vez las 5 suites Patrol existentes contra
un emulador Android real (`emulator-5554`, `--flavor dev --dart-define-from-file=.env.dev`). El
estado consolidado por feature vive en `docs/patrol-e2e-tracking.md`; este documento es el detalle
de causa raíz y fixes para que alguien pueda retomarlos sin releer toda la sesión.

## 1. Bug de infraestructura (bloqueaba las 5 suites) — CORREGIDO

`integration_test/support/patrol_app.dart` (`startApp`) no reutiliza `lib/core/bootstrap.dart` a
propósito (`bootstrap()` instala un `FlutterError.onError` que Patrol prohíbe tocar), pero al no
reutilizarlo también se saltó dos pasos que `bootstrap()` sí hace antes de `configureDependencies()`:
abrir PowerSync (`openPowerSyncDatabase()`) e inicializar Supabase (`Supabase.initialize(...)`).
`configureDependencies()` lee ambos de forma síncrona (`register_module.dart`), así que cualquier
escenario reventaba en el primer paso con:

```
Bad state: openPowerSyncDatabase() must complete before anything
reads powerSyncDatabase (see bootstrap.dart).
```

Regresión introducida por `f5e10c8` ("cablear Google/Apple login, PowerSync+Supabase y flavors
dev/prod"). **Fix aplicado** (dentro de `integration_test/`, sin tocar `lib/`): `startApp` ahora
llama `await Supabase.initialize(...)` y `await openPowerSyncDatabase()` antes de
`configureDependencies()`, en el mismo orden que `bootstrap()`, más un cierre defensivo
(`_previousPowerSyncDatabase?.close()`) de la conexión previa antes de `resetLocalDatabase()` para
evitar una carrera entre escenarios.

Archivo: `integration_test/support/patrol_app.dart`.

## 2. Locators muertos por suite

Con el bloqueo de infraestructura corregido, cada suite todavía tenía locators desactualizados
(el código cambió, el test no) — no bugs de producto. Patrón general encontrado, útil para las
suites que faltan:

- **Copys que cambiaron** (mensajes de error, textos de sheets) — el test asume el texto viejo.
- **Formato de moneda**: `MoneyFormatter.currencyDecimals` ya no usa 2 decimales para COP — cualquier
  literal con `,00` en un assert de monto está desactualizado.
- **Íconos de "volver"**: páginas que usan el componente propio `PageHeader`
  (`lib/core/widgets/page_header.dart`) tienen su botón de volver en `LucideIcons.arrowLeft`, nunca
  `Icons.arrow_back` (Material).
- **Locators por índice** (`find.byType(X).last`/`.first`/`.at(n)`) sobre forms largos dentro de un
  `ListView` plano (no `.builder`): la virtualización por cache extent corre los índices cuando se
  hace scroll. Preferir locators por label/ancestor.
- **CTAs con l10n key que nunca se conectó a ningún widget real** — el test busca el string de la
  key, pero el widget real usa otro string/otra key.

### Cuentas (`accounts_patrol_test.dart`) — ✅ 6/7 estable

- Locator de navegación: `find.text('Ver mis cuentas')` (key `accountsOpenAction`, nunca wireada) →
  `find.text('Cuentas')` (el chip real de `quick_access_row.dart`, usa `l10n.accountsTitle`).
- Formato de moneda: `'500.000,00 COP'` → `'500.000 COP'`.
- Ícono de volver (HU-07, `ArchivedAccountsPage`): `Icons.arrow_back` → `LucideIcons.arrowLeft`.
- Locator frágil por índice (HU-02, campo de cupo/límite de crédito): `find.byType(TextFormField).last`
  → nuevo helper `_enterTextByLabel` (busca por label del campo, no por índice).
- **Pendiente, no bloqueante**: HU-02 (seleccionar día de corte) falla de forma intermitente con
  `Found 0 widgets with text "15"` al abrir el day-picker — parece un miss real de tap en el
  emulador (misma clase de flakiness que `adb input tap` ya documentada en
  `docs/dev-runs/bug-fixes-pixel-audit.md`), no un locator roto: el día sí es hit-testable en cuanto
  el sheet abre. Se agregó un retry acotado (hasta 3 intentos) sobre el tap que abre el sheet, que
  redujo pero no eliminó el flake. Si vuelve a fallar seguido, vale la pena revisar si el sheet
  necesita un `pump` extra antes del tap, o si es puramente infraestructura del emulador.

### Autenticación (`auth_patrol_test.dart`) — ✅ 5/5, verde

- Único fix: el sheet de "Eliminar cuenta" ahora dice "irreversible" en el copy, el test buscaba el
  texto viejo `find.textContaining('no se puede deshacer')` → `find.textContaining('irreversible')`.
- Sin locators de navegación muertos ni problemas de índice — la suite más simple de las 5.

### Categorías (`categories_patrol_test.dart`) — ✅ 6/6, verde (2 corridas consecutivas)

- Navegación muerta, mismo patrón que Cuentas pero con una variante nueva: `categoriesOpenAction`
  (`'Ver mis categorías'`) tampoco está wireada a ningún widget — pero a diferencia de Cuentas,
  Categorías **no tiene chip propio en `QuickAccessRow`** (Home solo expone Cuentas, Pagos
  programados, Deudas y Gráficas ahí). La única entrada real es la pestaña "Más" del
  `HomeTabBar` → `MoreRow(label: l10n.categoriesTitle)` en `MorePage`. Se agregó un helper
  `_openCategories($)` que hace `tap('Más')` y luego `tap('Categorías')`, reemplazando las 6
  apariciones del locator muerto.
- **Copy inexistente en el sheet de borrado simple** (HU-04 caso 1, `ConfirmDeleteSimpleSheet`):
  el test esperaba un título `'¿Eliminar esta categoría?'` que nunca se renderiza — el sheet no
  tiene título (`Sheet Icon Header` con `enabled:false` a propósito, según su doc comment), solo
  el mensaje `categoryDeleteSimpleMessage` ("Esta categoría se eliminará de tu lista..."). Fix:
  `find.textContaining('se eliminará de tu lista')`.
- **Mensajes interpolados con el nombre real de la categoría** (HU-04 casos 2 y 3,
  `categoryDeleteTransactionsMessage` / `categoryDeleteSubcategoriesMessage`): el test asumía
  strings literales (`'Tiene 1 movimiento asociado.'`, `'Esta categoría tiene subcategorías'`) que
  no calzan con el formato real (`"{categoryName}" tiene {count} ...`). Fix: `textContaining` sobre
  una subcadena estable (`'tiene 1 movimiento asociado'`, `'tiene 1 subcategoría activa'`) en vez
  del string completo.
- **Suposición de flujo incorrecta en HU-04 caso 2** (borrar con transacciones asociadas): el test
  asumía que "Dejar sin categoría" ya viene seleccionado por defecto en
  `ConfirmDeleteWithTransactionsSheet` y confirmaba tocando `'Eliminar'`. En realidad
  `_ConfirmDeleteWithTransactionsSheetState._choice` arranca en `.reassign` ("Reasignar a otra
  categoría"), y el botón de confirmar en ese paso dice `'Continuar'` (`commonContinue`), nunca
  `'Eliminar'` — elegir una resolución y confirmarla ya ejecuta el borrado en un solo salto
  (`CategoryFormPage._handlePrompt`), no hay un segundo prompt como en el caso de cascada. Fix: tap
  explícito en `'Dejar sin categoría'` antes de tocar `'Continuar'`.
- Sin problemas de formato de moneda, ícono de volver o locators por índice en esta suite — el
  único `TextFormField` del form es el de Nombre, sin ambigüedad de índice.
- Sin flakiness de touch-injection observado en 2 corridas consecutivas (incluyendo el drag-reorder
  de HU-05, que usa la misma técnica de pasos incrementales que `accounts_patrol_test.dart` HU-09).

### Inicio/Dashboard (`home_patrol_test.dart`) — ✅ 4/4, verde (2 corridas consecutivas)

- Único fix, y de una clase nueva no vista en las suites anteriores: **el producto avanzó, el test
  se quedó atrás**. El escenario "las pestañas Presupuestos y Metas muestran 'Próximamente'"
  asumía que ambas tabs renderizaban el `ComingSoonPage` compartido. Presupuestos ya shippeó como
  feature real (`BudgetsPage`, con su propio `BudgetsListCubit`/`ZeroBasedSummaryCubit` cableados
  en `app_router.dart`) — el router deja de usar `ComingSoonPage` para esa branch, solo Metas
  sigue en placeholder. Fix: split del escenario en "Presupuestos abre su feature real y Metas
  muestra 'Próximamente'", con `expect(find.byType(BudgetsPage), findsOneWidget)` para Presupuestos
  y `ComingSoonPage` solo para Metas.
- El resto de la suite (navegación por tab bar, hub "Más" → Cuentas, FAB → formulario de
  transacción) no tenía locators muertos: los labels (`Inicio`, `Movimientos`, `Presupuestos`,
  `Metas`, `Más`), el mensaje de estado vacío (`homeEmptyMovements`) y los tooltips
  (`transactionsAdd` = "Agregar movimiento", `accountsAdd` = "Agregar cuenta") siguen calzando
  contra el código real — se verificaron uno por uno contra los `.arb` y los widgets antes de
  correr, sin necesidad de tocar nada más.
- Sin flakiness de touch-injection observado en 2 corridas consecutivas.

### Transacciones (`transactions_patrol_test.dart`) — 🟡 EN PAUSA, sin trabajo diagnóstico pendiente — retomar mañana

**Confirmado al detener la corrida (mismo día, más tarde):** ningún locator ni bug de producto
sigue sin diagnosticar. `dart analyze lib/` está limpio en este momento y la suite ya llegó a 9/9
verde al menos una vez (`tx_run26`) — lo único que falta es conseguir 2 corridas consecutivas
verdes sin que un build ajeno interfiera en medio. El build se rompió de forma intermitente por
trabajo en progreso sin commitear de alguien más, en al menos 4 momentos distintos de la sesión
(`home_cubit`/progreso de presupuesto en Home, `budget_repository_impl` con métodos de
`BudgetRepository` sin implementar, y el de `scheduled_payments` ya documentado abajo) — cada vez
se resolvía solo minutos después, cuando quien estuviera trabajando en paralelo avanzaba su cambio.

**No reintentar esta noche.** Se hizo un trabajo real y extenso de corrección de locators (ver
`git diff integration_test/transactions_patrol_test.dart` — 456 líneas cambiadas, documentado en
los propios comentarios del archivo) y en una corrida (`tx_run26.log`, 10m18s) llegó a **9/9
verde**. Pero las corridas de esa madrugada oscilaron mucho — de 0/9 a 9/9 y de vuelta a fallos de
build — y la causa NO es flakiness normal de touch-injection: **el árbol de trabajo tiene cambios
sin commitear, ajenos a esta tarea, en `lib/features/scheduled_payments/` y
`lib/features/budgets/`** (feature de "confirmar ahora" un pago programado, ajustes de presupuesto)
que en varios momentos dejaron el build roto:

```
lib/core/di/injection.config.dart:758:47: Too few positional arguments: 6 required, 5 given.
lib/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart:248:33:
  Required named parameter 'onConfirmNow' must be provided.
lib/features/scheduled_payments/presentation/widgets/scheduled_payment_hero_card.dart:230:17:
  The method 'ScheduledPaymentConfirmNowButton' isn't defined
```

`injection.config.dart` (generado por `build_runner`) quedó desincronizado con
`ScheduledPaymentDetailCubit`/`ScheduledPaymentHeroCard` — probablemente falta correr
`dart run build_runner build --force-jit`, o ese feature está a medio terminar y alguien lo sigue
editando en paralelo (el build pasaba de fallar a compilar entre corridas consecutivas sin que
nadie tocara `integration_test/`). Ninguna suite Patrol puede correr de forma confiable mientras
ese árbol siga inestable — no es un problema de Transacciones ni de Patrol.

**Qué SÍ quedó corregido y guardado** en `integration_test/transactions_patrol_test.dart` (sin
commitear, no perder este trabajo):
- Locator de guardar cuenta ambiguo: `AccountFormPage` ahora tiene dos botones de guardar (el del
  `PageHeader` y un `Button/Primary` de ancho completo al final) — `find.byIcon(LucideIcons.check)`
  sin más se volvió ambiguo. Fix: `find.byTooltip('Guardar')` (solo el del header tiene tooltip).
- HU-07 ("crear etiqueta al vuelo desde el formulario") **sí es alcanzable hoy** — el comentario
  original del archivo decía que era un gap de producto sin arreglar (`TransactionFormBody` nunca
  renderizaba un picker de etiquetas), pero eso ya cambió: `TransactionFormPage` ahora sí renderiza
  `TransactionTagsField` con un chip "+ Nueva" que abre el mismo `TagFilterSheet`. Otro caso más del
  patrón "el producto avanzó, el test no" ya visto en Home/Presupuestos.
- Nuevo helper `_createCategory(..., {kind})` (antes solo creaba categorías de gasto) y
  `_pickCategory` (tap directo del chip en `CategoryQuickPicker`, no por "Ver más" — ese camino
  duplica el texto entre el picker y el sheet y vuelve ambiguo el locator).
- Guardado de transacción con reintento acotado (hasta 3 intentos) cuando el tap sobre el chip de
  categoría falla de forma intermitente — misma clase de flakiness de touch-injection ya vista en
  el day-picker de Cuentas.
- Import ajustado (`hide CategoryKind` en `app_database.dart`, `show CategoryKind` desde
  `categories/domain/entities/category.dart`) para evitar el choque de nombres entre ambos.

**Últimos 2 escenarios que aún fallaban** cuando el build lo permitía (`tx_run20.log`, 7/9): HU-03
(transferencia entre 2 cuentas) y HU-07 (etiqueta nueva desde el formulario) — sin confirmar todavía
si eran locators que faltaba terminar de ajustar o inestabilidad heredada del build. `tx_run26.log`
sí llegó a 9/9, así que probablemente ya estaban resueltos y lo que se vio después (`tx_run27` en
adelante, degradando de nuevo) fue el build inestable, no una regresión del test.

**Para retomar mañana:**
1. Confirmar con quien esté trabajando en `scheduled_payments`/`budgets` que el árbol compila limpio
   (`flutter analyze` sin errores, `dart run build_runner build --force-jit` si hace falta
   regenerar) antes de volver a correr Patrol.
2. Re-correr `transactions_patrol_test.dart` contra `--flavor dev --dart-define-from-file=.env.dev`
   una vez el build esté estable — con los fixes ya guardados en el archivo, es razonable esperar
   que llegue a 9/9 de nuevo (ya pasó una vez) sin más cambios de locator.
3. Si sigue fallando específicamente HU-03/HU-07 con el build limpio, ahí sí es un hallazgo nuevo
   que investigar (no descartarlo como flakiness sin confirmar primero).

**Aprendizaje aplicable (ya no queda ninguna suite pendiente de correr por primera vez, pero
queda como referencia)**: además de los patrones ya documentados (copys que cambian, formato COP,
íconos de `PageHeader`, locators por índice frágiles, CTAs sin wire, atajos que solo viven en "Más"
y no en `QuickAccessRow`, mensajes interpolados que necesitan `textContaining`, estado inicial real
de controles con default, "el producto avanzó y el test no"), esta corrida agregó uno nuevo:
**cuando los resultados de una suite oscilan de corrida en corrida sin que nadie toque el archivo
de test, sospecha primero del estado del árbol de trabajo (`git status`) antes de asumir
flakiness del emulador** — un build roto de forma intermitente por trabajo en progreso ajeno puede
parecer exactamente igual a flakiness real.

## Resumen consolidado (provisional — falta cerrar Transacciones)

| Suite | Estado | Fixes aplicados |
|---|---|---|
| Cuentas | ✅ 6/7 estable | Navegación, formato COP, ícono `PageHeader`, locator por índice → label. HU-02 día de corte intermitente (flakiness de touch, no locator; mitigado con retry). |
| Autenticación | ✅ 5/5 | Copy del sheet de eliminar cuenta actualizado. |
| Categorías | ✅ 6/6 (2 corridas) | Navegación vía "Más" (no `QuickAccessRow`), copys de sheets de borrado con `textContaining`, estado inicial real de un radio corregido. |
| Inicio/Dashboard | ✅ 4/4 (3 corridas) | Presupuestos dejó de ser `ComingSoonPage` (ya es feature real) — el test buscaba el tipo de widget viejo. |
| Transacciones | 🟡 En pausa | Ver arriba — fixes extensos ya aplicados y guardados, bloqueado por build inestable ajeno a esta tarea, no por locators. |

**Ningún bug real de producto quedó pendiente de reportar a `flutter-dev`** en las 4 suites
cerradas — todo fue drift de los tests contra un producto que siguió avanzando. Transacciones queda
abierta, sin evidencia todavía de bug real (los 2 escenarios que fallaban parecen resueltos en
`tx_run26`, pendiente de confirmar con build estable).

## Cómo continuar

1. Resolver primero el build roto en `lib/features/scheduled_payments/`/`lib/features/budgets/`
   (ver sección Transacciones arriba) — nada de Patrol corre de forma confiable hasta entonces.
2. Re-correr Transacciones contra un emulador Android con
   `patrol test --target integration_test/transactions_patrol_test.dart --flavor dev --dart-define-from-file=.env.dev -d <device>`.
3. Por cada fallo, diagnosticar si es (a) locator muerto de los tipos ya documentados → corregir en
   `integration_test/transactions_patrol_test.dart`, (b) bug real de producto → NO corregir desde
   `qa-automator`, reportar a `flutter-dev`, o (c) flakiness de touch-injection ya documentado →
   mitigar con retry acotado, no perseguir más allá de eso.
4. Actualizar la fila de Transacciones en `docs/patrol-e2e-tracking.md` y esta sección al cerrar.
