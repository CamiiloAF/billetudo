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
Que una transferencia (ej. ahorrar, o pagar un préstamo) **opcionalmente** cuente en presupuestos y reportes, con un **toggle** en el formulario de transferencia.

### Aclaración crítica (evitar doble conteo)
El **saldo ya se mueve** en ambas cuentas hoy. B **no** cambia el saldo: es una **capa de clasificación** para presupuestos y reportes. Marcar la transferencia como presupuestable NO debe volver a sumar/restar al saldo, o se contaría doble.

### Modelo — on/off-budget por cuenta: **DESCARTADO (usuario, 2026-07-24)**

> Se había decidido inicialmente marcar cada **cuenta** como on-budget/off-budget, derivando de ahí la clasificación de la transferencia. Al diseñar la pantalla en Pencil, el usuario notó el conflicto real: los presupuestos **ya tienen su propio alcance por cuenta** (`BudgetAccounts`, `docs/requirements/06-presupuestos.md` HU-01 — 0..N cuentas elegidas al crear el presupuesto, 0 = todas). Un atributo global "esta cuenta es on-budget" sería un **segundo eje de alcance compitiendo con el primero** — confuso y redundante, no complementario. Se descarta por completo: **no se añade ninguna columna a `Accounts`**. El switch ya diseñado en Pencil (`dFOnJ`/`Ydf4N`) se retira del canvas.

### Modelo elegido — flag único simétrico por transferencia

Un solo flag booleano en la transferencia (ej. `countsInBudget`) + una sola **categoría** que se habilita cuando está activo:
- **Sin marcar (default):** comportamiento actual, neutral. El saldo se mueve, ninguna transferencia entra a presupuestos ni reportes.
- **Marcada:** la transferencia se trata en presupuestos/reportes **igual que una transacción normal categorizada**, con efecto en ambos extremos según el alcance que ya tiene cada presupuesto — sin flags ni categorías separadas por lado:
  - Para cualquier presupuesto cuyo alcance (por cuenta) incluya la cuenta **origen**: cuenta como **gasto/egreso** de esa categoría.
  - Para cualquier presupuesto cuyo alcance incluya la cuenta **destino** (si el usuario llegó a crear uno ahí, ej. un presupuesto de ahorro): cuenta como **ingreso** de esa categoría.
- Es **el mismo mecanismo de alcance que ya usan los gastos/ingresos normales** (`BudgetAccounts`/`BudgetCategories`) — no se inventa un concepto nuevo, la transferencia presupuestable simplemente deja de estar excluida por `type = transfer` cuando el flag está activo, y aporta su categoría como cualquier otra transacción.
- **Caso borde aceptado, no un bug:** si ambas cuentas caen en el alcance del **mismo** presupuesto, el efecto se anula (gasto + ingreso de la misma categoría en el mismo presupuesto). Es correcto: ese presupuesto ve ambos lados del movimiento, así que "netea" — no hay dinero saliendo de *su* alcance. No hace falta lógica especial para evitarlo, es una consecuencia natural del alcance ya existente.
- Sin sugerencia automática por tipo de cuenta (ya no aplica, no hay tipos especiales que la habiliten tras el recorte de la Sub-feature A).

### Cambios de datos (B)
- **`Transactions`:** para que una transferencia entre a un presupuesto necesita **categoría** (hoy es `null` en transfers). Añadir `categoryId` habilitado en transfers + un flag `countsInBudget` (bool, default `false`). Bump `schemaVersion`. **Sin cambios en `Accounts`.**
- **Presupuestos:** ampliar el datasource que hoy filtra `type = expense` para incluir transferencias con `countsInBudget = true`: lado origen entra como `BudgetExpense` si la cuenta origen está en el alcance del presupuesto; lado destino entra como ingreso si la cuenta destino está en el alcance. Revisar `budget_expense.dart` y el datasource de presupuestos.
- **Reportes (futuro):** requisito ya escrito y **precisado** en `docs/requirements/10-graficas-informes.md` §Reglas de conteo (2026-07-24). La simetría origen/destino **no** se traslada tal cual: un reporte es global, no tiene alcance por cuenta, así que ve **siempre** ambos lados y aplicar la regla simétrica inflaría ingreso y gasto del mismo mes neteando a cero. En reportes cuenta **solo el lado origen, como gasto** de su categoría.

### Cambios de UI (B) — diseño en Pencil, EN CURSO (2026-07-24)

- **Toggle "¿Incluir en tu presupuesto?"** en el formulario de transferencia, reusando el componente `Toggle Field` (`gZyEC`, creado originalmente para el intento descartado de Cuentas). (Copy unificado el 2026-07-24 con el mismo toggle de los sheets de Metas; antes era "Cuenta en tu presupuesto", cambiado por ambiguo en un form lleno de "Cuenta origen/destino".) Al activarlo, se habilita el selector de categoría (`Category Quick Picker`, una sola, aplica a ambos lados del flag simétrico). Sin nudge/sugerencia automática (ya no aplica, ver arriba).
- **Posición final (decisión del usuario, no la solicitud original):** Cuenta → Fecha → Nota → Toggle → Categoría — al final del formulario, no justo tras la cuenta. Motivo: con el toggle inmediatamente después de la cuenta, Fecha y Nota quedaban tapadas por el teclado/zona de monto expandida (regresión frente al patrón ya aprobado en el form de Gasto). Con el toggle al final, solo el bloque opcional nuevo puede requerir scroll — igual que ya pasa con `Tags Row` en Gasto.
- **Se retiró el `Info Box` estático** ("las transferencias no cuentan como gasto ni ingreso") — quedaba redundante en OFF y directamente falso en ON. El propio hint del toggle cubre esa explicación.
- **Zona Fija de monto colapsada** (`ofg07`, mismo patrón que "Nota activa") en los estados con toggle ON, para que la categoría no quede tapada.
- **Hallazgo de accesibilidad corregido de paso:** primera instancia del componente `Switch` (`bWezV`) en estado OFF en todo el sistema — su color por defecto (`$border`) no cumplía 3:1 WCAG contra `$surface` en ningún tema. Corregido a `$text-secondary` a nivel de instancia (no se tocó el componente base). Pendiente de anotar en `MASTER.md` cuando se documente esta pieza.

**Estado del diseño — tema claro APROBADO (3 estados), tema oscuro en revisión:**

| Estado | Claro (aprobado) | Oscuro (en revisión) |
|---|---|---|
| Toggle OFF | `l4nR7l` | `L8bqAX` |
| Toggle ON | `S5Tjj` | `IRuP2` |
| Toggle ON + nota activa | `BmCFj` | `fmWeI` |

No se diseñó el 4to cruce (nota activa + toggle OFF) — decisión del usuario: no aporta nada nuevo sobre el patrón de nota activa ya existente.

**Falta:** auditoría de `ui-ux-reviewer` sobre el tema oscuro → aprobación del usuario → documentar `design-system/billetudo/pages/transacciones.md` (recién ahí, según la regla de "aprobar antes de documentar").

---

## 4. Decisiones abiertas (para el usuario)

1. ~~**A-1** Préstamo/Hipoteca: cuenta vs deuda~~ → **REABIERTA y RE-RESUELTA:** solo la **tarjeta** es cuenta; **toda** la demás deuda (informal + formal/institucional) vive en la feature Deudas. `loan`/`mortgage` retirados del mapeo. Ver §2 y `docs/requirements/08-deudas.md`.
2. ~~**A-2** Renombres: ¿`bank`→"Cuenta corriente" y `other`→"Cuenta general", o agregar `checking`/`general` como tipos nuevos y conservar los actuales?~~ → **DECIDIDO (usuario, 2026-07-24): renombrar.** `bank`→"Cuenta corriente", `other`→"Cuenta general". Solo cambia el label l10n (`accountTypeBank`/`accountTypeOther` en `app_es.arb`/`app_en.arb`); el valor del enum y las filas existentes no se tocan — es aditivo en dato, no en significado.
3. ~~**B-1** Modelo: **on/off-budget por cuenta** (recomendado, robusto) vs **flag simple `countsAsExpense` por transferencia** (mínimo viable).~~ → **REABIERTA y RE-DECIDIDA (usuario, 2026-07-24, tras diseñar en Pencil):** el modelo on/off-budget por cuenta se descarta — choca con el alcance por cuenta que **ya tienen los presupuestos** (`BudgetAccounts`), sería un segundo eje de configuración redundante. Se adopta el **flag único simétrico por transferencia** (`countsInBudget` + categoría), sin tocar `Accounts`. Ver §3 para el detalle completo del modelo final.
4. ~~**B-2** El "ingreso en el destino": ¿se registra como ingreso a presupuestar solo cuando entra a una cuenta on-budget desde una off-budget, o siempre que el usuario lo marque?~~ → **REABIERTA y RE-DECIDIDA junto con B-1 (usuario, 2026-07-24): un mismo flag cubre ambos lados.** No hay flags ni categorías separadas por lado. Con el flag activo, la transferencia entra a **cualquier** presupuesto cuya cuenta esté en su alcance — como gasto si es la cuenta origen, como ingreso si es la cuenta destino — usando la misma categoría y el mismo mecanismo de alcance que ya usan las transacciones normales. Sin derivación por tipo de cuenta (ya no existe ese concepto).
5. ~~**B-3** ¿La transferencia presupuestable exige **categoría** obligatoria?~~ → **DECIDIDO (usuario, 2026-07-24): sí, obligatoria** cuando la transferencia cuenta como gasto (derivado u override). Sin categoría no pega a ningún sobre — mismo comportamiento que un gasto normal.

---

## 5. Dimensionamiento y plan por fases

Esfuerzo estimado: **A = XS** (alcance recortado a renombre), **B = M** (bajó de L: sin columna nueva en `Accounts`, sin sugerencia automática). Sugerido en fases independientes y desplegables:

1. **Fase A — Renombre de tipos de cuenta.** l10n (`accountTypeBank`/`accountTypeOther`) + labels de los 2 chips existentes en Pencil (`CwiKu`/`xdLeB`). Sin cambios de esquema ni de enum. Se puede hacer en cualquier momento, sin bloquear B. **✅ Implementada y commiteada.**
2. **Fase B1 — Transferencia presupuestable (motor).** `categoryId` habilitado + `countsInBudget` (bool) en `Transactions` (ya en schema v18, sin bump nuevo); presupuestos ampliados para consumirlas — gasto si la cuenta origen está en su alcance. **✅ Implementado (lado origen).** Lado destino ("ingreso si es la cuenta destino", y el neteo cuando ambas caen en el mismo alcance) **queda pendiente**: el dominio de presupuestos no tiene hoy un concepto de "ingreso por alcance" que extender (`ZeroBasedSummary` solo suma un ingreso global) — ver `docs/requirements/06-presupuestos.md` §Reglas de negocio y edge cases. Tests: pendientes de `qa-automator`.
3. **Fase B2 — UI de transferencia.** Diseño Pencil (toggle `countsInBudget` reusando `Toggle Field` `gZyEC` + selector de categoría) → implementación. **✅ Implementado** (`ToggleField`/`AppSwitch` nuevos en `lib/core/widgets/`, bloque condicional en el formulario de transferencia). Golden + Patrol: pendientes de `qa-automator` (los goldens existentes de "create transfer" quedaron desactualizados por el retiro del Info Box, a regenerar).
4. **Fase B3 — Reportes (cuando exista la feature).** Requisito anotado en `10-graficas-informes.md`.

## 6. Cumplimiento (Nivel 0 / legal / tono)
- Todo esto es **Nivel 0 gratis**: registro manual, presupuestos, categorías. **Nada** de esto puede quedar tras anuncio o Premium.
- Dinero siempre en **centavos** (enteros); IDs UUID; `updatedAt` en cada escritura; borrado con `deletedAt`/`tombstonedAt` según corresponda.
- Tono **positivo** — nunca avergonzar por pagar/deber.
- Actualizar los requirements afectados al implementar: `01-cuentas.md`, `03-transacciones.md`, `06-presupuestos.md`, `08-deudas.md`, `10-graficas-informes.md`.
