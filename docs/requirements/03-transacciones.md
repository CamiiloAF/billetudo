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
- El monto se captura en la moneda de la cuenta seleccionada por defecto; ver `11-multi-moneda.md` si se registra en otra moneda.

**Teclado numérico anclado — regla de interacción (aplica a los 3 tipos, HU-01/02/03):**
- El teclado numérico personalizado (con operadores básicos `+ − × ÷ =`) vive anclado a la parte inferior de la pantalla, nunca en medio del formulario — evita el esfuerzo de alcance del pulgar que tendría en otra posición.
- **No es un panel permanente.** Se muestra automáticamente cuando el campo Monto tiene el foco (estado por defecto al abrir el formulario, ya que el monto suele ser el primer dato que se llena) y se oculta automáticamente en cuanto el usuario toca cualquier campo de texto libre (ej. Nota), cediendo el espacio inferior al teclado nativo del sistema operativo. Vuelve a aparecer si el usuario regresa al campo Monto.
- Esto evita que el teclado personalizado y el teclado nativo del sistema compitan por el mismo espacio en pantalla al mismo tiempo — nunca deben estar abiertos ambos a la vez.
- Cuenta, Categoría y Fecha son selectores (no abren teclado del sistema), así que no interactúan con esta regla — solo el campo Nota la dispara.

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
- Si origen y destino tienen monedas distintas, ver `11-multi-moneda.md` para la tasa aplicada.

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
- **Selección de categoría raíz — comportamiento de toggle:** al tocar una categoría raíz, sus subcategorías se seleccionan automáticamente todas (equivalente a "raíz + todo su árbol"). Al volver a tocar esa misma raíz (ya seleccionada), se deseleccionan todas sus subcategorías junto con ella — es un toggle simétrico, no solo de aplicación. El usuario puede además deseleccionar subcategorías individuales sin afectar a las demás ni a la raíz (selección granular parcial), pero la acción de tocar la raíz siempre afecta al árbol completo en bloque.
- Los filtros aplicados persisten mientras el usuario navega la lista (no se resetean al hacer scroll).
- Resultado ordenado por fecha descendente por defecto, con opción de ordenar por monto.

**Filtro por cuenta(s) — selección rápida (HU-06a):**
- Acceso al filtro de cuentas en máximo un toque desde el listado (chip/botón visible en la barra de filtros, no enterrado en un menú de "más opciones").
- Selección múltiple mediante bottom sheet (ver [[feedback_mobile_bottom_sheets]] — patrón estándar mobile de esta app, no modal/diálogo centrado), con:
  - Lista de todas las cuentas activas (incluye cuentas archivadas solo si el usuario ya las tenía filtradas explícitamente antes de archivarlas).
  - Cada ítem con checkbox/estado seleccionable de un toque; sin pasos intermedios (no "seleccionar" + "confirmar" por cuenta).
  - Acciones rápidas "Todas" / "Ninguna" en la cabecera del sheet para no tener que tocar cuenta por cuenta.
  - Saldo o ícono/color de la cuenta visible junto al nombre, para reconocerla sin leer el texto completo.
  - Botón "Aplicar" fijo al fondo del sheet; cierre sin aplicar (swipe/back) descarta la selección temporal y conserva el filtro previo.
- Estado por defecto: todas las cuentas incluidas (sin filtro activo) — el usuario nunca ve una lista vacía por un filtro de cuenta olvidado.
- El chip/botón de filtro refleja el estado seleccionado de forma compacta: sin badge si están todas, nombre de la cuenta si es una sola, o "N cuentas" si son varias (2+), para no obligar a abrir el sheet solo para confirmar qué está activo.
- Combinable con el resto de filtros de HU-06 (categoría, tipo, fechas, etiqueta) sin resetear la selección de cuentas al ajustar otro filtro.
- Limpiar cuentas seleccionadas es una acción directa desde el chip (ej. icono "x" o "Todas" en el propio sheet), sin tener que deseleccionar una por una.
- Una transferencia aparece en el resultado si la cuenta filtrada es origen **o** destino (`accountId` o `transferAccountId` coincide con alguna cuenta seleccionada) — auditar una cuenta debe mostrar todo lo que la movió, no solo la mitad del movimiento.
- Si las cuentas seleccionadas tienen monedas distintas, no se muestra un total sumado del periodo (sumar monedas distintas como si fueran la misma unidad es incorrecto); se muestra el total desglosado por cuenta/moneda. Conversión a moneda base queda fuera de alcance de esta HU — ver `11-multi-moneda.md`.

**Filtro por fecha — navegación rápida por periodo (HU-06b):**
- Acceso en máximo un toque desde el listado (chip/botón "Fecha" en la barra de filtros, igual que el resto de HU-06).
- **Siempre hay un filtro de fecha activo — no existe estado "sin filtro"/"Todo".** Mostrar de entrada todas las transacciones históricas sobrecarga la lista; un periodo acotado es siempre el caso de uso correcto. **Estado por defecto: mes en curso** ("Este mes", granularidad Mes).
- Selección mediante bottom sheet con:
  - Selector de granularidad (Semana / Mes / Año) arriba, tipo Segmented Control.
  - Stepper debajo (`‹ Julio 2026 ›`) que avanza/retrocede un paso de la granularidad activa por toque, aplicando el filtro de inmediato sin botón "Aplicar" — el label del stepper siempre refleja el periodo actualmente aplicado.
  - **"Rango personalizado"** al final, para fechas específicas — este sí requiere confirmación (botón "Aplicar"), a diferencia del resto que aplica al toque.
- **Al aplicar un rango personalizado, la UI cambia de estado:** dejar de mostrar el stepper de granularidad (no aplica — un rango arbitrario no es "un paso" de Semana/Mes/Año) y en su lugar mostrar el rango elegido (ej. "3 jul – 9 jul 2026") junto a una **"X" para limpiarlo**, que al tocarse vuelve al estado por defecto ("Este mes"). Esa "X" solo existe en este estado — no hay una acción general de "quitar filtro" fuera de un rango personalizado activo, porque el filtro nunca está realmente "apagado".
- El chip refleja el periodo activo de forma compacta (ej. "Jul 2026", "Esta semana", o el rango cuando aplica "Rango personalizado").
- Navegar a un mes/año sin transacciones registradas es válido (no es un error) — el listado muestra el estado vacío del periodo con el mismo tono neutral de siempre, no un error.

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
- Una transacción `transfer` nunca debe aparecer en el desglose de "estructura de gasto" ni sumar al total de gastos del periodo — ver `09-graficas-informes.md`.
- Lo mismo aplica a una transacción con `debtId` asignado: no cuenta en los totales de ingreso/gasto de gráficas/informes (ver `07-deudas.md`), aunque a diferencia de `transfer` sí puede llevar `categoryId` opcional para organización propia del usuario.
- `source` se fija automáticamente por el flujo de entrada (en Fase 0 solo `manual` e `imported` existen realmente; los demás valores del enum quedan reservados para Fase 2/4).
- Al eliminar una cuenta o categoría con transacciones asociadas, resolver primero según `01-cuentas.md` / `02-categorias.md` antes de permitir el borrado definitivo.
