# Feature: Presupuestos

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Budgets` + tablas de unión `BudgetAccounts`, `BudgetCategories` (`lib/core/database/app_database.dart`)

## Contexto

Presupuestos flexibles con **alcance configurable** (una o varias cuentas y/o categorías, o global), **periodicidad y anclaje elegidos por el usuario**, y un modo base-cero opcional inspirado en YNAB — pero **sin su fricción ni obligatoriedad**. Alimentan el cálculo de "disponible para gastar" (safe-to-spend), motor de retención clave de Fase 3, y las alertas anticipadas y positivas.

**Filosofía de fechas — el usuario no queda atado al calendario.** Un presupuesto recurrente se **ancla a una fecha de inicio que el usuario elige libremente**, y la periodicidad se mantiene idéntica periodo a periodo desde ese ancla. El caso guía es la **tarjeta de crédito**: su ciclo va, por ejemplo, del 21 al 20 del mes siguiente, no del 1 al 30. El usuario debe poder presupuestar ese ciclo real. El formulario puede sugerir un ancla por defecto (inicio del periodo calendario vigente), pero **no lo impone**: quien tiene un ciclo propio elige su fecha y la app respeta esa cadencia.

## Historias de usuario

### HU-01 — Crear presupuesto con alcance (cuentas + categorías)
Como usuario quiero crear un presupuesto y elegir **cuáles cuentas y cuáles categorías** entran en él, para presupuestar exactamente el gasto que me interesa (ej. solo mi tarjeta, o solo "Comida" + "Restaurantes" de mis cuentas de débito).

**Criterios de aceptación:**
- Campos base: `name` (obligatorio, 1-100 caracteres — es un presupuesto **personalizado** que el usuario nombra, ej. "Tarjeta de crédito", "Mercado del mes", "Gastos fijos"), `icon` (opcional — ícono para reconocer el presupuesto de un vistazo en lista/detalle), `amountMinor` (centavos, > 0, nunca decimal), `currency` (ISO-4217), periodicidad y anclaje (ver HU-03), alcance (esta HU), y opcionalmente `alertThresholdPct` (HU-08) y `rollover` (HU-07, diferido).
- **Ícono (`icon`):** el usuario elige un ícono en el formulario para identificar el presupuesto (no es derivable del alcance, que puede abarcar varias categorías/cuentas). **No lleva color propio**: por el sistema de diseño sobrio, el fondo del ícono permanece neutro (`$muted`) en todas las tarjetas — no se reintroduce color por presupuesto (única excepción: el estado de sobregasto tiñe a la familia semántica `expense`). Por eso `Budgets` añade `icon` pero **no** `color`.
- Un presupuesto es una **entidad con nombre propio**, no un desglose automático por categoría: el usuario lo crea, lo nombra, y le asigna el alcance (cuentas/categorías) que quiera. La lista de presupuestos muestra **un elemento por presupuesto**, no una fila por categoría.
- **Alcance por cuentas:** el usuario selecciona 0..N cuentas. **0 cuentas seleccionadas = todas las cuentas** (sin filtro de cuenta).
- **Alcance por categorías:** el usuario selecciona 0..N categorías de `kind = expense`. **0 categorías = todas las categorías de gasto**. El selector oculta las de `kind = income` (no se presupuestan ingresos). Seleccionar una **categoría raíz incluye automáticamente todas sus subcategorías**.
- Un presupuesto con **ambos alcances vacíos** es el **presupuesto global** (ver HU-02).
- El alcance se persiste en tablas de unión (`BudgetAccounts`, `BudgetCategories`), no como columnas en `Budgets` (ver Cambios de esquema).
- No hay límite de presupuestos activos simultáneos (Nivel 0).
- **Solapamientos permitidos:** a diferencia de un modelo de una-categoría-por-presupuesto, aquí los alcances pueden solaparse a propósito (un presupuesto global + uno de "Comida" son dos lentes distintos sobre el mismo gasto, no un error). No se bloquea el solape; a lo sumo se **advierte** si ya existe un presupuesto **activo** con alcance y periodicidad idénticos (duplicado exacto).

### HU-02 — Crear presupuesto global (todo por defecto)
Como usuario quiero crear un presupuesto que abarque **todo** mi gasto del periodo sin tener que seleccionar cuentas ni categorías, para tener un tope general de forma inmediata.

**Criterios de aceptación:**
- El presupuesto global = **sin cuentas y sin categorías seleccionadas** (ambos alcances vacíos). La UI ofrece esto como opción explícita de un toque ("Todo"), no obliga a dejar los selectores vacíos a mano.
- Su progreso se calcula sobre la suma de **todos** los gastos del periodo (todas las cuentas, todas las categorías), excluyendo transferencias, independientemente de si esos gastos además caen en otro presupuesto de alcance más estrecho. Es intencional que un gasto cuente en el global y en su presupuesto de categoría a la vez — son dos topes distintos, no doble conteo erróneo.

### HU-03 — Periodicidad, anclaje y recurrencia
Como usuario quiero decidir **cada cuánto** se repite el presupuesto, **desde qué fecha** y **hasta cuándo**, para que se ajuste a mi ciclo real (quincena de pago, corte de tarjeta) y no al calendario.

**Criterios de aceptación:**
- **Periodicidad** (`period`, `BudgetPeriod`): `weekly` (semanal), `biweekly` (quincenal), `monthly` (mensual), `yearly` (anual), o `custom` (ventana a la medida). El usuario elige una.
  - **Quincenal (`biweekly`) = quincena semi-mensual**, no "cada 14 días rodante": **dos periodos por mes** anclados al día de inicio elegido. Con ancla día 1 → `1–15` y `16–fin de mes`; con ancla día 21 → `21–5` y `6–20`. Es siempre 2 por mes, alineado al pago quincenal (es-CO). Si un mes no tiene el día del punto medio o del ancla, se usa el último día del mes (mismo criterio que `statementDay` en Cuentas).
- **Anclaje por fecha:** para los periodos recurrentes, `startDate` es una fecha **elegida libremente por el usuario** y ancla toda la cadencia. El periodo vigente se obtiene avanzando desde `startDate` en bloques enteros de `period` hasta contener "hoy". El formulario puede sugerir el inicio del periodo calendario vigente como default, pero el usuario lo cambia a su gusto (ej. día 21 de la tarjeta).
- **Recurrencia** (`recurring`, bool, default `true`): el usuario decide entre dos formas, cada una con sus propios campos de fecha:
  - **Una única vez** (`recurring = false`): elige **fecha de inicio + fecha de fin**. Es una sola ventana `[startDate, endDate]`, no se repite. `endDate` **obligatorio**. La periodicidad (`period`) no aplica aquí, salvo `custom` que es justamente esta forma.
  - **Periódico** (`recurring = true`): elige **fecha de inicio + periodicidad**. Se repite cada `period` desde `startDate`. Corre **"Para Siempre"** por defecto (`endDate = null`); opcionalmente el usuario puede fijar una **fecha de finalización** (`endDate`) para que deje de renovarse después de esa fecha.
- **`custom`** implica siempre `recurring = false` (una ventana a la medida no tiene cadencia que repetir); `endDate` obligatorio y posterior a `startDate`.

### HU-04 — Ver progreso del presupuesto
Como usuario quiero ver cuánto llevo gastado y cuánto me queda de cada presupuesto activo, para decidir si puedo seguir gastando.

**Criterios de aceptación:**
- Progreso = suma de `amountMinor` de transacciones `type = expense` **no eliminadas** (`deletedAt IS NULL`), con `date` dentro del **rango vigente** del periodo (HU-03), que cumplen el **alcance** del presupuesto:
  - `(cuentas del presupuesto vacías OR accountId ∈ cuentas)` **AND** `(categorías vacías OR categoryId ∈ categorías, expandiendo cada raíz a sus subcategorías)`.
  - Solo cuenta gasto en la **misma `currency`** del presupuesto (ver Reglas de negocio / multi-moneda).
- Las **transferencias** (`type = transfer`) nunca cuentan (ver Reglas de negocio).
- Se muestra: **gastado**, **restante** (`amountMinor − gastado`, puede ser negativo), **porcentaje** y **días restantes** del periodo.
- **Restante como dato primario (tono positivo):** en la lista, la cifra destacada es **"Te quedan $X"**; en sobregasto se muestra **"Excedido por $X"** (nunca "Te pasaste", que en es-CO se lee como reproche), con el monto y el porcentaje (>100%) en rojo semántico (`$expense-text`).
- **Ancla temporal del periodo en la lista** — depende de la recurrencia (HU-03):
  - **Recurrente:** "se reinicia el [día/fecha del próximo ciclo]" (ej. "se reinicia el 21"). Da al usuario el ancla del borrón y cuenta nueva.
  - **Una única vez (no recurrente):** "termina el [fecha]" — no se reinicia, se acaba en `endDate`. Al finalizar sale de la lista de activos (pasa a histórico si se cierra, HU-10/11).
- El estado se visualiza con color/progreso (verde/ámbar/rojo según el umbral de HU-08) pero el **tono del texto es siempre positivo**, nunca de reproche (ver `Tono de la app` en CLAUDE.md).
- Cálculo **en tiempo real**: recalcula al agregar/editar/eliminar una transacción del rango, igual que el saldo de cuentas.

### HU-05 — Navegar entre periodos (histórico rápido y panorama futuro)
Como usuario, dentro de un presupuesto recurrente, quiero **moverme entre periodos** para ver rápido cómo me fue en periodos pasados y cómo se ve el panorama en los próximos.

**Criterios de aceptación:**
- Un **stepper de periodo** (‹ / ›) permite avanzar y retroceder de a un periodo, análogo al stepper de fechas de Transacciones (`DatePeriodFilter`). El periodo vigente es el default.
- **Periodos pasados:** muestran el resultado real de ese periodo (gastado vs. `amountMinor`), calculado contra las transacciones históricas de esa ventana. En Fase 0 el cálculo usa los **valores vigentes** del presupuesto (no se congela por periodo; ver HU-09).
- **Periodos futuros:** muestran el `amountMinor` asignado y el gasto ya registrado con fecha futura (si lo hubiera), como panorama; sin proyecciones de IA (Fase 0 es cálculo determinístico local).
- No se puede retroceder antes de `startDate` ni avanzar más allá de `endDate` (si existe).
- Es una vista de **solo lectura del progreso**; no crea filas por periodo (el arrastre entre periodos es HU-07, diferido).

### HU-06 — Presupuesto base-cero opcional
Como usuario quiero, si lo activo, distribuir todo mi ingreso del periodo entre presupuestos hasta que "cada peso tenga un trabajo", para aplicar la metodología YNAB de forma simplificada y opcional.

**Criterios de aceptación:**
- Es un modo **opt-in a nivel de app**, no obligatorio para usar presupuestos normales. Se persiste en `AppSettings.zeroBasedEnabled` (ver Cambios de esquema; requiere el mecanismo de settings persistentes, hoy inexistente).
- Con el modo activo, la pantalla muestra: **ingreso del periodo − total asignado a presupuestos = sin asignar**, donde:
  - Ingreso del periodo = suma de `Transactions.type = income` no eliminadas, con `date` en el periodo de referencia (el mes calendario vigente en Fase 0).
  - Total asignado = suma de `amountMinor` de los presupuestos activos de ese periodo y moneda.
- "Sin asignar" debe llegar a **cero** para considerarse completo, pero **no bloquea ninguna acción** si no llega a cero (es guía, no obstáculo — coherente con "sin fricción").
- **No introduce una tabla nueva** para base-cero: se apoya en `Budgets` + suma de `Transactions.type = income`.

### HU-07 — Rollover (arrastre de presupuesto) — *diferido a Fase 3*
Como usuario quiero que el sobrante (o el exceso) de un presupuesto se arrastre al siguiente periodo, para no perder el margen que no usé o compensar un mes en que me pasé.

**Estado:** el modelo de datos lo soporta desde Fase 0 (columna `rollover` en `Budgets`), pero la **lógica de arrastre no se implementa en Fase 0**. El arrastre exige estado por-periodo (sobrante/déficit de cada periodo cerrado), interactúa con la edición del monto y obliga a reglas de retroactividad — el tipo de mecánica de fricción que nuestro diferenciador evita hacer obligatoria. Aterriza junto a safe-to-spend en Fase 3, donde se decidirá el modelo de persistencia (recompute determinístico desde `startDate` vs. tabla `BudgetPeriods` con snapshots inmutables).

**Criterios de aceptación (para cuando se implemente):**
- Se controla con el flag `rollover` del presupuesto (default `false`).
- Si `rollover = true`: disponible del nuevo periodo = `amountMinor` + (sobrante o déficit del periodo anterior).
- Si `rollover = false`: cada periodo inicia limpio con solo `amountMinor`.
- Cambiar el flag **no recalcula retroactivamente** periodos ya cerrados.

### HU-08 — Alertas de presupuesto anticipadas
Como usuario quiero recibir un aviso **antes** de pasarme de un presupuesto (no después), para poder ajustar mi gasto a tiempo.

**Criterios de aceptación:**
- **Umbral configurable por presupuesto** (`alertThresholdPct`, entero 1-100, nullable con default 80). Al alcanzar ese % del `amountMinor` gastado, se dispara una notificación local positiva: "Te queda X% del presupuesto de [alcance] y faltan Y días" — no es IA, es cálculo local determinístico.
- Al **completar el periodo dentro del presupuesto**, se felicita al usuario (refuerzo positivo, no solo alertas de exceso).
- Es **Nivel 0** (cálculo local, sin costo). Su implementación completa (disparo de notificaciones locales) puede aterrizar en Fase 3 según el roadmap; el modelo de datos (`alertThresholdPct`) debe soportarla desde Fase 0.
- La **entrega** de la notificación local (scheduling, permisos) es de la feature de notificaciones, que leerá `alertThresholdPct` y el progreso; aquí solo se persiste el umbral y se define el cálculo.

### HU-09 — Editar presupuesto
Como usuario quiero modificar el monto, la periodicidad, las fechas o el alcance de un presupuesto.

**Criterios de aceptación:**
- Puedo editar `amountMinor`, `currency`, `period`, `startDate`, `endDate`, `recurring`, el alcance (cuentas/categorías), `alertThresholdPct` y `rollover`.
- Editar **no recalcula retroactivamente** el histórico: el progreso siempre se computa contra los valores vigentes del presupuesto en el periodo consultado, no se congela por periodo en Fase 0 (consistente con HU-05).
- `updatedAt` se actualiza en cada edición (en el repositorio); las tablas de unión de alcance también actualizan su `updatedAt`.

### HU-10 — Cerrar presupuesto (conservar en histórico)
Como usuario quiero **cerrar** un presupuesto que ya no quiero seguir activo pero sí conservar, para tenerlo en mi histórico sin que ensucie mis presupuestos vigentes.

**Criterios de aceptación:**
- "Cerrar" marca el presupuesto con `archivedAt` (timestamp del cierre). Un presupuesto cerrado **desaparece de la lista de activos** y de los cálculos vigentes, pero **se conserva** para consulta.
- Cerrar **no borra** nada: es distinto de eliminar (HU-11). No hay pérdida de datos.
- Se puede **reactivar** un presupuesto cerrado (limpiar `archivedAt`), volviéndolo a activos.
- Cerrar es la salida natural de un presupuesto recurrente "Para Siempre" que el usuario ya no necesita, sin tener que eliminarlo.

### HU-11 — Ver histórico de presupuestos cerrados / Eliminar
Como usuario quiero ver el **histórico de los presupuestos que cerré** (no los que eliminé), y poder eliminar definitivamente uno cuando quiera.

**Criterios de aceptación:**
- Una vista "**Histórico**" lista los presupuestos con `archivedAt` no nulo (cerrados), ordenados por fecha de cierre. **No** incluye los eliminados (papelera), que son cosa aparte.
- **Eliminar es borrado lógico (`deletedAt`)**, recuperable desde la **papelera** (no desde el histórico). Se usa `deletedAt` y **no** `tombstonedAt` porque ninguna otra tabla referencia `Budgets.id` por FK: no hay integridad referencial que preservar. PowerSync sincroniza el DELETE real por su cuenta.
- Histórico (`archivedAt`) y papelera (`deletedAt`) son **dos conceptos separados**: cerrar conserva a la vista de histórico; eliminar manda a papelera para undo. Nunca se mezclan.

### HU-12 — Ver los pagos programados que afectan el presupuesto
Como usuario quiero ver, dentro del presupuesto, lo que ya tengo **programado por pagar** en este periodo y verlo reflejado en la barra de progreso en un color atenuado, para saber cuánto de mi presupuesto ya está comprometido antes de gastarlo.

Lee de la feature `09-pagos-programados.md` (tabla `ScheduledPayments`); no introduce esquema nuevo.

**Criterios de aceptación:**
- **Qué cuenta como programado** — ocurrencias de pagos programados que caen en el **rango vigente** del periodo (HU-03) y cumplen el **mismo alcance** que el gasto real (HU-04): `type = expense`, misma `currency`, `(cuentas vacías OR accountId ∈ cuentas)` AND `(categorías vacías OR categoryId ∈ categorías, expandiendo raíces)`, plantilla no eliminada (`deletedAt IS NULL`).
- **Nunca doble conteo (regla crítica):** una ocurrencia ya generada existe como transacción real (`source = scheduled`) y por tanto **ya está en `spentMinor`**. El monto programado cuenta **solo las ocurrencias aún no materializadas** en una transacción. Sumar la plantilla completa además de sus transacciones generadas contaría el mismo dinero dos veces.
- **Una plantilla puede aportar varias ocurrencias al periodo:** hay que **proyectar las ocurrencias desde `nextDate` hacia adelante** según `frequency`/`interval`, acotadas por el fin de la ventana y por `endDate` de la plantilla — no basta con `nextDate`. Ej.: una plantilla semanal dentro de un presupuesto mensual aporta ~4 ocurrencias, no una.
- Una ocurrencia **pendiente de confirmación** (modo manual, HU-03 de pagos programados) todavía **no afectó el saldo**, así que cuenta como programado, no como gastado.
- **En la barra de progreso:** el monto programado se muestra como un **segmento atenuado contiguo al gastado** (gastado sólido → programado atenuado → resto sin usar). Se mantiene el acento único de marca: el segmento atenuado es una variante suave de `$primary`, **no** un color nuevo ni un semáforo.
- **La proyección no es sobregasto:** que `gastado + programado` supere el 100% **no** tiñe la tarjeta de rojo. El rojo (familia semántica `expense`) sigue reservado exclusivamente al sobregasto **real** (`spentMinor > amountMinor`, HU-04). Un compromiso futuro es un aviso útil, no una falta cometida — teñirlo de rojo sería castigar al usuario por planear, justo lo contrario del tono de la app.
- Se muestra la cifra de lo programado y el acceso a **qué** lo compone (la lista de esos pagos programados del periodo), no solo el total opaco.
- **Periodos pasados** (HU-05): no hay programado (toda ocurrencia ya se resolvió, se omitió o quedó atrás) → el segmento no aparece. **Periodos futuros**: el gasto real suele ser 0 y el programado es justamente el panorama de valor.
- Cálculo **local y determinístico** (sin IA, sin red), recalculado en tiempo real igual que el progreso, y **Nivel 0**.

## Reglas de negocio y edge cases

- Las **transferencias** (`type = transfer`) nunca cuentan para el progreso de ningún presupuesto (no son gasto real; evitan doble conteo con el pago de tarjeta — ver `03-transacciones.md`). Esto vale también para presupuestos con alcance de cuenta (el pago de la tarjeta desde otra cuenta no consume el presupuesto de la tarjeta).
- Seleccionar una **categoría raíz** en el alcance incluye automáticamente el gasto de todas sus subcategorías.
- **Alcances anidados/solapados son válidos** (global + específico, cuenta + categoría): son lentes distintos sobre el mismo gasto, no un error. Solo se advierte ante un **duplicado exacto** (mismo alcance + misma periodicidad, ambos activos).
- **Multi-moneda (Fase 0):** el presupuesto tiene una sola `currency`; su progreso suma **solo transacciones de esa misma moneda**. Los gastos en otra moneda quedan fuera del alcance de ese presupuesto. La conversión se define en `12-multi-moneda.md` y se difiere. Advertir en la UI si el alcance incluye cuentas de distinta moneda.
- **Borrado de cuenta/categoría dentro del alcance:** si se elimina una cuenta (`tombstonedAt`, irreversible) o una categoría (`deletedAt`, reversible) referenciada por un presupuesto, **la fila de unión se conserva** — no se limpia ni se borra en cascada. El cálculo de progreso hace JOIN a `Accounts`/`Categories` y **filtra el referente borrado** (cuentas con `tombstonedAt IS NULL`; categorías con `deletedAt IS NULL AND tombstonedAt IS NULL`). Así, restaurar una categoría desde la papelera **repone el alcance intacto sin trabajo extra**.
  - **Global vs. acotado-que-quedó-vacío (regla crítica):** "sin filas de unión = todo" (global, HU-02) **no** es lo mismo que "hay filas de unión pero todos sus referentes están borrados". El cálculo debe contar las filas de unión **crudas** (incluyendo referentes borrados) para decidir global-vs-acotado, y filtrar los borrados **solo** del conjunto `IN(...)`. Si existen filas pero ninguna sobrevive → el presupuesto matchea **cero** transacciones (nunca "todas"), y la UI lo **advierte**. Un cálculo ingenuo aquí convertiría un presupuesto estrecho en global por accidente.
  - **Aviso al borrar:** al eliminar una cuenta o categoría, la computación de impacto (la que ya cuenta metas/deudas afectadas) también cuenta los presupuestos cuyo alcance la referencia, para que el sheet de confirmación diga "se usa en N presupuestos". No se elimina el presupuesto en cascada.
  - El `deletedAt` **propio** de las filas de unión (llevan `_SyncColumns`) es para cuando el usuario **quita un referente editando el alcance** (HU-09), no para reflejar el borrado del referente en otra feature — son cosas distintas.
- Presupuestos **ilimitados y sin anuncios** — ninguna feature de esta pantalla puede quedar bloqueada tras Modo anuncios o Premium (regla de Nivel 0 en CLAUDE.md). Incluye alcance, periodicidad, base-cero, alertas, histórico y (a futuro) rollover.
- Todo el cálculo es **local-first** (Drift/SQLite): no depende de red, coherente con "la app funciona sin conexión".
- **Dinero siempre en centavos** (`amountMinor`), nunca `double`. El umbral es un **porcentaje entero** (`alertThresholdPct`), no una fracción decimal.

## Cambios de esquema requeridos (Drift)

El modelo pasa de un `categoryId` único a **alcance multi-cuenta + multi-categoría** vía tablas de unión, más recurrencia, cierre y umbral. Ejecutar vía `/drift-schema-change`: subir `schemaVersion`, escribir migración y regenerar con build_runner, manteniendo paridad en Supabase/PowerSync.

**Enum `BudgetPeriod`** — agregar `biweekly` (quincenal semi-mensual):
```
enum BudgetPeriod { weekly, biweekly, monthly, yearly, custom }
```

**Tabla `Budgets`** — quitar `categoryId` (lo reemplaza `BudgetCategories`) y agregar columnas (nullable donde aplique para no romper filas):

| Columna | Tipo | Notas |
|---|---|---|
| ~~`categoryId`~~ | — | **Se elimina**; el alcance de categorías pasa a `BudgetCategories`. |
| `name` | `text().withLength(min: 1, max: 100)` | Nombre del presupuesto personalizado (obligatorio). HU-01. |
| `icon` | `text().nullable()` | Ícono del presupuesto (opcional), como en Cuentas/Categorías/Metas. **No** se añade `color`: el icon-wrap es neutro `$muted` por el diseño sobrio. HU-01. |
| `recurring` | `boolean().withDefault(false→true?)` | `true` = periódico, `false` = una única vez. Default `true`. HU-03. |
| `endDate` | `dateTime().nullable()` | Fin de ventana. Obligatorio si `recurring = false` o `period = custom`; en periódicos, `null` = "Para Siempre", fijado = fecha de finalización. Posterior a `startDate`. HU-03. |
| `archivedAt` | `dateTime().nullable()` | Cierre a histórico (HU-10/11). No nulo = cerrado. Distinto de `deletedAt` (papelera) y de `tombstonedAt` (no aplica). |
| `alertThresholdPct` | `integer().nullable()` (1-100, default 80) | Umbral de alerta anticipada por presupuesto. HU-08. |

`rollover` (`boolean`, default `false`), `amountMinor`, `currency`, `period`, `startDate` **ya existen**; `rollover` se conserva aunque su lógica se difiera (HU-07).

**Tablas de unión nuevas** (cada una con el mixin `_SyncColumns`, por lo que llevan su propio `id` UUID — PowerSync necesita PK de una sola columna, igual que `TransactionTags`):

| Tabla | Columnas | Notas |
|---|---|---|
| `BudgetAccounts` | `budgetId → Budgets.id`, `accountId → Accounts.id` | Alcance por cuenta. **Sin filas = todas las cuentas.** `uniqueKeys = {budgetId, accountId}`. |
| `BudgetCategories` | `budgetId → Budgets.id`, `categoryId → Categories.id` | Alcance por categoría (raíz expande subcategorías en el cálculo). **Sin filas = todas las categorías de gasto.** `uniqueKeys = {budgetId, categoryId}`. |

**Fuera de la tabla `Budgets` — mecanismo de settings de app (nuevo):**

| Setting | Tipo | Notas |
|---|---|---|
| `zeroBasedEnabled` | `bool` (default `false`) | Flag global del modo base-cero (HU-06). Vive en una **tabla Drift `AppSettings` nueva, sincronizada** (es preferencia de nivel cuenta, debe seguir al usuario entre dispositivos), no en `Budgets` (es global, no por-presupuesto) ni en almacenamiento local (no sincronizaría). Ver nota de esquema abajo. |

**Tabla `AppSettings` nueva** (mecanismo de settings persistentes, hoy inexistente — `lib/features/settings/` es solo presentación):

| Aspecto | Decisión |
|---|---|
| Forma | **Fila única** (singleton por usuario) con columnas **tipadas** (`zeroBasedEnabled` bool default false), no clave-valor sin tipar. Lleva el mixin `_SyncColumns`. |
| `id` | **Valor constante bien conocido** (ej. `'app'`), **no** `clientDefault` con UUID aleatorio: dos dispositivos offline generarían dos filas y el merge de PowerSync las duplicaría. Con id constante la fila es un verdadero singleton y el merge queda **last-write-wins sobre `updatedAt`**. Es la única desviación del patrón `_SyncColumns` y debe documentarse en el esquema. |
| Alcance | Solo ajustes de **nivel cuenta** que deben sincronizar (base-cero, moneda por defecto). Un ajuste device-local como el tema claro/oscuro iría en un almacén local aparte, no aquí. |
| Migración | Sube `schemaVersion`, crea la tabla e inserta la fila singleton por defecto; paridad en Supabase + sync rules de PowerSync (pendiente del wiring de `05-auth-sync.md`). |
