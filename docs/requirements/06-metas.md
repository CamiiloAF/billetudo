# Feature: Metas de ahorro

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Goals` (`lib/core/database/app_database.dart`)

## Contexto

Queja directa contra Wallet: **las metas no se vinculan a cuentas específicas**. Aquí `accountId` es parte del modelo desde el día 1. Las metas alimentan también los retos de ahorro y los hitos celebrados (Fase 3), pero el CRUD base es Nivel 0.

## Historias de usuario

### HU-01 — Crear meta de ahorro
Como usuario quiero crear una meta con nombre, monto objetivo y fecha límite opcional, para tener un propósito claro para mi ahorro (ej. "Vacaciones", "Fondo de emergencia").

**Criterios de aceptación:**
- Campos: `name` (obligatorio), `targetMinor` (obligatorio, centavos), `currency`, `targetDate` (opcional), `icon`/`color` (opcionales).
- `savedMinor` inicia en 0 salvo que el usuario indique un avance ya existente al crearla.
- No hay límite de metas simultáneas (Nivel 0).

### HU-02 — Vincular meta a una cuenta
Como usuario quiero asociar mi meta a una cuenta específica (ej. mi cuenta de ahorros del banco X), para que el progreso refleje dinero real y no solo un número aspiracional.

**Criterios de aceptación:**
- `accountId` es opcional pero recomendado en el formulario; si se asigna, debe ser una cuenta existente no eliminada.
- Una meta sin `accountId` funciona igual, pero su avance depende solo de aportes manuales (ver HU-03) sin cruce contra saldo real.

### HU-03 — Registrar un aporte a la meta
Como usuario quiero registrar un aporte a una meta (moviendo dinero real o marcando un avance manual), para ver crecer mi progreso.

**Criterios de aceptación:**
- Un aporte puede originarse de una transacción con `goalId` asignado (ej. una transferencia o un ingreso etiquetado a esa meta) — el `savedMinor` se recalcula sumando esas transacciones cuando existan.
- Alternativamente, el usuario puede ajustar `savedMinor` manualmente si no quiere modelarlo con transacciones (caso: meta puramente de seguimiento, sin cuenta vinculada).
- El progreso nunca puede quedar negativo ni superar visualmente el 100% sin indicar que la meta ya se cumplió.

### HU-04 — Ver progreso y proyección
Como usuario quiero ver una barra de progreso y una proyección de cuándo alcanzaré la meta al ritmo actual de ahorro, para saber si voy bien o necesito ahorrar más.

**Criterios de aceptación:**
- Progreso = `savedMinor / targetMinor`, mostrado como barra y porcentaje.
- Si hay `targetDate`, se muestra si el ritmo actual alcanza para llegar a tiempo (cálculo simple: aporte promedio mensual reciente vs. lo que falta y el tiempo restante).
- Sin `targetDate`, se omite la proyección de fecha pero se muestra el progreso normal.

### HU-05 — Celebrar hitos
Como usuario quiero que la app celebre cuando alcanzo tramos importantes de mi meta (25%, 50%, 75%, 100%), para sentirme motivado a seguir ahorrando.

**Criterios de aceptación:**
- Al cruzar cada umbral se muestra una celebración visual/notificación con tono positivo (nunca condicionada a pago — cálculo local).
- Al llegar a 100%, la meta se marca como cumplida pero no se elimina automáticamente; el usuario decide archivarla o mantenerla visible.

### HU-06 — Editar y eliminar meta
Como usuario quiero modificar el nombre, monto objetivo, fecha o cuenta vinculada de una meta, o eliminarla si ya no aplica.

**Criterios de aceptación:**
- Editar `targetMinor` no borra el `savedMinor` acumulado.
- Eliminar es borrado lógico (`deletedAt`), recuperable desde papelera; las transacciones que tenían `goalId` apuntando a esta meta quedan con la referencia histórica (no se eliminan las transacciones).

## Reglas de negocio y edge cases

- Retos de ahorro basados en reglas (52 semanas, redondeo, "no gastar en X") son una capa sobre esta feature, prevista para Fase 3 — el modelo de `Goals` + `Transactions.goalId` ya la soporta sin cambios de esquema.
- El tono de toda esta feature debe ser de progreso, nunca de presión o culpa (regla transversal de CLAUDE.md).
