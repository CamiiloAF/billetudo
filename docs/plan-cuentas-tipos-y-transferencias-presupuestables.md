# Plan — Tipos de cuenta ampliados + transferencias presupuestables

> **Estado:** Propuesta (corto plazo, **no** en ejecución). Solo análisis y plan.
> **Fecha:** 2026-07-21 · **Alcance:** Cuentas, Transacciones, Presupuestos, Reportes (y roce con Deudas).
> Cuando se implemente, seguir el flujo de diseño (Pencil primero) y `/drift-schema-change` para el esquema.

Este documento cubre tres cambios que el usuario pidió documentar juntos:

- **A.** Ampliar la lista de **tipos de cuenta** (a ~11, estilo el mockup adjunto) y cambiar el **selector** a un scroll horizontal de dos filas.
- **B.** Permitir que una **transferencia** cuente opcionalmente como **gasto** (origen) e **ingreso** (destino) que afecte **reportes y presupuestos**, con un **toggle** por transferencia y una **sugerencia** según el tipo de cuenta (ej. préstamo).

B es el cambio de fondo; A es el habilitador (los nuevos tipos de cuenta alimentan la sugerencia de B).

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

## 2. Sub-feature A — Tipos de cuenta ampliados + selector 2 filas

### Mapeo propuesto (mockup → dominio)
El mockup adjunto lista 11 tipos: *Cuenta general, Efectivo, Cuenta corriente, Tarjeta de crédito, Cuenta de ahorros, Bono, Seguro, Inversión, Préstamo, Hipoteca, Cuenta con sobregiro.* Mapeo sugerido sobre el enum actual (aditivo, sin romper filas existentes):

| Mockup | Enum | Nota |
|---|---|---|
| Cuenta general | `other` (relabel "General") | o nuevo `general` |
| Efectivo | `cash` | — |
| Cuenta corriente | `bank` (relabel) o nuevo `checking` | hoy `bank`="Banco" |
| Tarjeta de crédito | `card` | saldo negativo (deuda) |
| Cuenta de ahorros | `savings` | — |
| Bono | **nuevo** `bond` | activo |
| Seguro | **nuevo** `insurance` | activo |
| Inversión | `investment` | — |
| ~~Préstamo~~ | ~~`loan`~~ | **retirado** → feature Deudas (ver A-1 reabierta) |
| ~~Hipoteca~~ | ~~`mortgage`~~ | **retirado** → feature Deudas (ver A-1 reabierta) |
| Cuenta con sobregiro | **nuevo** `overdraft` | puede ir a negativo sin ser tarjeta |

### Implicaciones por tipo (a definir para cada uno)
Cada tipo debe declarar: ¿permite número completo? ¿tasa de interés? ¿es "tipo deuda" (saldo negativo, como tarjeta)? ¿es **on-budget u off-budget** (clave para B)? Propuesta (sin `loan`/`mortgage`, retirados a Deudas en A-1):
- **Tipo deuda (saldo negativo):** solo `card`. `overdraft` puede ir a negativo pero es on-budget.
- **Off-budget por defecto (sugieren "cuenta como gasto" en B):** `investment`, `bond`, `insurance`.
- **On-budget:** `cash`, `bank/checking`, `savings`, `card`, `overdraft`, `general`.

### Cambios técnicos (A)
1. **Drift/dominio:** añadir valores al enum `AccountType` (dominio + `db.AccountType`) y al mapper (`account_mapper.dart`). Añadir valores a un enum **texto es aditivo**: las filas actuales conservan su valor, no requiere migración de datos, pero **sí regenerar** con `build_runner` y considerar bump de `schemaVersion` si se agregan columnas nuevas (ver B). Usar `/drift-schema-change`.
2. **Presentación:** extender `AccountTypePresentation` (icono Lucide, color, color-soft, label) para cada tipo nuevo — `account_type_avatar.dart`. Requiere elegir 5 iconos/colores nuevos del sistema (tokens `$`, nunca hex).
3. **l10n:** nuevas keys `accountType*` en `app_es.arb` + `app_en.arb`, `flutter gen-l10n`.
4. **Reglas por tipo:** centralizar en el propio enum (getters `isDebtLike`, `defaultOffBudget`, `allowsFullAccountNumber`, `allowsInterestRate`) en vez de dispersarlas en `account_form_state`; migrar los `if (type == ...)` actuales.
5. **Selector 2 filas + scroll horizontal:** reemplazar `AccountTypeGrid` (`GridView.count` 3 col, no scrollable) por un `SingleChildScrollView(horizontal)` con **dos filas** de chips (`AccountTypeChip` se reusa tal cual). Mantener el patrón inline (no bottom sheet) para no romper el flujo del form; el mockup usa modal pero el sistema de diseño ya decidió grid inline + pill al editar (`cuentas.md`). **Requiere pasar por Pencil** (modifica `CwiKu`/`xdLeB`).

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
2. **A-2** Renombres: ¿`bank`→"Cuenta corriente" y `other`→"Cuenta general", o agregar `checking`/`general` como tipos nuevos y conservar los actuales?
3. **B-1** Modelo: **on/off-budget por cuenta** (recomendado, robusto) vs **flag simple `countsAsExpense` por transferencia** (mínimo viable).
4. **B-2** El "ingreso en el destino": ¿se registra como ingreso a presupuestar solo cuando entra a una cuenta on-budget desde una off-budget, o siempre que el usuario lo marque? (Recomendado: derivado, para no doble-contar.)
5. **B-3** ¿La transferencia presupuestable exige **categoría** obligatoria? (Recomendado: sí, si cuenta como gasto — sin categoría no pega a ningún sobre.)

---

## 5. Dimensionamiento y plan por fases

Esfuerzo estimado: **A = M**, **B = L** (toca datos + presupuestos + UI + reportes futuros). Sugerido en fases independientes y desplegables:

1. **Fase A1 — Tipos de cuenta (datos + presentación).** Enum, mapper, presentación, l10n, reglas por tipo centralizadas. `/drift-schema-change`. Sin UI nueva de selector todavía. Tests unit del mapper/enum.
2. **Fase A2 — Selector 2 filas.** Diseño Pencil → `AccountTypeGrid` a scroll horizontal de 2 filas. Golden tests. `/design-fidelity-check cuentas`.
3. **Fase B1 — Atributo on/off-budget en cuentas** (columna + default por tipo + override). Schema + UI mínima (un switch en el form/detalle de cuenta). 
4. **Fase B2 — Transferencia presupuestable (motor).** `Transactions`: categoría + clasificación en transfers; ampliar presupuestos para consumirlas; casos de uso y tests (el saldo NO se toca; verificar no-doble-conteo).
5. **Fase B3 — UI de transferencia + nudge.** Diseño Pencil (toggle + categoría + sugerencia por tipo) → implementación. Golden + Patrol.
6. **Fase B4 — Reportes (cuando exista la feature).** Requisito anotado en `10-graficas-informes.md`.

## 6. Cumplimiento (Nivel 0 / legal / tono)
- Todo esto es **Nivel 0 gratis**: registro manual, presupuestos, categorías. **Nada** de esto puede quedar tras anuncio o Premium.
- Dinero siempre en **centavos** (enteros); IDs UUID; `updatedAt` en cada escritura; borrado con `deletedAt`/`tombstonedAt` según corresponda.
- Tono **positivo** en el nudge — nunca avergonzar por pagar/deber.
- Actualizar los requirements afectados al implementar: `01-cuentas.md`, `03-transacciones.md`, `06-presupuestos.md`, `08-deudas.md`, `10-graficas-informes.md`.
