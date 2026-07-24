# Plan — Tipos de cuenta ampliados + transferencias presupuestables

> **Estado:** Propuesta con **todas las decisiones abiertas cerradas** (2026-07-24) — lista para dimensionar/agendar, **aún no** en ejecución.
> **Fecha:** 2026-07-21 · **Alcance:** Cuentas, Transacciones, Presupuestos, Reportes (y roce con Deudas).
> Cuando se implemente, seguir el flujo de diseño (Pencil primero) y `/drift-schema-change` para el esquema.

Este documento cubre tres cambios que el usuario pidió documentar juntos:

- **A.** Renombrar 2 tipos de cuenta existentes para mayor claridad (`bank`→"Cuenta corriente", `other`→"Cuenta general"). **Alcance recortado el 2026-07-24** — ver §2: se descartó ampliar a ~11 tipos y rediseñar el selector, sin caso de uso que lo justificara.
- **B.** Permitir que una **transferencia** cuente opcionalmente como **gasto** (origen) e **ingreso** (destino) que afecte **reportes y presupuestos**, con un **toggle** por transferencia y una **sugerencia** según el tipo de cuenta (ej. inversión).

B es el cambio de fondo; A es un renombre de claridad, sin relación de dependencia con B (la sugerencia de B usa `defaultOffBudget` de los tipos ya existentes, ej. `investment`).

---

## 1. Estado actual (código real)

### Tipos de cuenta
- Enum de dominio `AccountType { cash, bank, card, savings, investment, other }` — `lib/features/accounts/domain/entities/account.dart:5`.
- Enum de Drift homónimo, guardado como **texto** (`textEnum`) — `lib/core/database/app_database.dart:36`, columna `Accounts.type` (`:150`).
- Presentación (icono, color, color-soft, label l10n) en la extensión `AccountTypePresentation` — `lib/features/accounts/presentation/widgets/account_type_avatar.dart:14`.
- Labels en `.arb`: `accountTypeCash/Bank/Card/Savings/Investment/Other` — `lib/core/l10n/arb/app_es.arb:97+`.
- **Selector:** `AccountTypeGrid` = `GridView.count(crossAxisCount: 3)` **inline** en el formulario (no un bottom sheet) — `lib/features/accounts/presentation/widgets/account_type_grid.dart`. Al editar se colapsa en un pill (`AccountTypePill`).
- Reglas por tipo dispersas: `isCard` / `allowsFullAccountNumber` (`account.dart:13,20`), `showFullNumberField` / `showLast4Field` / `showInterestRateField` (`account_form_state.dart:112-127`). El saldo de tarjeta se guarda **negativo** (deuda) y se muestra como "Deuda actual" (ver `plan` de la Mejora #1 en curso).

### Transferencias
- `TransactionType { income, expense, transfer }` (Drift `EntryType`, `app_database.dart:39`).
- Una transferencia es **una sola fila** `Transaction` con `accountId` (origen) + `transferAccountId` (destino), `type = transfer`. Reglas en `TransactionDraft.validated` — `lib/features/transactions/domain/entities/transaction_draft.dart:147`: destino obligatorio y distinto del origen; **sin categoría, sin kind** (`return Right((null, null, transferAccountId))`).
- **El saldo YA se mueve en ambas cuentas:** `AccountBalance` aplica `transferOut` (−) al origen y `transferIn` (+) al destino — `lib/features/accounts/domain/entities/account_balance.dart:9,30`. El patrimonio neto no cambia.
- El formulario limpia la categoría al cambiar a transferencia — `transaction_form_cubit.dart:typeSelected`.

### Presupuestos
- **Excluyen transferencias por diseño.** `BudgetExpense` (doc en `lib/features/budgets/domain/entities/budget_expense.dart:7`): *"Only real expenses ever become one of these: transfers are never budget... the data layer filters `type = expense`, `deletedAt IS NULL` before mapping."*
- Zero-based / sobres: existen `ZeroBasedSummaryCubit`, "safe-to-spend", nudges de sobre → hay concepto de **ingreso-a-presupuestar**.

### Reportes y Deudas
- **Reportes:** `lib/features/reports/` solo tiene `.gitkeep` — **no construido**. "Que afecte los informes" es en parte trabajo futuro; el plan solo deja el requisito anotado.
- **Deudas:** tabla `Debts` con `DebtDirection { iOwe, owedToMe }` existe (`app_database.dart:52,292`) pero la feature está vacía (`.gitkeep`). **Toda deuda salvo la tarjeta vive acá** (informal + formal/institucional) → ver A-1 reabierta en §2 y `docs/requirements/08-deudas.md`.

---

## 2. Sub-feature A — Tipos de cuenta: SOLO renombres (alcance reducido, 2026-07-24)

> **Recorte de alcance (usuario, 2026-07-24).** El mockup de 11 tipos era una referencia visual, no una validación de mercado (ver memoria del proyecto "datos de mockup no son especificación"). `Bono`, `Seguro` y `Cuenta con sobregiro` se **descartan**: un bono ya cabe en `investment`; un seguro no es una cuenta con saldo derivado de transacciones, es una póliza — forzarlo al modelo de `Accounts` no encaja; sobregiro es un comportamiento de `bank/checking` (puede ir a negativo), no un tipo aparte, y ya estaba anotado así en §3. El propio usuario, que es el primer usuario real de la app, confirmó que se limita a los tipos ya existentes — señal directa de que no hay caso de uso que justifique la superficie nueva (3 íconos, 1 token de color, selector rediseñado).
>
> **Alcance final de Sub-feature A: solo A-2, el renombre.** `bank`→"Cuenta corriente", `other`→"Cuenta general" (labels en `.arb`, el valor del enum no cambia). Sigue siendo **6 tipos** (`cash`, `bank`, `card`, `savings`, `investment`, `other`), que el `AccountTypeGrid` actual (`GridView.count(crossAxisCount: 3)`, 2 filas) ya acomoda sin cambios — **la Fase A2 (selector de 2 filas + scroll horizontal) deja de ser necesaria** y se retira del plan de fases (§5).
>
> Las 3 variantes del selector diseñadas en Pencil (`zaQKJ`/`y0VBP`/`Kfrqc`) y el token `slate`/`slate-soft` (para el ícono de Seguro que ya no se usa) se limpian del canvas por no tener caso de uso.

### Cambio técnico (A, alcance reducido)
1. **l10n:** actualizar `accountTypeBank`→"Cuenta corriente" y `accountTypeOther`→"Cuenta general" en `app_es.arb`/`app_en.arb`, `flutter gen-l10n`. El valor del enum (`bank`/`other`) no cambia — es aditivo en dato, no en significado.
2. **Pencil:** actualizar el label de los 2 chips existentes en `CwiKu`/`xdLeB` ("Banco"→"Cuenta corriente", "Otro"→"Cuenta general"). Sin selector nuevo, sin íconos nuevos.
3. Sin cambios de esquema Drift, sin `/drift-schema-change`, sin bump de `schemaVersion` para esta sub-feature.

### Decisión A-1 — dónde vive la deuda → **REABIERTA y RE-RESUELTA (usuario, 2026-07-21)**

> La resolución anterior (Deudas = solo informal; `loan`/`mortgage` = tipos de cuenta) **queda anulada**. El análisis de refinamiento de Deudas mostró que la costura estaba mal trazada.

La costura correcta **no es formal vs. informal** —el gota a gota es informal pero se comporta como un crédito (cuota, cadencia, avance); "le debo 50 lucas a mi hermano" es informal y flojo—, sino **"instrumento de gasto vs. compromiso de monto que amortizas"**:

- **Tarjeta de crédito → se queda como cuenta (`AccountType.card`).** Es un instrumento de gasto: le cargas transacciones, tiene cupo disponible, extractos; su deuda *emerge* del gasto. Nada cambia acá.
- **Todo lo demás que se debe o te deben → feature Deudas.** Incluye lo **informal** (préstamo al primo, gota a gota) **y lo formal/institucional** (crédito vehicular, hipoteca, libre inversión). Es un monto fijo que baja hacia 0, con un **único modelo de avance** construido una sola vez. Ver `docs/requirements/08-deudas.md` (ledger de asientos, cuota vía Pagos Programados, interés simple diario).

**Consecuencia (afecta la Sub-feature A):** los tipos de cuenta `loan`/`mortgage` propuestos abajo **ya NO hacen falta** y se retiran del mapeo. Motivos:
- Una **cuenta no tiene "principal original"**; habría que inventarle un `originalPrincipalMinor` para *fingir* la barra de avance → olor a que se reconstruye `Debts` dentro de `Accounts`. El principal ya vive en `Debts`.
- El avance ("pagado / total") es una **misma UX** para el banco y para el gota a gota; con `loan`=cuenta se construiría dos veces (en detalle de cuenta y en Deudas).
- "Pagar la cuota" no necesita el rodeo de transferencia off-budget: la transacción de abono ya lleva `debtId` + `categoryId` opcional y pega al presupuesto por la misma mecánica (feature B se simplifica; su on/off-budget queda solo para cuenta-a-cuenta real como fondear ahorro/inversión).

---

## 3. Sub-feature B — Transferencias presupuestables (el cambio de fondo)

### Qué pide el usuario
Que una transferencia (ej. ahorrar, o pagar un préstamo) **opcionalmente** cuente como:
- **Gasto** en la cuenta origen → afecta presupuestos y reportes.
- **Ingreso** en la cuenta destino → registrado en reportes, afecta saldo (ya ocurre) y presupuestos.
- Con un **toggle** en el formulario de transferencia.
- Con una **sugerencia** automática para ciertos tipos (préstamo, hipoteca…) que incentive marcarla como gasto.

### Aclaración crítica (evitar doble conteo)
El **saldo ya se mueve** en ambas cuentas hoy. B **no** cambia el saldo: es una **capa de clasificación** para presupuestos y reportes. Marcar "cuenta como gasto" NO debe volver a sumar/restar al saldo, o se contaría doble.

Y ojo con el neto: si entre **dos cuentas on-budget** el origen cuenta como gasto **y** el destino como ingreso a la vez, el efecto en el presupuesto es cero (se anulan) y no aporta nada. El caso que el usuario quiere (pagar préstamo / ahorrar afuera) es cuando el dinero **sale del espacio presupuestado**.

### Modelo recomendado — on-budget / off-budget (estándar tipo YNAB)
Marcar cada cuenta como **on-budget** (dentro del presupuesto) u **off-budget** (préstamos, inversiones, externo). La clasificación de la transferencia se **deriva** y el toggle es un **override**:
- on-budget → on-budget: **neutral** (comportamiento actual). El saldo se mueve, presupuesto intacto.
- on-budget → **off-budget** (pagar préstamo/hipoteca, fondear inversión): cuenta como **gasto/egreso** del presupuesto y del reporte. Sin ingreso fantasma.
- off-budget → on-budget: cuenta como **ingreso** a presupuestar.

Ventajas: da la **sugerencia gratis** (los tipos `loan/mortgage/investment/...` nacen off-budget → el toggle viene sugerido/activado), no doble-cuenta, y escala a metas/ahorro. El toggle por transferencia permite excepciones manuales.

### Alternativa simple (si se quiere menos alcance)
Un flag por transferencia `countsAsExpense` (bool) + permitir **categoría** en la transferencia cuando está activo. Los presupuestos amplían su filtro a `type = expense OR (type = transfer AND countsAsExpense)`. Menos robusto (el usuario decide cada vez, sin inferencia), pero es el mínimo viable y no necesita el atributo on/off-budget en cuentas.

### Cambios de datos (B)
- **`Accounts`:** columna `onBudget` (bool) — o derivar de `AccountType.defaultOffBudget` con override por cuenta. (Modelo recomendado.)
- **`Transactions`:** para que una transferencia entre a un presupuesto necesita **categoría** (hoy es null en transfers). Añadir soporte de `categoryId` en transfers presupuestables + un `budgetImpact`/`countsAsExpense` (o derivarlo de on/off-budget). Bump `schemaVersion`.
- **Presupuestos:** ampliar el datasource que hoy filtra `type = expense` para incluir las transferencias que cuentan como egreso, mapeándolas a `BudgetExpense` con su categoría/monto del **lado origen**. Revisar `budget_expense.dart` y el datasource de presupuestos.
- **Reportes (futuro):** cuando se construya `lib/features/reports/`, tratar estas transferencias como gasto/ingreso según el modelo. Dejar el requisito escrito en `docs/requirements/10-graficas-informes.md`.

### Cambios de UI (B) — requieren Pencil
- **Toggle "Esta transferencia cuenta como gasto"** en el formulario de transferencia (`transaction_form_page`/`transaction_form_cubit`). Al activarlo, **habilitar selector de categoría** (para que pegue al presupuesto correcto). Reusar el selector de categoría existente como componente.
- **Nudge/sugerencia:** cuando el destino (u origen) es un tipo off-budget (préstamo/hipoteca/inversión), pre-activar el toggle o mostrar un hint positivo ("Pagar tu préstamo puede contar en tu presupuesto"). Tono positivo, nunca punitivo (MASTER/brand).
- Diseñar en `billetudo.pen` (pantalla de transferencia) antes de implementar.

---

## 4. Decisiones abiertas (para el usuario)

1. ~~**A-1** Préstamo/Hipoteca: cuenta vs deuda~~ → **REABIERTA y RE-RESUELTA:** solo la **tarjeta** es cuenta; **toda** la demás deuda (informal + formal/institucional) vive en la feature Deudas. `loan`/`mortgage` retirados del mapeo. Ver §2 y `docs/requirements/08-deudas.md`.
2. ~~**A-2** Renombres: ¿`bank`→"Cuenta corriente" y `other`→"Cuenta general", o agregar `checking`/`general` como tipos nuevos y conservar los actuales?~~ → **DECIDIDO (usuario, 2026-07-24): renombrar.** `bank`→"Cuenta corriente", `other`→"Cuenta general". Solo cambia el label l10n (`accountTypeBank`/`accountTypeOther` en `app_es.arb`/`app_en.arb`); el valor del enum y las filas existentes no se tocan — es aditivo en dato, no en significado.
3. ~~**B-1** Modelo: **on/off-budget por cuenta** (recomendado, robusto) vs **flag simple `countsAsExpense` por transferencia** (mínimo viable).~~ → **DECIDIDO (usuario, 2026-07-24): on/off-budget por cuenta**, sin perder el flag. La cuenta fija el comportamiento por defecto (menos fricción, sin error silencioso si el usuario olvida marcar algo); el toggle por transferencia se conserva como **override manual** para la excepción puntual, tal como ya lo describe el modelo recomendado en §3 — no es un modelo aparte, es la combinación de ambos.
4. ~~**B-2** El "ingreso en el destino": ¿se registra como ingreso a presupuestar solo cuando entra a una cuenta on-budget desde una off-budget, o siempre que el usuario lo marque?~~ → **DECIDIDO (usuario, 2026-07-24): las dos, mismo patrón que B-1.** Por defecto se **deriva** (off-budget → on-budget = ingreso a presupuestar automático, sin que el usuario tenga que marcar nada). El toggle de la transferencia se conserva como **override manual** para la excepción puntual (ej. el usuario no quiere que ese ingreso puntual cuente, o sí quiere marcarlo aunque el par de cuentas no lo derive). Simetría exacta con B-1: la cuenta fija el default, el flag cubre la excepción — en ningún punto el usuario tiene que decidir a mano el caso común.
5. ~~**B-3** ¿La transferencia presupuestable exige **categoría** obligatoria?~~ → **DECIDIDO (usuario, 2026-07-24): sí, obligatoria** cuando la transferencia cuenta como gasto (derivado u override). Sin categoría no pega a ningún sobre — mismo comportamiento que un gasto normal.

---

## 5. Dimensionamiento y plan por fases

Esfuerzo estimado: **A = XS** (alcance recortado a renombre), **B = L** (toca datos + presupuestos + UI + reportes futuros). Sugerido en fases independientes y desplegables:

1. **Fase A — Renombre de tipos de cuenta.** l10n (`accountTypeBank`/`accountTypeOther`) + labels de los 2 chips existentes en Pencil (`CwiKu`/`xdLeB`). Sin cambios de esquema ni de enum. Se puede hacer en cualquier momento, sin bloquear B.
2. **Fase B1 — Atributo on/off-budget en cuentas** (columna + default por tipo + override). Schema + UI mínima (un switch en el form/detalle de cuenta).
3. **Fase B2 — Transferencia presupuestable (motor).** `Transactions`: categoría + clasificación en transfers; ampliar presupuestos para consumirlas; casos de uso y tests (el saldo NO se toca; verificar no-doble-conteo).
4. **Fase B3 — UI de transferencia + nudge.** Diseño Pencil (toggle + categoría + sugerencia por tipo) → implementación. Golden + Patrol.
5. **Fase B4 — Reportes (cuando exista la feature).** Requisito anotado en `10-graficas-informes.md`.

## 6. Cumplimiento (Nivel 0 / legal / tono)
- Todo esto es **Nivel 0 gratis**: registro manual, presupuestos, categorías. **Nada** de esto puede quedar tras anuncio o Premium.
- Dinero siempre en **centavos** (enteros); IDs UUID; `updatedAt` en cada escritura; borrado con `deletedAt`/`tombstonedAt` según corresponda.
- Tono **positivo** en el nudge — nunca avergonzar por pagar/deber.
- Actualizar los requirements afectados al implementar: `01-cuentas.md`, `03-transacciones.md`, `06-presupuestos.md`, `08-deudas.md`, `10-graficas-informes.md`.
