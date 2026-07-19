# Feature: Metas de ahorro

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tablas Drift:** `Goals` + tabla de movimientos `GoalContributions` (`lib/core/database/app_database.dart`)

## Contexto

Queja directa contra Wallet: **las metas no se vinculan a cuentas específicas**. Aquí `accountId` es parte del modelo desde el día 1. Las metas alimentan también los retos de ahorro y los hitos celebrados (Fase 3), pero el CRUD base es Nivel 0.

**Filosofía del progreso — el avance es un historial, no un número que se edita.** El progreso de una meta (`savedMinor`) **siempre se deriva** de la suma de sus movimientos en `GoalContributions`; nunca es una columna que la UI sobrescriba. Un aporte "manual" (meta sin cuenta vinculada) y un aporte "real" (transferencia hacia la cuenta vinculada) son la **misma fila** de movimiento — la única diferencia es si esa fila apunta o no a una transacción. Un solo camino de escritura, historial auditable, y el detalle de la meta siempre tiene qué listar.

**Todo aporte nace desde la meta.** El formulario de transacción **no** expone un campo "Meta". Los movimientos se crean desde el detalle de la meta con acciones explícitas ("Aportar" / "Retirar"), por lo que la dirección del movimiento siempre queda declarada por el usuario y nunca se infiere de la dirección de una transferencia.

## Historias de usuario

### HU-01 — Crear meta de ahorro
Como usuario quiero crear una meta con nombre, monto objetivo y fecha límite opcional, para tener un propósito claro para mi ahorro (ej. "Vacaciones", "Fondo de emergencia").

**Criterios de aceptación:**
- Campos: `name` (obligatorio, 1-100 caracteres), `targetMinor` (obligatorio, centavos, > 0), `currency` (ISO-4217), `targetDate` (opcional), `icon` (opcional), `accountId` (opcional, HU-02).
- `targetDate`, si se indica, debe ser **posterior a hoy** en el momento de crear. Una meta cuya `targetDate` ya pasó no se bloquea ni se marca como fallida (tono positivo): simplemente deja de mostrar proyección de fecha y ofrece "Ajustar la fecha" (ver HU-05).
- El progreso inicia en 0. Si el usuario indica un **avance ya existente** al crear la meta, ese monto se guarda como el **primer movimiento** de `GoalContributions` (tipo `contribution`, sin `transactionId`), no como un valor suelto — así el historial arranca completo desde el día 1.
- No hay límite de metas simultáneas (Nivel 0).
- **Sin color por meta.** Se evaluaron ambas opciones en Pencil (variantes colorida y sobria del mismo layout) y el usuario eligió la **sobria**: el icon-wrap permanece neutro y no hay selector de color en el formulario, solo de ícono. Motivo de diseño: el anillo de progreso ya aporta suficiente carácter y el color por entidad competía con él. Mismo criterio que `Budgets` y `Accounts`.
- **El color queda reservado al estado, nunca a la identidad.** El único color con significado en esta pantalla es el de la meta cumplida (familia `income` vía `$income-text`). Regla del sistema: *el color decorativo vive en el ícono; el color del indicador de progreso es semántico* — y aquí, sin color decorativo, el canal semántico queda íntegro para la celebración.

### HU-02 — Vincular meta a una cuenta
Como usuario quiero asociar mi meta a una cuenta específica (ej. mi cuenta de ahorros del banco X), para que el progreso refleje dinero real y no solo un número aspiracional.

**Criterios de aceptación:**
- `accountId` es opcional pero recomendado en el formulario; si se asigna, debe ser una cuenta existente, no eliminada ni con lápida (`tombstonedAt`).
- **La cuenta no define el progreso.** El progreso siempre sale de `GoalContributions`. La cuenta define **cómo se registran los aportes** (HU-03) y habilita la señal de coherencia (HU-12).
- Si hay `accountId`, la **moneda de la meta se fija a la moneda de la cuenta** y el selector de moneda queda bloqueado. Cambiar la cuenta por una de otra moneda solo se permite si la meta **no tiene movimientos**; con movimientos, la app lo impide y explica por qué (mezclar monedas invalidaría el histórico).
- Una meta **sin** `accountId` funciona igual, pero su avance depende solo de aportes manuales (HU-03) y no ofrece la señal de coherencia.
- Varias metas pueden apuntar a la **misma cuenta**; eso es válido y esperado (una cuenta de ahorros suele albergar varios propósitos). La sobre-asignación se comunica, no se bloquea (HU-12).
- Si la cuenta vinculada recibe lápida (`tombstonedAt`, HU-08 de Cuentas), la meta **conserva** su histórico y su `accountId`, pasa a comportarse como meta sin cuenta (aportes manuales) y muestra un aviso neutro invitando a vincular otra cuenta.

### HU-03 — Registrar un aporte a la meta
Como usuario quiero registrar un aporte a una meta, moviendo dinero real o marcando un avance manual, para ver crecer mi progreso.

**Criterios de aceptación:**
- El aporte se registra **desde el detalle de la meta** con la acción "Aportar". El formulario de transacción no ofrece un campo "Meta".
- **Meta con cuenta vinculada:** "Aportar" pide monto, fecha y **cuenta de origen**, y crea una **transferencia real** (`type = transfer`, `accountId` = origen, `transferAccountId` = cuenta de la meta) con `goalId` apuntando a la meta, más la fila de `GoalContributions` (`direction = contribution`) que la referencia. El saldo de ambas cuentas se mueve como en cualquier transferencia.
- **Meta sin cuenta vinculada:** "Aportar" pide monto y fecha y crea **solo** la fila de `GoalContributions` (`transactionId` nulo). No se crea transacción ni se toca ningún saldo — es seguimiento puro.
- **Tipos de transacción admitidos con `goalId`:** `transfer` (aporte/retiro real entre cuentas) e `income` (un ingreso que se aparta directo a la meta, ej. un bono). **`expense` con `goalId` está prohibido** por invariante: un gasto no es ahorro, y además contaminaría el cálculo de presupuestos, que suma exactamente `type = expense`.
- **Los aportes no consumen presupuesto.** Al no ser `expense`, quedan fuera del cálculo de Presupuestos por construcción; no hace falta una exclusión especial.
- El monto de un movimiento es **siempre positivo** (centavos); la dirección la da `direction` (`contribution` / `withdrawal`), igual que `Transactions.amountMinor` + `type`.
- `savedMinor` = `SUM(contribution) − SUM(withdrawal)`. Nunca puede quedar negativo, porque el retiro está acotado (HU-04).

### HU-04 — Retirar dinero de la meta
Como usuario quiero poder sacar dinero de una meta si lo necesito, para que la meta refleje la realidad y no me castigue por un imprevisto.

**Criterios de aceptación:**
- "Retirar" es la acción inversa de "Aportar" y crea una fila con `direction = withdrawal`.
- **Meta con cuenta vinculada:** crea una transferencia desde la cuenta de la meta hacia la cuenta de destino que elija el usuario, con `goalId`.
- **Meta sin cuenta vinculada:** solo crea la fila de movimiento.
- El monto del retiro **no puede superar** el `savedMinor` actual. La UI acota el máximo en vez de dejar fallar la validación.
- **Tono:** retirar es una operación normal, nunca un error ni un retroceso señalado. Sin lenguaje de culpa ni iconografía de alerta.
- **Asimetría deliberada entre aportar y retirar.** El tope del retiro es duro porque `savedMinor` es una invariante del modelo. En cambio, **aportar más que el saldo de la cuenta de origen NO se bloquea**: el saldo local es una foto que puede ir por detrás del banco, la app ya admite saldos negativos como hecho normal (tarjetas de crédito), y bloquear un aporte sería la app diciéndole al usuario "no puedes ahorrar eso". Se muestra una línea informativa neutra bajo el campo de cuenta ("Nequi quedaría en −$59.500"), nunca en la familia `$expense` ni con iconografía de alerta.
- **En una meta cumplida, retirar no revierte nada** (HU-07) y el copy del sheet debe decirlo explícitamente. Un texto genérico del tipo "ajustamos el avance" contradice la promesa de la pantalla de meta cumplida justo en el momento de mayor ansiedad: se requieren variantes de copy separadas para meta en curso y meta cumplida.

### HU-05 — Ver progreso y proyección
Como usuario quiero ver una barra de progreso y una proyección de cuándo alcanzaré la meta al ritmo actual de ahorro, para saber si voy bien o necesito ahorrar más.

**Criterios de aceptación:**
- Progreso = `savedMinor / targetMinor`, mostrado como barra y porcentaje, acotado visualmente al 100%.
- **Proyección (solo si hay `targetDate`):** ritmo = **promedio de aportes netos de los últimos 3 meses completos**. Con ese ritmo se estima la fecha de llegada y se compara contra `targetDate`.
- **Sin historial suficiente** (cero movimientos, o menos de un mes de vida de la meta): no se proyecta nada. Se muestra el aporte mensual necesario para llegar a tiempo ("$X al mes te lleva a tu meta en junio"), que no requiere historial.
- **Redacción obligatoriamente positiva.** Nunca "vas tarde" ni "no vas a lograrlo". El patrón es siempre: *estado actual + acción concreta*. Ej. "A este ritmo llegas en marzo. Con $120.000 más al mes llegas en tu fecha."
- **Sin `targetDate`:** se omite toda proyección de fecha; se muestra progreso, monto restante y ritmo actual.
- **`targetDate` ya vencida:** se omite la proyección y se ofrece "Ajustar la fecha" como acción principal. No se muestra estado de fracaso.

### HU-06 — Celebrar hitos
Como usuario quiero que la app celebre cuando alcanzo tramos importantes de mi meta (25%, 50%, 75%, 100%), para sentirme motivado a seguir ahorrando.

**Criterios de aceptación:**
- Umbrales: 25%, 50%, 75%, 100%. Cálculo **100% local**, nunca condicionado a pago ni a anuncio.
- **La celebración es idempotente.** `Goals.lastMilestonePct` guarda el umbral más alto ya celebrado. Solo se celebra al cruzar un umbral **estrictamente mayor** al guardado. Si el progreso baja por un retiro y vuelve a subir, **no se vuelve a celebrar** — sin esto, un saldo oscilando alrededor del 50% celebraría en bucle.
- `lastMilestonePct` **solo se reinicia** si el usuario sube `targetMinor` de forma que el progreso caiga por debajo de un umbral ya celebrado; en ese caso se ajusta al umbral vigente, no a 0.
- **Alcance de la celebración: solo in-app.** No hay infraestructura de notificaciones locales en el repo y no se introduce en Nivel 0. Si varios umbrales se cruzan de un solo aporte (0% → 80%), se celebra **uno solo**: el más alto alcanzado.

### HU-07 — Meta cumplida
Como usuario quiero que la app reconozca que cumplí mi meta y que gastar ese dinero después no me borre el logro.

**Criterios de aceptación:**
- Al alcanzar el 100%, la meta se marca con `completedAt` y muestra estado "Cumplida". **No se elimina ni se archiva automáticamente.**
- **Una meta cumplida queda congelada:** los retiros posteriores (ej. gastar lo ahorrado en el viaje) **no reducen** su progreso ni revierten `completedAt`. Sin esta regla la barra se desplomaría al 0% justo en el momento de mayor satisfacción del usuario.
- El detalle de una meta cumplida ofrece como acción principal **"Archivar"** (HU-09), y los movimientos siguen registrándose en el historial aunque no muevan la barra.
- Si el usuario **sube `targetMinor`** de una meta cumplida, `completedAt` se limpia y la meta vuelve a estar en curso (decisión explícita del usuario de ampliar el objetivo).

### HU-08 — Editar meta
Como usuario quiero modificar el nombre, monto objetivo, fecha o cuenta vinculada de una meta.

**Criterios de aceptación:**
- Editar `targetMinor` **no toca el historial de movimientos**: el progreso se recalcula solo porque cambió el denominador.
- Bajar `targetMinor` por debajo del `savedMinor` actual marca la meta como cumplida (HU-07).
- Cambiar `accountId` está sujeto a la regla de moneda de HU-02. Cambiar de cuenta **no** reescribe las transacciones históricas ya creadas.
- Editar o eliminar la **transacción** que respalda un movimiento mantiene la consistencia: si se cambia su monto, el movimiento se actualiza; si se elimina la transacción, su movimiento se elimina también. Esta cascada vive en el repositorio, no en la base.

### HU-09 — Archivar meta y ver archivadas
Como usuario quiero guardar mis metas terminadas sin borrarlas, para conservar el logro sin saturar la lista.

**Criterios de aceptación:**
- Archivar fija `archivedAt`. La meta sale de la lista principal y pasa a "Metas archivadas", con su progreso e historial intactos. Es reversible (desarchivar).
- Se puede archivar cualquier meta, cumplida o no (una meta abandonada se archiva, no se borra).
- Una meta archivada **no** acepta nuevos movimientos ni entra en la señal de coherencia de cuenta (HU-12).
- Mismo patrón que Presupuestos (`archivedAt` + pantalla de archivados): tres estados distintos y no intercambiables — `archivedAt` (histórico), `deletedAt` (papelera), `tombstonedAt` (lápida por integridad referencial).

### HU-10 — Eliminar meta
Como usuario quiero eliminar una meta que ya no aplica, sin perder el histórico de mis transacciones.

**Criterios de aceptación:**
- Eliminar es **borrado lógico con `deletedAt`** (papelera, recuperable), como cualquier otra papelera de UX.
- **Al vaciar la papelera la fila no se borra físicamente: se le pone `tombstonedAt`.** Motivo: `Transactions.goalId` referencia `Goals.id`, y la regla del proyecto es que una fila referenciada por otra tabla sobrevive con lápida. Así las transacciones conservan su referencia histórica sin quedar colgadas.
- Las transacciones que apuntaban a la meta **no se eliminan ni se modifican**; el dinero se movió de verdad entre cuentas y ese hecho no depende de la meta.
- Los movimientos de `GoalContributions` de una meta con lápida quedan ocultos de toda query, igual que la meta.

### HU-11 — Lista de metas
Como usuario quiero ver todas mis metas de un vistazo desde la navegación principal, para saber cómo van mis ahorros.

**Criterios de aceptación:**
- "Metas" es un destino de la barra de navegación inferior (ver `04-inicio.md`).
- Orden por defecto: metas en curso primero (las de `targetDate` más próxima arriba, luego las sin fecha), y las cumplidas no archivadas al final.
- Cada fila muestra nombre, ícono, barra de progreso, `savedMinor` / `targetMinor` y, si aplica, la cuenta vinculada.
- Estados obligatorios: **vacío** (invitación positiva a crear la primera meta, sin culpa), **carga** (skeleton, mismo patrón que Presupuestos), **error** (reintento).
- Acceso a "Metas archivadas" desde la propia pantalla, no enterrado en Ajustes.

### HU-12 — Señal de coherencia con la cuenta
Como usuario quiero saber si el dinero que tengo asignado a mis metas realmente existe en la cuenta, para que mis metas no sean un número inflado.

**Criterios de aceptación:**
- Para cada cuenta con metas vinculadas activas: si la **suma de `savedMinor`** de esas metas **supera el saldo real** de la cuenta, se muestra una señal informativa en el detalle de la meta y en la lista.
- Es **informativa, nunca bloqueante ni punitiva**: no impide aportar, no marca error. Redacción tipo "Tus metas en Ahorros suman $X y la cuenta tiene $Y" con un enlace para ajustar.
- No se calcula para metas sin cuenta vinculada ni para metas archivadas.

## Reglas de negocio y edge cases

- **`savedMinor` nunca se escribe directamente.** Es una proyección de `GoalContributions`. Cualquier código que intente asignarlo es un bug de arquitectura.
- **Invariante:** ninguna transacción con `type = expense` puede tener `goalId`. Debe validarse en el caso de uso, no solo en la UI.
- Un aporte no consume presupuesto y no cuenta como gasto en reportes de gasto: es un movimiento entre cuentas propias.
- Retos de ahorro basados en reglas (52 semanas, redondeo, "no gastar en X") son una capa sobre esta feature, prevista para Fase 3 — el modelo `Goals` + `GoalContributions` la soporta sin cambios de esquema: un reto genera movimientos como cualquier otro origen.
- El tono de toda esta feature debe ser de progreso, nunca de presión o culpa (regla transversal de CLAUDE.md). Aplica especialmente a retiros (HU-04), proyección atrasada (HU-05) y coherencia de cuenta (HU-12).

## Estado del diseño (2026-07-19)

**El diseño de Metas en `billetudo.pen` NO está aprobado todavía: el usuario aún no lo ha revisado por completo.** El tema claro está construido y pasó varias rondas de `ui-ux-reviewer`, pero la revisión humana está pendiente, así que **no se debe escribir `design-system/billetudo/pages/metas.md` ni pasar a `flutter-dev`** hasta que esa aprobación exista (ver el flujo por feature en `CLAUDE.md`).

Lo construido en tema claro: lista con sus estados (con datos, vacío, carga, error, señal de coherencia) y banda de peor caso; detalle en 9 variantes (en curso, cumplida, sin historial, sin fecha, fecha vencida, historial vacío, carga, archivada, cuenta con lápida); sheets de aportar y retirar (con y sin cuenta vinculada, más variantes de meta cumplida) y de detalle del movimiento; formulario de crear/editar con moneda bloqueada y desbloqueada; metas archivadas; celebración de hitos (25/50/75/100); y sheets de confirmación.

Pendientes técnicos conocidos, no resueltos:

- **`EZdcd` (Action Row) dentro del componente `Goal Panel` tiene ancho 0**, lo que hace que sus hijos salgan como "fully clipped" en las 6 instancias del detalle. Sin diagnosticar; probablemente falte `fill_container`. La fila sí se ve en `lRlDo` y `YxKgE`, así que podría ser un artefacto de medición.
- **`Yx937` es la única pantalla de la banda sin rótulo propio** y comparte `x` con el rótulo de banda.
- **La variante sin fecha (`YxKgE`) cierra con margen cero** (contenido en y=814 sobre 814 útiles). Al implementar, el historial debe poder recortarse a 3 filas en el peor caso.
- **Tema oscuro sin generar**, bloqueado por la deuda de sistema del token de track (ver abajo).

## Notas de diseño

El diseño de Metas se está construyendo desde cero en `billetudo.pen` (el frame anterior fue descartado por obsoleto). Reglas de accesibilidad y consistencia que salieron de la auditoría de `ui-ux-reviewer` y que **toda variante debe cumplir**:

- **El `%` nunca en `$primary` crudo** a 16px/800: da 3.00:1 sobre `$surface` en tema oscuro, insuficiente para texto no-grande (requiere 4.5:1). → `$primary-on-soft`.
- **Barra de meta cumplida en `$income-text`, nunca `$income`**: `$income` da 1.96:1 sobre el track en claro, por debajo del 3:1 de WCAG 1.4.11. `$income-text` da 6.12:1 en claro y en oscuro es el mismo valor.
- **Deuda de sistema pendiente para el tema oscuro:** `$primary` sobre track `$border` queda ~2.2:1 y sobre `$muted` ~2.75:1, ambos bajo el 3:1. Afecta por igual a `Budget Line` en Presupuestos, así que debe resolverse a nivel de sistema (¿un token `track` propio?) antes de generar el oscuro de cualquiera de las dos features.
- **Prohibido el resumen monetario agregado** ("ahorro total en metas"): sumaría metas de distintas monedas, justo lo que `pages/presupuestos.md` prohíbe, y HU-02 fija la moneda de cada meta a la de su cuenta. Si hay resumen, debe ser no monetario (conteo, racha, próximo hito) o de una sola moneda declarada.

- **Los montos no truncan nunca; el nombre sí.** En es-CO un objetivo de 9 cifras (`$180.000.000`, y `US$180.000.000` con multi-moneda) desborda con facilidad. Prohibido abreviar el objetivo a `$180 M`: el usuario está haciendo aritmética mental sobre cuánto le falta. El nombre de la meta y la línea de metadatos (cuenta · fecha) son los únicos que pueden hacer ellipsis.
- **En la lista, una sola línea; en el detalle, dos.** El nombre va `maxLines: 1` + ellipsis en la lista: al envolver, la tarjeta crece de 112 a ~131px y rompe el ritmo uniforme de una lista de altura constante. `maxLines: 2` es correcto solo en el detalle de la meta.
- **La línea de metadatos va debajo de la barra de progreso**, alineada con `Goal Card` y `Balance Card Hero`. Diverge a propósito de `Budget Line`, que la pone encima; es una decisión consciente, no una inconsistencia. Ese patrón no está escrito en `MASTER.md` aunque ya se cumple en tres componentes — conviene registrarlo ahí.
- **Forma de la señal de coherencia (HU-12): una fila informativa condicional encima de la lista**, no una línea dentro de cada tarjeta. La sobre-asignación es un hecho de la **cuenta**, no de la meta: repetirla en las N metas de esa cuenta es ruido y sugiere que cada meta individual está mal, justo el tono punitivo que HU-12 prohíbe. Ícono `info` neutro — **nunca** `triangle-alert` ni la familia `$expense`, porque no es un error financiero. Toda la fila navega; sin botón de descartar, porque es un dato y no una alerta que se cierra.

## Cambios de esquema requeridos (Drift)

El progreso pasa de una columna materializada a un **historial de movimientos derivado**, más los estados de cumplimiento, archivo y celebración. Ejecutar vía `/drift-schema-change`: subir `schemaVersion`, escribir migración y regenerar con build_runner, manteniendo paridad en Supabase/PowerSync.

**Enum nuevo `GoalMovementDirection`** (texto, como todos los enums del esquema, por paridad con Postgres):
```
enum GoalMovementDirection { contribution, withdrawal }
```

**Tabla `Goals`** — quitar `savedMinor` y `color`, agregar estados:

| Columna | Tipo | Notas |
|---|---|---|
| ~~`savedMinor`~~ | — | **Se elimina.** El progreso se deriva de `GoalContributions`. La migración convierte cualquier valor existente en un movimiento `contribution` inicial. |
| ~~`color`~~ | — | **Se elimina.** Sin color por meta (HU-01, decisión de diseño tomada contra las variantes de Pencil); el icon-wrap es neutro, mismo criterio que `Budgets`. |
| `completedAt` | `dateTime().nullable()` | No nulo = meta cumplida y congelada (HU-07). |
| `archivedAt` | `dateTime().nullable()` | No nulo = archivada (HU-09). Distinto de `deletedAt` y `tombstonedAt`. |
| `lastMilestonePct` | `integer().clientDefault(() => 0)` | Umbral más alto ya celebrado (0/25/50/75/100). Hace idempotente la celebración (HU-06). |

`name`, `targetMinor`, `currency`, `accountId`, `targetDate`, `icon` **ya existen** y se conservan. Conviene añadir `withLength(min: 1, max: 100)` a `name` para alinearlo con `Budgets`.

**Tabla nueva `GoalContributions`** (con el mixin `_SyncColumns`, por lo que lleva su propio `id` UUID):

| Columna | Tipo | Notas |
|---|---|---|
| `goalId` | `text().references(Goals, #id)` | Meta a la que pertenece el movimiento. |
| `amountMinor` | `integer()` | **Siempre positivo**, en centavos. El signo lo da `direction`, igual que en `Transactions`. |
| `direction` | `textEnum<GoalMovementDirection>()` | `contribution` o `withdrawal`. |
| `date` | `dateTime()` | Fecha del movimiento (la elige el usuario, no es `createdAt`). |
| `transactionId` | `text().nullable().references(Transactions, #id)` | No nulo = respaldado por una transacción real; nulo = aporte manual (meta sin cuenta). |
| `note` | `text().nullable()` | Nota opcional del movimiento. **No se muestra en la fila del historial** (esa línea ya carga `cuenta · fecha` con ellipsis y una segunda línea rompería el ritmo). Se escribe como campo colapsado "Agregar nota" en los sheets de Aportar/Retirar y se lee en el sheet de detalle del movimiento. Si esos dos sitios no existen, la columna se elimina: no se shipea un campo que nadie puede escribir. |

**Sin cambios en `Transactions`.** `goalId` ya existe y es suficiente; el nuevo invariante (`expense` no puede llevar `goalId`) se aplica en el dominio, no en el esquema.
