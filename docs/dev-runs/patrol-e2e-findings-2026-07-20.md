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

### Transacciones (`transactions_patrol_test.dart`) — ✅ 8/9 estable (2 corridas consecutivas), 1 bug real de producto encontrado

Suite cerrada. La sesión completa fue larga (más de 35 corridas) porque el árbol de trabajo estuvo
inestable la mayor parte del tiempo por **trabajo concurrente sin commitear de otro agente** en
`lib/features/accounts/`, `lib/features/home/`, `lib/features/budgets/` y
`lib/features/scheduled_payments/` — nada de eso es un problema de Transacciones ni de Patrol, pero
explica por qué el diagnóstico tomó tantas iteraciones (varios fixes tuvieron que revisarse dos
veces porque el código que el test ejercía cambió *mientras* se investigaba). El emulador
(`emulator-5554`) también se cayó por completo varias veces a mitad de sesión (proceso `qemu`
terminado, sin `adb devices`) y tuvo que reiniciarse (`emulator -avd Pixel_9a -no-snapshot-load`)
— infraestructura, no Patrol ni el código.

**Fixes de locator aplicados** en `integration_test/transactions_patrol_test.dart`:

- **Categoría ahora obligatoria** (hallazgo no documentado antes en esta sesión): HU-01/02/04/05/06
  nunca seleccionaban categoría, pero `TransactionDraft.validated()` la exige para
  expense/income (`fieldCategoryId`, "a category is required") — sin ella el `submit()` falla en
  silencio y el formulario nunca se cierra. Se agregó `_createCategory(..., {kind})` (antes solo
  creaba de tipo gasto) y `_pickCategory` (tap directo del chip en `CategoryQuickPicker` — no por
  "Ver más": `GetMostUsedCategories` hace fallback a las categorías más antiguas por `sortOrder`
  cuando no hay historial de uso, así que con una sola categoría creada **ya aparece como chip**
  desde el primer momento; pasar por "Ver más" de todas formas deja el chip Y la fila del sheet
  mostrando el mismo texto a la vez, cosa que sí es ambigua).
- **El teclado numérico no desplaza 2 decimales para COP**: `TransactionFormCubit
  .amountDigitPressed`'s "whole-number mode" escala por `MoneyFormatter.currencyDecimals`, que es
  `0` para COP — escribir `[2, 5, 0, 0, 0]` (asumiendo un calculador de 2 decimales fijos) da
  `$25.000`, no `$250`; el dígito correcto es `[2, 5, 0]`. Afectaba **todos** los montos de la
  suite. `_enterAmount` ahora también verifica que el monto mostrado avanza después de cada dígito
  (reintento acotado por dígito) — un tap de dígito ocasionalmente no registraba, produciendo un
  monto final incorrecto sin ninguna pista de qué dígito se perdió.
- **El monto de la fila de lista SÍ lleva signo para gasto** (`transactionAmountLabel`, extraído a
  `utils/transaction_amount_presentation.dart` y compartido con `RecentActivityRow` de Inicio):
  `-$X` para gasto, `+$X` para ingreso, sin signo para transferencia — la propia página de detalle
  (`DetailAmountHero`) sigue sin signo; son dos convenciones distintas a propósito, hay que
  verificar cada una contra el widget que realmente la usa, no asumir que ambas coinciden.
- **`AccountCard` cambió de `MoneyFormatter.format` a `.formatSymbol`**: los saldos de Cuentas ahora
  leen `$-100`/`$100` (símbolo `$`, signo en el número), no `-100 COP`/`100 COP` — mismo cambio de
  convención que el punto anterior, en un archivo distinto (`account_card.dart`), parte del mismo
  trabajo de fidelidad visual en curso sobre Cuentas.
- **`AccountFormPage` ahora tiene dos botones de guardar**: el del `PageHeader` y un
  `Button/Primary` de ancho completo al final del formulario (mismo trabajo de fidelidad visual) —
  `find.byIcon(LucideIcons.check)` sin más se volvió ambiguo. Fix: `find.byTooltip('Guardar')`
  (solo el del header tiene `Tooltip`).
- **HU-07 ("crear etiqueta al vuelo desde el formulario") sí es alcanzable hoy** — el comentario
  original del archivo decía que era un gap de producto sin arreglar (`TransactionFormBody` nunca
  renderizaba un picker de etiquetas), pero eso ya cambió: `TransactionFormPage` ahora sí renderiza
  `TransactionTagsField` con un chip "+ Nueva" que abre el mismo `TagFilterSheet`. Otro caso más del
  patrón "el producto avanzó, el test no" ya visto en Home/Presupuestos. Ese chip vive al final de
  un `ListView(children: ...)` — la virtualización por cache extent aplica igual que en un
  `.builder` (solo cambia cómo se obtiene el widget, no cómo se crean sus elementos), así que
  `ensureVisible` solo no basta cuando el objetivo cae fuera del extent ya construido: hace falta
  `dragUntilVisible` para ir extendiéndolo por scroll, igual que con la barra de filtros horizontal.
- Guardado de transacción con reintento acotado (hasta 3 intentos, revisando el `Matcher` real en
  cada intento, no solo si el finder está vacío — un ambiguo transitorio durante la transición de
  cierre del formulario también cuenta como "todavía no asentado") cuando la selección de categoría
  falla de forma intermitente — misma clase de flakiness de touch-injection ya vista en el
  day-picker de Cuentas.
- Import ajustado (`hide CategoryKind` en `app_database.dart`, `show CategoryKind` desde
  `categories/domain/entities/category.dart`) para evitar el choque de nombres entre ambos.

#### Bug real de producto encontrado — HU-07, `NewTagSheet` se desborda con teclado abierto

**Reportado, no corregido** (fuera del alcance de `qa-automator`): al abrir `NewTagSheet` (crear una
etiqueta nueva) con el teclado visible, Flutter lanza un error real de layout:

```
A RenderFlex overflowed by 16 pixels on the bottom.
Column:file:///Users/cami/Developer/Personal/billetudo/lib/features/transactions/presentation/widgets/sheets/new_tag_sheet.dart:50:14
```

Reproducido de forma consistente (2/2 corridas) contra un Pixel 9a (1080×2424, densidad 420) — no
apareció en las corridas anteriores de la misma sesión contra el emulador original (que se cayó por
completo a mitad de sesión y tuvo que reemplazarse), lo que sugiere que el `Column` de
`NewTagSheet` no deja suficiente margen para pantallas más bajas una vez el teclado empuja el sheet
hacia arriba — un candidato claro es que al `Column` (o a su `Padding` que ya compensa
`viewInsets.bottom`) le falta envolver el contenido en algo que se ajuste (`Flexible`/`ClipRect`) o
recortar el `TextField`/label en vez de dejarlos a tamaño natural. No se tocó `lib/` para
"arreglarlo" ocultando el síntoma — queda para `flutter-dev`.

## Resumen consolidado final (las 5 suites)

| Suite | Estado | Fixes aplicados | Bug real de producto |
|---|---|---|---|
| Cuentas | ✅ 6/7 estable | Navegación, formato COP, ícono `PageHeader`, locator por índice → label. | Ninguno — HU-02 día de corte intermitente es flakiness de touch (ver `bug-fixes-pixel-audit.md`), mitigado con retry. |
| Autenticación | ✅ 5/5 | Copy del sheet de eliminar cuenta actualizado. | Ninguno. |
| Categorías | ✅ 6/6 (2 corridas) | Navegación vía "Más" (no `QuickAccessRow`), copys de sheets de borrado con `textContaining`, estado inicial real de un radio corregido. | Ninguno. |
| Inicio/Dashboard | ✅ 4/4 (3 corridas) | Presupuestos dejó de ser `ComingSoonPage` (ya es feature real) — el test buscaba el tipo de widget viejo. | Ninguno. |
| Transacciones | ✅ 8/9 estable (2 corridas) | Categoría ahora obligatoria (helper nuevo), teclado numérico sin desplazamiento de 2 decimales para COP, monto de fila de lista con signo (`transactionAmountLabel`), `AccountCard`/`AccountFormPage` con la misma pasada de fidelidad visual que rompió 2 locators compartidos, HU-07 alcanzable con `dragUntilVisible`, reintentos acotados para la misma clase de flakiness de touch ya documentada. | **Sí — 1**: `NewTagSheet` se desborda (`RenderFlex overflowed by 16 pixels`) con el teclado abierto en pantallas más bajas (reproducido 2/2 en Pixel 9a). Reportado a `flutter-dev`, no corregido desde aquí. |

**4 de las 5 suites no tuvieron ningún bug real de producto** — todo fue drift de los tests contra
un producto que siguió avanzando. Transacciones es la única con un hallazgo real, y quedó aislado y
reproducible (no es la causa de que HU-07 "falle a veces": falla siempre que la pantalla es
suficientemente baja, es un bug determinístico dependiente del tamaño de pantalla, no flakiness).

## Cómo continuar

1. Pasar el bug de `NewTagSheet` (arriba) a `flutter-dev` para que ajuste el `Column`/`Padding` a
   pantallas bajas con teclado abierto.
2. Si se vuelve a tocar `AccountCard`/`AccountFormPage`/`TransactionRow`/`transaction_row.dart` u
   otro archivo que esta sesión encontró en pasada de fidelidad visual concurrente, revisar si
   `accounts_patrol_test.dart` (que comparte `_addCashAccount`'s patrón de guardar) necesita el
   mismo fix de `find.byTooltip('Guardar')` que se aplicó aquí — no se tocó esa suite en esta
   sesión (fuera de alcance), pero el mismo commit que agregó el segundo botón de guardar
   probablemente también la rompe.
3. Cuando `qa-automator` agregue suite Patrol a Presupuestos, Pagos programados o Settings, correrla
   con `patrol-e2e-runner` siguiendo el mismo checklist de patrones documentado arriba.
