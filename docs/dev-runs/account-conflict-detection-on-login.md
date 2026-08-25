# Detección de conflicto de cuenta al iniciar sesión (account-conflict-detection-on-login)

## Objetivo y criterios de aceptación

Al iniciar sesión con Google/Apple en un dispositivo que ya tiene datos locales `user_id`-marcados de **otra** cuenta, bloquear el login con una hoja de confirmación no-dismissible (nunca preseleccionada) que advierte pérdida de cambios sin subir. Confirmar borra los datos locales (mismo alcance que `LocalDataWipeDatasource.wipeAll()`) y completa el login; cancelar cierra toda sesión (Supabase + Google/Apple + PowerSync) sin tocar los datos locales existentes y vuelve a login. Mientras la hoja está visible, la app debe seguir reportando `signedOut` pese a que Supabase ya intercambió la sesión en disco. Fail-closed si la detección local falla. Es el complemento exacto e inverso de la detección de HU-04 (`user_id IS NULL`).

Criterios de aceptación:

1. Al completar el intercambio de token (Google o Apple), si alguna de las 13 tablas de `ownedTables` tiene una fila con `user_id IS NOT NULL AND user_id != <id entrante>`, se muestra la hoja bloqueante antes de completar el login.
2. La hoja no preselecciona ninguna acción: ningún botón aparece como default visual o de foco al abrirse.
3. Mientras la hoja está visible, `currentSession`/`watchSession()` siguen reportando `signedOut` y PowerSync permanece desconectado, aunque Supabase ya intercambió y persistió sesión en disco.
4. Confirmar borra todos los datos locales (alcance de `wipeAll()`) y completa el login: sesión pasa a signed-in, PowerSync se conecta, `hasEverSignedIn()` queda en true.
5. Confirmar NO navega a `MergeConfirmationPage` (HU-04): no hay nada que fusionar tras el borrado local.
6. Cancelar deja intactos los datos locales de la cuenta anterior: ninguna fila modificada ni borrada.
7. Cancelar cierra por completo la sesión recién intercambiada (Supabase + Google/Apple + PowerSync) y vuelve a login con `signedOut`.
8. Si la detección local falla (excepción de lectura), se trata como conflicto y se muestra la misma hoja (fail-closed).
9. La hoja no se cierra con back de Android, edge-swipe ni tap fuera; solo sus dos botones la cierran.
10. El flujo de fusión de HU-04 (`user_id IS NULL`) no se ve afectado.
11. Un dispositivo ya asociado a la MISMA cuenta que inicia sesión nunca dispara la hoja.
12. El mensaje de la hoja es genérico y nunca nombra ni da pistas de la cuenta dueña de los datos en conflicto.

**Tamaño:** L · **Review:** deep, APROBADO.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/auth/domain/entities/sign_in_outcome.dart` | Nuevo. `SignInOutcome` sellado (`SignedIn` / `AccountConflictDetected`), mismo patrón que `SignOutOutcome`. |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Firma de sign-in ahora devuelve `SignInOutcome`; nuevos métodos `resolveAccountConflict()` / `cancelAccountConflict()`. |
| `lib/features/auth/domain/usecases/sign_in_with_google.dart` / `sign_in_with_apple.dart` | Adaptados a `FutureResult<SignInOutcome>`. |
| `lib/features/auth/domain/usecases/resolve_account_conflict.dart` | Nuevo caso de uso: confirma el conflicto (wipe + completar login). |
| `lib/features/auth/domain/usecases/cancel_account_conflict.dart` | Nuevo caso de uso: cancela el conflicto (cierre total de sesión). |
| `lib/core/sync/data/datasources/synced_tables.dart` | Nuevo. Constante pública `ownedTables` (las 13 tablas), consumida tanto por la detección de conflicto como por HU-04 — sin duplicación de la lista. |
| `lib/features/auth/data/datasources/local_data_ownership_datasource.dart` | Ahora consume `ownedTables` en vez de su propia lista `_ownedTables`. |
| `lib/features/auth/data/datasources/local_data_conflict_datasource.dart` | Nuevo. `hasConflict(incomingUserId)`: `SELECT 1 ... WHERE user_id IS NOT NULL AND user_id != ? LIMIT 1` por cada tabla de `ownedTables`; no atrapa excepciones (fail-closed lo maneja el llamador). |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` | `_completeSignIn` corre la detección con el `id` de Supabase antes de tocar `_current`/PowerSync/`_everSignedIn`. Campo `_pendingConflictUser` retiene el `AuthUser` y hace de guard en `_onAuthStateChange` para que ningún evento (incluido el que dispara `signInWithIdToken` internamente) filtre la sesión mientras la hoja está pendiente. `resolveAccountConflict()`/`cancelAccountConflict()` implementados; cancelar reusa `_clearLocalSession(force: true)`. |
| `lib/core/di/injection.config.dart` | Regenerado (`--force-jit`) por el cambio de aridad del constructor de `AuthRepositoryImpl`. |
| Presentation (`login_state.dart`, `login_cubit.dart`, `confirm_account_conflict_sheet.dart`, `login_page.dart`, `bottom_sheet_base.dart`, `app_router.dart`, `.arb` + l10n gen) | Ya estaba implementado y correctamente cableado antes de esta corrida — verificado exhaustivamente contra los 12 AC, sin cambios de código necesarios. |
| `test/features/auth/data/datasources/local_data_conflict_datasource_test.dart` | Nuevo. |
| `test/features/auth/data/repositories/auth_repository_impl_test.dart` | Grupo nuevo "account conflict detection on login". |
| `test/features/auth/domain/usecases/resolve_account_conflict_test.dart` / `cancel_account_conflict_test.dart` | Nuevos. |
| `test/features/auth/domain/usecases/auth_usecases_test.dart` / `sign_out_with_local_data_choice_powersync_test.dart` | Actualizados por el cambio de firma. |
| `test/features/auth/data/logout_never_deletes_through_drift_guard_test.dart` | `driftAllowlist` suma `local_data_conflict_datasource.dart` (solo SELECT). |
| `test/features/auth/presentation/widgets/sheets/confirm_account_conflict_sheet_golden_test.dart` + goldens (dark/light) | Ya existían, verificados. |

**Deliberadamente sin tocar:** `app_database.dart` / `powersync_schema.dart` (índice en `user_id`). El change map marca ese ítem como "Evaluar (no obligatorio), debe pasar por `drift-migration-helper`". Toda tabla con `_SyncColumns` (incluidas `transactions`/`transaction_tags`) es una vista manejada por PowerSync — un índice ahí se declara en `powersync_schema.dart` vía `Table(indexes: [...])`, mecanismo que hoy no se usa en ningún lado del schema (grep de `indexes|Index(` sin resultados). `schemaVersion` sigue en 29, no hubo bump porque no hubo cambio de esquema real.

## Tests

Resultado: `flutter analyze` limpio, suite verde, e2e en skip (ver "Verifica a mano").

Comandos para re-correr:

```bash
flutter analyze
flutter test test/features/auth/
flutter test test/core/sync/
flutter test test/features/settings/data/app_settings_after_wipe_test.dart
flutter test test/features/auth/presentation/widgets/sheets/confirm_account_conflict_sheet_golden_test.dart
```

Cobertura AC → test:

- AC1: `local_data_conflict_datasource_test.dart` + `auth_repository_impl_test.dart` (grupo "account conflict detection on login").
- AC2: `confirm_account_conflict_sheet_test.dart::'ningún botón está preseleccionado'`.
- AC3: `auth_repository_impl_test.dart::'holds back the sign-in...'` y `'...onAuthStateChange event...does not leak the exchanged session...'`.
- AC4: `auth_repository_impl_test.dart::resolveAccountConflict 'wipes local data and completes the sign-in...'`.
- AC5: `login_cubit_test.dart::'resolveConflict emite signedIn con signedInAfterConflict en true'` + `login_page_test.dart` (router salta `mergeConfirmation`).
- AC6: `auth_repository_impl_test.dart::cancelAccountConflict '...never wipes local data'`.
- AC7: `auth_repository_impl_test.dart::cancelAccountConflict 'closes Google + Supabase + PowerSync...'` + `login_page_test.dart::'cancelar la hoja de conflicto cierra la sesión sin completar el...'`.
- AC8: `local_data_conflict_datasource_test.dart::'propaga la excepción...'` + `auth_repository_impl_test.dart::'treats a conflict-detection failure as a conflict too (fail-closed)'`.
- AC9: `confirm_account_conflict_sheet_test.dart::'no es dismissible con un tap fuera'` + `'el botón/gesto atrás de Android no puede cerrar la hoja (PopScope canPop:false)'`.
- AC10: `local_data_conflict_datasource_test.dart::'las filas con user_id IS NULL nunca disparan un conflicto'` + `auth_repository_impl_test.dart::'does not fire for a device with only unowned local data'`.
- AC11: `local_data_conflict_datasource_test.dart::'un dispositivo ya asociado a la MISMA cuenta...nunca dispara la hoja'`.
- AC12: `confirm_account_conflict_sheet_test.dart::'muestra un mensaje genérico...'` (texto fijo, sin interpolar datos de la cuenta).

## Fidelidad visual vs Pencil

**BLOQUEADO sin acceso a Pencil.** El spec `design-system/billetudo/pages/auth.md` existe y es extenso (13 pantallas de flujo + Ajustes + Más, ambos temas), y `get_app_state` confirmó acceso real al `.pen` activo (`billetudo.pen`, con `q394ty` = "Zona — AUTH / AJUSTES / MAS" visible entre los nodos top-level). Sin embargo, el toolset disponible en esta sesión para `pencil-fidelity-reviewer` solo expuso `get_app_state` — sin `get_screenshot` ni `execute`, que son las herramientas que el playbook requiere para traer la referencia visual de cada nodeId (`fTetG`, `vexqA`, `sqm4I`, `wlVUL`, `K8SAG`, `j8ZdEx`, etc.) y compararla pixel a pixel contra cada golden. `get_app_state` con `include_canvas_design:true` tampoco estaba disponible como para reconstruir estructura+color de cada frame de forma confiable.

Por regla del playbook ("si no puedes acceder, detente y repórtalo — no evalúes a ciegas contra el `.md` solamente"), no se reportan hallazgos de severidad crítico/importante/menor sobre spacing/color/tipografía. Solo se pudo leer los `.png` de golden reales y cruzarlos contra la tabla de nodeId del `.md` (comparación documental/estructural, no visual) — esa comparación no arrojó gaps adicionales sobre lo ya cerrado en la fila "Auth" del tracking (2026-07-20).

Nota aparte, fuera de este alcance: `test/features/auth/presentation/widgets/sheets/failures/` contiene `masterImage`/`testImage`/`maskedDiff` para `confirm_delete_account_sheet`, `confirm_sign_out_sheet` y `local_data_choice_sheet` (ambos temas) — señal de que la última corrida de golden tests tuvo goldens fallando contra su propio master. Es un problema de estabilidad para `qa-automator`, no evaluado aquí.

## 👤 Verifica a mano

- [ ] Confirmar en un dispositivo/emulador real (con credenciales Google/Apple reales) que el sheet de conflicto realmente aparece tras un intercambio de token exitoso — no automatizable en Patrol porque `google_sign_in`/Sign in with Apple exigen interacción OAuth real con un picker de cuenta (misma limitación ya documentada en `integration_test/auth_patrol_test.dart` para el resto de HU-02/03/06/07).
- [ ] Verificar visualmente en dispositivo que el mensaje genérico de la hoja se ve bien en pantallas pequeñas / con font scaling grande (accesibilidad).
- [ ] Confirmar contra Pencil la fidelidad visual del sheet — no tiene frame dedicado aún, el propio widget documenta que reutiliza el patrón de `ConfirmDeleteAccountSheet`/`ConfirmDiscardQuarantinedChangeSheet`, pendiente de una pasada de fidelidad dedicada.
- [ ] El e2e quedó en skip pese al intento de bootear emulador — revisar por qué.

## Pendientes y riesgos

**Blockers sin resolver:** ninguno.

**Observaciones no bloqueantes:** ninguna.

**Riesgos del plan:**

- `signInWithIdToken` dispara un evento en `onAuthStateChange` con la sesión ya persistida — sin el guard `_pendingConflictUser`, ese listener completaría el sign-in por su cuenta. Punto de mayor riesgo de implementación, ya mitigado.
- `BottomSheetBase.show` no era no-dismissible por defecto; extenderlo tocó un widget compartido por ~10+ hojas — el default preserva el comportamiento actual para todas ellas, merece un pase de `finance-code-reviewer`/`ui-convention-reviewer` sobre ese archivo puntual.
- Hay DOS call sites de `onSignedIn` en `app_router.dart` (login desde Ajustes y desde onboarding) — verificar que ninguno quedó saltándose el skip de `MergeConfirmationPage` tras conflicto.
- El índice en `user_id` (si se decide agregar) toca vistas manejadas por PowerSync, no tablas SQL planas — se declara en `powersync_schema.dart`, y por la lección ya registrada del proyecto ("migrar columna Drift también en Supabase") puede necesitar equivalente en Postgres si la consulta corre server-side algún día. Debe decidirlo `drift-migration-helper`.
- Revisar en QA que ningún string nuevo en los `.arb` termine filtrando el email/nombre de la cuenta detectada — el mensaje debe quedar deliberadamente genérico.

**Gaps de cobertura:** ninguno pendiente sobre los 12 AC.

**Gaps de fidelidad:** el sheet no tiene frame dedicado en Pencil (reutiliza patrón de otras hojas), pendiente de pasada de fidelidad dedicada cuando exista acceso completo a Pencil (`get_screenshot`/`execute`).

## Mensaje de commit sugerido

```
feat(auth): bloquea login si el dispositivo tiene datos locales de otra cuenta

Detecta conflicto de cuenta (user_id IS NOT NULL != entrante) al completar
el intercambio de token con Google/Apple, complemento inverso de HU-04.
Muestra hoja bloqueante no-dismissible sin default: confirmar borra los
datos locales y completa el login; cancelar cierra toda la sesión sin
tocar datos. Fail-closed si la detección falla.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
