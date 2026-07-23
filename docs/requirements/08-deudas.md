# Feature: Deudas y préstamos

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Debts` (`lib/core/database/app_database.dart`), + nueva `DebtEntries` (ver "Cambios de esquema")

## Contexto

Cubre **todo lo que el usuario debe o le deben**, en un solo modelo, para ambas direcciones (`DebtDirection`: `iOwe` / `owedToMe`):

- **Deuda informal entre personas:** le presté al primo, le debo a un amigo, gota a gota.
- **Deuda formal/institucional:** crédito vehicular, hipoteca, crédito de libre inversión.

La única deuda que **no** vive acá es la **tarjeta de crédito**, porque una tarjeta es un **instrumento de gasto** (le cargas transacciones, tiene cupo disponible, extractos): su deuda *emerge* del gasto, así que se modela como **cuenta** (`AccountType.card`, ver `01-cuentas.md`), no como Deuda.

> **La costura correcta no es formal vs. informal, es "instrumento de gasto vs. compromiso de monto que amortizas".** El gota a gota es informal pero se comporta como un crédito (cuota, cadencia, ganas de ver el avance); "le debo 50 lucas a mi hermano" es informal y flojo. La formalidad no predice el comportamiento; sí lo predice el que sea un monto fijo que baja hacia 0. Por eso **tarjeta = cuenta; todo lo demás que se debe o te deben = Deuda.** (Consecuencia: los tipos de cuenta `loan`/`mortgage` que se habían propuesto en `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §2 ya **no** hacen falta; ver Decisión A-1 reabierta ahí.)

Objetivo diferenciador: que el usuario **sienta el progreso** de una deuda —tanto la grande con el banco como el préstamo del gota a gota o del familiar— con una **misma** experiencia de avance construida una sola vez.

## Modelo: la deuda es un ledger de asientos, el saldo se deriva

En cuanto entra el interés que crece día a día, el saldo **deja de ser** `principal − abonos`. El saldo pendiente se **deriva** de un pequeño libro de asientos tipados; nunca se guarda como un número mutable:

```
saldo pendiente = apertura (principalMinor)
                + Σ desembolsos posteriores   (aumentan la deuda)
                + Σ intereses acumulados       (solo-deuda, no caja)
                ± Σ ajustes manuales           (solo-deuda, "poner la cifra del banco")
                − Σ abonos / cuotas            (reducen la deuda)
```

Hay **dos naturalezas de asiento** que no se pueden mezclar:

- **Eventos de caja** — mueven una de tus cuentas. Son una `Transaction` con `debtId` (columna ya existente). Ej.: tomar el préstamo (entra plata), pagar la cuota (sale plata). Afectan saldos y presupuestos (ver "Estadísticas").
- **Eventos de solo-deuda** — NO mueven ninguna cuenta. El interés diario y el "actualizar saldo" solo cambian *cuánto debes*; no sale ni entra plata ese día. Viven en la tabla `DebtEntries` (ver esquema), **nunca** como `Transaction`. Por construcción quedan fuera de las gráficas de flujo y de los presupuestos.

Este mismo ledger sirve para todo: préstamo familiar (apertura + abonos), gota a gota (apertura + abonos + quizá interés), y crédito vehicular (apertura + interés diario + abonos + algún ajuste de reconciliación). Un solo modelo, escala según qué asientos uses.

### El signo lo decide (`direction` × `type`)

Una `Transaction` con `debtId` no siempre reduce la deuda. El efecto se deriva del par:

| `direction` | `type` de la tx | Significa | Efecto en la deuda |
|---|---|---|---|
| `iOwe` (yo debo) | `income` (entra plata) | **desembolso** — tomé el préstamo | aumenta |
| `iOwe` | `expense` (sale plata) | **abono / cuota** — pago | reduce |
| `owedToMe` (me deben) | `expense` (sale plata) | **desembolso** — presté | aumenta |
| `owedToMe` | `income` (entra plata) | **abono** — me pagaron | reduce |

`principalMinor` es el **saldo de apertura** (para deudas que ya existían antes de usar la app, sin transacción de origen). Si el desembolso sí se registra como transacción de caja, `principalMinor` puede quedar en 0 y el saldo se construye desde los asientos.

## Historias de usuario

### HU-01 — Registrar una deuda
Como usuario quiero registrar una deuda que tengo (o que me deben) con nombre, monto, moneda y contraparte, para llevar control de compromisos que no están en mis cuentas normales.

**Criterios de aceptación:**
- Campos: `name` (obligatorio), `direction` (`iOwe`/`owedToMe`, obligatorio), `principalMinor` (obligatorio, centavos — saldo de apertura), `currency`, `counterparty` (opcional, ej. "Banco Bogotá" o "Juan Pérez"), `dueDate` (opcional), `interestRateBps` (opcional, % anual en puntos base — ver HU-06).
- No hay límite de deudas simultáneas (Nivel 0).
- Al crear, el usuario puede **opcionalmente** registrar el desembolso como movimiento de caja hacia/desde una cuenta (ver HU-02): útil cuando el préstamo entró a una cuenta real.

### HU-02 — Registrar el desembolso y los abonos (con caja opcional)
Como usuario quiero registrar cuándo tomé/di el préstamo y cada abono, y decidir en cada uno si toca una de mis cuentas, porque a veces se paga por fuera de la app (efectivo, o alguien más lo paga).

**Criterios de aceptación:**
- Cada evento (desembolso o abono) ofrece un toggle **"¿agregar a una cuenta?"**:
  - **Sí** → crea una `Transaction` con `debtId` que mueve el saldo de la cuenta elegida (ingreso o gasto según `direction`×`type`) y **afecta estadísticas** (ver sección).
  - **No** → **cambia la deuda igual** (sube el desembolso, baja el abono, suma al avance), pero **no toca saldos ni presupuestos**. Es la salida para "lo pagó otro / fue en efectivo / por fuera de mis cuentas".
- **El default del toggle se recuerda por deuda** (última elección de *esa* deuda, incluida la última cuenta usada), con fallback a la última elección global para una deuda nueva, y default duro "Sí". Se guarda en **preferencias locales** indexadas por `debtId` (no sincroniza; es solo el default de un toggle, la verdad real es por-transacción). Opción futura: promover a columna en `Debts` si se quiere que sincronice.
- El saldo pendiente se deriva del ledger (ver "Modelo"), respetando la dirección.
- El saldo pendiente **nunca se muestra negativo**; si los abonos superan el saldo, la deuda se marca **saldada** y se avisa el exceso (el cálculo sí puede pasar de 0; el límite es de presentación).

### HU-03 — Cuota programada (opcional) vía Pagos Programados
Como usuario quiero ponerle una cuota a una deuda para que, al llegar la fecha, se genere la transacción (automática o con confirmación) desde la cuenta que yo elija, sin tener que registrarla a mano cada mes.

**Criterios de aceptación:**
- La cuota **reusa el motor de Pagos Programados** (`ScheduledPayments`, `09-pagos-programados.md`) — no hay motor nuevo. Configurar una cuota en la deuda crea un `ScheduledPayment` enlazado por `debtId`; al dispararse genera una `Transaction` con `debtId` (gasto para `iOwe`) que baja la cuenta **y** reduce la deuda.
- **Regla de UX (crítica, para no generar ruido):** separar por trabajo, no por feature —
  - **Configurar/editar la cuota** (monto, día, cadencia, auto/manual) vive en **Deudas** (es propiedad de la deuda; el usuario piensa "mi crédito tiene cuota", no "voy a crear un pago programado").
  - **Confirmar / omitir / posponer** una cuota que **vence** vive en **Pagos Programados** (la bandeja única de vencimientos; misma acción que el arriendo o Netflix). Duplicar la aprobación en dos bandejas sería el ruido a evitar.
  - El detalle de la deuda **muestra** la próxima cuota con un **atajo** al mismo flujo de confirmación (un solo flujo, dos entradas, nunca dos bandejas compitiendo).
- **Cross-link Deuda ↔ Pago Programado (ambos sentidos):**
  - En la **lista** de Pagos Programados y en la **tarjeta**, un **badge/banner** identifica que ese pago corresponde a una deuda.
  - En el **detalle** del pago programado, un **card** indica cuál deuda se está pagando; al tocarlo navega al **detalle de la deuda**.
- **Abono ad-hoc vs. cuota programada (la distinción real es programado vs. ad-hoc, no formal vs. informal):**
  - Cualquier deuda —formal o informal— puede tener **cuota programada** (un gota a gota informal la tiene; un crédito bancario que pagas a mano puede no tenerla). Con cuota → entra a Pagos Programados como arriba.
  - Cualquier abono suelto sin fecha fija (ej. me prestaron 100k y abono 50k desde Nequi cuando puedo) se registra **ad-hoc desde Deudas**: queda en el **historial de la deuda** y mueve la cuenta (si el toggle de caja está en "Sí"), pero **no** aparece en Pagos Programados (no fue agendado).
- Modo auto/manual, catch-up, omitir/posponer: heredados tal cual de `09-pagos-programados.md` (HU-02/HU-03/HU-07).

### HU-04 — Ver saldo pendiente, avance y vencimiento
Como usuario quiero ver cuánto debo (o me deben) en total y por deuda, con el avance y la fecha de vencimiento, para priorizar y sentir el progreso.

**Criterios de aceptación:**
- Vista resumen: total `iOwe` pendiente vs. total `owedToMe` pendiente. **Multi-moneda:** en Fase 0 los totales se **segmentan por moneda** (no se normaliza a una base; ver `12-multi-moneda.md` para la normalización futura).
- **Barra de avance "pagado / total"** por deuda (análoga al "cupo usado" de la tarjeta), es el corazón emocional de la feature y se construye **una sola vez** para deuda formal e informal.
- Si `dueDate` existe y se acerca (umbral configurable, ej. 7 días), se muestra un aviso local (sin IA).
- Tono **neutral/positivo, nunca alarmista** — la regla de "nunca avergonzar al usuario por sus gastos" se extiende a sus deudas.

### HU-05 — Editar y eliminar deuda
Como usuario quiero modificar los datos de una deuda o eliminarla cuando se salda o fue un error.

**Criterios de aceptación:**
- Editar `principalMinor` (apertura) no borra el historial de abonos ni de asientos ya registrados.
- Eliminar es **borrado lógico reversible (`deletedAt`)**, recuperable desde papelera.
  - **Nota sobre `deletedAt` vs `tombstonedAt`:** las `Transaction` con `debtId` referencian la fila. `deletedAt` mantiene la fila viva (soft delete), así que la integridad FK no se rompe; la diferencia con `tombstonedAt` es solo la **reversibilidad**, y aquí el usuario **sí** quiere restaurar → `deletedAt` es lo correcto (no es el caso de "lápida irreversible" de CLAUDE.md).
  - Al eliminar una deuda, sus abonos de caja **no se borran** (fueron movimientos reales de cuenta): quedan con su `debtId` apuntando a la deuda en papelera y **siguen** afectando saldos. Al **restaurar** la deuda, todo vuelve a contar en sus resúmenes. Los asientos de solo-deuda (`DebtEntries`) sí se ocultan con ella.

**Quitar la cuota de una deuda (que sigue viva) = eliminar su pago programado.** El vínculo cuota↔deuda vive en `ScheduledPayments.debtId`, así que **no existe un "desligar" separado**: para quitarle la cuota a una deuda, el usuario **elimina el pago programado** (acción "Eliminar cuota" en la config de cuota, modo edición; o "Eliminar pago programado" desde el detalle del PP — es el mismo objeto). Es borrado lógico (`deletedAt`, HU-05 de `09-pagos-programados.md`): detiene la generación futura, pero las **transacciones ya generadas se conservan** (fueron abonos reales que ya redujeron la deuda, mantienen su `debtId`). La deuda **sigue existiendo, sin cuota**. **No se soporta** `debtId → null` (desligar conservando el pago como plantilla suelta): contradiría el principio de `09-pagos` línea 111 de que la plantilla de una cuota no existe como plantilla independiente. Si aparece la necesidad real, se evalúa en una fase posterior.

### HU-06 — Interés (opcional): ver la deuda crecer día a día
Como usuario quiero ver cómo mi deuda aumenta cada día según su tasa, tal como lo veo en la app del banco, para tenerla al día.

**Criterios de aceptación:**
- **Modo de cálculo por deuda (`accrualMode`), opt-in:**
  - **Manual (default):** el usuario mantiene la cifra al día con **"actualizar saldo"** (igual que ajustar el saldo de una cuenta): pone la cifra real del banco y la app registra un asiento de **ajuste** (`DebtEntries`, solo-deuda) que absorbe la diferencia. Cero riesgo de matemática; siempre exacto contra el banco.
  - **Automático:** dada una **tasa fija anual** (`interestRateBps`), la app estima el crecimiento diario: `interés_del_día = saldo × (tasa_anual / 365)`, **compuesto** (el interés se suma al saldo y al día siguiente el saldo mayor genera más interés; entre pagos es la fórmula cerrada `saldo × (1 + tasa/365)^días`). Reproduce el "sube solito cada día" de la app del banco.
- **Con tasa fija + cuota fija se calcula todo lo estimable:** crecimiento diario (pasado→hoy), **fecha estimada de saldado** y el **split "cuánto de la cuota fue interés / cuánto capital"** salen del **mismo modelo simulado hacia adelante**. **No hace falta un motor de amortización francesa aparte** — proyectar es correr `(interés diario − cuota)` hacia el futuro hasta llegar a 0; esa simulación *es* la amortización.
- **Todo lo automático va rotulado "estimado":** no igualamos la cifra del banco al peso (convenciones de conteo de días 30/360 vs. real/365, redondeos, seguros metidos en la cuota). El **"actualizar saldo" manual es la válvula de reconciliación** y sigue disponible aunque el modo sea automático: al pagar, snapea a la cifra real y el ajuste absorbe el desfase.
- **El interés NO es caja:** el asiento de interés no toca ninguna cuenta ni presupuesto; solo crece la deuda. Lo único que pega a presupuesto es la **cuota** (el gasto real, HU-02/HU-03). El día de la cuota, el interés ya se acumuló al saldo, así que la cuota se descuenta del total completo (justo el comportamiento que el usuario ve en el banco).

### HU-07 — Marcar deuda como saldada
Como usuario quiero que una deuda pagada salga de mi vista activa sin eliminarla.

**Criterios de aceptación:**
- Se considera saldada automáticamente cuando el saldo pendiente llega a 0 (HU-02), sin acción manual extra; el usuario puede archivarla/ocultarla de la vista activa.

## Estadísticas: qué afecta una deuda (reemplaza la regla anterior de "excluir como transfer")

"Estadísticas" son tres cosas distintas y una deuda las toca distinto. **Esto invierte la regla previa** que excluía todo movimiento con `debtId` de los totales igual que un `transfer`:

- **Saldos:** siempre (si el evento tiene caja). Un desembolso `iOwe` sube la cuenta como **ingreso**; una cuota la baja como **gasto**.
- **Presupuestos:** la **cuota cuenta como gasto presupuestable** (presupuestas tu cuota de carro); el préstamo que entra puede ser **ingreso para presupuestar**. Es la misma mecánica de las transferencias presupuestables (`plan-cuentas...` §3): la transacción lleva `debtId` + `categoryId` opcional y pega al sobre.
- **Reporte de flujo (ingreso vs. gasto):** único lugar con riesgo de distorsión —un préstamo de 50M entra como "ingreso" que no ganaste, y las cuotas suman más que el préstamo por los intereses. Solución: los movimientos con `debtId` **cuentan por defecto**, pero el reporte de flujo puede **separarlos opcionalmente** como "movimientos de deuda" (toggle en la vista). Ver el cambio anotado en `10-graficas-informes.md`.
- **Interés (solo-deuda):** no toca ninguna de las tres (no es caja). Baja el patrimonio pero no es gasto de flujo.

## Patrimonio

Las deudas entran al **patrimonio total** (una hipoteca de 200M resta; lo que me debe el primo suma como cuenta por cobrar) pero **salen del "disponible para gastar" / presupuesto**. Es el "tracking account" de YNAB, nombrado con honestidad como deuda. Corrige la lectura previa de que "no es cuenta para no mezclar con el patrimonio": lo que había que separar era el patrimonio **líquido/gastable**, no el **total**.

## Categorías

`categoryId` sigue siendo **opcional** en las transacciones con `debtId` (ver `02-categorias.md`): sirve para que la cuota pegue al sobre correcto en presupuestos y para filtros del usuario, nunca para el cálculo del saldo pendiente.

## Fases

- **Fase 0:** ledger de asientos + registro de caja opcional por evento (HU-01/02) · cuota vía Pagos Programados con la regla de UX y el cross-link (HU-03) · avance y totales por moneda (HU-04) · borrado reversible (HU-05) · interés **manual** con "actualizar saldo" (HU-06) · saldada automática (HU-07).
- **Fase 0 opcional (barato, mismo modelo):** interés **automático** simple-diario + proyección de payoff + split interés/capital, todo rotulado "estimado" (HU-06).
- **Fase 1:** **tasa variable** exacta (historial de tasa con fecha efectiva; el interés diario usa la tasa vigente cada día). **Cuota variable no necesita nada** — la base ya es "registra el monto que pagaste"; lo único que la cuota fija añade es poder *proyectar*. Se puede **anotar** una tasa/cuota nueva como informativa desde ya aunque el cálculo con fecha efectiva llegue en Fase 1.

## Cambios de esquema requeridos (Drift)

- **Tabla nueva `DebtEntries`** (mixin `_SyncColumns`) para los asientos de **solo-deuda** (los de caja ya son `Transaction` con `debtId`): `debtId → Debts.id`, `kind` (`textEnum<DebtEntryKind>`: `interestAccrual`/`manualAdjustment`), `amountMinor` (con signo: + aumenta la deuda), `entryDate`, `note` (opcional), y snapshot de tasa usada para el interés (opcional). El saldo se deriva; no se guarda.
- **`Debts`:** añadir `accrualMode` (`textEnum`, `manual`/`auto`, default `manual`). `interestRateBps` ya existe. `lastAccruedAt` es derivable del último asiento (evaluar si se materializa por rendimiento).
- **`ScheduledPayments`:** añadir `debtId` (`text().nullable().references(Debts, #id)`) para enlazar la cuota a su deuda y que la `Transaction` generada herede el `debtId` (habilita el cross-link y el efecto sobre el saldo de la deuda).
- Subir `schemaVersion` y escribir la migración `onUpgrade` (todo aditivo; no hay datos que migrar). Mantener paridad en Supabase/PowerSync. Ejecutar vía `/drift-schema-change`.

## Cumplimiento (Nivel 0 / legal / tono)

- Todo es **Nivel 0 gratis**: registro, cuotas, avance, interés. **Nada** detrás de anuncio o Premium.
- Dinero en **centavos** (enteros); IDs UUID; `updatedAt` en cada escritura; borrado con `deletedAt` (papelera) según HU-05.
- Tono **positivo** en todo (avance, recordatorios de vencimiento) — nunca avergonzar por pagar o deber.
- Al implementar, actualizar los requirements con roce: `01-cuentas.md` (tarjeta se queda; `loan`/`mortgage` no se agregan), `09-pagos-programados.md` (link de cuota), `10-graficas-informes.md` (separación opcional en flujo), `06-presupuestos.md` (cuota presupuestable).
