# Feature: Pagos programados

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `ScheduledPayments` (`lib/core/database/app_database.dart`)

## Contexto

Plantillas de transacciones planeadas a futuro: pueden repetirse (suscripciones, arriendo, nómina) con frecuencia configurable, o ser un pago único programado para una fecha futura. Alimentan además los recordatorios de vencimientos (notificaciones locales, Fase 2) y el cálculo de "disponible para gastar" al proyectar compromisos futuros.

## Historias de usuario

### HU-01 — Crear un pago programado
Como usuario quiero definir una transacción planeada a futuro —que se repite (ej. arriendo mensual, Netflix) o de una sola vez (un pago puntual la próxima semana)—, para no tener que registrarla manualmente cuando llegue la fecha.

**Criterios de aceptación:**
- Campos: `accountId` (obligatorio), `categoryId` (opcional), `amountMinor` (obligatorio), `currency`, `type` (income/expense/transfer), `transferAccountId` (obligatorio solo si `type = transfer`), `note` (opcional), `frequency` (`ScheduleFrequency`: `once`/daily/weekly/monthly/yearly), `interval` (cada cuántas unidades de frecuencia, default 1; se ignora si `frequency = once`), `nextDate` (obligatoria), `endDate` (opcional), `requiresConfirmation` (bool, default `false`, HU-03).
- `frequency = once` es un **pago único**: se programa para una sola fecha (`nextDate`) y no se repite. `interval`/`endDate` no aplican.
- No hay límite de pagos programados activos (Nivel 0).
- Ejemplo: `frequency = weekly`, `interval = 2` = cada 2 semanas.

### HU-02 — Generar transacciones automáticamente
Como usuario quiero que al llegar `nextDate` se genere automáticamente la transacción correspondiente, para no tener que crearla a mano cada periodo.

**Criterios de aceptación:**
- La transacción generada tiene `source = scheduled` y `scheduledPaymentId` apuntando a la plantilla.
- Si `frequency = once`, tras generar su única transacción la plantilla queda inactiva/histórica (no avanza `nextDate`).
- Si `frequency` es repetible, tras generarse `nextDate` avanza según `frequency`/`interval` hasta la siguiente ocurrencia.
- Si `endDate` está definida y ya se alcanzó, la plantilla deja de generar nuevas transacciones (pero no se elimina; queda inactiva/histórica).
- Si la app estuvo cerrada y pasaron varias ocurrencias, se generan todas las transacciones pendientes al reabrir (o se ofrece confirmarlas en lote), sin perder ninguna.

### HU-03 — Confirmar o editar antes de aplicar (opcional)
Como usuario quiero poder revisar un pago programado antes de que se aplique definitivamente (ej. si el monto de este mes varía), para ajustar montos variables como servicios públicos.

**Criterios de aceptación:**
- El flujo por defecto es automático (HU-02), pero el usuario puede marcar una plantilla como "requiere confirmación", en cuyo caso al llegar `nextDate` se genera un borrador editable antes de aplicarse al saldo.

### HU-04 — Ver próximos vencimientos
Como usuario quiero ver una lista de mis próximos pagos programados ordenados por fecha, para anticipar mis compromisos financieros.

**Criterios de aceptación:**
- Vista con `nextDate` ascendente, mostrando monto, cuenta y categoría de cada plantilla activa.
- Sirve de insumo para recordatorios de vencimiento (notificaciones locales) — previstos en Fase 2, pero la vista de "próximos" es Nivel 0.

### HU-05 — Editar y eliminar un pago programado
Como usuario quiero modificar el monto, frecuencia o fecha de un pago programado, o eliminarlo si ya no aplica (ej. cancelé una suscripción).

**Criterios de aceptación:**
- Editar la plantilla no modifica transacciones ya generadas en el pasado, solo las futuras.
- Eliminar detiene la generación futura; es borrado lógico (`deletedAt`), y las transacciones ya generadas mantienen su `scheduledPaymentId` como referencia histórica.

### HU-06 — Crear un pago programado desde un gasto con fecha futura
Como usuario quiero que, si registro un gasto (o ingreso/transferencia) con una fecha futura desde el formulario normal, la app me ofrezca convertirlo en un pago programado, para no crear por error un movimiento pasado que ya afecta mi saldo.

**Criterios de aceptación:**
- Al guardar en el formulario de transacciones con `date` en el futuro, la app pregunta "¿Es un pago programado?" antes de persistir.
- Si el usuario acepta, se abre el flujo de pago programado prellenado con lo ya capturado (cuenta, monto, categoría, nota, fecha como `nextDate`) y `frequency = once` por defecto; el usuario ajusta frecuencia/notificaciones y confirma.
- Si el usuario rechaza, se mantiene el comportamiento actual (movimiento normal con esa fecha).
- El puente vive en la presentación de Transacciones; no acopla el dominio de ambas features.

## Reglas de negocio y edge cases

- Un pago programado de `type = transfer` requiere `transferAccountId` igual que una transacción normal (ver `03-transacciones.md`).
- El monto puede variar entre ocurrencias solo si el usuario usa el flujo de confirmación (HU-03); el flujo automático replica siempre el mismo `amountMinor`.
