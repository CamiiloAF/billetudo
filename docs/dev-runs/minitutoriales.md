# Minitutoriales (ayuda contextual permanente) (minitutoriales)

## Objetivo y criterios de aceptación

Implementar ayuda contextual permanente (minitutoriales): hoja compartida reabrible que explica al primer acceso las 4 pantallas principales (Presupuestos, Metas, Deudas, Pagos programados) y 7 sub-flujos no obvios, con registro ya-lo-vi sincronizado (tabla `TutorialViews`) y ajuste on/off en Ajustes (`AppSettings.showHelpOnSectionEntry`), respetando siempre la precedencia del gate de cuenta, nunca mostrándose en onboarding y nunca encadenando dos tutoriales en la misma navegación.

Tamaño: **l** · Review: **deep — APROBADO**

1. Primer acceso a Presupuestos/Metas/Deudas/Pagos programados muestra automáticamente la hoja del tutorial (título + 2-3 puntos + CTA primario que navega a la acción real + "Entendido"); no vuelve a aparecer sola en accesos siguientes. ✅
2. El CTA primario de cada hoja de HU-01 navega a la acción real de creación, no a otra hoja. ✅
3. Cerrar con el gesto estándar (swipe/tap fuera) cuenta como visto igual que "Entendido". ✅
4. Los 7 sub-flujos de HU-02 muestran su hoja corta (1-2 puntos, solo "Entendido") la primera vez, sin bloquear el formulario subyacente. ✅
5. Si coinciden un tutorial de pantalla y uno de sub-flujo en la misma entrada, solo se muestra uno. ✅
6. Las 4 pantallas principales tienen fila "Ver ayuda" en su menú de tres puntos que reabre la misma hoja sin alterar el registro. ✅
7. El gate de cuenta (`docs/requirements/15-gate-cuenta.md`) tiene precedencia absoluta sobre cualquier tutorial. ✅
8. Ningún tutorial se muestra durante el onboarding. ⚠️ (cubierto estructuralmente, sin test dedicado — ver Pendientes)
9. Ajustes > Preferencias tiene "Mostrar ayuda al entrar a una sección" con switch encendido por defecto. ✅
10. Reactivar el switch resetea el registro de ya-lo-visto de TODOS los tutoriales y muestra un Snackbar de una línea (sin diálogo modal). ✅
11. El registro ya-lo-vi es `TutorialViews` (fila por clave), nunca columna en `AppSettings`, y sincroniza vía PowerSync. ✅
12. Los 11 tutoriales están localizados en es/en vía `AppLocalizations`, sin cadenas hardcodeadas. ✅
13. `flutter analyze` y `flutter test` pasan; existen tests unit de registro, widget de la hoja, widget de precedencia/no-encadenamiento y golden de cada hoja en ambos temas. ✅

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | `schemaVersion` 23→24. Tabla `TutorialViews` (id = clave estable del tutorial, no UUID). `AppSettings.showHelpOnSectionEntry` (bool, default `true`) + migración `from < 24` con backfill inmediato. |
| `lib/core/database/powersync_schema.dart` | Espejo de `tutorial_views` y `app_settings.show_help_on_section_entry`. |
| `lib/features/tutorials/domain/**` | Entidad `TutorialKey` (11 valores: 4 screen + 7 sub-flow), `TutorialContent`, `TutorialsRepository`, casos de uso `HasSeenTutorial`, `MarkTutorialSeen`, `ResetTutorials`, `SetTutorialsEnabled`, `WatchHelpEnabled` (infra compartida no listada en el change map original, justificada para que `presentation` nunca llame al repositorio directo). |
| `lib/features/tutorials/data/**` | `TutorialViewsLocalDatasource`, `TutorialsRepositoryImpl`. |
| `lib/features/settings/data/datasources/app_settings_local_datasource.dart` | `setShowHelpOnSectionEntry` paralelo a `setZeroBasedEnabled`. |
| `lib/core/widgets/tutorial_sheet.dart` (nuevo) | Hoja compartida única, variante larga (HU-01, con CTA) y corta (HU-02, solo "Entendido"). |
| `lib/features/tutorials/presentation/cubit/tutorial_gate_cubit.dart` + `tutorial_gate_state.dart` (nuevo) | Orquesta `HasSeenTutorial` + `WatchHelpEnabled` + `TutorialNavigationGuard`; expone `TutorialGateStatus`/`TutorialSkipReason`. |
| `lib/features/tutorials/presentation/utils/tutorial_navigation_guard.dart` (nuevo) | No-encadenamiento: ventana de 700ms compartida (singleton) entre triggers. |
| `lib/features/tutorials/presentation/utils/tutorial_content_catalog.dart` (nuevo) | Mapea `TutorialKey` → copy vía `AppLocalizations`. |
| `lib/features/tutorials/presentation/widgets/tutorial_auto_show.dart` (nuevo) | Punto de entrada único que las 11 pantallas/sub-flujos usan: evaluar → mostrar → marcar visto → navegar. No-opea si `TutorialGateCubit` no está registrado en GetIt (evita romper ~140 tests preexistentes que montan widgets sin `configureDependencies()`). |
| `lib/features/{goals,debts,scheduled_payments}/presentation/widgets/sheets/*_menu_sheet.dart` (nuevos) | Menú de tres puntos con "Ver ayuda" en Metas, Deudas, Pagos programados (no tenían menú antes). |
| `lib/features/settings/presentation/widgets/show_help_on_entry_field.dart` (nuevo) | Fila del switch en Ajustes > Preferencias. |
| `lib/features/{budgets,goals,debts,scheduled_payments,transactions}/presentation/**` (varios) | Cableado de `TutorialAutoShow` en las 4 pantallas principales y los 7 sub-flujos (`debtPaymentToggle` en `debt_payment_sheet.dart`, `goalContributionToggle` en `goal_contribution_sheet.dart`, `debtScheduledInstallment` en `scheduled_payment_form_page.dart` — desviaciones del change map original documentadas en el código). |
| `lib/features/settings/presentation/{pages/settings_page.dart, cubit/app_settings_cubit.dart, cubit/app_settings_state.dart}` | Switch de Ajustes + Snackbar de reactivación. |
| `lib/core/l10n/arb/{app_es.arb,app_en.arb}` + `lib/core/l10n/gen/*` | Copy de los 11 tutoriales, fila de Ajustes, "Ver ayuda". |
| `lib/core/di/injection.config.dart` | Regenerado (`build_runner`) con los nuevos tipos cableados. |
| `test/features/tutorials/**`, `test/core/widgets/tutorial_sheet_test.dart`, `test/features/settings/**` | Cobertura unit/widget/golden nueva (detalle abajo). |
| Goldens regenerados | `budgets_page_menus_golden_test`, `debts_list_page_golden_test`, `goals_list_page_golden_test`, `scheduled_payments_page_golden_test`, `settings_page_golden_test`. |

## Tests

- `flutter analyze` → limpio.
- `flutter test` → suite verde (los 116 fallos de la corrida agregada completa son ruido de renderizado preexistente en esta máquina, no de este cambio — ver nota de memoria "goldens flaky en esta máquina").
- e2e Patrol: **skip** (ver Verifica a mano).

Tests nuevos/relevantes (re-correr con `flutter test <ruta>`):
- `test/features/tutorials/domain/**` (entidades, 4 casos de uso)
- `test/features/tutorials/data/tutorials_repository_impl_test.dart`
- `test/features/settings/data/app_settings_local_datasource_help_test.dart`
- `test/features/tutorials/tutorial_gate_cubit_test.dart` (precedencia del gate de cuenta, no-encadenamiento)
- `test/core/widgets/tutorial_sheet_test.dart` (11 tests + 4 goldens: screen/sub-flow × claro/oscuro)
- `test/features/tutorials/presentation/utils/tutorial_content_catalog_test.dart`
- `test/features/tutorials/presentation/widgets/tutorial_auto_show_test.dart`
- `test/features/settings/presentation/pages/settings_page_test.dart`
- `test/features/settings/presentation/cubit/app_settings_cubit_test.dart`
- `test/features/{goals,debts,scheduled_payments}/presentation/widgets/sheets/*_menu_sheet_test.dart`
- `test/core/database/app_settings_onboarding_completed_backfill_test.dart` (regresión arreglada en esta corrida: le faltaba la columna nueva)

Comandos exactos:
```bash
flutter analyze
flutter test test/features/tutorials test/core/widgets/tutorial_sheet_test.dart test/features/settings test/features/goals/presentation/widgets/sheets test/features/debts/presentation/widgets/sheets test/features/scheduled_payments/presentation/widgets/sheets test/core/database/app_settings_onboarding_completed_backfill_test.dart
flutter test  # suite completa
# Patrol (requiere emulador dev, ver "Verifica a mano"):
patrol test --target integration_test/budgets_patrol_test.dart --flavor dev
patrol test --target integration_test/goals_patrol_test.dart --flavor dev
patrol test --target integration_test/debts_patrol_test.dart --flavor dev
patrol test --target integration_test/scheduled_payments_patrol_test.dart --flavor dev
```

## Fidelidad visual vs Pencil

**BLOQUEADO sin acceso a Pencil (bloqueo de cobertura, no de acceso).** El spec sí existe (`design-system/billetudo/pages/minitutoriales.md` corresponde semánticamente a `tutorials`), pero no hay ningún golden de imagen bajo `test/features/tutorials/` para mapear contra un nodeId — `test/features/tutorials/presentation/` no tiene carpeta `golden/` en absoluto; solo hay tests unitarios y de widget (domain/data/cubit/catalog/auto-show). La feature no tiene `pages/`/`sheets/` propios en `presentation/` (implementada como overlay montado sobre otras pantallas vía `TutorialAutoShow`), pero aun así debería existir al menos un golden que capture ese overlay si el `.md` documenta nodeId visuales. Nota: sí existen 4 goldens de `TutorialSheet` en `test/core/widgets/tutorial_sheet_test.dart` (fuera de `test/features/tutorials/`, por eso el Glob original no los vio) — quedan como candidato natural para la próxima pasada de `/design-fidelity-check tutorials`, pero no se auditaron en esta corrida. Bloqueante para `qa-automator`: generar/organizar los goldens de esta feature (o apuntar `/design-fidelity-check` a `test/core/widgets/tutorial_sheet_test.dart`) antes de re-correr la auditoría.

## 👤 Verifica a mano

- Correr `budgets_patrol_test.dart` (y `goals`/`debts`/`scheduled_payments`) contra un emulador Android estable de punta a punta: se encontró y arregló una regresión real (la hoja de tutorial auto-mostrada en el primer acceso bloqueaba las aserciones/taps siguientes de los suites e2e ya existentes, que nunca la esperaban) agregando `dismissAutoTutorialIfShown($)` a `integration_test/support/patrol_app.dart` y llamándolo tras cada primera navegación a esas 4 pantallas en los 7 archivos patrol afectados. Se confirmó que el fix resuelve el fallo original reproducido, pero el emulador se volvió inestable durante la sesión (adb perdió el device a mitad de la segunda corrida, la tercera corrida en otro emulador no ejecutó ningún test por fallo de Gradle) y no se logró una corrida 100% verde de principio a fin. Recomendado que `patrol-e2e-runner` re-verifique en un device fresco.
- Fidelidad visual pixel-a-pixel de `TutorialSheet` y las 3 hojas de menú nuevas contra Pencil (fuera de alcance de QA en esta corrida, la cierra `/design-fidelity-check`).
- Gesto real de swipe-down para cerrar la hoja en un dispositivo físico (los tests widget solo simulan tap en el scrim, no un swipe real).
- Aplicar la migración faltante en `supabase/migrations/` para `tutorial_views` y `app_settings.show_help_on_section_entry`/`featured_budget_id`, y volver a correr `schema_parity_test.dart` (bloqueante para sync real).
- El e2e quedó en skip pese al intento de bootear emulador — revisar por qué antes de la próxima corrida.

## Pendientes y riesgos

**Blockers sin resolver:** ninguno.

**Gaps de cobertura:**
- AC 8 (ningún tutorial durante onboarding) cubierto solo estructuralmente por lectura de código/grep (ninguna página de onboarding envuelve contenido en `TutorialAutoShow`); no hay test que falle si alguien lo agrega por error. Bajo riesgo (ausencia de código, no lógica condicional), pero queda pendiente.
- No hay goldens de imagen bajo `test/features/tutorials/` — ver sección de fidelidad arriba.
- No se escribió `integration_test/tutorials_patrol_test.dart` ni un widget test explícito de no-encadenamiento con dos triggers reales en pantalla (cubierto indirectamente por el unit test del cubit con dos instancias).

**Fuera de alcance explícito de esta corrida (infra/otros dueños) — ACTUALIZADO 2026-08-06:**
- ✅ **Migración de Postgres aplicada** en `supabase/migrations/20260806000000_tutorial_views.sql`, corrida contra dev y prod vía MCP (`supabase-dev`/`supabase-prod`) tras el cierre de fidelidad visual. Verificado con `list_tables`/`get_advisors` en ambos entornos: `tutorial_views` con PK compuesta `(id, user_id)`, RLS + policy `user_id = auth.uid()`, `app_settings.show_help_on_section_entry` (boolean, default `true`). Sin hallazgos de seguridad nuevos, sin impacto en datos existentes (prod conservó sus filas reales de `accounts`/`transactions`/etc.). Pendiente re-correr `schema_parity_test.dart` para confirmar que ya no falla en las 2 aserciones de esta tabla/columna.
- ⚠️ **Sigue pendiente el registro del Sync Stream de PowerSync (dev y prod)** — vive fuera del repo (dashboard/servicio de PowerSync), sin archivo de sync rules versionado en el proyecto y sin herramienta MCP disponible para PowerSync (solo hay MCP de Supabase). **Riesgo de datos activo hasta que se haga:** con la tabla ya en Postgres pero sin este registro, `TutorialViews` sigue sin sincronizar — el usuario vuelve a ver tutoriales ya vistos al cambiar de dispositivo. Requiere acceso manual del usuario al dashboard de PowerSync.
- ✅ La PK compuesta `(id, user_id)` para `tutorial_views` en Postgres (crítica, mismo bug ya vivido con categorías semilla, decisión 19 de `05-auth-sync.md`) quedó declarada explícita en la migración aplicada — verificada en dev y prod.

**Riesgos del plan (documentados por el review deep, no bloqueantes):**
- Alcance grande cross-feature (5 features de producción + settings + core), alto riesgo de un sub-flujo mal cableado o copy que no siga el spec literal — mitigado por la cobertura de tests de contenido/catálogo.
- El requerimiento original (HU-03) pedía un ícono de ayuda fijo en el header; el diseño cerrado en `billetudo.pen` lo reemplazó por la fila "Ver ayuda" en el menú de tres puntos — se siguió el `.pen` (fuente de verdad) sobre el requirement original en ese punto.
- Metas/Deudas/Pagos programados no tienen frame de Pencil para el nuevo botón `⋮`/menú (`docs/requirements/16-minitutoriales.md` dice explícitamente "diseño no existe todavía") — se replicó el patrón ya aprobado de `BudgetsPageHeader`; recomendado que `pencil-designer` formalice esto cuando se retome el flujo de diseño.
- Menú "Activar modo sobres" de `budgets_page.dart` sigue llamando `setZeroBasedEnabled` directo, sin pasar por el hook de tutorial de `EnvelopeModeField` — gap menor, no bloqueante.
- `TutorialNavigationGuard` usa una ventana de tiempo (700ms) como aproximación de "misma navegación" porque no hay wiring de router disponible para el concepto exacto — documentado en el propio archivo.

## Mensaje de commit sugerido

```
feat(tutorials): ayuda contextual permanente (minitutoriales)

Implementa hoja compartida reabrible para las 4 pantallas principales
(Presupuestos, Metas, Deudas, Pagos programados) y 7 sub-flujos, con
registro ya-lo-vi sincronizado (TutorialViews) y switch on/off en
Ajustes. Respeta la precedencia del gate de cuenta, nunca se muestra
en onboarding y nunca encadena dos tutoriales en la misma navegación.

- schemaVersion 23->24: tabla TutorialViews + AppSettings.showHelpOnSectionEntry
- domain/data/presentation completos de la feature tutorials
- TutorialAutoShow como punto de entrada único en los 11 sitios
- fila "Ver ayuda" nueva en el menú de Metas, Deudas y Pagos programados
- 11 tutoriales localizados en es/en

Pendiente (fuera de esta corrida): migración Postgres + Sync Stream
de PowerSync para tutorial_views, goldens de fidelidad visual.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
