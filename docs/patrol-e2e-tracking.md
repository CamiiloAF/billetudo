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
| Cuentas | 🟡 Parcial | 2026-07-20 | ✅ (`integration_test/accounts_patrol_test.dart`) | corrida `qa-automator` de hoy tras arreglar el bloqueo | ✅ 6/7 estable. HU-02 intermitente por flakiness de touch-injection (no locator, ver `docs/dev-runs/bug-fixes-pixel-audit.md`), con retry acotado agregado. Fix: locator de navegación, formato COP sin decimales, ícono `PageHeader`, locator por índice reemplazado por label. |
| Autenticación | ✅ Verde | 2026-07-20 | ✅ (`integration_test/auth_patrol_test.dart`) | corrida `qa-automator` de hoy tras arreglar el bloqueo | ✅ 5/5. Único fix: copy del sheet de eliminar cuenta cambió a "irreversible" (antes "no se puede deshacer"), el test seguía el texto viejo. |
| Categorías | ✅ Verde | 2026-07-20 | ✅ (`integration_test/categories_patrol_test.dart`) | corrida `qa-automator` de hoy tras arreglar el bloqueo | ✅ 6/6 en 2 corridas consecutivas. Fix: navegación (`Ver mis categorías` muerto, la ruta real es la pestaña "Más" → `Categorías`, no hay chip en `QuickAccessRow` de Home), copy inexistente en el sheet de borrado simple (sin título), mensajes interpolados de los sheets de borrado con transacciones/subcategorías (`textContaining` en vez de string exacto), y una suposición de flujo incorrecta en HU-04 caso 2 (el radio por defecto es "Reasignar", no "Dejar sin categoría", y el botón de confirmar ahí dice "Continuar", no "Eliminar"). |
| Inicio / Dashboard | ✅ Verde | 2026-07-20 | ✅ (`integration_test/home_patrol_test.dart`) | corrida `qa-automator` de hoy tras arreglar el bloqueo | ✅ 4/4 en 2 corridas consecutivas. Único fix: Presupuestos dejó de ser `ComingSoonPage` (la feature ya ships como `BudgetsPage`), el test seguía asumiendo el placeholder — se actualizó a `find.byType(BudgetsPage)`. Metas sigue en "Próximamente", sin cambios ahí. |
| Transacciones | 🟡 En pausa | 2026-07-20 | ✅ (`integration_test/transactions_patrol_test.dart`) | `docs/dev-runs/patrol-e2e-findings-2026-07-20.md` (sección Transacciones) | Fixes extensos de locator ya aplicados y guardados sin commitear (llegó a 9/9 en una corrida). Bloqueada esta noche por un build roto de forma intermitente por trabajo en progreso ajeno en `lib/features/scheduled_payments/`/`lib/features/budgets/` — NO reintentar hasta confirmar que ese árbol compila limpio. Retomar mañana. |
| Presupuestos | ⬜️ N/A | — | ❌ | — | Sin `integration_test/budgets_patrol_test.dart` todavía. |
| Pagos programados | ⬜️ N/A | — | ❌ | — | Sin `integration_test/scheduled_payments_patrol_test.dart` todavía — el dev-run (`docs/dev-runs/pagos-programados.md`) deja el e2e explícitamente en skip. |
| Configuración (Settings) | ⬜️ N/A | — | ❌ | — | Sin `integration_test/settings_patrol_test.dart` todavía. |
| Deudas, Metas, Reportes, Captura, Improvement | ⬜️ N/A | — | ❌ | — | Sin implementación en `lib/features/` (solo `.gitkeep`) o sin suite propia — no aplica corrida e2e. |

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
2. **Bloqueante nuevo (2026-07-20, noche):** el árbol de trabajo tiene cambios sin commitear en
   `lib/features/scheduled_payments/` y `lib/features/budgets/` que rompen el build de forma
   intermitente (`injection.config.dart` desincronizado con `ScheduledPaymentDetailCubit`/
   `ScheduledPaymentHeroCard` — falta `build_runner` o el feature está a medio terminar). Ninguna
   suite Patrol corre de forma confiable hasta que ese árbol compile limpio. Confirmar con quien
   esté editando esos archivos antes de re-correr nada.
3. Re-correr `transactions` una vez resuelto el punto 2 — los fixes de locator ya están aplicados
   y guardados en `integration_test/transactions_patrol_test.dart` (llegó a 9/9 en una corrida),
   así que no debería necesitar más cambios, solo confirmación con build estable. Detalle completo
   en `docs/dev-runs/patrol-e2e-findings-2026-07-20.md`.
4. Cuando `qa-automator` agregue suite Patrol a Presupuestos, Pagos programados o Settings, correrla con `patrol-e2e-runner` y mover la fila de `⬜️ N/A` a `⏳ Sin correr`.
