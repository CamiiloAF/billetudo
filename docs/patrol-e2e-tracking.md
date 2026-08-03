# Track de e2e Patrol (flavor `dev`)

Estado de la ultima corrida de cada suite Patrol (`patrol-e2e-runner`, ejecutada a demanda o vía
`qa-automator`) contra el flavor **`dev`** de la app. **Patrol nunca corre contra `prod`** — todo
resultado de esta tabla viene de `--flavor dev --dart-define-from-file=.env.dev`. Los
`docs/dev-runs/*.md` quedan como el detalle de cada corrida; esta tabla es el único lugar que
consolida el estado actual por feature.

## Cómo leer la tabla

- **Estado**: ✅ Verde (todos los escenarios pasan) · 🟡 Parcial (algún escenario falla o quedó en skip) · ⏳ Sin correr (suite existe, nunca se ejecutó o no hubo device) · 🚫 Bloqueada (ej. iOS sin Patrol habilitado en `Runner`) · ⬜️ N/A (feature sin suite Patrol todavía)
- **Suite**: si existe `integration_test/<feature>_patrol_test.dart` — prerrequisito para que `patrol-e2e-runner` tenga algo que ejecutar.
- **Fuente**: el dev-run o corrida donde se registró el resultado.

| Feature | Estado | Fecha | Suite | Fuente | Notas |
|---|---|---|---|---|---|
| Cuentas | ✅ Verde | 2026-07-21 | ✅ (`integration_test/accounts_patrol_test.dart`) | corrida `qa-automator` de hoy tras el commit `b42e5ed` (fidelidad visual del form) | ✅ 7/7 en 2 corridas consecutivas. `b42e5ed` dejó dos íconos `LucideIcons.check` visibles a la vez en el form (el botón secundario del `PageHeader` y el `FilledButton` "Guardar cuenta" de ancho completo) más un tercero en la fila de moneda seleccionada (HU-02): todo `tap(find.byIcon(LucideIcons.check))` quedó ambiguo. Fix: nuevo `_saveAccountButton`/`_submitAccountForm` que ubica el botón por su label ("Guardar cuenta") vía `byWidgetPredicate((w) => w is FilledButton)` — no `find.widgetWithText(FilledButton, ...)`, porque `FilledButton.icon` resuelve a la subclase privada `_FilledButtonWithIcon` y los finders por tipo exacto no matchean subclases. Además: `DayPickerSheet` (HU-02) ahora exige un tap explícito en su propio "Guardar" tras elegir el día (ya no cierra al primer tap, ver su doc comment) — `_pickDay` no lo hacía y dejaba el día sin confirmar; el copy real de balance es `MoneyFormatter.formatSymbol` (`$500.000`), no `"500.000 COP"`; y `ConfirmDeleteAccountSheet` (HU-08) no tiene título separado ("¿Eliminar esta cuenta?"), solo el mensaje narrativo — los 3 eran asunciones obsoletas del test, no bugs de `lib/`. |
| Autenticación | ✅ Verde | 2026-07-21 | ✅ (`integration_test/auth_patrol_test.dart`) | re-validado en la corrida completa del 2026-07-21 | ✅ 5/5, sin novedad tras los commits recientes de formularios/date-picker. Fix histórico (2026-07-20): copy del sheet de eliminar cuenta cambió a "irreversible" (antes "no se puede deshacer"). |
| Categorías | ✅ Verde | 2026-07-21 | ✅ (`integration_test/categories_patrol_test.dart`) | re-validado en la corrida completa del 2026-07-21 | ✅ 6/6, sin novedad tras los commits recientes de formularios/date-picker. Fixes históricos (2026-07-20): navegación (`Ver mis categorías` muerto, la ruta real es la pestaña "Más" → `Categorías`), copy inexistente en el sheet de borrado simple, mensajes interpolados con `textContaining`, y flujo de HU-04 caso 2 (radio por defecto "Reasignar", botón "Continuar"). |
| Inicio / Dashboard | ✅ Verde | 2026-07-21 | ✅ (`integration_test/home_patrol_test.dart`) | re-validado en la corrida completa del 2026-07-21 | ✅ 4/4, sin novedad tras los commits recientes de formularios/date-picker. Fix histórico (2026-07-20): Presupuestos dejó de ser `ComingSoonPage` (ya ships como `BudgetsPage`). Metas sigue en "Próximamente". |
| Transacciones | ✅ Verde | 2026-07-24 | ✅ (`integration_test/transactions_patrol_test.dart`) | 2 corridas consecutivas tras agregar el escenario de Fase B1+B2, 2026-07-24 | ✅ 10/10 estable en 2 corridas seguidas (9 previos + 1 nuevo: "Fase B1+B2: transferencia con toggle '¿Incluir en tu presupuesto?' cuenta como gasto del presupuesto de su cuenta origen"). **3 fallos de infraestructura de test cerrados el 2026-07-24, ninguno bug real de `lib/`:** (1) `_createAccountScopedBudget` buscaba `find.text('Cuentas')` pero `BudgetNavField` renderiza label+valor en un solo `Text` interpolado — fix a `find.textContaining`; de paso destapó que `_goToTransactions` (usa `push()`) llamado 2 veces sin popear duplica la key de página y revienta `Navigator` — se agregó `_returnToTransactions` (usa `go()`) para la segunda entrada. (2) Seed de HU-04 caso 2 vía `TransactionsCompanion.insert` no seteaba la columna nueva `countsInBudget`; como `powersync_schema.dart` la declara sin default SQL (el `withDefault(false)` de Drift solo existe en el DDL Dart), el insert dejaba `NULL` físico y el mapper generado revienta con "Null check operator used on a null value" al leer la fila — no era timing/flaky, era determinístico. Fix: `countsInBudget: const Value(false)` explícito en el seed. **Riesgo latente sin corregir** (mismo patrón de insert, fuera del alcance de esa tarea): `categories_patrol_test.dart` y `debts_patrol_test.dart` también insertan `Transaction` sin `countsInBudget`. (3) `_enterAmount` comparaba contra `find.text('\$$whole')` sin agrupar miles, pero la UI agrupa con puntos (es-CO) desde \$1.000 — el finder nunca matcheaba y el retry interno triple-tapeaba cada dígito, escalando el monto exponencialmente; fix: comparar con `MoneyFormatter().formatSymbol(...)`, el mismo formateador que usa la UI. Ningún test anterior a Fase B1+B2 había tipeado montos ≥ \$1.000, por eso no se había visto. **Bug de `NewTagSheet` cerrado** (2026-07-21): `BottomSheetBase` ya pad-ea su `child` por el inset del teclado; `new_tag_sheet.dart` agregaba un segundo `Padding` idéntico, restando `viewInsets.bottom` dos veces y desbordando el `Column` de alto fijo cuando el timing de la animación del teclado dejaba justo poco margen (por eso era intermitente). Fix de `flutter-dev`: quitó el padding duplicado y envolvió el contenido en `SingleChildScrollView` como red de seguridad real. |
| Presupuestos | ✅ Verde | 2026-07-21 | ✅ (`integration_test/budgets_patrol_test.dart`) | corrida `qa-automator` de hoy, 2 corridas consecutivas | ✅ 5/5 estable en 2 corridas seguidas. Todas las 5 usan alcance "Todo" (global, HU-02) a propósito — un alcance por categorías necesita el catálogo de `category_seeds`, que se siembra desde Supabase y no es determinístico offline/en un proyecto de pruebas. Cubre HU-01/02 (crear), HU-09 (editar nombre+monto), HU-13 (ajustar monto solo el período actual — la regresión que cerró el commit `0c55978` — confirmando que el período siguiente conserva el monto original al navegar con el stepper), HU-10/11 (cerrar → histórico → reactivar) y HU-11 (eliminar con confirmación, incluida la ruta de "Cancelar"). **Posible edge case de `MoneyInputFormatter` encontrado, no confirmado como bug real de usuario** (ver Notas abajo) — reportado a `flutter-dev`, no corregido acá (fuera de alcance de `qa-automator`, solo lee/escribe bajo `test/`+`integration_test/`). |
| Pagos programados | ✅ Verde | 2026-07-21 | ✅ (`integration_test/scheduled_payments_patrol_test.dart`) | corrida `qa-automator` de hoy, 2 corridas consecutivas | ✅ 5/5 estable en 2 corridas seguidas. Cubre HU-01 (crear y verlo en el listado), HU-05 (editar nombre+monto — refleja en el detalle, no en el listado, porque el `AppBar` de esta página es el título fijo "Detalle"), la CTA "Confirmar ahora" (fix `81cb943`: confirmar un pago manual antes de su `nextDate`), historial de pagos omitidos + "Recuperar" (`6d15e61`), y eliminar con confirmación (incluida la ruta de "Cancelar"). Todas las plantillas usan cuenta/categoría propias creadas en el mismo escenario, sin depender del catálogo remoto de categorías. Navega a `/pagos-programados` con `GoRouter.push` en vez de un tap de UI: la feature no tiene pestaña propia en `HomeTabBar` (solo Inicio/Movimientos/Presupuestos/Metas/Más), a diferencia de Presupuestos. Dos hallazgos de infraestructura de test corregidos durante la escritura (no bugs de `lib/`): (1) un `SnackBar` con su propio timer de auto-dismiss (`Pago recuperado`) hace que `pumpAndSettle()` corra el reloj hasta el final de su ventana visible antes de devolver el control — se resolvió con pumps acotados (`_expectSnackbar`, mismo patrón que la HU-05 de `transactions_patrol_test.dart`); (2) `find.text(...)` puede matchear un widget que ya no está en pantalla (el detalle es un `ListView` plano) y el tap subsiguiente cae en lo que sí es visible en esa coordenada — el link "Recuperar" del historial necesitó `dragUntilVisible` antes de tocarlo. |
| Configuración (Settings) | ✅ Verde | 2026-07-21 | ✅ (`integration_test/settings_patrol_test.dart`) | corrida `qa-automator` de hoy, 2 corridas consecutivas | ✅ 4/4 estable en 2 corridas seguidas. Cubre el Segmented Control de "Apariencia" (Claro/Oscuro/Sistema, aplicado de inmediato, `MaterialApp.themeMode` reflejándolo), "Modo sobres" (switch directo y desde la hoja "¿Qué es?", persistiendo al salir de Ajustes y volver — `AppSettingsCubit` no es singleton de DI, se reconstruye por visita, así que esto sí prueba un round-trip real por Drift) y el punto de entrada de "Eliminar cuenta" (abre/cancela la hoja; el flujo completo de HU-07 ya lo cubre `auth_patrol_test.dart`, no se duplicó). "Moneda" quedó fuera a propósito: hoy es un placeholder "Próximamente" (`onOpenComingSoon`), no un toggle real. Hallazgo de infraestructura de test (no bug de `lib/`): `Supabase.initialize` solo puede llamarse una vez por proceso (assertion propia de `supabase_flutter`) — llamar `startApp($)` una segunda vez dentro del mismo test para simular un "reinicio real" de la app cuelga el intento y deja el árbol de widgets congelado en la pantalla anterior (`find.text('Más')` no encuentra nada después). La persistencia real de "Apariencia" en `SharedPreferences` se verificó en cambio leyendo `getIt<ThemePreferenceDatasource>().read()` directamente tras el cambio, más navegar fuera/volver a Ajustes dentro del mismo proceso. |
| Onboarding | ✅ Verde | 2026-07-29 | ✅ (`integration_test/onboarding_patrol_test.dart`) | corrida `patrol-e2e-runner` 2026-07-29, worktree `feature/onboarding`, emulator-5554 | ✅ 2/2 (12s + 5s, 1m24s total). Cubre HU-01/02/04 (primer arranque creando cuenta pre-llenada → registrar primer movimiento → Inicio) y HU-02/04 (primer arranque omitiendo cuenta → Inicio con CTA de cierre cambiado a "crear cuenta"). Tercer escenario ("Ya tengo cuenta" → login → onboarding cerrado) es skip intencional documentado en el propio test file: requiere round-trip OAuth real que Patrol no puede automatizar, mismo patrón que `auth_patrol_test.dart`. Corrida previa había destapado un crash real en el router (`_startedOnboardingAccountForm` llamaba `AppLocalizations.of(context)` dentro de un `BlocProvider.create`, prohibido por Flutter), ya corregido; esta corrida confirma estabilidad post-fix. |
| Splash | ⬜️ N/A | — | ❌ | — | Sin suite propia, pero es solo una pantalla de transición (1 archivo) ya cubierta indirectamente por `startApp` en las otras 5 suites — baja prioridad. |
| Deudas | ✅ Verde | 2026-07-24 | ✅ (`integration_test/debts_patrol_test.dart` + `integration_test/debts_installment_patrol_test.dart` + `integration_test/debts_lifecycle_patrol_test.dart`) | corrida `patrol-e2e-runner` 2026-07-24, segunda pasada tras aplicar 3 fixes (Pixel_9a/emulator-5554, flavor `dev`) | ✅ **32/32** (`debts_patrol_test.dart` 20/20, 4m30s + `debts_installment_patrol_test.dart` 6/6, 2m55s + `debts_lifecycle_patrol_test.dart` 6/6, 2m1s — este último con su 6to escenario corriendo por primera vez). Recupera los 9 escenarios rotos en la corrida inmediatamente anterior del mismo día (ver sección "Deudas: resultado real en device de la corrida 2026-07-24" abajo, con los 3 fixes que lo lograron): (1) `qa-automator` portó `_openEditForm` de `debts_patrol_test.dart` al patrón de menú ⋮ (5 escenarios recuperados); (2) `qa-automator` quitó el `/` literal del nombre del escenario "tab Cerradas" que crasheaba `AndroidTestOrchestrator` (1 escenario, nunca había corrido); (3) `flutter-dev` corrigió una carrera real entre `DebtPaymentSheet`/`DebtUpdateBalanceSheet` y `DebtCelebrationSheet` — dos hojas modales disparadas por la misma escritura podían pisarse (`pop()` cerraba la hoja equivocada); nuevo `BottomSheetBase.dismiss(context)` resuelve el pop por referencia de ruta (3 escenarios de felicitación recuperados). Sin bugs abiertos ni bloqueos de infraestructura pendientes en Deudas. Histórico: **BUG DE APP DEL ABONO — RESUELTO (flutter-dev, previo):** el CTA de la hoja de abono estaba DENTRO del `SingleChildScrollView`; con el toggle "Sí" + teclado con héroe autofocus, el botón quedaba bajo el fold → el tap de submit no aterrizaba. Fix: CTA como footer fijo fuera del scroll. |
| Metas, Reportes, Captura, Improvement | ⬜️ N/A | — | ❌ | — | Sin implementación en `lib/features/` (solo `.gitkeep`) — lienzo en blanco, no aplica escribir suite Patrol todavía. |

## Bloqueo del 2026-07-20 (YA CORREGIDO): las 5 suites fallaban por un bug de infraestructura, no por las features

Corrida completa del 2026-07-20 (`emulator-5554`, `--flavor dev --dart-define-from-file=.env.dev`): **0/31 escenarios pasaron en las 5 suites**, y las 31 fallas eran el mismo error, en el mismo punto (`startApp`):

```
Bad state: openPowerSyncDatabase() must complete before anything
reads powerSyncDatabase (see bootstrap.dart).
```

Causa raíz: `integration_test/support/patrol_app.dart` (`startApp`) no reutiliza `lib/core/bootstrap.dart` (a propósito, porque `bootstrap()` instala un `FlutterError.onError` que Patrol prohíbe tocar), pero al no reutilizarlo también se saltó el `await openPowerSyncDatabase()` que `bootstrap()` hace *antes* de `configureDependencies()` (`lib/core/bootstrap.dart:44`). `configureDependencies()` construye `AppDatabase` leyendo el getter `powerSyncDatabase` (`lib/core/database/database_connection.dart:43`) de forma síncrona, así que revienta con `StateError` en el primer paso de cada escenario.

Regresión introducida por `f5e10c8` ("cablear Google/Apple login, PowerSync+Supabase y flavors dev/prod") — antes de ese commit no existía este paso obligatorio. No es un bug de las 5 features ni de `lib/` en general: es un bug del harness bajo `integration_test/support/`, propiedad de `qa-automator`. Hasta que se corrija (falta un `await openPowerSyncDatabase()` — o equivalente sin activar los handlers de error — antes de `configureDependencies()` en `startApp`), **ninguna suite Patrol puede pasar**, sin importar la feature.

## Pendientes activos

1. ~~Bloqueante: arreglar `integration_test/support/patrol_app.dart`~~ — corregido 2026-07-20 (ver `docs/dev-runs/patrol-e2e-findings-2026-07-20.md`).
2. ~~Bloqueante: build inestable por trabajo concurrente sin commitear en `scheduled_payments`/`budgets`~~ — se resolvió solo (el otro trabajo avanzó); Transacciones ya corrió limpio 2 veces seguidas el 2026-07-21.
3. ~~Bug real de producto pendiente de que `flutter-dev` lo corrija~~ — corregido y confirmado 2026-07-21 (ver fila Transacciones arriba): padding duplicado del inset del teclado en `NewTagSheet`, causaba overflow intermitente. 27/27 escenarios en 3 corridas post-fix.
4. ~~Si se vuelve a tocar `AccountCard`/`AccountFormPage`... revisar si `accounts_patrol_test.dart` necesita el mismo fix~~ — corregido 2026-07-21 (ver fila Cuentas arriba).
5. ~~Cuando `qa-automator` agregue suite Patrol a Presupuestos, Pagos programados o Settings, correrla con `patrol-e2e-runner`~~ — las 3 ya tienen suite y quedaron en ✅ Verde (ver filas arriba). Con esto, las 8 features implementadas (`lib/features/` sin `.gitkeep`) tienen cobertura Patrol completa; solo Splash queda sin suite propia a propósito (baja prioridad, ver su fila).
6. **Posible edge case de `MoneyInputFormatter` a evaluar por `flutter-dev`** (hallado escribiendo `budgets_patrol_test.dart`, 2026-07-21): al reemplazar de una sola vez el valor ya escrito de un campo de monto (`BudgetAmountField`, y probablemente cualquier otro campo que use `MoneyInputFormatter`) por un valor cuya longitud formateada es exactamente un carácter más corta que la anterior (ej. `'500.000'` (7) → raw `'750000'` (6)), el formateador interpreta la operación como "borrar el dígito antes del separador" (su guarda de `backspacing onto a separator`, pensada para un borrado real de un solo carácter con selección colapsada) y descarta un dígito (`$750.000` termina guardado como `$75.000`). Verificado reproduciendo el escenario en un emulador real. **No confirmado que sea un bug real de usuario**: con tecleo carácter por carácter la selección al reemplazar no queda colapsada (no dispara la guarda); el camino que sí lo dispara es más parecido a "seleccionar todo + pegar/autocompletar" que a escritura manual. `qa-automator` lo evitó en el test limpiando el campo (`enterText` a `''`) antes de escribir el valor nuevo, en vez de "arreglarlo" tocando `lib/`. Vale que `flutter-dev` decida si amerita un fix (ej. no tratar como backspace un reemplazo completo del texto) o si se documenta como comportamiento aceptado.

## Deudas: suites nuevas 2026-07-22 (escritas, sin correr en device)

Dos suites Patrol para Deudas Fase 0, contra el flavor `dev`. Ambas compilan
(`flutter analyze integration_test/` → *No issues found*). **Ninguna se ha
corrido en emulador todavía**: eso es de `patrol-e2e-runner`. Los resultados de
abajo son los *esperados*, no confirmados en device.

Convención de montos: el héroe de deuda/abono/actualizar-saldo (`DebtAmountHeroField`)
es un `TextField` + `MoneyInputFormatter` (teclado del sistema), así que se
escribe con `enterText` (ej. `'600'` → `$600`, almacenado `60000` minor —
storage siempre 1/100, COP se muestra sin decimales). La cuota reusa el form de
Pagos programados, cuyo monto se teclea en el keypad anclado (`NumericKeypad`),
igual que `scheduled_payments_patrol_test.dart` — montos < 1.000.

### `debts_patrol_test.dart` (flujos núcleo de Deudas)

| Escenario | Flujo | Assert principal |
|---|---|---|
| HU-01 crear "Yo debo" | lista vacía → form → nombre + saldo apertura → Crear deuda | card con nombre, `$600` y `0% pagado` |
| HU-01 crear "Me deben" | dirección inversa | `0% cobrado` (copy cambia por dirección, no color) |
| HU-02 abono con caja (Sí) | detalle → Registrar abono → monto + cuenta preseleccionada → Registrar abono | saldo `$600`→`$400`, ledger "Abono a la deuda", **1** `Transaction` con `debtId` y `amountMinor==20000` |
| HU-02 abono sin caja (No) | toggle No → abono cash-less | saldo baja a `$450`, tag "No afecta cuentas", tabla `transactions` **vacía** |
| HU-02 abono "Me deben" | reduce en dirección inversa | saldo `$900`→`$600`, ledger "Pago recibido" |
| HU-02 enlazar movimiento | seed de `Transaction` real → hoja abono → "Enlaza un movimiento" → Movimientos link mode → tocar fila | vuelve a la deuda, `$600`→`$400`, sigue **1** transacción ahora con `debtId` |
| HU-06 actualizar saldo | meta card "Actualizar saldo" → nuevo saldo `520` → Guardar saldo | saldo `$520`, ledger "Saldo actualizado" |
| HU-07 deuda saldada | abono total ($500 sobre $500) | saldo `$0`, hero `100%` (`DebtBalance.settled`) |
| HU-05 editar | detalle → lápiz → nombre + apertura nuevos → Guardar cambios | vuelve al detalle con nombre y `$750` nuevos |
| HU-05 eliminar | editar → Eliminar deuda → (Cancelar y) confirmar | sale de la vista activa; DB `deletedAt` no nulo, `tombstonedAt` nulo |
| Ledger completo | apertura + abono caja + abono sin caja + ajuste | 4 filas `DebtLedgerRow`, "Saldo de apertura"/"Abono a la deuda"×2/"Saldo actualizado", saldo corrido `$650` |
| Interés automático | tasa 24% + modo Automático | meta card muestra "Crece …" + tag "estimado" (`dailyGrowthMinor`) |

### `debts_installment_patrol_test.dart` (integración con Pagos Programados, HU-03)

| Escenario | Flujo | Assert principal |
|---|---|---|
| Configurar cuota → aparece | detalle → Configurar cuota → form cuota (monto/cuenta/categoría/manual) → guardar | `DebtInstallmentCard` "Próxima cuota" en la deuda; en PP el template lleva `ScheduledDebtChip` ("Deuda") |
| Cuota generada reduce la deuda | cross-link a PP → "Confirmar ahora" → Confirmar | `Transaction` con `debtId`; al reabrir la deuda saldo `$600`→`$100` |
| Cross-link ambos sentidos | deuda→PP (card "Próxima cuota" → "Cuota de …") y PP→deuda (card enlazada → detalle de la deuda) | ambos `*LinkedDebtCard`/`DebtInstallmentCard` navegan bien |
| Editar cuota deep-linkea | PP detalle → ⋮ Editar | header "Editar cuota" (no "Editar pago programado"), subtítulo con la deuda |
| Eliminar cuota | Editar cuota → "Eliminar cuota" → confirmar | fuera de PP (sin `ScheduledDebtChip`); la deuda vuelve a `DebtConfigureInstallmentCard` |

### `Key`s / finders que convendría agregar en `lib/` (pendiente para `flutter-dev`, no tocados por `qa-automator`)

Todos los flujos arriba se resolvieron con finders por texto/l10n o por tipo de
widget, pero varios son frágiles y un `Key` estable los haría robustos:

1. **Botón de submit de cada hoja de abono / actualizar-saldo.** El CTA "Registrar
   abono" (`debtPaymentCta`) es idéntico al del bottom bar del detalle
   (`debtDetailRegisterPayment`) y al header de la propia hoja → hoy se
   desambigua tapeando el `LucideIcons.check` dentro de `DebtPaymentSheetBody`.
   Un `Key('debtAbonoSubmit')` / `Key('debtUpdateBalanceSubmit')` sería directo.
2. **`DebtCashSwitch` y su fila de cuenta revelada.** El toggle Sí/No se lee hoy
   por la presencia de `DebtSelectedAccountRow`; un `Key('debtCashToggle')` con
   estado semántico legible evitaría inferir el estado por el árbol.
3. **`DebtAmountHeroField`.** Se comparte entre form, hoja de abono y hoja de
   actualizar-saldo; hoy se asume que solo hay uno montado a la vez. Un `Key`
   por contexto (`opening`/`abono`/`nuevoSaldo`) haría el `enterText` explícito.
4. **Estado "saldada" sin distintivo textual.** `DebtBalance.settled` no pinta
   ningún badge "Saldada" — el escenario HU-07 lo verifica indirectamente por
   `$0` + `100%`. Si el diseño espera un sello de "saldada", hoy no existe en
   `lib/` (posible gap de UI a revisar contra Pencil, no solo de test).
5. **Inconsistencia de copy al eliminar una cuota.** La hoja de acciones del
   detalle de PP usa siempre `scheduledDetailActionsDelete` ("Eliminar pago
   programado") aun para una cuota, mientras el link del form de edición sí usa
   `scheduledPaymentInstallmentDeleteAction` ("Eliminar cuota"). La suite borra
   la cuota por el camino del form ("Eliminar cuota"); si se espera que la hoja
   de acciones también diga "Eliminar cuota" para cuotas, es un ajuste de `lib/`.

## Deudas: suite nueva 2026-07-24 — cerrar/completar deuda (extensión HU-07)

`integration_test/debts_lifecycle_patrol_test.dart`, escrita por `qa-automator`
contra el flavor `dev`. Compila (`dart analyze
integration_test/debts_lifecycle_patrol_test.dart` → *No issues found*).
**Ninguno de los 6 escenarios se ha corrido en emulador todavía** — eso es
tarea de `patrol-e2e-runner`; los resultados de la tabla de abajo son los
*esperados*, no confirmados en device.

Ninguno de los escenarios crea una cuenta de efectivo: todos los abonos son
cash-less (`DebtCashSwitch` apagado), porque lo que se ejercita es el ciclo de
vida cerrar/completar, no el movimiento de caja (ya cubierto por
`debts_patrol_test.dart`). Los helpers están deliberadamente duplicados de
`debts_patrol_test.dart` en vez de compartidos — mismo patrón que
`debts_installment_patrol_test.dart`, no existe un módulo de soporte común
para Deudas en este proyecto.

| Escenario | Flujo | Assert principal |
|---|---|---|
| Cerrar manualmente con saldo pendiente | crear deuda → detalle → ⋮ → "Cerrar deuda" → confirmar | sale de "Activas", aparece en "Cerradas" con badge "Cerrada · fecha" (no "Pagada") y el saldo `$600` congelado; DB `closedAt` no nulo, `deletedAt`/`tombstonedAt` nulos |
| Felicitación automática (iOwe) | abono que salda por completo | sheet con "¡Felicidades! Ya no debes nada", stats "Total pagado"/"Duración"; "Completar" cierra la deuda (pasa a "Cerradas" con badge "Pagada · fecha") |
| Felicitación automática (owedToMe) | mismo flujo, dirección "Me deben" | copy distinto: "¡Felicidades! Ya no te deben nada", "Total cobrado" (nunca "Total pagado") |
| "Ahora no" en la felicitación | dismissar en vez de completar | saldo `$0`/`100%` pero la deuda sigue en "Activas" (CTA "Registrar abono" sigue visible); DB `closedAt` nulo |
| Bloqueo de escritura en deuda cerrada | cerrar manualmente → detalle | "Registrar abono" ausente (CTA fija oculta); "Actualizar saldo" visible pero inerte (tocarlo no abre la hoja "Nuevo saldo"); el menú ⋮ sigue ofreciendo Editar/Eliminar |
| Tab "Cerradas" con varias deudas | 2 deudas iOwe cerradas ($200+$300 pagado) + 1 owedToMe cerrada ($250 cobrado) + 1 iOwe activa ($1.000, no debe filtrarse) | `DebtClosedSummaryCard` muestra "Pagué" `$500` y "Me pagaron" `$250`, nunca `$1.000`; DB: 3 deudas con `closedAt`, 1 sin él |

## Deudas: resultado real en device de la corrida 2026-07-24 (patrol-e2e-runner)

> ✅ **RESUELTO** — segunda pasada el mismo día, 32/32 (ver fila "Deudas" arriba). Los 3
> fixes que lo lograron: finder `_openEditForm` portado al menú ⋮ (`qa-automator`),
> nombre de escenario sin `/` (`qa-automator`), y `BottomSheetBase.dismiss(context)`
> para la carrera de hojas modales (`flutter-dev`). Se deja el detalle original abajo
> como registro histórico de la investigación.

Corrida completa contra `emulator-5554` (AVD `Pixel_9a`), flavor `dev`. El emulador se
cerró accidentalmente a mitad de la primera corrida de `debts_patrol_test.dart`; se
relanzó el mismo AVD y las 3 suites se corrieron completas desde cero.

**`debts_patrol_test.dart`: 15/20** (regresión frente al 20/20 confirmado el 2026-07-23).
Los 5 fallos son la MISMA causa: `_openEditForm` (línea 201) sigue usando
`find.byTooltip('Editar deuda')`, pero el header de `debt_detail_page.dart` cambió a un
único ícono `⋮` (`tooltip: l10n.debtMenuTooltip`, "Más opciones") que abre
`DebtActionsSheet` — cambio real de UI de la extensión HU-07 (cerrar/completar deuda),
mismo que `debts_lifecycle_patrol_test.dart` ya usa correctamente vía su propio
`_openActionsMenu`. No es bug de `lib/`: `debts_patrol_test.dart` quedó desactualizado.
Pendiente para `qa-automator`: portar `_openEditForm`/el flujo de eliminar al patrón
`_openActionsMenu` → tap "Editar deuda"/"Eliminar deuda" dentro de la hoja.
Escenarios afectados: HU-05 editar, HU-05 eliminar, item 2b editar+Actualizar,
item 2b editar+Cancelar, item 2b cambiar dirección.

**`debts_installment_patrol_test.dart`: 6/6**, 2m53s, sin novedad.

**`debts_lifecycle_patrol_test.dart`: 2/6 exitosos, 3 fallos, 1 nunca ejecutado.**
- ✅ "cerrar una deuda manualmente con saldo pendiente..." (6s)
- ❌ "felicitación automática al saldar por completo (iOwe)" — `Found 0 widgets with text "¡Felicidades! Ya no debes nada"` en debts_lifecycle_patrol_test.dart:268
- ❌ "felicitación al saldar en dirección Me deben" — mismo patrón, `"¡Felicidades! Ya no te deben nada"` no aparece, línea 315
- ❌ ""Ahora no" en la felicitación..." — mismo patrón, línea 339 (depende de que la felicitación aparezca primero)
- ✅ "una deuda cerrada bloquea Registrar abono y Actualizar saldo" (7s)
- **⚠️ NO EJECUTADO**: "el tab Cerradas con varias deudas suma Pagué/Me pagaron..." —
  `AndroidTestOrchestrator` crasheó (`IllegalArgumentException: ... contains a path
  separator`) porque el nombre del escenario tiene un `/` literal
  (`"Pagué"/"Me pagaron"`), que Android no permite en nombres de archivo de salida del
  test. Bug de infraestructura del harness, no de `lib/`. Pendiente para
  `qa-automator`: renombrar la descripción del escenario para quitar el `/`
  (p.ej. `"Pagué" y "Me pagaron"`), sin tocar el assert.

**Bug real de app, sin confirmar causa raíz — pendiente `flutter-dev`:** el sheet
`DebtCelebrationSheet` nunca se monta en device real tras un abono que salda por
completo, en ninguna de las 3 direcciones probadas, pese a que la lógica de
`DebtDetailCubit._celebrationFor`/`_wasSettled` y el render del sheet en aislado ya
están confirmados por tests de widget/cubit. Sin excepción de Flutter ni crash — la
hoja simplemente no aparece ("0 widgets found"), lo que apunta a un problema de
disparo/timing end-to-end, no de lógica. Hipótesis no confirmada: carrera entre el
`Navigator.pop()` propio de `DebtPaymentSheet` al guardar (`debt_payment_sheet.dart:62`)
y el `DebtCelebrationSheet.show(context)` que dispara casi simultáneamente
`DebtDetailPage._handleSideEffects` (`debt_detail_page.dart:181-188`) sobre el mismo
contexto de detalle — dos hojas modales encadenadas por la misma escritura async, sin
precedente documentado en `docs/dev-runs/*.md`. Bloquea la validación completa de la
felicitación automática (HU-07 extensión) hasta que se resuelva.

**Actualización 2026-07-24 (qa-automator): los 2 problemas de infraestructura ya se
corrigieron, pendiente RE-correr para confirmar.**
- `debts_patrol_test.dart`: `_openEditForm` ahora abre el menú ⋮ (`find.byTooltip('Más
  opciones')` → tap "Editar deuda") antes de tocar el form, portado del patrón de
  `_openActionsMenu` de `debts_lifecycle_patrol_test.dart`. Los dos usos inline
  (`byTooltip('Editar deuda')` en HU-05 editar y HU-05 eliminar) también se movieron a
  este helper. Debería recuperar los 5 escenarios que fallaban.
- `debts_lifecycle_patrol_test.dart`: el nombre del escenario con el `/` literal se
  renombró a `'el tab "Cerradas" con varias deudas suma "Pagué" y "Me pagaron" solo
  sobre las cerradas, nunca sobre la que sigue activa'` (mismo assert, sin tocar
  lógica). Se revisó el resto de `integration_test/` (las 11 suites) por el mismo
  patrón y no se encontró ningún otro `/` literal en nombres de escenario.
- Ninguno de los dos fixes toca `lib/`; el bug real de `DebtCelebrationSheet` descrito
  arriba sigue sin resolver y sigue siendo responsabilidad de `flutter-dev`.
- `dart analyze integration_test/` → *No issues found!* tras el cambio. **Pendiente:**
  `patrol-e2e-runner` debe volver a correr `debts_patrol_test.dart` y
  `debts_lifecycle_patrol_test.dart` completas en device para confirmar que los 5 + 1
  escenarios afectados ahora pasan (el escenario del `/` renombrado sigue sin
  ejecutarse nunca en device real, más allá de compilar).
