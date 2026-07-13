# Feature: Presupuestos

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Budgets` (`lib/core/database/app_database.dart`)

## Contexto

Presupuestos por categoría o globales, con periodos flexibles y un modo base-cero opcional inspirado en YNAB — pero **sin su fricción ni obligatoriedad**. Alimentan el cálculo de "disponible para gastar" (safe-to-spend), motor de retención clave de Fase 3, y las alertas anticipadas y positivas.

## Historias de usuario

### HU-01 — Crear presupuesto por categoría
Como usuario quiero asignar un monto máximo a una categoría para un periodo (semanal, mensual, anual o personalizado), para controlar cuánto gasto en esa categoría.

**Criterios de aceptación:**
- Campos: `categoryId` (opcional; null = presupuesto global que cubre todos los gastos), `amountMinor`, `currency`, `period` (`BudgetPeriod`: weekly/monthly/yearly/custom), `startDate`.
- Solo se presupuestan categorías de `kind = expense` (no tiene sentido presupuestar ingresos).
- No hay límite de presupuestos activos simultáneos (Nivel 0).
- No se permite crear dos presupuestos activos con el mismo `categoryId` y `period` solapado — evita ambigüedad de "cuál aplica".

### HU-02 — Crear presupuesto global
Como usuario quiero definir un tope de gasto total del periodo (sin categoría específica), para tener un límite general además de los desgloses por categoría.

**Criterios de aceptación:**
- `categoryId = null` representa el presupuesto global.
- El progreso del presupuesto global se calcula sobre la suma de **todos** los gastos del periodo (excluyendo transferencias), independientemente de si además tienen presupuesto de categoría.

### HU-03 — Ver progreso del presupuesto
Como usuario quiero ver cuánto llevo gastado y cuánto me queda de cada presupuesto activo, para decidir si puedo seguir gastando en esa categoría.

**Criterios de aceptación:**
- Progreso = suma de `amountMinor` de transacciones `expense` no eliminadas, con `date` dentro del rango vigente del periodo y `categoryId` correspondiente (incluye subcategorías si el presupuesto es sobre una categoría raíz).
- Se muestra: gastado, restante, porcentaje, y días restantes del periodo.
- El estado se visualiza con color/progreso (verde/ámbar/rojo) pero el tono del texto es siempre positivo, nunca de reproche (ver `Tono de la app` en CLAUDE.md).

### HU-04 — Presupuesto base-cero opcional
Como usuario quiero, si lo activo, distribuir todo mi ingreso del periodo entre presupuestos hasta que "cada peso tenga un trabajo", para aplicar la metodología YNAB de forma simplificada y opcional.

**Criterios de aceptación:**
- Es un modo opt-in a nivel de app/periodo, no obligatorio para usar presupuestos normales.
- Muestra "ingreso del periodo − total asignado a presupuestos = sin asignar", y ese "sin asignar" debe llegar a cero para considerarse completo — pero no bloquea ninguna acción si no llega a cero.
- No introduce una tabla nueva: se apoya en `Budgets` + suma de `Transactions.type = income` del periodo.

### HU-05 — Rollover (arrastre de presupuesto)
Como usuario quiero que el sobrante (o el exceso) de un presupuesto se arrastre al siguiente periodo, para no perder el margen que no usé o compensar un mes en que me pasé.

**Criterios de aceptación:**
- Se controla con el flag `rollover` del presupuesto.
- Si `rollover = true`: el monto disponible del nuevo periodo = `amountMinor` del periodo + (sobrante o déficit del periodo anterior).
- Si `rollover = false` (default): cada periodo inicia limpio con solo `amountMinor`.
- El cambio de este flag no recalcula retroactivamente periodos ya cerrados.

### HU-06 — Alertas de presupuesto anticipadas
Como usuario quiero recibir un aviso antes de pasarme de un presupuesto (no después), para poder ajustar mi gasto a tiempo.

**Criterios de aceptación:**
- Umbral configurable (ej. al alcanzar 80% del presupuesto) dispara una notificación local positiva: "Te queda X% del presupuesto de [categoría] y faltan Y días" — no es IA, es cálculo local determinístico.
- Al completar el periodo dentro del presupuesto, se felicita al usuario (refuerzo positivo, no solo alertas de exceso).
- Esta feature es Nivel 0 (cálculo local, sin costo), aunque su implementación completa puede aterrizar en Fase 3 según el roadmap — el modelo de datos debe soportarla desde Fase 0.

### HU-07 — Editar y eliminar presupuesto
Como usuario quiero modificar el monto, periodo o categoría de un presupuesto, o eliminarlo si ya no aplica.

**Criterios de aceptación:**
- Editar no altera el histórico de progreso ya calculado de periodos pasados (el cálculo de progreso siempre se hace contra los valores vigentes en cada periodo, no retroactivo).
- Eliminar es borrado lógico (`deletedAt`), recuperable desde papelera.

## Reglas de negocio y edge cases

- Las transferencias (`type = transfer`) nunca cuentan para el progreso de ningún presupuesto.
- Un presupuesto sobre una categoría raíz agrega automáticamente el gasto de todas sus subcategorías.
- Presupuestos ilimitados y sin anuncios — ninguna feature de esta pantalla puede quedar bloqueada tras Modo anuncios o Premium (regla de Nivel 0 en CLAUDE.md).
