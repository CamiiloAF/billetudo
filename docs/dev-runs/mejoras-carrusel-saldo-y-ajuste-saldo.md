# Dev-run — Carrusel de saldo en Movimientos (#2) + Ajustar saldo (#1)

> **Fecha:** 2026-07-21 · **Estado:** #2 implementada y verde · #1 en implementación · tema oscuro de Pencil PENDIENTE (servidor de render caído). **Nada commiteado.**
> Documento vivo: se actualiza al cerrar #1 y el tema oscuro.

Dos mejoras diseñadas en Pencil (aprobadas por el usuario, solo tema claro) e implementadas contra los PNG exportados (Pencil sin render durante la implementación).

---

## Mejora #2 — Carrusel de saldo en Movimientos ✅ IMPLEMENTADA (verde)

Bloque de saldo en vivo de la(s) cuenta(s) del filtro, justo debajo de la fila de chips y arriba de la lista. Colapsable. La data ya estaba en `TransactionsListCubit` (`state.accounts`), así que no hubo cambios de esquema.

**Archivos creados**
- `lib/core/preferences/balance_carousel_preference_datasource.dart` — persistencia per-device (SharedPreferences).
- `lib/core/preferences/balance_carousel_cubit.dart` — `Cubit<bool>` (colapsado) con `load/toggle/collapse/expand`.
- `lib/features/transactions/presentation/widgets/movements_balance_card.dart` — balance card (variante normal + tarjeta de crédito, altura fija 160 compartida; reusa `AccountTypeAvatar`, `CreditUsageBar`).
- `lib/features/transactions/presentation/widgets/movements_balance_carousel.dart` — `PageView` + dots + manija/chevron-up (expandido) y barra compacta (colapsado).
- `test/features/transactions/presentation/widgets/movements_balance_carousel_test.dart` — 7 tests de widget.

**Archivos editados**
- `transactions_list_state.dart` — getters `displayedAccounts`, `displayedBalanceTotalMinor`, `displayedCurrency`.
- `transactions_page.dart` — inserta `MovementsBalanceCarousel(state: state)` entre filtros y lista.
- `app_router.dart` — provee `BalanceCarouselCubit` en la ruta de Movimientos.
- `app_es.arb` / `app_en.arb` (+ l10n regenerado), `injection.config.dart` (build_runner).
- `transactions_page_golden_test.dart` — helper con `BalanceCarouselCubit`; 4 goldens de página regenerados.

**l10n:** `transactionsBalanceTotalLabel`, `transactionsBalanceCarouselCollapse`, `transactionsBalanceCarouselExpand`. Reusa `transactionsFilterAccountsSelected`, `accountDebtLabel`, `accountAvailableCreditLabel`, `accountBalancePage`.

**Persistencia del colapso:** patrón per-device (SharedPreferences, como `ThemePreferenceDatasource`), no Drift, no sincronizado. Default: expandido.

**Decisiones anotadas**
- Total multi-moneda: suma `balanceMinor` en la moneda de la primera cuenta (app single-currency hoy); no separa por moneda (fuera de alcance).
- Montos grandes: `FittedBox(scaleDown)` para que un saldo largo escale sin truncar dinero.
- Sin cuentas / sin filtro: el carrusel retorna `SizedBox.shrink()`.
- Re-clamp del `PageController` si el filtro reduce el set por debajo de la página actual.

**Verificación:** `flutter analyze` limpio · `flutter test test/features/transactions` → +333 pasando.

**Refinamientos (pedidos por el usuario 2026-07-21) — ✅ IMPLEMENTADOS (verde: analyze limpio, +341 tests):**
1. **Pre-selección por card activa del carrusel.** `BalanceCarouselCubit` pasó a `Cubit<BalanceCarouselState{collapsed, currentPage}>` (nuevo `balance_carousel_state.dart`); `PageView.onPageChanged` → `pageChanged(int)`. `_preselectedAccountId` devuelve `displayedAccounts[clamp(currentPage)].account.id` (cubre 1 / 2+ / "Todas"), null si no hay cuentas. `currentPage` en-memoria; solo `collapsed` persiste.
2. **Centrado con 1 cuenta:** si `displayedAccounts.length == 1`, la card va en `Padding(horizontal:20)` a ancho completo, sin `PageView` (sin peek) y sin dots. Con 2+ idéntico (`PageView` viewportFraction 0.88 + peek + dots).
3. **Carrusel scrollea con la lista:** salió del `Column` fijo (quedan fijos solo buscador y chips) y es el primer ítem scrolleable de `TransactionsListView` en sus dos modos (agrupado `index 0` de `ListView.builder`; plano antes del Sort Label). Padding horizontal de la lista bajado a 0 y 20px por fila. Estados: ready-con-datos → header scrolleable; ready-vacío → carrusel fijo arriba del mensaje; loading/error → sin carrusel. Barra colapsada también dentro del scroll.

**Tweaks adicionales (usuario, post-QA) — ✅ aplicados (verde):**
- Barra COLAPSADA: más margen vertical (`fromLTRB(20,0,20,4)`→`(20,8,20,12)`). Solo afecta al estado colapsado (widget aparte del expandido).
- Estado EXPANDIDO: menos gap entre el chevron/handle y la card (`SizedBox(8)`→`(2)`). Goldens de página regenerados.
- Barra COLAPSADA: se quitó el label visible "Saldo total" y el monto pasó a tener PRIORIDAD (Text de ancho natural, no `Flexible`; "N cuentas" en `Expanded` que cede/ellipsa) para que el total **nunca se recorte** y quede en 1 línea. "Saldo total" se conserva en el `semanticsLabel` del monto (a11y). No afecta goldens (colapsado no se renderiza en ninguno). +359 tests verdes.

---

## Mejora #1 — Ajustar saldo ✅ IMPLEMENTADA (verde no-golden; goldens de accounts a regenerar)

Edición controlada del saldo: se elimina la edición libre del "Saldo inicial" y se ofrecen 2 opciones explícitas desde el detalle de la cuenta. Recordar: saldo = `initialBalanceMinor + Σ movimientos`; una tarjeta guarda saldo negativo (deuda).

**Alcance (lo que el agente está construyendo)**
1. **Quitar "Saldo inicial" del form de EDICIÓN** (solo se pide al crear). Gate por `state.isEditing`.
2. **Campo "Deuda actual" al CREAR tarjeta** en `CardDetailsSection` (label `accountDebtLabel`, enlazado a `initialBalanceText`, solo al crear). La plomería del cubit (`_formFor` abs / `_buildDraft` negate) ya existía.
3. **Lápiz sutil "Ajustar saldo"** a la derecha de la cifra en `BalanceCardSimple` y `BalanceCardHero` (distinto del lápiz violeta del header). Abre la hoja.
4. **Hoja "Ajustar saldo" (Var 1):** campo "Nuevo saldo deseado" + 2 tarjetas-radio + "Aplicar".
   - `diff = nuevoSaldo − saldoActual`.
   - **(a) Registrar ajuste:** transacción con fecha de hoy por `|diff|` (income si sube, expense si baja), `source: manual`. **Cuenta como transacción normal** (afecta reportes/presupuestos — decisión del usuario). Reusa `CreateTransaction`.
   - **(b) Corregir saldo inicial:** `nuevoInitial = initialActual + diff` vía `UpdateAccount`.
   - **Tarjeta:** la cifra es la DEUDA; copy "Nueva deuda" + manejo de signo (deuda positiva ingresada → saldo real negativo).
   - Lógica en DOMINIO (caso[s] de uso), no en el cubit. Dependencia cross-feature accounts↔transactions vía interfaces.

**Cómo quedó implementado**
- **Dominio (accounts):** `account_balance_adjustment.dart` (calculadora pura + `BalanceAdjustmentMode {registerMovement, correctInitial}`; toda la lógica de signo, incluido el caso tarjeta deuda→saldo negativo, vive aquí) + `adjust_account_balance.dart` (`@injectable`).
- **Cross-feature:** `AdjustAccountBalance` depende domain→domain de `UpdateAccount` (corregir inicial) y `CreateTransaction` (registrar ajuste) — nunca de repos/DAOs. Respeta capas.
- **Categoría del ajuste:** se agregó una bandera `isBalanceAdjustment` a `TransactionDraft` (default false, no persistida) que **solo** relaja la regla de "categoría obligatoria" para el ajuste; el form de transacciones nunca la setea (su regla queda intacta).
- **Presentación:** `adjust_balance_cubit`/`_state`, `sheets/adjust_balance_sheet.dart` (reusa `BottomSheetBase`+`AccountMoneyField`, campo "Nuevo saldo deseado"/"Nueva deuda", 2 radio-cards con diff con signo, "Aplicar"), `balance_adjust_mode_option.dart` (reusable), `balance_edit_button.dart` (lápiz sutil reusable). `balance_card_simple`/`_hero` con el lápiz junto a la cifra. `account_detail_page` abre la hoja. `account_form_page`: "Saldo inicial" solo al crear (`!isCard && !isEditing`). `card_details_section`: "Deuda actual" solo al crear tarjeta.
- **l10n:** keys `accountBalanceAdjust*` (es+en). **DI regenerado** (`AdjustAccountBalance`, `AdjustBalanceCubit`).
- **Tests:** 27 nuevos (calculadora signo/tarjeta, use case, bandera del draft, cubit, sheet). `account_detail_page_test` actualizado (ahora 2 lápices).

**Verificación:** `flutter analyze` (proyecto completo) → **No issues found**. `flutter test --exclude-tags golden` (transactions +341, accounts +335) verde. **16 goldens de accounts en rojo** (`account_detail_page_golden` ×10, `account_form_page_golden` ×6) = cambios de píxeles esperados por el rediseño → **regenerar (qa-automator)**.

---

## QA de cierre (qa-automator + revisores) — 2026-07-21

**Revisores (read-only):** `ui-convention-reviewer` y `finance-code-reviewer` → **sin hallazgos**. Verificado a fondo el signo del caso tarjeta (sin doble-negación) y que `isBalanceAdjustment` no abre hueco (solo relaja categoría en ajustes; no persiste en `Transaction`, así que el ajuste cuenta como transacción normal en presupuestos/reportes).

**qa-automator:** `flutter analyze` limpio. Suite completa `+2102 ~1 -17`. **Accounts + transactions + budgets + categories + core: 100% verde.**
- Goldens regenerados (cambios de píxel legítimos): `account_detail_page_golden` ×10 (lápiz de ajuste en la balance card), `account_form_page_golden` ×6 ("Saldo inicial" fuera de edición / "Deuda actual" al crear tarjeta), transactions_page ×4 (confirmados).
- Goldens nuevos: `adjust_balance_sheet_golden_test` ×6 (sheet nuevo, sin golden antes).
- Tests nuevos: getters del carrusel (9 unit), carrusel widget (+3: sobrecupo, header scrolleable en modo monto, clamp de página), pre-selección del FAB por card activa (4), presencia de campos del form (4). Barra colapsada: ningún golden la captura (`collapsed:false` forzado), tests no-golden pasan.

**⚠️ 17 fallas AJENAS a estas mejoras — DIFERIDO (usuario, retomar luego):** todas en `scheduled_payments` (16 goldens de `scheduled_payment_form_page_golden_test` + 1 widget test de copy ausente, `las tarjetas de modo van bajo el label "Al llegar la fecha"` → texto esperado ausente). NO es flakiness (regresión estructural). Patrón atribuido al commit `6d15e61 (feat pagos-programados)` que cambió copy/layout sin actualizar sus tests. **Fuera del alcance de #1/#2.** Pendiente decidir al retomar: ¿cambio intencional (regenerar goldens/actualizar test) o bug real en `lib/features/scheduled_payments/`?

**Verificación humana pendiente (bloqueada por Pencil render caído):** fidelidad visual de los goldens regenerados/nuevos contra Pencil (`/design-fidelity-check accounts`); confirmar visualmente el nuevo padding de la barra colapsada (ningún golden lo captura).

## Diseño (Pencil) — aprobado, tema oscuro PENDIENTE

**Frames claros aprobados:** Movimientos Var A — expandido `cgasM`, colapsado `rGVw1`, tarjeta activa `Ljf8l`; Mejora #1 — detalle cuenta `c2jrG`, detalle tarjeta `Uk8DL`, hoja Ajustar saldo `s0c82`, crear tarjeta Deuda actual `XcEBG`.

**Componentes Pencil nuevos:** `C2g9cA` Balance Card (Movimientos), `d2TX3` Balance Bar Colapsada, `P0pSKV` Balance Adjust Option.

**Descartados (borrados del canvas):** `LuSBL` (Ajustar saldo Var 2), `eP3uk` (Movimientos hero), `ddypA` (Movimientos barra compacta — su barra se unificó como estado colapsado de A).

**PENDIENTE (bloqueado por servidor de render de Pencil caído):**
- Quitar los 7 badges de revisión: `Al1p7`, `m91WJ`, `mOcdH`, `plwvK`, `d9OXU`, `HGS9S`, `gCIds`.
- Generar el **tema oscuro** de los 7 frames (por copia + `theme:dark`).
- Retomar apenas Pencil recupere el render (verificar con una llamada primero).

**Regla nueva establecida:** el diseñador marca cada frame nuevo con un badge `🔖 EN REVISIÓN` y lo retira al aprobar (en `.claude/agents/pencil-designer.md` + memoria).

---

## Decisiones clave (log)

- El saldo de una cuenta **no se edita libremente**; se ajusta solo por (a) registrar ajuste o (b) corregir saldo inicial.
- El **ajuste registrado cuenta como transacción normal** (ingreso/gasto), afecta presupuestos/reportes.
- Las **tarjetas fijan su deuda inicial al crear** ("Deuda actual"); no había forma antes.
- **Colapso del carrusel** unifica las variantes A+C: colapsado = barra compacta "N cuentas · Total"; control = manija + chevron-up; persistido per-device, default expandido.
- Carrusel **refleja el filtro** de cuenta; "Todas" → todas las cuentas.

## Pendientes / próximos pasos

1. ~~Terminar **Mejora #1**~~ ✅ hecho · ~~refinamientos del carrusel~~ ✅ hecho.
2. ~~**QA completa**~~ ✅ hecho (ver "QA de cierre" abajo). Revisores limpios; qa-automator regeneró goldens, agregó cobertura, suite verde en accounts+transactions.
3. ~~**Tweak:** más padding/margen vertical en la barra COLAPSADA~~ ✅ aplicado (`MovementsBalanceCarouselCollapsed`: `Padding` exterior `fromLTRB(20,0,20,4)` → `fromLTRB(20,8,20,12)`). Golden colapsado a regenerar dentro de la corrida de qa-automator (avisado).
4. ~~**Tweaks al ajuste (modo `registerMovement`)**~~ ✅ hecho (+720 tests verdes):
   - **Nota "Ajuste de saldo":** key l10n `accountBalanceAdjustNote` (es "Ajuste de saldo" / en "Balance adjustment"); leída en `AdjustBalanceSheet` (presentación) → `AdjustBalanceCubit.apply(note:)` → `AdjustAccountBalance.call(note:)` → `TransactionDraft.note`.
   - **Categoría "Otros" por dirección:** constantes en `AdjustAccountBalance` (`seed-other-income` / `seed-other-expenses`, del catálogo `category_seeds`). Ingreso → "Otros ingresos" (kind income); gasto → "Otros gastos" (kind expense). El draft pasa "categoría obligatoria" por la vía normal; `isBalanceAdjustment` queda como fallback defensivo. Sin cambio visual → sin regen de goldens.
5. ~~**Tap en card del carrusel → detalle de cuenta**~~ ✅ hecho (callback `onOpenAccount` desde `app_router` → `TransactionsPage` → `TransactionsListView` → carrusel → `MovementsBalanceCard.onTap`; `context.push(AppRoutes.account(id))`. No afecta swipe ni barra colapsada. +359 tests verdes).
6. ~~**Tema oscuro + limpieza de badges** en Pencil~~ ✅ hecho (render recuperado). 7 frames oscuros generados: `Y0lWi`/`uxIps`/`RdbCG` (Movimientos), `r0hXJd`/`bT7Ga`/`t42NgN`/`Dyfwj` (Mejora #1). 7 badges borrados. Barra colapsada sincronizada con el código (sin "Saldo total", monto con prioridad). **Fix de contraste:** la deuda de `C2g9cA` (Balance Card Movimientos) estaba en `$expense` (falla 4.5:1 en oscuro para texto de 16px) → cambiado a `$expense-text` en Pencil Y en código (`movements_balance_card.dart` línea de la variante tarjeta), goldens sin cambio.
7. ~~**Specs por pantalla**~~ ✅ hecho: carrusel en `design-system/billetudo/pages/transacciones.md`, lápiz/hoja/deuda-actual en `pages/cuentas.md` (ambas marcan el oscuro; actualizar esa nota a "hecho").
8. **Fidelidad visual** (`/design-fidelity-check`): pendiente/opcional.
9. **Commit del cierre de diseño** (`.pen` con oscuro + badges limpios + fix `expenseText` en código) — pendiente de hacer.
10. **scheduled_payments** (17 tests): ✅ resuelto por qa-automator (cambio de copy intencional, goldens + finder actualizados; 371 verdes). Ya commiteado.
11. `.github/`, `ios/ExportOptionsProd.plist`, `integration_test/test_bundle.dart`: ajenos, sin commitear a propósito.
12. **Fidelidad — pendientes (post-auditoría 2026-07-21):**
    - **Orden de chips (Fecha 2º):** el usuario confirmó que Fecha va en 2º lugar (él lo pidió). Código ✅ y spec §3 ✅ ya lo reflejan. **Falta sincronizar los frames de Pencil** (mover Chip Fecha al índice 1 en los frames de Movimientos con Chips Row, claro+oscuro) — BLOQUEADO: Pencil se desconectó otra vez ("transport not connected to app: desktop"). Retomar cuando vuelva. No bloquea código.
    - **Títulos raíz a la izquierda (consistencia):** Movimientos y Más pasan de `AppBar` centrado a header izquierdo (patrón `BudgetsPageHeader`), como Presupuestos/Inicio/Pencil. 🔄 flutter-dev en curso.
    - **Goldens faltantes:** estados colapsado + tarjeta-activa del carrusel → qa-automator (en cola tras el título).

## Relacionado (fuera de estas mejoras)
- Pre-selección de la cuenta filtrada al tocar el FAB "+" en Movimientos (cambio previo de esta sesión, también sin commitear).
- Plan a corto plazo: `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` (tipos de cuenta ampliados + transferencias presupuestables; A-1 re-resuelta por el usuario: toda deuda salvo tarjeta vive en la feature Deudas).
