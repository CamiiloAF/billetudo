# Transacciones core (transacciones-core)

## Objetivo y criterios de aceptacion

Construir la feature Transacciones completa (HU-01 a HU-08 de `docs/requirements/03-transacciones.md`, Nivel 0): registrar gasto/ingreso/transferencia con teclado numerico anclado, editar, eliminar con papelera/undo, buscar y filtrar (cuenta, categoria con jerarquia, tipo, fecha con periodo por defecto, etiqueta), etiquetado libre con creacion al vuelo, y detalle de transaccion — sobre el esquema Drift existente (tabla `Transactions`) y el diseno ya cerrado en `billetudo.pen` / `design-system/billetudo/pages/transacciones.md`.

Tamano: **l** | Review: **deep APROBADO**

Criterios de aceptacion (12):

1. `CreateTransaction` persiste un gasto con `accountId` obligatorio, `categoryId` opcional restringido a `kind=expense` (rechaza uno de `kind=income`), `amountMinor` entero positivo, `currency`, `date` (default hoy) y `note` opcional; `type=expense` y `source=manual` por defecto (HU-01).
2. `CreateTransaction` persiste un ingreso de forma analoga con `type=income`, restringiendo `categoryId` a `kind=income` (HU-02).
3. `CreateTransaction` para `type=transfer` exige `accountId` y `transferAccountId` obligatorios y distintos entre si, sin `categoryId`; nunca se cuenta como ingreso/gasto en agregados de estructura de gasto (HU-03).
4. `UpdateTransaction` edita todos los campos salvo `source`, actualiza `updatedAt` en cada escritura, y expone una advertencia de impacto cuando la transaccion tiene `recurringId`, `goalId` o `debtId` y el cambio la afecta (HU-04).
5. `DeleteTransaction` marca solo `deletedAt` (nunca `tombstonedAt`); las filas con `deletedAt!=null` quedan fuera de `watchTransactions`/busqueda/calculo de saldo; `RestoreTransaction` limpia `deletedAt` desde el "Deshacer" del snackbar (HU-05).
6. `WatchTransactions` soporta busqueda de texto sobre nota y nombre de categoria, mas filtros combinables por cuenta(s), categoria(s) —con el toggle simetrico raiz+subcategorias—, tipo, rango de fechas y etiqueta; los filtros persisten entre re-emisiones/scroll; orden por defecto fecha desc con opcion por monto (HU-06).
7. El filtro de cuenta incluye una transaccion si `accountId` O `transferAccountId` coincide con alguna cuenta seleccionada; por defecto todas las cuentas sin badge en el chip (HU-06a).
8. El filtro de fecha inicia en "Este mes" y siempre esta activo (nunca "sin filtro"); el stepper de granularidad aplica de inmediato; "Rango personalizado" exige boton Aplicar y su "X" regresa a "Este mes"; un periodo sin transacciones muestra estado vacio, no error (HU-06b).
9. `CreateTag` crea una etiqueta al vuelo desde el formulario; `SetTransactionTags` enlaza N:N via `TransactionTags` permitiendo multiples etiquetas por transaccion; el filtro por etiqueta narrows `watchTransactions` (HU-07).
10. `TransactionDetail` muestra un label legible para cada valor de `TxSource` (manual, voz, ocr, notificacion, importado, recurrente), aunque hoy solo manual/imported sean alcanzables (HU-08).
11. El teclado numerico anclado se muestra cuando el campo Monto tiene foco y se oculta al enfocar Nota (nunca ambos teclados abiertos a la vez); verificado con `bloc_test`/widget test del estado de foco del formulario, no con interaccion manual.
12. `flutter analyze`, `dart run custom_lint` y `flutter test` pasan en verde sobre el codigo nuevo, con unit tests de cada caso de uso de dominio (incluida la logica de filtro/toggle de categorias) y `bloc_test` de cada cubit.

## Que cambio

| Archivo | Que |
|---|---|
| `lib/features/transactions/domain/entities/*.dart` | Entidades puras: `Transaction`, `TransactionDraft` (incluye `categoryKind` para validar sin tocar `data`), `TransactionWithDetails`, `TransactionFilter`, `DatePeriodFilter`, `TransactionEditImpact`, `Tag` |
| `lib/features/transactions/domain/repositories/*.dart` | Interfaces `TransactionRepository`, `TagRepository` |
| `lib/features/transactions/domain/usecases/*.dart` | Un caso de uso por accion: create/update/delete/restore/watch transactions, watch detail, get edit impact, create/watch tags, set transaction tags |
| `lib/features/transactions/data/models/*.dart` | Mappers Drift ↔ dominio (`transaction_mapper.dart`, `tag_mapper.dart`) |
| `lib/features/transactions/data/datasources/*.dart` | `TransactionsLocalDatasource`, `TagsLocalDatasource` — join reactivo Transactions ⨝ Accounts x2 ⨝ Categories ⨝ TransactionTags ⨝ Tags, agrupado en Dart |
| `lib/features/transactions/data/repositories/*.dart` | `TransactionRepositoryImpl`, `TagRepositoryImpl` (implementan las interfaces de `domain`) |
| `lib/features/transactions/presentation/cubit/*.dart` | `TransactionsListCubit` (HU-05/06, undo por snackbar), `TransactionFormCubit` (HU-01-04, teclado anclado, foco mutuamente excluyente), `TransactionDetailCubit` (HU-08), `AccountFilterCubit`/`CategoryFilterCubit`/`DateFilterCubit`/`TagFilterCubit` |
| `lib/features/transactions/presentation/pages/*.dart` | `TransactionsPage`, `TransactionFormPage`, `TransactionDetailPage` |
| `lib/features/transactions/presentation/widgets/*.dart` | `NumericKeypad`, segmented control de tipo, fila de transaccion, estados vacio/error/skeleton, 6 bottom sheets de filtro y confirmacion |
| `lib/core/router/app_router.dart` | Rutas `/movimientos`, `/movimientos/nuevo`, `/movimientos/<id>`, `/movimientos/<id>/editar` |
| `lib/core/l10n/arb/app_{es,en}.arb` + `gen/*.dart` | ~90 claves nuevas, regeneradas con `flutter gen-l10n` |
| `lib/core/di/injection.config.dart` | Regenerado con `dart run build_runner build --delete-conflicting-outputs` |
| `test/features/transactions/**` | Unit de cada entidad/caso de uso/mapper/repo, `bloc_test` de los 8 cubits, widget test de `TransactionDetailPage`/`TransactionFormPage`, `tier0_test.dart` (ningun flujo de Transacciones queda detras de anuncio/premium) |
| `integration_test/transactions_patrol_test.dart` | e2e Patrol de los 9 escenarios HU-01 a HU-08 (HU-04 tiene 2 casos) |

## Tests

Resultado (esta corrida de QA): **analyze=limpio, custom_lint=limpio, flutter test=verde (621/621), Patrol e2e=9/9 verde**, verificado contra un emulador Android real (`build/app/reports/androidTests/connected/debug/index.html`) y ademas con reproduccion manual paso a paso del flujo de borrado/deshacer (capturas de pantalla), no solo "deberia pasar".

Comandos para re-correr:

```bash
flutter analyze
dart run custom_lint
flutter test
flutter test test/features/transactions/
flutter test test/features/transactions/presentation/pages/transaction_detail_page_test.dart
flutter test test/features/transactions/presentation/pages/transaction_form_page_test.dart
cd android && ./gradlew --stop && cd ..
patrol test --target integration_test/transactions_patrol_test.dart -d emulator-5554
```

## Bug de navegacion en el e2e (encontrado y arreglado en esta ronda de QA)

`integration_test/transactions_patrol_test.dart` pasaba de 9/9 a 3/9 (o 4/9, segun el orden de fixes) por un bug sistemico de autoria del test, no de la app: varias funciones auxiliares (`_goToAccountsList`, `_createExpenseCategory`) tocaban textos que solo existen en `BootstrapHomePage` ('Ver mis cuentas', 'Ver mis categorías'), pero se encadenaban unas con otras sin volver nunca a home entre medio — el segundo tap fallaba con "Found 0 widgets" porque ya no estaban en home. Se resolvio reemplazando esos taps por navegacion determinista via `GoRouter.of(context).go(AppRoutes.X)`, que reemplaza todo el stack y aterriza siempre en la ruta pedida sin importar de donde vinieras.

Matiz importante descubierto al verificar cada escenario contra el emulador real (no basta con arreglar las 3 funciones auxiliares, hay que correr cada HU): este router **no** usa `ShellRoute`/`StatefulShellRoute` (un solo `Navigator` raiz), asi que `go()` en `_goToTransactions` (para entrar a `/movimientos`) resulto ser la eleccion equivocada — coexistia mal con el flujo de borrado de HU-05 (`ConfirmDeleteTransactionSheet` hace su propio `Navigator.pop()`, y el listener de `TransactionDetailPage` hace un segundo `Navigator.pop()` apenas milisegundos despues, cuando el borrado logico termina) y disparaba de forma reproducible un `Navigator.dispose`/`!_debugLocked` de Flutter. `push()` no lo presenta. Regla practica para futuros Patrol e2e de este repo: usar `go()` para saltos deterministas entre features (Cuentas, Categorias) que no van a volver atras con `pop`, pero `push()` para entrar a una pantalla desde la que el propio flujo de la app hace `pop`s asincronos encadenados (borrado, guardado) — mezclar los dos estilos en el mismo `Navigator` raiz es lo que rompe.

Otros hallazgos del mismo tipo (finder ambiguo, no bug de la app) arreglados en esta ronda:
- HU-06: `find.text('Cuenta A')` era ambiguo con la hoja de filtro abierta — la fila de la lista subyacente tambien se titula 'Cuenta A' cuando la transaccion no tiene categoria (`TransactionRow.title` cae al nombre de cuenta). Se acoto el finder a `CheckboxListTile` dentro de la hoja.
- HU-07: la ultima chip del filtro ('Etiqueta') queda fuera de la pantalla visible en el emulador probado — sigue en el arbol de widgets pero un `tap` sobre su centro no llega a ningun punto visible, y no lanza excepcion (falla en silencio mas adelante). Se agrego `_scrollFilterBarUntilVisible` (arrastra el `SingleChildScrollView` horizontal) antes de tocarla. Tambien `find.byType(TextField)` sin acotar en `NewTagSheet` era ambiguo con el buscador de `TransactionsPage`, que sigue montado debajo de cualquier `showModalBottomSheet`.
- HU-04 (casos 1 y 2): el formulario de edicion hace un solo `Navigator.pop()` al guardar, que devuelve al detalle (de donde se abrio editar), no a la lista — el detalle muestra el monto sin signo (`TransactionDetailBody`, a diferencia de `TransactionRow` en la lista, que es quien antepone +/-). Los asserts se corrigieron para verificar el monto sin signo en el detalle en vez de repetir el formato con signo de la lista.

## Bug del snackbar "Deshacer" (encontrado y arreglado en esta ronda)

HU-05 pide un "Deshacer" tipo snackbar tras borrar. El unico borrado alcanzable desde la UI real es el icono de basura de `TransactionDetailPage`, que pasa por `TransactionDetailCubit.confirmDelete` — un cubit distinto de `TransactionsListCubit`, que es quien sabe mostrar el snackbar via `pendingUndoId`. Se conecto asi: `TransactionDetailPage` hace `Navigator.pop(id)` en vez de `pop()` al terminar de borrar, y `TransactionsPage` llama `TransactionsListCubit.notifyExternalDelete(id)` con lo que reciba. Verificando esto a mano contra el emulador real (no solo con Patrol) aparecieron dos bugs reales en cascada, no de autoria del test:

1. **Doble pop por `listenWhen` sin flanco de subida.** El `listenWhen` de `TransactionDetailPage` disparaba el listener con solo `current.deleted == true`, sin comparar contra `previous.deleted`. Como la suscripcion al stream de `WatchTransactionDetail` sigue viva tras el borrado (la fila ya no matchea la query y el stream reemite), esa reemision conservaba `deleted: true` via `copyWith` y volvia a disparar el listener — `Navigator.pop()` se llamaba dos veces, la segunda saltandose la lista y aterrizando en Home. Arreglado exigiendo el flanco `!previous.deleted && current.deleted`.
2. **`ProviderNotFoundError` silencioso al notificar al cubit equivocado.** `AppRoutes.transactions`' `GoRoute.builder` crea un `TransactionsListCubit` nuevo (via `getIt`, factory) en **cada** navegacion (push o pop) dentro del mismo arbol de rutas — GoRouter re-ejecuta el `builder` de cada ruta activa en cada cambio de ubicacion, no solo el de la hoja. El codigo original capturaba `listCubit` en el closure de `onOpenTransaction` y lo usaba tras el `await` del push; para entonces ya podian existir 2-3 cubits nuevos y el capturado estaba huerfano (nadie lo escuchaba) — pero ademas, el intento de arreglo de "leer el cubit vigente" fallaba distinto: usar `context.read<TransactionsListCubit>()` con el `context` del `builder` del router lanza `ProviderNotFoundError`, porque ese `context` es **ancestro**, no descendiente, del `BlocProvider.value` que el propio builder retorna. La excepcion quedaba silenciada (nunca crasheaba visiblemente, solo el snackbar nunca aparecia). Arreglado moviendo la logica de "avisar al cubit" a `TransactionsPage._openTransaction`, que usa su propio `BuildContext` (si descendiente del provider); el router ahora solo navega y devuelve el resultado (`onOpenTransaction: (id) => context.push<String>(...)`).

Diagnosticado con reproduccion manual paso a paso (`uiautomator dump` para coordenadas exactas + secuencias de capturas de pantalla) y `print`/logcat temporales para confirmar identidad de cubit y la excepcion silenciada; ambos se retiraron antes de este commit. Verificado: Patrol 9/9 (incluido HU-05 con las assertions del snackbar) y reproduccion manual con el snackbar "Movimiento eliminado." + "Deshacer" visibles y funcionales.

## 👤 Verifica a mano

- ~~`AccountPickerField`/`CategoryPickerField` mostraban la etiqueta estatica en vez del nombre elegido~~ — **arreglado** (no por este rol; reportado por QA en la corrida anterior y corregido despues por el usuario): `TransactionFormState` gano `accountName`/`transferAccountName`/`categoryName`; `TransactionFormCubit._formFor` los mapea desde `TransactionWithDetails` al editar, y `accountSelected`/`transferAccountSelected`/`categorySelected` ahora reciben y guardan el nombre al crear; los widgets de `transaction_form_page.dart` renderizan `selectedName` cuando existe. Cubierto por regresion en `test/features/transactions/presentation/transaction_form_cubit_test.dart` (grupo "nombres visibles al elegir (regresión)") y `test/features/transactions/presentation/pages/transaction_form_page_test.dart` (grupo "regresión: el picker muestra el nombre elegido, no el label estático").
- `BootstrapHomePage` (placeholder temporal) no tiene boton hacia Transacciones (solo Cuentas y Categorias) — es intencional segun los propios comentarios del codigo ("goes away with the real shell"), documentado tambien en el header del nuevo e2e. Confirmar que sigue siendo el plan cuando llegue el shell real.
- Verificacion visual real del teclado numerico anclado (que no se solape con el resto del formulario, animacion de aparicion/desaparicion, contraste en tema oscuro) — el `bloc_test` y el widget test cubren el estado logico pero no la percepcion visual.
- Gestos reales de swipe/scroll en las hojas de filtro (chips de cuenta/categoria/tipo/fecha/etiqueta) con datos reales de un usuario, mas alla de lo que cubre `bloc_test`. En el emulador probado la barra de chips no cabe completa en una pantalla de telefono tipico (ver hallazgo de HU-07 arriba); verificar la experiencia real de scroll horizontal en dispositivo.
- Formato de moneda y separadores (COP, NBSP antes del codigo de moneda) en dispositivos con configuracion regional distinta a `es_CO`.

## Pendientes y riesgos

- Sin blockers sin resolver. Sin observaciones no bloqueantes.
- No hay golden tests ni widget tests de interaccion para las paginas/sheets nuevas (solo `bloc_test` de los 8 cubits, que es lo pedido); el diseno visual no fue auditado contra `billetudo.pen`/design-system en esta etapa (le toca a `pencil-designer`/`ui-ux-reviewer`).
- El borrado logico de HU-05 esta probado contra Drift real en memoria, en el cubit de lista, y en el e2e Patrol (ver "Bug de navegacion" arriba). La papelera/undo tipo snackbar tambien quedo cubierta end-to-end: ver "Bug del snackbar Deshacer" abajo — el gap que existia (`TransactionDetailPage` borraba via un cubit que nunca tocaba `pendingUndoId`) esta arreglado, verificado por Patrol y por reproduccion manual con capturas.
- HU-04 (advertencia de impacto en `recurringId`/`goalId`/`debtId`) solo puede construir deteccion defensiva (el campo no es null), porque Recurrentes/Metas/Deudas siguen siendo lienzo en blanco en el repo — alcance acotado a eso, sin inventar semantica de esas features futuras.
- Multi-moneda (HU-01/03, ver `docs/requirements/12-multi-moneda.md`) queda fuera de alcance: `currency` = moneda de la cuenta seleccionada, sin conversion.
- Tags/`TransactionTags` no tenian modulo propio; se introdujeron dentro de `transactions/` porque solo `03-transacciones.md` las menciona. Si aparece una feature de Tags dedicada, revisar que no se dupliquen entidades/repos.
- `TxSource` reserva `voice`/`ocr`/`notification`/`recurring` para fases futuras; el label legible de HU-08 cubre los seis valores del enum aunque hoy solo `manual`/`imported` sean alcanzables.
- Nivel 0: Transacciones es registro manual ilimitado y gratis por `CLAUDE.md` — ningun limite/cupo aplica a `source=manual/imported`; confirmar con `compliance-reviewer` que ningun flujo quedo detras de un gate de anuncio/premium.
- La falla intermitente de `test/core/di_test.dart` (`CategoryRepository`) fue confirmada preexistente en `main` (con `git stash -u`), no es una regresion de esta corrida.
- Riesgo arquitectonico mas amplio, no arreglado (fuera de alcance de esta corrida): `getIt<XxxListCubit>()` esta registrado `@injectable` (factory) y se llama dentro del `builder` de cada `GoRoute`, que GoRouter re-ejecuta en cada push/pop de cualquier ruta activa — no solo la hoja. Eso crea una instancia nueva del cubit (con su propia suscripcion al stream de Drift) en cada navegacion, dejando huerfanas las anteriores (nunca se cierran, ya que `BlocProvider.value` no las posee). Confirmado con logging temporal en esta corrida para Transacciones; el mismo patron (`_started(getIt<Cubit>(), ...)` dentro del `builder`) se usa para `AccountsListCubit` y `CategoriesListCubit`, asi que probablemente sufren el mismo leak de suscripciones — sin efecto visible ahi porque ninguna tiene un callback cross-route que dependa de una referencia de cubit capturada. Vale la pena revisar en una pasada dedicada (opciones: registrar como `@lazySingleton` con scope de sesion, o cachear la instancia por ruta).
- Nota operativa de esta corrida: `lib/core/database/app_database.dart` tiene una migracion de esquema sin commitear en curso (`updatedAt` de `DateTimeColumn` a `IntColumn` en epoch millis, v4→v5, ver `docs/requirements/05-auth-sync.md`), aparentemente en progreso en paralelo por otra sesion — el `.g.dart` generado (gitignoreado) se desincronizo del source dos veces durante esta corrida de QA y rompio la compilacion hasta volver a correr `dart run build_runner build`. No es un bug de Transacciones ni algo que este rol haya tocado en `lib/`, pero si otra corrida futura ve `flutter analyze`/`flutter test`/Patrol romperse con errores `DateTime`/`int` en `updatedAt`, ese es el sintoma — regenerar con build_runner antes de reportarlo como regresion nueva.

## Mensaje de commit sugerido

```
Agregar la feature Transacciones completa (HU-01 a HU-08)

Registro de gasto/ingreso/transferencia con teclado numerico anclado,
edicion, borrado con papelera/undo, busqueda y filtros combinables
(cuenta, categoria jerarquica, tipo, fecha, etiqueta), etiquetado libre
al vuelo y detalle de transaccion, sobre el esquema Drift existente.
```
