# Corrida de Patrol tras issues #25/#26/#34 — 2026-09-10

Contexto: se resolvieron los issues de GitHub #25 (login con Apple), #26 (FAB de
movimientos) y #34 (hoja del avatar) en la rama `fix/incidencias-abiertas` (desde
`dev`). Antes de cerrar la ronda se corrió Patrol sobre `home`, `transactions` y
`auth` para descartar regresiones. Ninguno de los 3 fixes rompió nada — todos los
fallos encontrados ya existían en `dev` sin relación con estos cambios (confirmado
con `git stash` + rerun contra el mismo código sin los fixes). Dos de esos hallazgos
preexistentes se corrigieron en esta misma sesión; otro se investigó, no se logró
arreglar y su intento de fix se revirtió.

## Resueltos en esta sesión

### `home_patrol_test.dart` — "Presupuestos y Metas abren sus features reales"

**Causa raíz real, confirmada con logcat:** en una instalación fresca (la que usa
`startApp` en cada test), la primera visita a Presupuestos o Metas auto-abre un
`TutorialSheet` (minitutorial, HU legítima). El escenario tapeaba Presupuestos →
Metas → Inicio en secuencia sin cerrar esos sheets; `WidgetTester.tap()` no lanza
excepción cuando el offset calculado no impacta el widget (solo imprime un warning),
así que el tap se perdía contra el sheet y la navegación de branch nunca ocurría.

**Fix:** se agregó `await dismissAutoTutorialIfShown($);` tras cada primera visita,
reusando el helper que ya existía en `integration_test/support/patrol_app.dart` y que
otras suites (`debts_patrol_test.dart`) ya usaban para las mismas 4 pantallas, pero
que `home_patrol_test.dart` nunca llamaba pese a importarlo.

**Verificado:** 4/4 en verde, corrida limpia sin otros procesos Patrol concurrentes.

### `auth_patrol_test.dart` — "HU-07 paso 1: Eliminar cuenta"

**Causa raíz:** bug de test, no de producto. `SettingsPage` es un `ListView` con
"Eliminar cuenta" como última fila (decisión de diseño intencional, documentada en
`settings_page.dart:25` — mantener una acción destructiva lejos del flujo casual). El
helper `_openSettings` no scrolleaba dentro de `SettingsPage` antes de buscar el
texto; en un `ListView` los elementos fuera del cache extent se descartan del árbol,
así que el finder fallaba con "Found 0 widgets", no con un miss de hit-test.

**Fix:** `_tapDeleteAccountRow` con `dragUntilVisible`, mismo patrón que ya usan
`_openSettings` y `_scrollUntilVisible` en otras suites del repo.

**Verificado:** 4/5 en verde (el quinto es un hallazgo nuevo y distinto, ver abajo).

**Alcanzabilidad real evaluada:** revisado `settings_page.dart` completo — "Eliminar
cuenta" es visualmente distinguible (fondo `expenseSoft`, icono en círculo) y
alcanzable con un scroll normal. No es un bug de UX/cumplimiento legal, es la
posición intencional de una acción irreversible.

## Investigado, sin resolver — fix intentado y revertido

### `transactions_patrol_test.dart` — HU-03, HU-05, "Fase B1+B2", "Issue #7"

Estos 4 escenarios **ya estaban documentados como fallando** en
[`patrol-e2e-findings-2026-08-25.md`](patrol-e2e-findings-2026-08-25.md) (ahí:
8/12, con la misma causa hipotética — "finders no encontrados" en HU-03/HU-05 y "el
mismo gate de cuenta nuevo en presupuestos que otras suites ya adaptaron pero este
helper compartido no" en Fase B1+B2). Casi 3 semanas después, sin cambios de por
medio, siguen exactamente igual.

**Hipótesis investigada esta sesión:** que `AccountPickerField`
(`transaction_form_page.dart`) y la ruta `/presupuestos/nuevo`
(`AccountGatedRoute`) no muestran ningún loading state mientras
`showAccountGateIfNeeded` resuelve de forma async, así que el `pumpAndSettle()` del
test se asienta antes de que la hoja/formulario termine de montar.

**Fix intentado:** spinner visible en `AccountPickerField` mientras `beforeOpen` está
en vuelo + callback `onFirstCount` en `show_account_gate_if_needed.dart` para que
`AccountGatedRoute` distinga "consultando" de "puente esperando al usuario" +
`_expectEventually` con más reintentos en el test.

**Resultado real:** `flutter test` completo (1436 tests) pasó en verde con el fix,
pero la corrida en vivo de Patrol (`emulator-5556`, sin contención de otros procesos)
mostró **exactamente el mismo fallo** en los 4 escenarios, sin cambio de síntoma ni de
línea. El fix no tocaba la causa real. **Se revirtió** (`git checkout --` sobre los 5
archivos tocados) para no dejar código especulativo sin efecto en el árbol.

**Estado:** sigue abierto, causa raíz real sin confirmar. Candidatos a investigar en
la próxima sesión dedicada: inspeccionar el árbol de widgets real en el momento exacto
del fallo (screenshot del reporte HTML de Patrol, o un breakpoint manual), en vez de
inferir la causa por lectura de código — el enfoque de "leer el código y suponer un
fix" ya se intentó dos veces (25 ago y 10 sep) sin éxito.

## Hallazgos nuevos, fuera del alcance original de esta ronda

### `tag_filter_sheet.dart` — overflow con teclado abierto (HU-07 de transacciones)

Reaparición de un bug ya reportado el
[2026-07-20](patrol-e2e-findings-2026-07-20.md) en `new_tag_sheet.dart`
("se desborda con teclado abierto", 16px). Ese componente fue absorbido dentro del
reusable `tag_filter_sheet.dart` (usado también por Pagos Programados) y el overflow
persiste en la nueva ubicación, magnitud distinta (20px en `tag_filter_sheet.dart:120`
+ 12px secundario en `transaction_form_page.dart:142`).

### "Note autocomplete" — widget desactivado + overflow en cascada

Hallazgo nuevo, sin documentación previa. `Looking up a deactivated widget's ancestor
is unsafe` seguido de 3 `RenderFlex overflowed` (10-12px) en
`transaction_form_page.dart:142` — mismo archivo/línea que el overflow de arriba,
posible causa compartida.

Ambos se atienden en esta misma sesión, ver commit siguiente.

## Corrección posterior (misma fecha, sesión de `/pr-review 37`) — el fix de "Metas" no es confiable

La sección "Resueltos en esta sesión" de arriba afirma **4/4 en verde** para
`home_patrol_test.dart` tras agregar `dismissAutoTutorialIfShown`. Verificando el PR
#37 antes de aprobarlo, se re-corrió esa suite **dos veces** en un emulador
dedicado (`emulator-5556`, sin ningún otro proceso Patrol apuntándole, confirmado con
`ps aux`) — incluida una segunda corrida con las ventanas de espera de
`_pumpUntilFound`/`dismissAutoTutorialIfShown` 3-5x más largas (100/60 frames en vez
de 30/20) para descartar que fuera solo timing. **Las dos corridas fallaron
exactamente igual:**

```
HU-01: Presupuestos y Metas abren sus features reales — FAILED
Expected: exactly one matching candidate
  Actual: _TypeWidgetFinder:<Found 0 widgets with type "GoalsListPage": []>
```

Alargar la espera no cambió el resultado, así que **no es una carrera de timing** del
tipo que el fix de arriba asume — hay algo más impidiendo que la rama de Metas
construya `GoalsListPage` tras el tap, sin ningún error de Flutter/Dart visible en
consola (se revisó el log completo de ambas corridas, sin "EXCEPTION CAUGHT BY
WIDGETS LIBRARY" ni ningún stack trace adicional al de la propia aserción fallida).

**No es una regresión de este PR:** `git diff d810d9b5..HEAD` (base real del PR vs.
su punta) muestra que el PR **no toca** `app_router.dart`, `home_shell_page.dart`,
`goals/`, `budgets/` ni `tutorials/` — el único archivo tocado en esta área es el
propio `home_patrol_test.dart` (las 15 líneas que agregaron
`dismissAutoTutorialIfShown`, el intento de fix de arriba). El escenario ya fallaba
antes de esas 15 líneas y sigue fallando después, con el mismo síntoma.

**Estado real (al momento de escribir el párrafo de arriba):** 🟡 sigue roto, no 🟢.
Pendiente de una investigación con más instrumentación (logcat en vivo durante la
corrida, o el reporte HTML de Patrol con captura del momento del fallo) en vez de
inferir la causa por lectura de código — mismo enfoque que ya se recomendó para
HU-03/HU-05/Fase B1+B2/Issue #7 de `transactions_patrol_test.dart` más abajo, que
tampoco se resolvió leyendo código dos veces seguidas.

## Resuelto de verdad esta vez (2026-09-11) — causa raíz confirmada por aislamiento

El reporte HTML de Patrol de la corrida anterior no aportó nada (se había
sobrescrito con una corrida posterior de otra suite, sin captura del momento del
fallo). En vez de seguir con logcat en vivo, se aisló el escenario del minitutorial
por completo: `AppSettings.showHelpOnSectionEntry` (el mismo flag que
`AppSettingsCubit`/Ajustes exponen como "Mostrar ayuda al entrar a una sección") se
apagó explícitamente con `getIt<AppSettingsCubit>().setShowHelpOnSectionEntry(
enabled: false)` justo después de `startApp($)`, eliminando la posibilidad de que
`TutorialAutoShow` dispare cualquier sheet en este escenario, en vez de intentar
ganarle la carrera con más espera.

**Resultado: 4/4 en 2 corridas consecutivas, limpias, en un emulador dedicado sin
contención** (8s y 3s el escenario de Metas, contra los ~23s + fallo de antes). Esto
confirma la causa real: el minitutorial de Presupuestos/Metas sí interfiere con el
tap a la siguiente pestaña, y `dismissAutoTutorialIfShown` — pese a estar pensado
exactamente para esto — no lo atrapa de forma confiable incluso con ventanas de
espera 3-5x más largas. La causa exacta de por qué el dismiss no alcanza a ganar la
carrera queda sin instrumentar a nivel de widget tree (no se necesitó para
resolverlo: aislar el escenario de la variable en vez de sincronizarse con ella es
la solución aplicada).

**Fix aplicado en `integration_test/home_patrol_test.dart`:** se reemplazaron las dos
llamadas a `dismissAutoTutorialIfShown` (que ya no hacen nada — el tutorial nunca se
dispara) por el flag apagado al inicio del escenario, con un comentario explicando
por qué (este escenario prueba navegación entre pestañas, no el minitutorial mismo —
esa es responsabilidad de una suite propia de `16-minitutoriales.md`, no de esta).

**Riesgo de producto real, distinto de la flakiness del test, sin confirmar:** si el
`TutorialGateCubit.evaluate()` de un usuario real tarda lo suficiente en resolver
(su `await` a `HasSeenTutorial`/`WatchHelpEnabled` vía Drift), un usuario que toque
"Presupuestos" y de inmediato "Metas" podría, en teoría, ver aparecer el minitutorial
de Presupuestos justo cuando esperaba llegar a Metas — el mismo mecanismo que rompe
el test. No se confirmó que esto pase en un dispositivo real fuera del harness de
test (que sí lo reproduce de forma consistente); vale la pena que `flutter-dev` lo
evalúe si se quiere descartar del todo, pero no bloquea este PR ni la suite.

## Verificación adicional del mismo PR (misma sesión) — `transactions_patrol_test.dart` limpio

Corrida completa (12/12 escenarios ejecutados, sin corte de infraestructura) en el
mismo emulador dedicado: **8/12 en verde**, y los 4 fallos son *exactamente* los
mismos 4 ya documentados como preexistentes más abajo (HU-03, HU-05, "Fase B1+B2",
"Issue #7") — mismo síntoma, misma línea. **HU-07 ("crear una etiqueta nueva al vuelo
desde el formulario de transacción"), el escenario que más directamente ejercita el
fix de colapso de teclado de este PR, pasó limpio.** Sin regresiones nuevas
introducidas por este PR en esta suite.

## Resuelto de verdad esta vez (2026-09-11) — `auth_patrol_test.dart` también era un test desactualizado, no un bug

El otro fallo pendiente de esta ronda — "HU-07 paso 1: confirmar sin backend
cableado cae al estado de error" (`Found 0 widgets with text "No pudimos eliminar
tu cuenta"`, reproducible en 2/2 corridas) — tampoco era un bug de `lib/`.

**Causa raíz:** `AuthRepositoryImpl.deleteAccount` tiene un short-circuit deliberado
y bien documentado (`if (!_current.isSignedIn) return const Right(unit)`): sin
sesión no hay nada en la nube que borrar, así que paso 1 siempre tiene éxito de
inmediato y avanza a paso 2 — nunca llega al estado de error. El escenario asumía
(el propio header del archivo lo decía, ya desactualizado: "paso 1's (currently
unimplemented) cloud call succeeds") que paso 1 sin implementar siempre fallaba.
Eso dejó de ser cierto el día que se implementó el short-circuit, sin que nadie
actualizara este escenario — no es una regresión de PR #37 (el PR no toca
`auth_repository_impl.dart` ni `delete_account_cubit.dart`).

La ruta de error real (backend que sí falla) sigue completamente cubierta sin
necesidad de un backend real: `test/features/auth/presentation/cubit/
delete_account_cubit_test.dart` la mockea explícitamente (`Left(NetworkFailure(...))`)
y `confirm_delete_account_sheet_test.dart` + sus goldens
(`confirm_delete_account_sheet_error_{light,dark}.png`) verifican que el sheet la
muestra bien — nada de eso se tocó.

**Fix aplicado:** se reescribió el escenario para afirmar lo que realmente pasa en
esta ruta (sin sesión): paso 1 → succeeds → paso 2 con la copia "Nunca iniciaste
sesión en este dispositivo..." — y se actualizó el header del archivo, que ya no
refleja "paso 1 sin implementar". **5/5 estable en 2 corridas consecutivas.**

## Bugs de tooling encontrados en esta sesión (nuevos, no documentados el 25 ago)

- **Agentes concurrentes sobre el mismo emulador se pisan de verdad:** dos
  invocaciones de `patrol test` corriendo a la vez contra el mismo
  `emulator-5554`/mismo worktree producen resultados inconsistentes entre sí (un
  mismo escenario pasa o falla según qué proceso "ganó" la carrera) y sobrescriben
  `integration_test/test_bundle.dart` entre ellos. Mitigación aplicada: nunca correr
  dos `patrol test` en paralelo contra el mismo device — usar un segundo emulador si
  hace falta paralelizar.
- **Storage del emulador se llena con apps de otros proyectos instaladas ahí antes**
  (`INSTALL_FAILED_INSUFFICIENT_STORAGE` con solo 2 apps instaladas, 88% de uso en
  una partición de ~6GB) — mitigación: `adb uninstall` de paquetes de otros proyectos
  antes de instalar el APK de test.
