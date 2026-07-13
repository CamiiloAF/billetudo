# Feature: Cuentas

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Accounts` (`lib/core/database/app_database.dart`)

## Contexto

Las cuentas son la base de todo el registro: cada transacción pertenece a una cuenta. Deben cubrir efectivo, banco, tarjetas, ahorros e inversión sin límite de cantidad — a diferencia de apps que cobran por múltiples cuentas, aquí es gratis desde el día 1 (son solo filas en SQLite local).

La **tarjeta de crédito** es un caso especial: su "saldo" no es dinero disponible sino **deuda**, y necesita datos propios (cupo máximo, fecha de corte, fecha de pago). El resto de tipos comparten un formulario común con unos pocos campos opcionales de identificación.

## Historias de usuario

### HU-01 — Crear cuenta
Como usuario quiero crear una cuenta indicando nombre, tipo, moneda y saldo inicial, para empezar a registrar transacciones desde un punto de partida real.

**Criterios de aceptación:**
- Puedo elegir un `type`: efectivo, banco, tarjeta de crédito, ahorros, inversión, otro (`AccountType`).
- El nombre es obligatorio (1-100 caracteres).
- Elijo una moneda ISO-4217 (ej. COP, USD, MXN) al crear la cuenta; no cambia después sin flujo explícito de conversión (ver `10-multi-moneda.md`).
- El saldo inicial se guarda en centavos (`initialBalanceMinor`), nunca como decimal.
- Puedo asignar ícono y color para identificarla visualmente en listas y gráficas.
- **Campos opcionales de identificación** (todos los tipos): `institution` (nombre de la entidad, ej. "Bancolombia", "Nu"; texto libre 0-100) y número de cuenta (ver HU-03).
- **Tasa de interés opcional** (`interestRateBps`) para ahorros, inversión y tarjeta: se captura como porcentaje anual y se guarda en **puntos básicos enteros** (24,5% → `2450`); en Fase 0 es solo informativa, no calcula rendimientos.
- Si el tipo es **tarjeta de crédito**, el formulario habilita los campos específicos de HU-02 (cupo, corte, pago). Para los demás tipos esos campos permanecen ocultos y nulos.
- No hay límite de número de cuentas (Nivel 0).
- La cuenta queda disponible de inmediato para seleccionar en el formulario de transacciones.

### HU-02 — Configurar tarjeta de crédito
Como usuario quiero registrar el cupo, la fecha de corte y la fecha de pago de mi tarjeta de crédito, para controlar mi deuda, mi cupo disponible y cuándo debo pagar.

**Criterios de aceptación:**
- Al elegir `type = card`, se habilitan y se piden estos campos:
  - **Cupo máximo** (`creditLimitMinor`, centavos): tope de crédito. Obligatorio para tarjeta.
  - **Día de corte** (`statementDay`, 1-31): día del mes en que cierra el estado de cuenta.
  - **Día de pago** (`paymentDueDay`, 1-31): día límite de pago del periodo.
  - Tasa de interés opcional (`interestRateBps`, ver HU-01).
- Las fechas se guardan como **día del mes** (no una fecha absoluta), porque se repiten cada periodo. Si el mes no tiene ese día (ej. corte el 31 en febrero), se usa el último día del mes.
- El **saldo de una tarjeta es deuda**: se interpreta como negativo. Compras (gastos) aumentan la deuda; pagos (transferencia desde otra cuenta a la tarjeta) la reducen. No requiere cálculo especial — usa la misma fórmula de saldo que cualquier cuenta (ver HU-03), solo cambia la interpretación del signo.
- **Cupo disponible** = `creditLimitMinor` + saldo (saldo es negativo) = cupo máximo − deuda actual. Se muestra siempre para tarjetas.
- Los campos de tarjeta solo aplican a `type = card`; cambiar el tipo de/hacia tarjeta ajusta qué campos son válidos (ver HU-06).
- **Nota de alcance:** el recordatorio/notificación de fecha de pago **no** es parte de esta feature; aquí solo se persisten las fechas. La alerta se implementará en la feature de notificaciones, que leerá `statementDay`/`paymentDueDay` de esta tabla.

### HU-03 — Guardar y consultar el número de cuenta
Como usuario quiero guardar el número completo de mi cuenta (banco, ahorros, etc.) de forma segura, para tenerlo a la mano cuando lo necesite (ej. dar mis datos para una transferencia) sin exponerlo a la vista.

**Criterios de aceptación:**
- Puedo ingresar el **número completo** de la cuenta en cuentas de tipo **banco, ahorros, inversión y otro**. Es un campo opcional. **Efectivo no lleva número de cuenta** (el campo no aparece).
- **Tarjeta de crédito NO permite guardar el número completo** (PAN): solo se captura/deriva `last4`. Esto evita el alcance regulatorio de PCI-DSS. El formulario de tarjeta oculta el campo de número completo y **no muestra ojito ni botón de copiar** — `last4` solo se lee en la lista/detalle como identificador.
- **Almacenamiento seguro:** el número completo se guarda **cifrado** usando una clave del dispositivo (Keychain en iOS / Keystore en Android) y **no se sincroniza** a Supabase/PowerSync — vive solo en el dispositivo local. Si el usuario cambia de dispositivo, lo vuelve a ingresar.
- `last4` (últimos 4 dígitos) se **deriva automáticamente** del número completo y **sí** se puede sincronizar/mostrar; sirve para identificar la cuenta en listas sin exponer el resto. Si el usuario no ingresa el número completo, puede escribir `last4` manualmente.
- **Presentación por defecto ofuscada:** en la vista de detalle de la cuenta, el número se muestra enmascarado (ej. `•••• •••• •••• 4321`).
- **Botón "ojito" (mostrar/ocultar):** solo en cuentas que guardan número completo (no tarjeta). El usuario alterna la visibilidad para ver el número en claro. Volver a ocultarlo lo re-enmascara. La visibilidad es efímera (no persiste; cada vez arranca oculto).
- **Copiar rápido:** solo en cuentas que guardan número completo (no tarjeta). Un botón copia el número completo (en claro) al portapapeles, con confirmación visual ("Copiado"). Por seguridad, el portapapeles se limpia automáticamente tras un tiempo corto (ej. 60 s) en las plataformas que lo permitan.
- El número completo nunca aparece en logs, exportaciones no cifradas, ni backups en la nube.

### HU-04 — Ver saldo de cada cuenta
Como usuario quiero ver el saldo actual de cada cuenta, para saber cuánto dinero tengo disponible en cada una.

**Criterios de aceptación:**
- El saldo mostrado = `initialBalanceMinor` + suma de transacciones no eliminadas (`deletedAt IS NULL`) que afectan esa cuenta (ingresos suman, gastos restan, transferencias entrantes suman y salientes restan vía `transferAccountId`).
- El saldo se recalcula en tiempo real al agregar/editar/eliminar una transacción.
- Se muestra formateado según la moneda de la cuenta (símbolo y separadores correctos para es-CO/es-ES/es-MX según configuración regional).
- **Para tarjetas de crédito** se muestran **deuda actual** (valor absoluto del saldo negativo) y **cupo disponible** (ver HU-02). Por defecto se presentan ambos; el usuario puede elegir cuál resaltar como cifra principal (preferencia por cuenta, sin impacto en el cálculo). Si la deuda supera el cupo (saldo más negativo que `-creditLimitMinor`), el cupo disponible se muestra en 0 y se marca visualmente el sobrecupo.

### HU-05 — Ver transacciones combinadas de varias cuentas
Como usuario quiero seleccionar una o varias cuentas y ver sus transacciones en una sola lista, para revisar mi actividad de forma combinada sin saltar entre cuentas.

**Criterios de aceptación:**
- Puedo seleccionar entre 1 y N cuentas (incluida una opción "todas"). Con una sola cuenta seleccionada, es la vista de cuenta individual de siempre.
- La lista muestra las transacciones de todas las cuentas seleccionadas ordenadas por fecha (más reciente primero), indicando a qué cuenta pertenece cada una.
- Se muestra un **saldo combinado** = suma de los saldos de las cuentas seleccionadas.
  - **Edge case multi-moneda:** si las cuentas seleccionadas tienen monedas distintas, no se suma un total único; se muestra un subtotal por moneda (la conversión se define en `10-multi-moneda.md`).
- **Edge case transferencias internas:** una transferencia entre dos cuentas ambas seleccionadas aparece una sola vez, marcada como movimiento interno, y **no** altera el saldo combinado (sale de una y entra a otra dentro del mismo grupo).
- La selección de cuentas persiste entre sesiones para no tener que re-elegirla cada vez (comportamiento por defecto configurable).
- Las cuentas archivadas no aparecen en el selector por defecto, pero sus transacciones históricas sí se incluyen si estaban en un grupo previamente guardado (coherente con HU-07).

### HU-06 — Editar cuenta
Como usuario quiero editar los datos de una cuenta existente, para corregir información o reorganizar mi lista de cuentas.

**Criterios de aceptación:**
- Puedo cambiar `name`, `icon`, `color`, `sortOrder`, `institution`, número de cuenta (ver HU-03), `last4`, `interestRateBps` en cualquier momento.
- Para tarjetas puedo editar `creditLimitMinor`, `statementDay`, `paymentDueDay`.
- Cambiar el `type` o la `currency` de una cuenta con transacciones existentes exige confirmación explícita (afecta cálculos y reportes). Al cambiar el tipo **a** tarjeta se piden los campos obligatorios de HU-02; al cambiarlo **desde** tarjeta, los campos de tarjeta quedan nulos.
- `updatedAt` se actualiza en cada edición.

### HU-07 — Archivar cuenta
Como usuario quiero archivar una cuenta que ya no uso (sin eliminarla), para dejar de verla en mis flujos activos sin perder su historial.

**Criterios de aceptación:**
- `archived = true` oculta la cuenta de selectores de "nueva transacción" y del resumen principal, pero no de reportes históricos.
- Las transacciones ya registradas en una cuenta archivada siguen contando en gráficas de periodos que las incluyan.
- Puedo desarchivar en cualquier momento desde una vista "cuentas archivadas".

### HU-08 — Eliminar cuenta
Como usuario quiero eliminar una cuenta, para deshacer un error de creación o borrar una cuenta que ya no existe en la vida real.

**Criterios de aceptación:**
- El borrado es lógico (`deletedAt`) para permitir deshacer desde la papelera; PowerSync sincroniza el DELETE real por su cuenta cuando aplique.
- Si la cuenta tiene transacciones asociadas, se advierte al usuario del impacto (cuántas transacciones, metas o deudas quedarían huérfanas) antes de confirmar.
- No se permite eliminar la única cuenta existente sin advertencia — la app siempre necesita al menos una cuenta para registrar.

### HU-09 — Reordenar cuentas
Como usuario quiero arrastrar y reordenar mis cuentas en la lista, para ver primero las que más uso.

**Criterios de aceptación:**
- El `sortOrder` persiste y se respeta en todas las vistas donde aparece el selector de cuentas.

## Reglas de negocio y edge cases

- Ninguna operación de cuentas depende de red: todo es local-first (Drift/SQLite), coherente con "la app funciona sin conexión".
- El tipo `investment` no calcula rendimientos ni valorización automática en Fase 0 — es solo una etiqueta de cuenta para separar el patrimonio invertido; el saldo se mueve igual que cualquier otra cuenta vía transacciones manuales. La tasa de interés es informativa.
- La **tarjeta de crédito** es una cuenta de pasivo: su saldo es deuda (negativo). El pago de la tarjeta es una transferencia desde otra cuenta, no un gasto nuevo (evita doble conteo). Ver `03-transacciones.md`.
- **Número de cuenta (HU-03):** el número completo se guarda cifrado y solo en el dispositivo (Keychain/Keystore), nunca en texto plano ni sincronizado a la nube. `last4` es el único fragmento que se sincroniza/muestra. Para **tarjeta de crédito** no se guarda el número completo (PAN) en ningún caso — solo `last4` — para no entrar en PCI-DSS. La ofuscación con "ojito" es solo presentación; la protección real la da el cifrado en reposo.
- Transferencias entre cuentas se gestionan desde `Transactions` (`type = transfer`, `transferAccountId`), no desde esta feature — ver `03-transacciones.md`.
- Dinero siempre en centavos (`amountMinor`/`initialBalanceMinor`/`creditLimitMinor`), nunca `double`. La tasa de interés en puntos básicos enteros, nunca `double`.

## Cambios de esquema requeridos (Drift)

Estas HU requieren nuevas columnas en la tabla `Accounts` (todas nullable para no romper cuentas existentes). Ejecutar vía `/drift-schema-change`: subir `schemaVersion`, escribir migración y regenerar con build_runner, manteniendo paridad en Supabase/PowerSync.

| Columna | Tipo | Notas |
|---|---|---|
| `institution` | `text().nullable()` (max 100) | Nombre de la entidad. Todos los tipos. |
| `accountNumberEnc` | `text().nullable()` | Número de cuenta completo **cifrado** (Keychain/Keystore). **No** tipo tarjeta. **Excluir del sync** de PowerSync — vive solo local. HU-03. |
| `last4` | `text().nullable()` (max 4, numérico) | Últimos 4 dígitos; se deriva de `accountNumberEnc` o se ingresa manual. Único fragmento sincronizable. |
| `interestRateBps` | `integer().nullable()` | Tasa anual en puntos básicos. Informativa en Fase 0. |
| `creditLimitMinor` | `integer().nullable()` | Cupo máximo en centavos. Obligatorio si `type = card`. |
| `statementDay` | `integer().nullable()` (1-31) | Día de corte. Solo tarjeta. |
| `paymentDueDay` | `integer().nullable()` (1-31) | Día de pago. Solo tarjeta. |
| `cardBalancePrimary` | `text().nullable()` (enum: `debt`/`available`) | Preferencia de cifra a resaltar en tarjeta (HU-04). Sin impacto en cálculo; puede diferirse. |
