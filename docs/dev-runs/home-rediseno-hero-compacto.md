# Rediseño Home — hero compacto (home-rediseno-hero-compacto)

## Objetivo y criterios de aceptación

Implementar en Flutter el rediseño aprobado del Home (`design-system/billetudo/pages/inicio.md`,
`.pen` zona `CPHbt`): hero compacto multi-estado de 7 estados sobre `BudgetProgress`, card de IA
condicional (sin card / chips / insight único / insight con cola), header con avatar tocable y
badge de sync (retirando el ícono suelto), hoja de saldos "Tu dinero" agrupada por moneda, hoja de
cuenta con bloque de sync compacto (reusa el componente Sync Hero de `core/sync`), y ampliación de
Acceso rápido a 5 chips (Pagos programados con badge, Cuentas, Deudas, Gráficas, Metas) — todo en
claro y oscuro.

Tamaño: **L** | Review: deep, **APROBADO**.

16 criterios de aceptación (detalle completo en el historial de la corrida):

1. Header con badge de sync sobre el avatar (44×44, tocable, 4 estados) + saludo en una línea.
2. Avatar abre la hoja "Tu cuenta" (3 variantes: con sesión+sin conexión, con sesión+sincronizado, sin cuenta).
3. Botón wallet abre "Tu dinero": cuentas agrupadas solo por moneda, total sin tarjeta/inversión, chip de conteo, nota condicional.
4. Fila de cuenta en la hoja de saldos navega a Movimientos filtrados (`onOpenAccountMovements`), no a un detalle.
5. `HomeHeroCard` resuelve los 7 estados de negocio (sano, al límite, límite exacto, riesgo de sobregiro, sobregasto real, sin presupuesto, sin ninguno destacado) sin reestructurar el componente.
6. Kicker+monto siempre "Te quedan $X" salvo sobregasto real ("Excedido por $X").
7. Auto-tamaño del monto (30/26/32px) sin desbordar el track de 314px.
8. Barra de progreso sin hueco <10px con esquina redondeada suelta.
9. La pastilla de período absorbe el tap sin propagarlo al `InkWell` del hero.
10. Card de IA condicional según transacciones/insight/cola, con estado forzado "crea un presupuesto" cuando el hero está sin presupuesto.
11. CTA "Ayúdame a presupuestar" navega directo a `onCreateBudget`, nunca abre el chat.
12. Tap en card/chip de conversación sin acceso abre "Conversación en beta" en el momento del tap.
13. `QuickAccessRow` de 5 chips configurables, persistidos en `AppSettings.quickAccessOrder`.
14. Bloque de sync de la hoja de cuenta reusa `SyncHero` en modo compacto, sin widget paralelo.
15. Estados Vacío/Carga de pantalla completa siguen sin card de IA / sin skeleton de IA.
16. `avoid_widget_functions`/`avoid_private_widgets` + `AppLocalizations`, cero strings hardcodeadas.

## Qué cambió

La corrida se dividió en dos etapas de agente (`core`: domain/data, `ui`: presentation) sobre la
misma pieza. Archivos principales:

| Archivo | Qué |
|---|---|
| `lib/features/home/domain/entities/hero_state.dart` | `HomeHeroState`/`HomeHeroStateResolver`, resolución pura de los 7 estados a partir de `BudgetWithProgress?` + `hasAnyBudget`. |
| `lib/features/home/domain/entities/home_ai_insight.dart` | `HomeAiInsightType`/`HomeAiInsight`, sin copy de UI (solo tipo+números). |
| `lib/features/home/domain/entities/quick_access_item.dart` | Pasa de 3 a 5 miembros (+accounts, +goals); `defaultOrder`/`isValidOrder` actualizados. |
| `lib/features/home/domain/usecases/watch_has_any_budget.dart` | Distingue "nunca creó presupuesto" de "tiene, ninguno destacado". |
| `lib/features/home/domain/usecases/watch_home_ai_insight.dart` | Insight local (promedio 3 meses vs. mes actual, umbral 15%) + riesgo de sobregiro programado. |
| `lib/features/home/domain/usecases/watch_pending_scheduled_payment_count.dart` | Cuenta ocurrencias vencidas para el badge de "Pagos programados". |
| `lib/features/settings/domain/usecases/set_quick_access_order.dart` | Persistencia del orden de 5 chips. |
| `lib/features/home/presentation/widgets/home_header.dart`, `account_avatar.dart`, `status_badge.dart` | Header nuevo: avatar tocable + badge de sync (4 estados), saludo en una línea. Reemplazan `sync_indicator.dart` (eliminado). |
| `lib/features/home/presentation/widgets/home_hero_card.dart`, `home_hero_budget_progress.dart`, `risk_note.dart`, `month_selector_chip.dart` | Hero compacto de 7 estados, auto-tamaño de monto, `RiskNote`, pastilla de período con gesto independiente. |
| `lib/features/home/presentation/widgets/ai_card.dart`, `ai_card_chips.dart`, `ai_card_insight.dart`, `ai_orb.dart`, `ai_question_chip.dart` | Card de IA condicional (vacío/chips/insight/cola), gate de acceso al tocar. Reemplazan `ai_banner.dart` (eliminado). |
| `lib/features/home/presentation/widgets/quick_access_row.dart`, `quick_access_row_chip.dart`, `quick_access_chip_with_badge.dart` | 5 chips configurables con badge de contador. |
| `lib/features/home/presentation/widgets/balance_mini_card.dart`, `sheets/balances_sheet.dart`, `sheets/currency_group.dart`, `sheets/currency_group_section.dart` | Hoja "Tu dinero" agrupada por moneda. Reemplazan `home_balances_strip.dart` (eliminado). |
| `lib/features/home/presentation/widgets/sheets/account_sheet.dart`, `identity_row.dart`, `account_sync_block.dart`, `settings_row.dart`, `sign_out_row.dart`, `no_account_invite.dart` | Hoja "Tu cuenta" con 3 variantes, `SyncHero` en modo compacto. |
| `lib/features/home/presentation/widgets/sheets/month_picker_sheet.dart` | Selector de mes/período (abierto desde la pastilla del hero). |
| `lib/core/sync/presentation/widgets/sync_hero.dart` | Parametrizado con `compact`/`trailingChevron`/`cta` nulable — sin componente paralelo. |
| `lib/core/theme/app_colors.dart`, `lib/core/widgets/spinning_icon.dart` | Tokens/ícono de spinner reusados por el badge de sync. |
| `lib/features/home/presentation/cubit/home_state.dart`, `home_cubit.dart`, `pages/home_page.dart` | Orquestación de los estados nuevos, `hasAiAccess()`, `dismissAiInsight()`. |
| `lib/features/settings/presentation/pages/quick_access_order_page.dart` | Actualizada al enum de 5 miembros. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` (+ gen) | Strings nuevas de header, hero, card de IA, hojas y quick access. |
| `lib/core/router/app_router.dart`, `lib/core/di/injection.config.dart` | Wiring de las hojas nuevas y de los 3 usecases (`@injectable`, regenerado con `build_runner`). |
| `test/features/home/**`, `test/features/settings/**`, `integration_test/home_patrol_test.dart`, `integration_test/home_hero_period_patrol_test.dart` | Cobertura unit/widget/golden/Patrol de toda la pieza. |

Archivos completos tocados (código + tests + goldens): ver el change map de la sesión, ~95
archivos entre `lib/`, `test/` e `integration_test/`.

## Tests

- `flutter analyze`: limpio (0 warnings nuevos).
- `flutter test`: suite completa en verde.
- Patrol e2e: `home_patrol_test.dart` y `home_hero_period_patrol_test.dart`, PASS.

Comandos para re-correr:

```bash
flutter analyze
flutter test
flutter test integration_test/home_patrol_test.dart -d <device>
flutter test integration_test/home_hero_period_patrol_test.dart -d <device>
```

Logs de la corrida de Patrol de esta sesión (temporales, no versionados):
`patrol_home.log`, `patrol_hero.log` en el scratchpad de la sesión.

### Cobertura por criterio de aceptación

| AC | Cubierto por |
|---|---|
| 1 | `test/features/home/presentation/widgets/home_header_test.dart` |
| 2 | `home_page_test.dart` (grupo "avatar tocable abre Tu cuenta") + golden `account_sheet_golden_test.dart` (3 estados × claro/oscuro) |
| 3 | `widgets/sheets/balances_sheet_test.dart` + golden `balances_sheet_golden_test.dart` |
| 4 | `widgets/sheets/balances_sheet_test.dart:201` ("criterio 4") |
| 5/6 | `domain/hero_state_test.dart` + `widgets/home_hero_card_test.dart` + golden `home_page_golden_test.dart` |
| 7 | `widgets/home_hero_card_test.dart` + goldens `home_page_hero_overspent_{light,dark}.png` |
| 8 | `widgets/home_hero_card_test.dart` (asserts de `BorderRadius` por umbral) — verificado en corrida previa |
| 9 | `home_page_test.dart` (stepper de período) + `integration_test/home_hero_period_patrol_test.dart` (e2e real, PASS) |
| 10 | `widgets/ai_card_test.dart` + golden `home_page_golden_test.dart` (casos `ai_card_*`) |
| 11 | `widgets/ai_card_test.dart` / `ai_question_chip` |
| 12 | `home_page_test.dart:171` (grupo "criterios 11/12: gate de acceso al chat de IA") |
| 13 | `widgets/quick_access_row_test.dart` + `settings/domain/usecases/set_quick_access_order_test.dart` + `settings/data/datasources/app_settings_local_datasource_test.dart` |
| 14 | golden `account_sheet_golden_test.dart` + `home_page_test.dart` (variantes de account sheet) |
| 15 | golden `home_page_golden_test.dart` (casos "loading", "empty (HU-08)") + `home_page_test.dart` |
| 16 | `dart analyze` limpio; clases nuevas públicas en su propio archivo, `AppLocalizations` por inspección manual del diff (sin lint plugin activo) |

## Fidelidad visual vs Pencil

**N/A — el agente no respondió.** No se pudo correr el chequeo de fidelidad de esta corrida
(`pencil-fidelity-reviewer` / `/design-fidelity-check`) contra los 41 frames nuevos/tocados en
`billetudo.pen` (zona `CPHbt`, 16 pares + 4 pares de la hoja de cuenta). Queda pendiente como el
verificador de cierre real: el gate de acceso a Pencil se aplicó antes de construir (`flutter-dev`
reportó acceso de solo lectura disponible), pero no hay auditoría de fidelidad post-implementación
para esta corrida.

**Pendiente explícito:** correr `/design-fidelity-check inicio` (o el nombre real del `.md`,
`inicio.md`) sobre los goldens ya generados antes de dar la pieza por visualmente cerrada,
especialmente el auto-tamaño del monto (30/26/32px) y el umbral de <10px de la barra, que son
reglas de pixel-fitting que Pencil no valida por sí solo.

## 👤 Verifica a mano

- Gesto real de arrastre/scroll en la hoja "Tu dinero" y "Tu cuenta" en un dispositivo físico (los widget tests simulan `pump`/`tap`, no gestos táctiles reales de sheet).
- Fidelidad visual pixel-perfect contra Pencil (nodeId `CPHbt`) — corresponde a `/design-fidelity-check`, no a esta corrida de QA (ver sección anterior, quedó sin correr).
- Comportamiento del badge de sync "requiere atención" con una desconexión de red real prolongada (los tests mockean el estado, no una desconexión real de PowerSync).
- Verificar en dispositivo que la card de IA no interrumpe con el bottom sheet "Conversación en beta" de forma inesperada durante scroll rápido (gesto real, no simulable con `pump`).

## Pendientes y riesgos

- **Fidelidad visual sin correr** (ver sección arriba) — es el mayor pendiente de esta corrida, no un gap menor.
- Seed de pregunta al chat no implementado: `AiCard.onAskQuestion` recibe el texto pero `HomePage._onAskQuestion` lo ignora al navegar — `AiAssistantPage` no expone hoy un modo "abrir con pregunta ya enviada".
- "Ahora no" en el insight se implementó como descarte de sesión (`dismissAiInsight()`), no como persistencia local — el insight descartado puede reaparecer antes del siguiente período.
- Badge del avatar simplifica `HomeSyncStatus.offline` con sesión activa igual que `synced` (apagado); el `.md` no especifica un 5º estado distinto.
- `sync_status_sheet.dart` (hoja vieja que abría el ícono de sync suelto) quedó sin ningún llamador desde `HomePage` — huérfana, compila y sigue en verde, candidata a limpieza aparte (no estaba en el change map).
- Auto-tamaño del monto del hero implementado con umbral de longitud de string (>10 glifos) en vez de `FittedBox` real — mismo resultado visual en los casos documentados, más simple para tests.
- Goldens de `home_page_golden_test.dart` (12 imágenes) y `quick_access_order_page_golden_test.dart` (1 imagen) reflejan el rediseño visual real (no una regresión) — no se regeneraron automáticamente en esta corrida por no ser responsabilidad de `flutter-dev`; ya están versionadas como parte del change map.
- Algoritmo de "comparación contra promedio" del insight de IA no tenía fórmula especificada en `pages/inicio.md` (solo la existencia de la familia) — se implementó y documentó como cómputo local puro sobre `TransactionRepository`, ajustable si el algoritmo real difiere.
- `QuickAccessItem` de 3→5 miembros: un orden persistido de 3 en `AppSettings.quickAccessOrder` ya no es una permutación válida de 5 — cae al `defaultOrder` vía `isValidOrder` (comportamiento preexistente reusado, no hay migración in-place 3→5).
- Riesgo de alcance: la corrida cruzó 5+ features (home, budgets, accounts, scheduled_payments, ai, core/sync) más l10n y DI en una sola pasada de `/feature-dev` — quedó completa y en verde, pero el tamaño real hizo el review final más difícil de verificar por completo; considerar dividir corridas grandes similares en el futuro.
- Verificado explícitamente sin regresión: `CheckAiAccess` no se invoca de forma eager al construir la card de IA (el gate solo aparece al tocar); el chip "Ayúdame a presupuestar" navega siempre a `onCreateBudget` sin pasar por el chat, incluso dentro del insight "crea un presupuesto" (regla de Nivel 0).

## Mensaje de commit sugerido

```
feat(home): rediseño hero compacto, card de IA condicional y hoja de saldos por moneda

Implementa los 16 criterios de aceptación del rediseño de Home aprobado en
design-system/billetudo/pages/inicio.md (.pen zona CPHbt):

- HomeHeroCard resuelve 7 estados de negocio sobre BudgetProgress (sano, al
  límite, límite exacto, riesgo de sobregiro, sobregasto real, sin
  presupuesto, sin ninguno destacado)
- Header con avatar tocable + badge de sync de 4 estados, reemplaza el
  ícono de sync suelto
- Card de IA condicional (vacío/chips/insight/cola), gate de acceso solo
  al tocar, CTA "Ayúdame a presupuestar" nunca abre el chat
- Hoja "Tu dinero" agrupada por moneda con total sin tarjeta/inversión
- Hoja "Tu cuenta" (3 variantes) reusa SyncHero en modo compacto
- QuickAccessRow pasa de 3 a 5 chips configurables, persistidos en
  AppSettings.quickAccessOrder

Fidelidad visual vs Pencil pendiente de correr (agente no respondió en
esta corrida) — ver docs/dev-runs/home-rediseno-hero-compacto.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```
