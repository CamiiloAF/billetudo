# Feature: Pagos programados

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `ScheduledPayments` (`lib/core/database/app_database.dart`)

## Contexto

Plantillas de transacciones planeadas a futuro: pueden repetirse (suscripciones, arriendo, nómina) con frecuencia configurable, o ser un pago único programado para una fecha futura. Alimentan además los recordatorios de vencimientos (notificaciones locales, Fase 2) y el cálculo de "disponible para gastar" al proyectar compromisos futuros.

## Historias de usuario

### HU-01 — Crear un pago programado
Como usuario quiero definir una transacción planeada a futuro —que se repite (ej. arriendo mensual, Netflix) o de una sola vez (un pago puntual la próxima semana)—, para no tener que registrarla manualmente cuando llegue la fecha.

**Criterios de aceptación:**
- Campos: `accountId` (obligatorio), `categoryId` (opcional), `amountMinor` (obligatorio), `currency`, `type` (income/expense/transfer), `transferAccountId` (obligatorio solo si `type = transfer`), `note` (opcional), `tags` (opcional, ver abajo), `frequency` (`ScheduleFrequency`: `once`/daily/weekly/monthly/yearly), `interval` (cada cuántas unidades de frecuencia, default 1; se ignora si `frequency = once`), `nextDate` (obligatoria), `endDate` (opcional), `requiresConfirmation` (bool, default `false`: modo de registro automático vs. manual, HU-03).
- **Etiquetas (`tags`):** una plantilla admite múltiples etiquetas, relación N:N vía tabla puente nueva **`ScheduledPaymentTags`** (`scheduledPaymentId` + `tagId`), misma mecánica y misma tabla `Tags` que `TransactionTags` en transacciones (HU-07 de `03-transacciones.md`). Se pueden crear etiquetas al vuelo desde el formulario, igual que en transacciones. **No aplican a `type = transfer`** (paridad con transacciones, donde una transferencia no lleva categoría ni etiquetas). Requiere cambio de esquema (ver abajo).
- `frequency = once` es un **pago único**: se programa para una sola fecha (`nextDate`) y no se repite. `interval`/`endDate` no aplican.
- No hay límite de pagos programados activos (Nivel 0).
- Ejemplo: `frequency = weekly`, `interval = 2` = cada 2 semanas.

### HU-02 — Generar transacciones automáticamente
Como usuario quiero que al llegar `nextDate` se genere automáticamente la transacción correspondiente, para no tener que crearla a mano cada periodo.

**Criterios de aceptación:**
- La transacción generada tiene `source = scheduled` y `scheduledPaymentId` apuntando a la plantilla.
- **Las etiquetas de la plantilla se heredan:** la transacción generada recibe copia de las etiquetas de la plantilla (filas en `TransactionTags` por cada `tagId` de `ScheduledPaymentTags`). Es el propósito de tener etiquetas en la plantilla — no volver a etiquetar cada ocurrencia a mano. Es una copia en el momento de generar, no un vínculo vivo: editar las etiquetas de la plantilla después no reescribe las de transacciones ya generadas (misma filosofía que HU-05 para monto/frecuencia).
- Si `frequency = once`, tras generar su única transacción la plantilla queda inactiva/histórica (no avanza `nextDate`).
- Si `frequency` es repetible, tras generarse `nextDate` avanza según `frequency`/`interval` hasta la siguiente ocurrencia.
- Si `endDate` está definida y ya se alcanzó, la plantilla deja de generar nuevas transacciones (pero no se elimina; queda inactiva/histórica).
- Si la app estuvo cerrada y pasaron varias ocurrencias, se generan todas las transacciones pendientes al reabrir (o se ofrece confirmarlas en lote), sin perder ninguna.

### HU-03 — Registro automático o manual (confirmar antes de aplicar)
Como usuario quiero elegir si un pago programado se registra automáticamente o si me pide confirmarlo, para poder ajustar los que varían de un periodo a otro (servicios públicos) o los que no siempre pago el mismo día.

**Criterios de aceptación:**
- Al crear o editar la plantilla (HU-01) el usuario elige el modo de registro, persistido en `requiresConfirmation`:
  - **Automático** (`false`, default): al llegar `nextDate` la transacción se genera y afecta el saldo sin intervención (HU-02).
  - **Manual** (`true`): al llegar `nextDate` NO se afecta el saldo todavía; el pago queda pendiente de confirmación.
- **Confirmar nunca es a ciegas (regla crítica):** confirmar una ocurrencia pendiente **siempre** abre primero una vista de verificación/edición con los datos precargados; no existe un "aceptar tal cual" en un solo toque desde la lista. El motivo es la razón misma del modo manual: quien lo activó lo hizo porque el monto o la fecha varían, así que aplicar los valores de la plantilla sin mirarlos registraría un dato incorrecto (ej. confirmar $179.000 cuando el recibo llegó en $206.000). El usuario sí puede aceptar sin cambiar nada, pero **después de ver** lo que va a registrar.
- En esa vista de verificación el usuario puede modificar, con los datos precargados de la plantilla:
  - `date` (fecha del pago; precargada con `nextDate`),
  - `accountId` (cuenta),
  - `amountMinor` (monto).
  El resto (`categoryId`, `note`, `type`, `currency`) también viene precargado de la plantilla.
- Confirmar aplica la transacción al saldo con los valores finales (los editados, no los de la plantilla) y con `source = scheduled` + `scheduledPaymentId` (HU-02).
- Editar los valores al confirmar **no modifica la plantilla**: afecta solo esa ocurrencia. La siguiente ocurrencia vuelve a proponer los valores de la plantilla. (Para cambiar la plantilla, HU-05.)
- Tras confirmar, `nextDate` avanza igual que en el flujo automático (o la plantilla queda inactiva si `frequency = once`).
- El usuario puede **omitir** una ocurrencia pendiente sin registrarla: es la salida para el pago que simplemente no ocurrió (ej. este mes no fui al gimnasio). Descarta esa ocurrencia sin generar transacción y la plantilla avanza a la siguiente. Sin esta salida el pendiente sería una trampa: confirmarlo registraría un gasto que nunca pasó, e ignorarlo lo acumula para siempre.
- **Omitir vive en la vista de verificación, no como acción directa en la lista.** Aunque no escribe nada (y por tanto no necesitaría verificación), dejarlo como la única acción de un toque de la pantalla —cuando confirmar sí exige abrir la hoja— haría que la app hiciera fácil descartar y difícil registrar, en contra del tono de marca. Puede ofrecerse un acelerador opcional (swipe) siempre que sea **reversible** (deshacer): un toque accidental no puede descartar en silencio un compromiso real.
- **Confirmación en lote:** un "confirmar todos" que aplique N ocurrencias de un golpe **viola** la regla de "confirmar nunca es a ciegas" (es N confirmaciones ciegas). Si se ofrece un flujo de lote para varias ocurrencias pendientes, debe ser una **revisión guiada** en la que el usuario ve (y puede ajustar) cada ocurrencia antes de aplicarla, no un botón de aplicar-todo. Cómo se resuelve la interacción es decisión de diseño; la restricción no es negociable.

### HU-04 — Ver próximos vencimientos
Como usuario quiero ver una lista de mis próximos pagos programados ordenados por fecha, para anticipar mis compromisos financieros.

**Criterios de aceptación:**
- Vista con `nextDate` ascendente, mostrando monto, cuenta y categoría de cada plantilla activa.
- **Arriba ocurrencias, abajo plantillas (regla crítica):** la zona de pendientes de confirmación lista **ocurrencias**; la lista principal lista **plantillas activas**. Una plantilla con una ocurrencia pendiente **no se repite abajo**: mientras la ocurrencia está pendiente, `nextDate` todavía **no ha avanzado** (solo avanza al confirmar u omitir, HU-03), así que mostrarla en ambos lados sería mostrar la misma fecha dos veces. El contador de plantillas activas cuenta **todas** las activas, incluidas las que tienen un pendiente arriba.
- Sirve de insumo para recordatorios de vencimiento (notificaciones locales) — previstos en Fase 2, pero la vista de "próximos" es Nivel 0.

### HU-05 — Editar y eliminar un pago programado
Como usuario quiero modificar el monto, frecuencia o fecha de un pago programado, o eliminarlo si ya no aplica (ej. cancelé una suscripción).

**Criterios de aceptación:**
- Editar la plantilla no modifica transacciones ya generadas en el pasado, solo las futuras.
- Eliminar detiene la generación futura; es borrado lógico (`deletedAt`), y las transacciones ya generadas mantienen su `scheduledPaymentId` como referencia histórica.
- El detalle muestra el **historial de transacciones ya generadas** por la plantilla (`source = scheduled`). El link "Ver historial completo (N)" **expande la lista in-place** (cargar más), **no navega** a otra pantalla — mismo patrón que la actividad de Presupuestos (`design-system/billetudo/pages/presupuestos.md`). Cada fila del historial sí enlaza al detalle de esa transacción.

### HU-06 — Crear un pago programado desde un gasto con fecha futura
Como usuario quiero que, si registro un gasto (o ingreso/transferencia) con una fecha futura desde el formulario normal, la app me ofrezca convertirlo en un pago programado, para no crear por error un movimiento pasado que ya afecta mi saldo.

**Criterios de aceptación:**
- Al guardar en el formulario de transacciones con `date` en el futuro, la app pregunta "¿Es un pago programado?" antes de persistir.
- Si el usuario acepta, se abre el flujo de pago programado prellenado con lo ya capturado (cuenta, monto, categoría, nota, **etiquetas**, fecha como `nextDate`) y `frequency = once` por defecto; el usuario ajusta frecuencia/notificaciones y confirma.
- Si el usuario rechaza, se mantiene el comportamiento actual (movimiento normal con esa fecha).
- El puente vive en la presentación de Transacciones; no acopla el dominio de ambas features.

### HU-07 — Posponer una ocurrencia (snooze)
Como usuario quiero mover un pago próximo a una fecha posterior sin registrarlo ni saltarlo, para cuando sé que lo voy a pagar pero más tarde de lo previsto (ej. este mes el arriendo lo pago el 10, no el 5).

**Criterios de aceptación:**
- **Posponer es una tercera vía**, distinta de las otras dos: **Confirmar** registra (afecta el saldo), **Omitir** descarta la ocurrencia y avanza al siguiente ciclo, **Posponer** la mantiene viva y solo mueve su fecha a más adelante.
- **Mueve solo esa ocurrencia**, a una fecha posterior elegida por el usuario (reusa el date picker `Date Picker Sheet`). **La cadencia de la plantilla no se altera:** la siguiente ocurrencia sigue anclada al ritmo original (posponer el arriendo de marzo al 10 no mueve el de abril del 5). Mover *toda* la cadencia es "editar la plantilla" (HU-05), no esto.
- **No afecta el saldo** mientras está pospuesta, pero sigue contando como compromiso futuro (para "disponible para gastar" y para el segmento "programado" de Presupuestos, HU-12 de `06-presupuestos.md`).
- La nueva fecha debe ser **posterior al piso `max(fecha original, hoy)`** — nunca al pasado. Para un pago **aún no vencido** (posponer desde el detalle) el piso es la fecha original; para una **ocurrencia ya vencida** (posponer desde la hoja de confirmación) el piso es **hoy** (posponer a una fecha ya pasada sería incoherente: la ocurrencia debe seguir viva como compromiso futuro). El date picker atenúa/deshabilita **todo el pasado hasta ese piso** en bloque continuo (convención universal de date pickers), no solo la fecha original. Si el piso cae a fin de mes, el calendario **abre en el mes de la primera fecha seleccionable**, no en el de la fecha original.
- Al llegar la nueva fecha, la ocurrencia se comporta según el modo de la plantilla: automática se registra sola; manual vuelve a quedar pendiente de confirmación.
- **Reversible:** posponer mueve una fecha real y debe poder deshacerse — tras posponer se muestra un `Snackbar` "Pago movido al [fecha] · Deshacer" (paridad con Omitir, que también es reversible). Un cambio de fecha silencioso es fácil de disparar por accidente.
- **Aplica a cualquier próximo pago, automático o manual, y por eso vive en dos lugares:**
  - **Ocurrencia pendiente de modo manual** (ya venció): Posponer es una **tercera acción en la hoja de verificación**, junto a Confirmar y Omitir.
  - **Pago próximo aún no vencido** (automático o manual): se pospone **desde el detalle**, sobre "Próximo pago" — permite adelantarse a un cobro automático antes de que ocurra.
- **Nota de dominio (implementación):** posponer una ocurrencia sin mover el ancla de la cadencia exige trackear la fecha pospuesta de *esa* ocurrencia sin recalcular las siguientes desde ella (el cómputo de las próximas ocurrencias debe partir del ancla original —`startDate`/`nextDate` natural—, no de la fecha pospuesta). Resolver el modelo de datos en implementación (posible columna de override de fecha por ocurrencia, o tabla de excepciones).

## Reglas de negocio y edge cases

- Un pago programado de `type = transfer` requiere `transferAccountId` igual que una transacción normal (ver `03-transacciones.md`).
- El monto, la fecha y la cuenta pueden variar entre ocurrencias solo si la plantilla usa el modo manual (HU-03); el modo automático replica siempre los valores de la plantilla.
- Una ocurrencia pendiente de confirmación (modo manual) no afecta el saldo hasta confirmarse, pero sí cuenta como compromiso futuro para "disponible para gastar".
- **Presupuestos consume esta feature** (ver HU-12 de `06-presupuestos.md`): las ocurrencias de `type = expense` que caen en el periodo de un presupuesto y cumplen su alcance se muestran ahí como "programado por pagar" en un segmento atenuado de la barra. Solo cuentan las ocurrencias **aún no materializadas** en una transacción — las ya generadas (`source = scheduled`) ya son gasto real y se contarían dos veces. Proyectar las ocurrencias de una plantilla dentro de una ventana (desde `nextDate`, según `frequency`/`interval`, acotado por `endDate`) es lógica de dominio de esta feature, no de Presupuestos.

## Cambios de esquema requeridos (Drift)

- **Tabla puente nueva `ScheduledPaymentTags`** (mixin `_SyncColumns`, con su propio `id` UUID igual que `TransactionTags`): `scheduledPaymentId → ScheduledPayments.id`, `tagId → Tags.id`, `uniqueKeys = {scheduledPaymentId, tagId}`. Reusa la tabla `Tags` existente (no se duplica). Es el gemelo de `TransactionTags` para plantillas.
- Subir `schemaVersion` (hoy 10 → 11) y escribir la migración `onUpgrade` (crear la tabla; no hay datos que migrar, es aditiva). Mantener paridad en Supabase/PowerSync. Ejecutar vía `/drift-schema-change`.
