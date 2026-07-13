# Feature: Deudas y préstamos

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Debts` (`lib/core/database/app_database.dart`)

## Contexto

Cubre tanto "yo debo" (tarjeta, préstamo, deuda con una persona) como "me deben" (`DebtDirection`: `iOwe` / `owedToMe`) — un solo modelo para ambas direcciones, algo que muchas apps manuales no resuelven bien.

## Historias de usuario

### HU-01 — Registrar una deuda
Como usuario quiero registrar una deuda que tengo (o que me deben) con nombre, monto principal, moneda y contraparte, para llevar control de compromisos que no están en mis cuentas normales.

**Criterios de aceptación:**
- Campos: `name` (obligatorio), `direction` (`iOwe` o `owedToMe`, obligatorio), `principalMinor` (obligatorio, centavos), `currency`, `counterparty` (opcional, ej. "Banco X" o "Juan Pérez"), `dueDate` (opcional), `interestRate` (opcional, % anual).
- No hay límite de deudas simultáneas (Nivel 0).

### HU-02 — Registrar pagos/abonos a una deuda
Como usuario quiero registrar abonos parciales a una deuda, para ver cuánto he pagado (o me han pagado) y cuánto queda pendiente.

**Criterios de aceptación:**
- Un abono se modela como una transacción con `debtId` asignado (ej. un gasto que reduce una deuda `iOwe`, o un ingreso que reduce una deuda `owedToMe`).
- El saldo pendiente de la deuda = `principalMinor` − suma de abonos (`Transactions` no eliminadas con ese `debtId`), respetando la dirección.
- El saldo pendiente nunca se muestra negativo; si los abonos superan el principal, se marca la deuda como saldada y se notifica el exceso.

### HU-03 — Ver saldo pendiente y vencimiento
Como usuario quiero ver cuánto debo (o me deben) en total y por deuda individual, junto con la fecha de vencimiento si existe, para priorizar pagos.

**Criterios de aceptación:**
- Vista resumen: total `iOwe` pendiente vs. total `owedToMe` pendiente.
- Si `dueDate` está definida y se acerca (umbral configurable, ej. 7 días), se muestra un aviso o recordatorio (cálculo/local, sin IA).
- Cálculo de interés (`interestRate`) es informativo en Fase 0 (muestra el interés simple anual estimado), no genera capitalización automática ni recalculo complejo de amortización.

### HU-04 — Editar y eliminar deuda
Como usuario quiero modificar los datos de una deuda o eliminarla cuando se salda o fue un error de registro.

**Criterios de aceptación:**
- Editar `principalMinor` no borra el historial de abonos ya registrados.
- Eliminar es borrado lógico (`deletedAt`), recuperable desde papelera; las transacciones con ese `debtId` mantienen la referencia histórica.

### HU-05 — Marcar deuda como saldada
Como usuario quiero marcar una deuda como completamente pagada, para sacarla de mi vista activa sin eliminarla.

**Criterios de aceptación:**
- Se considera saldada automáticamente cuando el saldo pendiente llega a 0 (ver HU-02), sin necesidad de una acción manual adicional, aunque el usuario puede archivarla/ocultarla de la vista activa.

## Reglas de negocio y edge cases

- No se modela como cuenta (`Accounts`) porque una deuda no es un lugar donde "vive" dinero disponible para gastar, sino un compromiso; mantener esta distinción evita que el saldo de deudas se mezcle con el patrimonio líquido en reportes de flujo/balance.
- El tono debe ser neutral/informativo, nunca alarmista, coherente con la regla de "nunca avergonzar al usuario por sus gastos" extendida a sus deudas.
