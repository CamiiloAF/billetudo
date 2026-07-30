# Onboarding: flujo de bienvenida (onboarding)

## Objetivo y criterios de aceptación

Implementar `lib/features/onboarding/` (Clean Architecture completa) contra el spec cerrado en
`docs/requirements/13-onboarding.md` y el diseño aprobado (claro+oscuro) en `billetudo.pen` /
`design-system/billetudo/pages/onboarding.md`: un flujo lineal de 4 pantallas (Bienvenida, Tu
primera cuenta, Respalda tus datos, Cierre) que corre una sola vez, se cierra para siempre con el
latch `AppSettings.onboardingCompleted`, es 100% completable offline y sin cuenta, y reusa (no
duplica) `CreateAccount`, el flujo real de transacción y la pantalla de login social existente.

Criterios de aceptación (derivados de HU-01, HU-02, HU-03 sin pantalla, HU-04, HU-06, HU-07;
HU-05 congelada fuera de alcance):

1. Latch `AppSettings.onboardingCompleted` (bool, `clientDefault false`), `schemaVersion` 20→21,
   migración Drift + `powersync_schema.dart` + Postgres dev y prod.
2. Sin cuentas activas y latch apagado → entra a `/bienvenida`; con latch encendido → Home directo.
   Evaluado una sola vez por arranque, tras el bootstrap.
3. Con al menos una cuenta activa ya existente → el latch se enciende en silencio, sin mostrar el
   flujo.
4. Bienvenida: una sola pantalla, "Nivel 0 completo y gratis para siempre", datos en el
   dispositivo, mención de categorías ya sembradas, enlace "Ya tengo cuenta".
5. Tu primera cuenta: reusa `CreateAccount`/`AccountFormCubit` real (mismas validaciones, sin
   relajar reglas de tarjeta), pre-llenado nombre "Ahorros" localizado / tipo `savings` / moneda
   por región del locale (fallback USD) / saldo 0, todo editable; "Listo" crea, "Omitir" avanza
   sin crear nada; 100% offline.
6. Respalda tus datos: informativa, "Activar respaldo" (login social existente) o "Después"; se
   omite si el usuario ya se autenticó vía "Ya tengo cuenta".
7. Cierre: si hay cuenta creada, el CTA abre el flujo real de transacción; si se omitió, el CTA
   cambia a "crear cuenta" (bridge local, sin depender de `15-gate-cuenta.md` que aún no existe).
   El latch se enciende al actuar en esta pantalla (registrar, saltar u omitir), no al crear
   cuenta.
8. "Ya tengo cuenta" (HU-06): enlace secundario, nunca acción principal; login exitoso corre la
   fusión existente y cierra el onboarding; cancelar/fallar vuelve al paso donde estaba.
9. Interrupción a mitad de flujo: el latch sigue apagado, el flujo reinicia, la cuenta ya creada
   se conserva y el paso 2 la refleja (no re-ofrece el default ni duplica).
10. Navegación: única ruta accesible mientras el flujo está activo; atrás del sistema en el primer
    paso minimiza la app; sin deep links.
11. HU-03: sin pantalla propia, solo mención de una línea.
12. HU-05: no aparece en ninguna pantalla (congelada).
13. Toda fila creada es un dato normal (UUID, centavos, `updatedAt`), sin marca de "onboarding".
14. Todo el texto viene de `AppLocalizations` (es + en).
15. Flujo completo 100% offline y sin cuenta.
16. Golden tests de las 6 pantallas/variantes en claro y oscuro.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | `AppSettings.onboardingCompleted` (bool), `schemaVersion` 20→21, migración `onUpgrade` |
| `lib/core/database/powersync_schema.dart` | Columna `onboarding_completed` en `app_settings` |
| `supabase/migrations/20260729000000_app_settings_onboarding_completed.sql` | Migración versionada (idempotente, ya aplicada en vivo a dev y prod vía MCP durante el desarrollo) |
| `test/core/database/fixtures/postgres_schema.json` | Snapshot actualizado para `schema_parity_test.dart` |
| `lib/features/settings/domain/**`, `data/**` | Latch `onboardingCompleted`: entidad, `AppSettingsRepository.markOnboardingCompleted()`, `SetOnboardingCompleted`, datasource + repo impl |
| `lib/features/onboarding/domain/**` | `OnboardingStep`, `OnboardingProgress`, `ResolveDefaultCurrencyForLocale` (CO→COP, resto→USD, acotado a lo que soporta hoy el picker de Cuentas), `ShouldShowOnboarding`, `CompleteOnboarding` |
| `lib/features/onboarding/presentation/**` | `OnboardingFlowCubit` + 4 páginas (`WelcomePage`, `FirstAccountPage`, `BackupIntroPage`, `ClosingPage`) + widgets propios (`OnboardingScaffold`, `OnboardingTopBar`, `OnboardingProgressDot`, `OnboardingSecondaryLink`, `OnboardingStatusBadge`, `OnboardingWalletCard`/`OnboardingWalletFan`/`OnboardingWalletFanCard`) |
| `lib/features/accounts/presentation/widgets/account_type_row.dart`, `.../sheets/account_type_picker_sheet.dart` | Extraídos de `AccountFormPage` para reusarlos en la variante compacta de Onboarding sin duplicar el selector de tipo |
| `lib/core/router/app_router.dart` | Rutas `/bienvenida`, `/bienvenida/cuenta`, `/bienvenida/respaldo`, `/bienvenida/cierre`, `/bienvenida/iniciar-sesion(/fusion)`, fuera del shell de tabs; **fix real**: `_startedOnboardingAccountForm` llamaba `AppLocalizations.of(context)` dentro de un `BlocProvider.create` (prohibido por Flutter, crasheaba en device real) — el nombre localizado ahora se resuelve en el `builder` del `GoRoute` y se pasa como parámetro; y ahora consulta `AccountRepository.watchActiveAccounts()` para reflejar una cuenta ya creada en un intento anterior (interrupción a mitad, AC 9) en vez de re-ofrecer siempre el default |
| `lib/core/bootstrap.dart` | Evalúa `ShouldShowOnboarding` una sola vez tras el bootstrap, fija `initialLocation` |
| `lib/app.dart` | Wiring del `initialLocation` resuelto por bootstrap |
| `lib/core/l10n/arb/app_{es,en}.arb` | Strings nuevos de las 4 pantallas |
| `test/features/onboarding/**` | Unit (casos de uso), cubit, widget (4 páginas), golden (12 goldens) |
| `test/features/settings/**` | Tests del latch nuevo |
| `test/features/{budgets,categories}/**`, `test/features/auth/tier0_test.dart` | Ajustados por el campo `onboardingCompleted` nuevo/requerido en `AppSettings(...)` |
| `integration_test/onboarding_patrol_test.dart`, `integration_test/support/patrol_app.dart` (`startOnboardingApp`) | Patrol e2e de los 2 caminos automatizables |
| `docs/patrol-e2e-tracking.md`, `docs/fidelidad-visual-tracking.md` | Filas de Onboarding agregadas |

## Tests

```
flutter analyze                                    # 0 issues
flutter test test/features/onboarding               # 37 unit/widget + 12 golden, todos verdes
flutter test test/features/settings                 # verde (latch nuevo)
flutter test test/core/router                        # verde (incluye el fix del router)
flutter test test/core/database/schema_parity_test.dart  # verde (fixture ya refleja onboarding_completed)
```

Suite completa del repo: sin fallos nuevos atribuibles a esta corrida. Quedan ~213 goldens
preexistentes con diffs de píxel 0.2-0.4% en `transactions`/`categories`/`scheduled_payments`/
`debts`/`budgets`/`accounts`/`auth`/`core/sync`/`settings` — ruido ya documentado en memoria del
proyecto ("goldens flaky en esta máquina"), ninguno toca `onboarding`, `settings` (latch) ni
`core/router`.

Patrol e2e (flavor `dev`, nunca `prod`):

```
patrol test --target integration_test/onboarding_patrol_test.dart --flavor dev --dart-define-from-file=.env.dev -d emulator-5554
```

- **(a) primer arranque creando la cuenta pre-llenada → registrar primer movimiento → Inicio**: ✅ pass
- **(b) primer arranque omitiendo la cuenta → Inicio con CTA de cierre cambiado a "crear cuenta"**: ✅ pass
- **(c) "Ya tengo cuenta" → login → onboarding cerrado**: ⏩ skip intencional, documentado en el propio test — requiere un round-trip OAuth real (Google/Apple) que Patrol no puede automatizar en este entorno, mismo patrón que `auth_patrol_test.dart`. Cubierto a nivel unit sin backend real por `onboarding_flow_cubit_test.dart`.

Esta suite destapó un bug real durante la primera corrida (crash de `_startedOnboardingAccountForm`
en el router, ver tabla de arriba) — corregido y reverificado 2/2 estable en la corrida formal
posterior.

## Review

- **Convenciones críticas** (`finance-code-reviewer`): aprobado, sin blockers.
- **Convenciones de UI** (`ui-convention-reviewer`): aprobado, sin blockers — las 3 reglas
  (`avoid_widget_functions`, `avoid_private_widgets`, `avoid_hardcoded_ui_strings`) se cumplen en
  los 17 archivos de `presentation/` revisados.
- **Compliance Nivel 0** (`compliance-reviewer`): aprobado, sin blockers. Observación no
  bloqueante: como "Ya tengo cuenta" solo vive en `WelcomePage` (no también en el paso de cuenta),
  la rama "autenticado pero con `closesFlow:false`" de `OnboardingFlowCubit.authenticated()` no se
  ejercita hoy en el flujo real — vale un test dedicado si en el futuro se agrega ese enlace también
  al paso 2.

## Fidelidad visual vs Pencil

**Bloqueada por herramienta, no por hallazgos.** Los 12 goldens están generados; el `.md` del spec
existe y mapea las 6 pantallas a sus nodeId. Pero en esta sesión el editor de Pencil no tenía
ningún `.pen` abierto (`get_app_state`/`get_screenshot`/`execute` fallaron con "A file needs to be
open in the editor" incluso pasando `filePath` explícito al worktree), y no existe una herramienta
MCP para abrir un archivo — requiere que la app de escritorio Pencil tenga
`billetudo-onboarding/billetudo.pen` cargado primero.

**Pendiente:** abrir `billetudo.pen` de este worktree en Pencil y re-correr
`/design-fidelity-check onboarding`. Ver fila "Onboarding" en `docs/fidelidad-visual-tracking.md`
(estado `❌ Sin auditar`) para el detalle.

## 👤 Verifica a mano

- Gestos de "atrás del sistema" en Android real en el primer paso (`PopScope` de `WelcomePage`
  debe minimizar la app, no dejar un Home a medias) — solo verificable en device físico/gesto real.
- El camino HU-06/HU-07 de login real (Google/Apple) de punta a punta, incluida la fusión de datos
  — Patrol no puede automatizarlo (round-trip OAuth interactivo).
- Fidelidad visual contra Pencil (bloqueada esta corrida, ver sección arriba) — re-correr
  `/design-fidelity-check onboarding` con el `.pen` abierto en el editor.
- Confirmar visualmente en un device real que la animación del `OnboardingWalletCard`/
  `OnboardingWalletFan` (hero/shared-element, sin precedente previo en el repo) se ve fluida — los
  golden tests no capturan animación.

## Pendientes y riesgos

- **Fidelidad visual sin cerrar** (bloqueo de tooling, ver arriba) — no es una divergencia
  detectada, es ausencia de verificación.
- **`15-gate-cuenta.md` no implementado todavía**: el CTA de "crear cuenta" en el paso de Cierre
  cuando se omitió la cuenta es un bridge local al cubit de Onboarding (copy autocontenido, igual
  al frame `bAKS6`/`ld3xh` de Pencil), no el widget puente compartido que describe ese documento
  hermano. Cuando `15-gate-cuenta.md` se implemente, converger a ese widget compartido en vez de
  mantener dos implementaciones — anotado como comentario en el propio código.
- **Moneda del onboarding acotada a COP/USD** (no la tabla completa de `13-onboarding.md`:
  CO/MX/AR/CL/PE/ES/US), porque el selector de Cuentas hoy solo soporta esas dos monedas
  (`AccountFormState.supportedCurrencies`). Ampliar el picker de Cuentas es trabajo aparte, fuera
  de esta corrida.
- **HU-05 sigue congelada** — no se tocó, como corresponde.
- Goldens preexistentes flaky (~0.4% de diff de píxel) en otras features, ruido conocido de esta
  máquina, no relacionados con esta corrida.

## Mensaje de commit sugerido

```
feat(onboarding): implementar flujo de bienvenida (13-onboarding.md)

Agrega lib/features/onboarding/ (4 pantallas: Bienvenida, Tu primera
cuenta, Respalda tus datos, Cierre) con el latch
AppSettings.onboardingCompleted, reusando CreateAccount, el flujo real
de transacción y el login social existentes. Incluye migración Drift
schemaVersion 21 + Postgres dev/prod, rutas /bienvenida en app_router,
y un fix real de router (AppLocalizations.of dentro de un
BlocProvider.create crasheaba en device).
```
