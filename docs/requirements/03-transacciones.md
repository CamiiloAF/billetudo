# Feature: Transacciones

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Transactions` (`lib/core/database/app_database.dart`)

## Contexto

El núcleo de la app. Registro **manual** ilimitado — limitarlo rompería la promesa de "100% funcional gratis". Incluye ingreso, gasto y transferencia entre cuentas propias, más búsqueda y filtros (queja de completitud identificada en la investigación).

## Historias de usuario

### HU-01 — Registrar un gasto
Como usuario quiero registrar un gasto indicando cuenta, categoría, monto, fecha y nota opcional, para llevar control de en qué se me va el dinero.

**Criterios de aceptación:**
- Campos: `accountId` (obligatorio), `categoryId` (opcional, debe ser `kind = expense`), `amountMinor` (obligatorio, entero positivo en centavos), `currency`, `date` (obligatoria, default hoy), `note` (opcional).
- `type = expense`, `source = manual` por defecto.
- El saldo de la cuenta se refleja de inmediato tras guardar.
- El monto se captura en la moneda de la cuenta seleccionada por defecto; ver `10-multi-moneda.md` si se registra en otra moneda.

### HU-02 — Registrar un ingreso
Como usuario quiero registrar un ingreso (salario, freelance, etc.), para que mi saldo y mis reportes reflejen también lo que entra, no solo lo que gasto.

**Criterios de aceptación:**
- Igual que HU-01 pero `type = income`, y `categoryId` debe ser de `kind = income` si se asigna.

### HU-03 — Registrar una transferencia entre cuentas
Como usuario quiero mover dinero de una cuenta a otra (ej. de banco a efectivo), para que mi patrimonio total no se distorsione como si fuera un gasto.

**Criterios de aceptación:**
- `type = transfer`, requiere `accountId` (origen) y `transferAccountId` (destino), ambos obligatorios y distintos entre sí.
- No requiere `categoryId` (una transferencia no es gasto ni ingreso real).
- Afecta el saldo de ambas cuentas (resta en origen, suma en destino) pero **no** cuenta como gasto ni ingreso en gráficas de flujo/estructura de gasto.
- Si origen y destino tienen monedas distintas, ver `10-multi-moneda.md` para la tasa aplicada.

### HU-04 — Editar transacción
Como usuario quiero corregir cualquier campo de una transacción ya registrada, para arreglar errores de captura.

**Criterios de aceptación:**
- Todos los campos editables excepto `source` (el origen de captura es un hecho histórico, no se reescribe manualmente).
- `updatedAt` se actualiza en cada edición.
- Si la transacción está enlazada a `recurringId`, `goalId` o `debtId`, la edición debe advertir el impacto en esas relaciones (ej. desvincular de la meta si cambia el monto de forma que ya no aplica el aporte).

### HU-05 — Eliminar transacción
Como usuario quiero eliminar una transacción, para deshacer un registro duplicado o erróneo.

**Criterios de aceptación:**
- Borrado lógico (`deletedAt`), recuperable desde papelera/undo inmediato tipo snackbar ("Transacción eliminada — Deshacer").
- El saldo de la(s) cuenta(s) afectada(s) se recalcula excluyendo transacciones con `deletedAt != null`.

### HU-06 — Buscar y filtrar transacciones
Como usuario quiero buscar transacciones por texto (nota/categoría) y filtrar por cuenta, categoría, tipo, rango de fechas y etiqueta, para encontrar rápido un movimiento específico o auditar un periodo.

**Criterios de aceptación:**
- Búsqueda por texto libre sobre `note` y nombre de categoría asociada.
- Filtros combinables: cuenta(s), categoría(s) (incluye subcategorías si se elige la raíz), tipo (income/expense/transfer), rango de fechas, etiqueta (`Tags`/`TransactionTags`).
- Los filtros aplicados persisten mientras el usuario navega la lista (no se resetean al hacer scroll).
- Resultado ordenado por fecha descendente por defecto, con opción de ordenar por monto.

### HU-07 — Etiquetar transacciones
Como usuario quiero asignar una o varias etiquetas libres a una transacción (además de la categoría), para cruzar información que la categoría sola no captura (ej. "viaje-cartagena", "deducible").

**Criterios de aceptación:**
- Relación N:N vía `TransactionTags`; una transacción admite múltiples etiquetas.
- Puedo crear una etiqueta nueva al vuelo desde el formulario de transacción.
- Puedo filtrar el listado de transacciones por etiqueta (ver HU-06).

### HU-08 — Ver detalle de transacción
Como usuario quiero ver el detalle completo de una transacción (cuenta, categoría, monto, fecha, nota, etiquetas, origen), para confirmar que todo quedó bien registrado.

**Criterios de aceptación:**
- Se muestra el `source` de forma legible (manual, voz, OCR, notificación, importado, recurrente) aunque en Fase 0 la inmensa mayoría sea `manual`.

## Reglas de negocio y edge cases

- `amountMinor` siempre entero positivo; el signo/dirección del efecto en el saldo lo determina `type`, nunca un monto negativo.
- Una transacción `transfer` nunca debe aparecer en el desglose de "estructura de gasto" ni sumar al total de gastos del periodo — ver `08-graficas-informes.md`.
- `source` se fija automáticamente por el flujo de entrada (en Fase 0 solo `manual` e `imported` existen realmente; los demás valores del enum quedan reservados para Fase 2/4).
- Al eliminar una cuenta o categoría con transacciones asociadas, resolver primero según `01-cuentas.md` / `02-categorias.md` antes de permitir el borrado definitivo.
