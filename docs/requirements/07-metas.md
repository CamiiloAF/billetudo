# Feature: Metas de ahorro

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tablas Drift:** `Goals` + tabla de movimientos `GoalContributions` (`lib/core/database/app_database.dart`)

## Contexto

Queja directa contra Wallet: **las metas no se vinculan a cuentas específicas**. Aquí `accountId` es parte del modelo desde el día 1. Las metas alimentan también los retos de ahorro y los hitos celebrados (Fase 3), pero el CRUD base es Nivel 0.

**Filosofía del progreso — el avance es un historial, no un número que se edita.** El progreso de una meta (`savedMinor`) **siempre se deriva** de la suma de sus movimientos en `GoalContributions`; nunca es una columna que la UI sobrescriba. Un aporte "manual" (meta sin cuenta vinculada) y un aporte "real" (transferencia hacia la cuenta vinculada) son la **misma fila** de movimiento — la única diferencia es si esa fila apunta o no a una transacción. Un solo camino de escritura, historial auditable, y el detalle de la meta siempre tiene qué listar.

**Todo aporte nace desde la meta.** El formulario de transacción **no** expone un campo "Meta". Los movimientos se crean desde el detalle de la meta con acciones explícitas ("Aportar" / "Retirar"), por lo que la dirección del movimiento siempre queda declarada por el usuario y nunca se infiere de la dirección de una transferencia.

## Concepto y valor (por qué Metas NO es Deudas)

**Tesis de la feature (norte de todo el diseño):** una meta es un **tablero de aspiraciones con momentum**, no un ledger de obligaciones. Metas y Deudas comparten el mismo esqueleto de ingeniería (ledger derivado, sheets de monto-héroe, pickers, archivado, tombstone) y **deben** compartirlo para que el usuario se sienta en casa. Pero son opuestos emocionales y **no pueden compartir el registro visual ni el encuadre del copy**:

| | Deudas | Metas |
|---|---|---|
| Naturaleza | Obligación | Aspiración |
| Emoción del usuario | Alivio: quiero que **baje** | Deseo: quiero que **suba** |
| Mirada | Hacia atrás (lo que debo) | Hacia adelante (lo que quiero) |
| Tono correcto | Sobrio, administrativo | Cálido, motivador, que **jala** |

Deudas es sobria a propósito: nadie quiere que la app lo entusiasme con una deuda. Metas heredó por error esa sobriedad administrativa (ledger dominando la pantalla, barra fina, icon-wrap gris, header que solo cuenta metas) y por eso se lee como un extracto bancario en vez de como un sueño. Este documento corrige el **concepto**, no el modelo de datos (que se conserva intacto).

**Decisión cerrada: sin imágenes/portadas por meta.** Se evaluó una imagen de portada como canal de identidad (estilo "pots" de Monzo/Qapital) y **se descartó**: las imágenes vivirían solo en local (PowerSync/Supabase no sincroniza binarios hoy), así que al cambiar de teléfono el usuario vería un hueco vacío donde estaba su foto — un desincentivo peor que no haber tenido imagen nunca, justo en el momento de re-enganche. La identidad visual se resuelve con datos que **sí viajan con el sync** (ícono + progreso + copy), sin blobs.

**Cinco principios de diseño que toda pantalla de Metas debe cumplir** (sobreescriben el registro heredado de Deudas donde entren en conflicto):

1. **Identidad por ícono con carácter + arco, no por número.** La emoción no la carga una foto: la cargan un **ícono expresivo** (set curado, más aspiracional que un glifo fino y gris; puro dato, viaja con el sync), el **arco de progreso** y el **copy**. Se mantiene la decisión de HU-01 de no usar color por identidad; el ícono y el arco son los que dan carácter.
2. **Encuadre hacia adelante.** El dato protagonista es **lo que falta y cuándo se llega** ("te faltan $X · a tu ritmo, en marzo"), no el acumulado. "Faltan" y "en N meses" motivan; "llevas $X" solo describe.
3. **El progreso tiene carácter.** El indicador héroe es un **arco/anillo**, no una barra fina (ver reconciliación en HU-01). El arco es el elemento que HU-01 ya invocaba para justificar la paleta sobria; aquí por fin existe.
4. **El payoff se celebra en grande.** Cumplir una meta es el momento de mayor emoción de toda la app. Merece pantalla completa e inversión visual (HU-07), no un sheet modesto.
5. **Momentum sobre conteo.** El resumen es de progreso vivo (racha, próximo hito), nunca un total monetario agregado —prohibido por multi-moneda (HU-15).

Ninguno de estos cinco principios requiere cambios de esquema respecto al modelo ya definido más abajo: el arco, la racha y el próximo hito se **derivan** de `GoalContributions` y de `savedMinor / targetMinor`, igual que el resto del progreso. El costo es de diseño y presentación, no de datos.

## Historias de usuario

### HU-01 — Crear meta de ahorro
Como usuario quiero crear una meta con nombre, monto objetivo y fecha límite opcional, para tener un propósito claro para mi ahorro (ej. "Vacaciones", "Fondo de emergencia").

**Criterios de aceptación:**
- Campos: `name` (obligatorio, 1-100 caracteres), `targetMinor` (obligatorio, centavos, > 0), `currency` (ISO-4217), `targetDate` (opcional), `icon` (opcional), `accountId` (opcional, HU-02).
- `targetDate`, si se indica, debe ser **posterior a hoy** en el momento de crear. Una meta cuya `targetDate` ya pasó no se bloquea ni se marca como fallida (tono positivo): simplemente deja de mostrar proyección de fecha y ofrece "Ajustar la fecha" (ver HU-05).
- El progreso inicia en 0. Si el usuario indica un **avance ya existente** al crear la meta, ese monto se guarda como el **primer movimiento** de `GoalContributions` (tipo `contribution`, sin `transactionId`), no como un valor suelto — así el historial arranca completo desde el día 1.
- No hay límite de metas simultáneas (Nivel 0).
- **Sin color por meta.** Se evaluaron ambas opciones en Pencil (variantes colorida y sobria del mismo layout) y el usuario eligió la **sobria**: el icon-wrap permanece neutro y no hay selector de color en el formulario, solo de ícono. Motivo de diseño: el anillo de progreso ya aporta suficiente carácter y el color por entidad competía con él. Mismo criterio que `Budgets` y `Accounts`.
- **Reconciliación (2026-07-24): el anillo tiene que existir de verdad.** La justificación para quitar el color se apoya en un "anillo de progreso" que **el diseño construido nunca tuvo** — usa una barra fina en lista, detalle y celebración. Sin anillo y sin color, la pantalla se quedó sin ningún canal de carácter, y esa es una de las causas de que se sienta plana. Decisión: el indicador héroe pasa a ser un **arco/anillo de progreso** (principio 3 de "Concepto y valor"), no una barra. Recién entonces la paleta sobria queda justificada. La barra fina puede sobrevivir en piezas secundarias (fila de lista compacta), pero el protagonista del detalle y de la celebración es el arco.
- **La identidad la dan el ícono y el arco, no una imagen.** No hay portada por meta (decisión cerrada en "Concepto y valor"): el canal de identidad es un **ícono expresivo** (set curado, puro dato que viaja con el sync) más el arco. El selector del formulario sigue siendo solo de ícono.
- **El color queda reservado al estado, nunca a la identidad.** El único color con significado en esta pantalla es el de la meta cumplida (familia `income` vía `$income-text`). Regla del sistema: *el color decorativo vive en el ícono; el color del indicador de progreso es semántico* — y aquí, sin color decorativo, el canal semántico queda íntegro para la celebración.

### HU-02 — Vincular meta a una cuenta
Como usuario quiero asociar mi meta a una cuenta específica (ej. mi cuenta de ahorros del banco X), para que el progreso refleje dinero real y no solo un número aspiracional.

**Criterios de aceptación:**
- `accountId` es opcional pero recomendado en el formulario; si se asigna, debe ser una cuenta existente, no eliminada ni con lápida (`tombstonedAt`).
- **La cuenta no define el progreso.** El progreso siempre sale de `GoalContributions`. Tras la revisión 2026-07-24, la cuenta **tampoco decide sola** si un aporte mueve dinero — eso lo decide el toggle "¿Mover dinero de una cuenta?" por aporte (HU-03). La asociación a una cuenta habilita la señal de coherencia (HU-12) y ofrece una cuenta destino por defecto para los aportes que sí mueven dinero.
- Si hay `accountId`, la **moneda de la meta se fija a la moneda de la cuenta** y el selector de moneda queda bloqueado. Cambiar la cuenta por una de otra moneda solo se permite si la meta **no tiene movimientos**; con movimientos, la app lo impide y explica por qué (mezclar monedas invalidaría el histórico).
- Una meta **sin** `accountId` funciona igual, pero sus aportes solo pueden ser de seguimiento puro (toggle en No, HU-03) y no ofrece la señal de coherencia.
- Varias metas pueden apuntar a la **misma cuenta**; eso es válido y esperado (una cuenta de ahorros suele albergar varios propósitos). La sobre-asignación se comunica, no se bloquea (HU-12).
- Si la cuenta vinculada recibe lápida (`tombstonedAt`, HU-08 de Cuentas), la meta **conserva** su histórico y su `accountId`, pasa a comportarse como meta sin cuenta (aportes manuales) y muestra un aviso neutro invitando a vincular otra cuenta.

### HU-03 — Registrar un aporte a la meta
Como usuario quiero registrar un aporte a una meta, moviendo dinero real o marcando un avance manual, para ver crecer mi progreso.

**Criterios de aceptación:**
- El aporte se registra **desde el detalle de la meta** con la acción "Aportar". El formulario de transacción no ofrece un campo "Meta".
- **Toggle "¿Mover dinero de una cuenta?" (mismo patrón que el abono de Deudas), no un binario según haya cuenta vinculada.** Revisión 2026-07-24: el modelo anterior era demasiado rígido (meta *con* cuenta → siempre transferencia; *sin* cuenta → siempre seguimiento). En su lugar, cada aporte declara si mueve dinero o no, **independiente** de si la meta está asociada a una cuenta (la asociación sigue habilitando la coherencia HU-12):
  - **No — seguimiento puro / apartado tipo "cajita":** crea **solo** la fila de `GoalContributions` (`transactionId` nulo). No se crea transacción, no se toca ningún saldo, **no afecta presupuesto ni disponible**. Es el caso de "aparto dentro de una misma cuenta" (bolsillos/cajitas de Nu, donde no hay transacción que registrar) o "solo llevo el número". Este es el caso simple y sin efectos.
  - **Sí — mueve dinero:** crea una **transferencia real** (`type = transfer`, `accountId` = origen, `transferAccountId` = cuenta de la meta) con `goalId`, más la fila de `GoalContributions` (`direction = contribution`) que la referencia. El saldo de ambas cuentas se mueve.
- **Enlazar un movimiento existente (paridad Deudas), en vez de crear un duplicado.** "Aportar" ofrece **enlazar un movimiento que el usuario ya registró** (o que creó un pago programado) y atribuirlo a la meta — no se crea una transacción nueva. Mismo patrón y copy que Deudas: *"Elige un movimiento que ya registraste; lo atribuimos a esta meta, no creamos uno nuevo."* Se cablea sobre `GoalContributions.transactionId` apuntando a la transacción ya existente.
- **Tipos de transacción admitidos con `goalId`:** `transfer` (aporte/retiro real entre cuentas) e `income` (un ingreso que se aparta directo a la meta, ej. un bono). **`expense` con `goalId` sigue prohibido** por invariante: un aporte nunca es un gasto **de tipo**, así que los reportes de gasto no se ensucian con un "gasto fantasma".
- **Impacto en presupuesto — se rige por el flag `countsInBudget` de la transferencia y el alcance por cuenta de los presupuestos, NO por una regla especial de Metas.** (Modelo final del plan de transferencias presupuestables, 2026-07-24: **se descartó el on/off-budget por cuenta** porque competía con el alcance por cuenta que los presupuestos ya tienen vía `BudgetAccounts`.) Reemplaza el antiguo "los aportes nunca consumen presupuesto por construcción":
  - Un aporte de **seguimiento puro** (toggle en No, sin transacción) nunca toca presupuesto ni disponible.
  - Un aporte que **mueve dinero** (transferencia) y se marca como **presupuestable** (`countsInBudget = true` + categoría) entra a los presupuestos según el **alcance por cuenta que cada presupuesto ya tiene** (`BudgetAccounts`): cuenta como **egreso** en cualquier presupuesto cuyo alcance incluya la **cuenta origen** (el "págate primero" que pidió el usuario), y como **ingreso** en cualquiera que incluya la **cuenta destino** (la de la meta). Si ambas cuentas caen en el mismo presupuesto, netea — correcto, ese presupuesto ve los dos lados. Lo decide el flag + el alcance, **no** un atributo de la cuenta ni una regla de Metas.
  - El aporte sigue siendo `transfer` + una **capa de clasificación**, nunca `type = expense`, así que los reportes de gasto quedan limpios (sin doble conteo del saldo, que ya se movió).
  - **Dependencia:** lo provee la **Fase B1** de `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` (`categoryId` + `countsInBudget` en `Transactions`). Metas se **diseña compatible** desde ya (el sheet de Aportar contempla el flag + la categoría, ver abajo) pero el conteo real se cablea cuando esa fase exista. Metas **no debe hard-codear** "nunca toca presupuesto".
- **Categoría en el aporte presupuestable + default "Ahorros".** Cuando el aporte que mueve dinero se marca como **presupuestable** (`countsInBudget`, el mismo toggle de "cuenta en tu presupuesto" del form de transferencia), pide **categoría obligatoria** (regla B-3 del plan), como el abono de Deudas en su rama "Sí". **Por defecto viene preseleccionada la categoría semilla "Ahorros"** (kind `expense`) — **hoy no existe en el catálogo semilla y hay que agregarla** (`category_seeds` en Postgres, ver `02-categorias.md`; no confundir con el *tipo de cuenta* "Ahorros"). Una sola categoría aplica a ambos lados del flag simétrico (egreso en origen, ingreso en destino). Un aporte de **seguimiento puro** no lleva categoría (no hay dónde vivir y no toca presupuesto).
- El monto de un movimiento es **siempre positivo** (centavos); la dirección la da `direction` (`contribution` / `withdrawal`), igual que `Transactions.amountMinor` + `type`.
- `savedMinor` = `SUM(contribution) − SUM(withdrawal)`. Nunca puede quedar negativo, porque el retiro está acotado (HU-04).

### HU-04 — Retirar dinero de la meta
Como usuario quiero poder sacar dinero de una meta si lo necesito, para que la meta refleje la realidad y no me castigue por un imprevisto.

**Criterios de aceptación:**
- "Retirar" es la acción inversa de "Aportar" y crea una fila con `direction = withdrawal`.
- **Mismo toggle "¿Mover dinero de una cuenta?" que Aportar (HU-03)**, simétrico: en **No** solo crea la fila de movimiento (deshacer un apartado/cajita, sin tocar saldos); en **Sí** crea una transferencia desde la cuenta de la meta hacia la cuenta de destino que elija el usuario, con `goalId`. El impacto en presupuesto de un retiro que mueve dinero se rige por el mismo flag `countsInBudget` + alcance por cuenta (HU-03): al invertirse la dirección, la cuenta de la meta pasa a ser el origen y la de destino el que puede recibir ingreso a presupuestar, según el alcance de cada presupuesto.
- El monto del retiro **no puede superar** el `savedMinor` actual. La UI acota el máximo en vez de dejar fallar la validación.
- **Tono:** retirar es una operación normal, nunca un error ni un retroceso señalado. Sin lenguaje de culpa ni iconografía de alerta.
- **Asimetría deliberada entre aportar y retirar.** El tope del retiro es duro porque `savedMinor` es una invariante del modelo. En cambio, **aportar más que el saldo de la cuenta de origen NO se bloquea**: el saldo local es una foto que puede ir por detrás del banco, la app ya admite saldos negativos como hecho normal (tarjetas de crédito), y bloquear un aporte sería la app diciéndole al usuario "no puedes ahorrar eso". Se muestra una línea informativa neutra bajo el campo de cuenta ("Nequi quedaría en −$59.500"), nunca en la familia `$expense` ni con iconografía de alerta.
- **En una meta cumplida, retirar no revierte nada** (HU-07) y el copy del sheet debe decirlo explícitamente. Un texto genérico del tipo "ajustamos el avance" contradice la promesa de la pantalla de meta cumplida justo en el momento de mayor ansiedad: se requieren variantes de copy separadas para meta en curso y meta cumplida.

### HU-05 — Ver progreso y proyección
Como usuario quiero ver una barra de progreso y una proyección de cuándo alcanzaré la meta al ritmo actual de ahorro, para saber si voy bien o necesito ahorrar más.

**Criterios de aceptación:**
- **Encuadre hacia adelante (protagonista de la pantalla).** El dato jerárquicamente dominante del detalle es **lo que falta y cuándo se llega** — "Te faltan $X · a tu ritmo, en marzo" — no el monto acumulado. El acumulado (`savedMinor`) y el objetivo siguen visibles pero como apoyo, no como héroe. Motivo: "faltan" y "en N meses" tiran hacia la meta; "llevas $X" solo describe el pasado. (Principio 2 de "Concepto y valor".) Excepción: la meta cumplida invierte el encuadre y celebra el acumulado (HU-07).
- Progreso = `savedMinor / targetMinor`, mostrado como **arco/anillo** (héroe del detalle, ver HU-01) y porcentaje, acotado visualmente al 100%.
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
- **La celebración es un momento, no un aviso (principio 4).** Los hitos intermedios (25/50/75) son un sheet celebratorio con anticipación real (confeti/animación con peso, no un glifo diminuto), el arco lleno hasta el hito y copy que mira hacia adelante ("¡Vas por la mitad! Te faltan $X"). El 100% escala a **pantalla completa** (HU-07), no un sheet. Todo el efecto es local y gratuito; nunca detrás de anuncio ni pago (Nivel 0).

### HU-07 — Meta cumplida
Como usuario quiero que la app reconozca que cumplí mi meta y que gastar ese dinero después no me borre el logro.

**Criterios de aceptación:**
- Al alcanzar el 100%, la meta se marca con `completedAt` y muestra estado "Cumplida". **No se elimina ni se archiva automáticamente.**
- **El 100% se celebra a pantalla completa (principio 4).** Es el momento de mayor emoción de la app y el cierre del bucle de ahorro: pantalla completa con el arco lleno, animación con peso, el nombre de la meta y el copy de logro permanente ("Este logro ya es tuyo: lo que muevas de aquí en adelante no lo cambia"). Cierra con un CTA hacia adelante — **"¿Qué sigue?"** (archivar esta + crear la próxima) — para encadenar la siguiente meta, no solo un "Listo" que devuelve a una pantalla estática. Aquí el encuadre se invierte respecto a HU-05: se celebra el **acumulado logrado**, no lo que falta.
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

### HU-13 — Primer arranque que invita (empty-state que vende)
Como usuario que abre Metas por primera vez quiero que la pantalla me haga *querer* empezar, no solo avisarme que está vacía, para dar el primer paso sin fricción.

**Criterios de aceptación:**
- El estado vacío (HU-11) es la pantalla más decisiva de la feature: es lo primero que ve alguien que aún no ahorra. **Debe vender el valor y bajar la fricción del primer paso**, no ser un `Empty State` genérico ("Aún no tienes metas" + botón).
- Ofrece **plantillas de arranque** de un toque que pre-rellenan el formulario de crear (HU-01): p. ej. "Fondo de emergencia", "Vacaciones", "Un colchón de 3 meses". Elegir una abre el form ya con nombre e ícono; el usuario solo confirma el monto.
- Cuando haya datos para hacerlo, la plantilla **sugiere un objetivo concreto derivado del propio usuario** — "3 meses de tus gastos ≈ $X" a partir del histórico de gasto. Es una sugerencia editable, nunca un valor impuesto.
- Tono positivo y aspiracional, jamás de culpa por no tener metas (regla transversal). El copy invita ("Elige algo por lo que ahorrar"), no reprocha.
- Las plantillas son **contenido local, sin llamada de red ni IA**; son Nivel 0. No condicionadas a anuncio ni pago.

### HU-14 — Aportar sin fricción (aporte rápido)
Como usuario quiero registrar un aporte en un toque cuando no necesito el detalle completo, para que ahorrar sea tan fácil que lo repita seguido.

**Criterios de aceptación:**
- Además del sheet completo de "Aportar" (HU-03), el detalle ofrece **montos rápidos** de un toque (p. ej. $50.000, $100.000, y "redondeo"/último monto usado) que registran el aporte con la fecha de hoy y la cuenta por defecto de la meta, sin abrir el sheet.
- El aporte rápido crea **exactamente el mismo tipo de fila** que el sheet completo (HU-03): en meta con cuenta, transferencia real + `GoalContributions`; en meta sin cuenta, solo la fila. No es un camino de escritura distinto — solo un atajo de captura. Un solo camino, historial auditable (filosofía del progreso).
- El sheet completo sigue disponible para cuando el usuario quiera fecha, cuenta de origen, o nota distintas de los valores por defecto.
- Menos fricción para aportar es el objetivo explícito: más aportes → más momentum (HU-15) → más celebraciones (HU-06). Sin fricción de red ni pago; Nivel 0.

### HU-15 — Momentum: racha y próximo hito
Como usuario quiero ver que voy avanzando y qué sigue, para sentir impulso y volver a aportar.

**Criterios de aceptación:**
- El resumen de la lista y del detalle es **de progreso vivo, no un conteo frío ni un total monetario**. Reemplaza (o enriquece) el header de conteo actual ("N en curso · M cumplidas").
- Señales de momentum, todas **derivadas** de `GoalContributions` / `savedMinor` (sin cambios de esquema):
  - **Racha de ahorro:** semanas o meses consecutivos con al menos un aporte ("Llevas 6 semanas aportando"). Se rompe con periodos sin aporte; el tono al romperse es neutro e invita a retomar, nunca culpa.
  - **Próximo hito:** el siguiente umbral 25/50/75/100 y cuánto falta para cruzarlo ("Próximo hito: 50% — te faltan $X"). Lee de `lastMilestonePct` (HU-06).
- **Prohibido el total monetario agregado** entre metas (sumaría distintas monedas; regla ya establecida en "Notas de diseño"). El resumen de momentum es no-monetario (racha, conteo, próximo hito) o de una sola moneda declarada.
- Es informativo y motivador, nunca punitivo: una racha corta o rota no se presenta como fracaso.

### HU-16 — Aporte recurrente (pago programado enlazado a la meta)
Como usuario quiero programar un aporte recurrente a mi meta (ej. $1.000.000 cada mes) para no perderlo de vista y tenerlo comprometido, sin registrarlo a mano cada vez.

**Criterios de aceptación:**
- Un aporte recurrente es un **pago programado enlazado a la meta** (`ScheduledPayments` con `goalId`), **mismo patrón que la cuota de Deudas** (pago programado con `debtId`, ver `08-deudas.md` y `09-pagos-programados.md`). No es un mecanismo nuevo: reusa el motor de pagos programados.
- Al configurarlo, el usuario puede **enlazar un pago programado existente o crear uno nuevo** (paridad exacta con Deudas). Enlazar evita duplicar un pago que el usuario ya tenía.
- Cada vez que el pago programado se ejecuta, **crea el aporte automáticamente** (la fila de `GoalContributions` + su transacción según el toggle/on-off-budget de HU-03), sin doble registro.
- El **detalle del pago programado muestra a qué meta está enlazado**: card **"Meta Enlazada"**, análoga a la card "Deuda Enlazada" ya definida en `09-pagos-programados.md`. Editar la plantilla **deep-linkea de vuelta a la meta** (su hogar), como en Deudas.
- Un pago programado enlazado a una meta **reduce el "disponible si aplicas los programados"** (visibilidad del compromiso, protege de gastar de más aun antes de ejecutarse). Su impacto en el presupuesto se rige por on/off-budget como cualquier transferencia (HU-03), no por el hecho de ser recurrente.
- **No aplica** enlazar un mismo pago programado a una deuda **y** a una meta a la vez: son direcciones opuestas (pagar una obligación vs. apartar un ahorro) y se contarían doble. Descartado por decisión del usuario (2026-07-24). El enlace es exclusivo: `debtId` **o** `goalId`, no ambos.

## Reglas de negocio y edge cases

- **`savedMinor` nunca se escribe directamente.** Es una proyección de `GoalContributions`. Cualquier código que intente asignarlo es un bug de arquitectura.
- **Invariante:** ninguna transacción con `type = expense` puede tener `goalId`. Debe validarse en el caso de uso, no solo en la UI.
- **Un aporte nunca es un gasto de tipo** (`expense` con `goalId` prohibido), así que **los reportes de gasto quedan siempre limpios**. Su efecto en el **presupuesto**, en cambio, ya no es "nunca": lo decide el flag `countsInBudget` de la transferencia + el alcance por cuenta de los presupuestos (HU-03) — un aporte que mueve dinero y se marca presupuestable cuenta como egreso en los presupuestos cuyo alcance incluya la cuenta origen (capa de clasificación sobre un `transfer`, sin doble contar el saldo). El seguimiento puro nunca toca presupuesto. Reemplaza la regla anterior de "un aporte no consume presupuesto por construcción".
- Retos de ahorro basados en reglas (52 semanas, redondeo, "no gastar en X") son una capa sobre esta feature, prevista para Fase 3 — el modelo `Goals` + `GoalContributions` la soporta sin cambios de esquema: un reto genera movimientos como cualquier otro origen.
- El tono de toda esta feature debe ser de progreso, nunca de presión o culpa (regla transversal de CLAUDE.md). Aplica especialmente a retiros (HU-04), proyección atrasada (HU-05) y coherencia de cuenta (HU-12).

## Estado del diseño (2026-07-24)

**Revisión de tesis (2026-07-24).** Tras revisar el diseño construido, se concluyó que era un CRUD correcto pero **emocionalmente plano**: un clon del registro visual de Deudas, que es el tono equivocado para una aspiración (ver "Concepto y valor (por qué Metas NO es Deudas)" arriba). El modelo de datos y las reglas se conservan intactos; se reabre solo la **capa de diseño** bajo la tesis nueva: tablero de aspiraciones con momentum, no ledger de obligaciones. Cambios que el rediseño debe incorporar y que la versión construida **no** tiene: arco/anillo como héroe (no barra), encuadre hacia adelante ("faltan · cuándo"), celebración de 100% a pantalla completa, empty-state que vende con plantillas (HU-13), aporte rápido (HU-14) y momentum/racha·próximo hito (HU-15). **Sin imágenes/portadas** (decisión cerrada). Prioridad de mayor retorno: empty-state, hero de lista/detalle y celebración.

**Diseño APROBADO y COMPLETO (claro + oscuro), 2026-07-24.** El rediseño bajo la tesis nueva se construyó, auditó con `ui-ux-reviewer` (sólido, 0 bloqueantes; 4 hallazgos resueltos), y el usuario lo aprobó. Set completo: lista + 6 estados, empty-state, detalle + 10 estados, sheets de Aportar/Retirar con el modelo de aportes revisado (doble toggle), Enlazar movimiento, integración con Pagos (recurrente + "Meta Enlazada"), gestión, formularios (con set de íconos expresivos), archivadas y celebraciones (100% a pantalla completa). Los frames viejos se retiraron. Spec por pantalla con los pares claro/oscuro en **`design-system/billetudo/pages/metas.md`**. Listo para `flutter-dev`. Deuda de sistema abierta: documentar el token nuevo `track` en `MASTER.md` y que `Budget Line` de Presupuestos lo adopte.

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

## Deltas de diseño por la revisión del modelo de aportes (2026-07-24)

La revisión de HU-03/04/16 abre piezas de UI que el diseño en claro ya construido **no** tiene todavía (los sheets de Aportar/Retirar actuales sobreviven en lenguaje de sistema pero con el modelo viejo):

- **Sheet de Aportar/Retirar:** agregar el **toggle "¿Mover dinero de una cuenta?"** (patrón del abono de Deudas `bWezV`), y en la rama "Sí" revelar **selector de categoría** con la semilla **"Ahorros" preseleccionada** (solo cuando el aporte sea presupuestable). El de seguimiento puro no muestra categoría.
- **Flujo "Enlazar un movimiento"** (paridad Deudas `olYUm`/`g0x859`): hoja de aporte con enlace + modo enlazar sobre la lista de movimientos.
- **Config de aporte recurrente** (HU-16): clon del patrón de "Config de cuota" de Deudas (pago programado enlazado), con enlazar-existente/crear-nuevo.
- **Card "Meta Enlazada"** en el detalle del Pago Programado (análoga a "Deuda Enlazada"), definida en `09-pagos-programados.md`.

Nada de esto bloquea el cierre visual de las pantallas de progreso ya aprobadas; son adiciones al set de sheets, a diseñar antes de pasar a `flutter-dev`.

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

**`Transactions`:** `goalId` ya existe y es suficiente para el enlace aporte↔transacción; el invariante (`expense` no puede llevar `goalId`) se aplica en el dominio. El **`categoryId` habilitado + el flag `countsInBudget` en transferencias** (para que un aporte cuente en presupuestos, HU-03) **no los agrega Metas** — los trae la Fase B1 de `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md`. Metas solo los consume.

**`ScheduledPayments` (para el aporte recurrente, HU-16):** agregar `goalId` (`text().nullable().references(Goals, #id)`), **análogo al `debtId` que ya usa la cuota de Deudas**. El enlace es **exclusivo**: una plantilla lleva `debtId` **o** `goalId`, nunca ambos (validado en el dominio). Subir `schemaVersion` y mantener paridad Supabase/PowerSync cuando se implemente HU-16.

**Categoría semilla nueva "Ahorros" (`expense`):** el default del aporte presupuestable (HU-03) requiere una categoría semilla "Ahorros" que **hoy no existe**. Agregarla al catálogo `category_seeds` (Postgres, ver `02-categorias.md`), con `id` estable (ej. `seed-savings`). No es un tipo de cuenta (ese "Ahorros" ya existe y es otra cosa).
