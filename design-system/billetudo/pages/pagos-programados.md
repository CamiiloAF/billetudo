# Página: Pagos programados

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`. Requisitos: `docs/requirements/09-pagos-programados.md`.

**Estado:** ✅ **cerrada en diseño — ambos temas (claro + oscuro), auditada de punta a punta.** Lista (con datos/vacío/carga/error), hoja de confirmación (6 variantes con Confirmar/Posponer/Omitir), formulario + companion `once` (con etiquetas), detalle híbrido (+ `once` histórico + transfer), menús "⋮", sheet de Posponer y sheet de confirmar-eliminar. Cada pieza pasó por diseño → auditoría de `ui-ux-reviewer` → aprobación explícita del usuario; paridad claro↔oscuro y contraste AA verificados. **Lista para `flutter-dev`** — la deuda que queda (más abajo) es de implementación, no de diseño.

## Frames

| Pantalla / pieza | Node ID (Claro) |
|---|---|
| Lista — con pendientes | `o0twiq` |
| Lista — sin pendientes | `t6UXUo` |
| Subpantalla "Por confirmar" (desbordamiento) | `QkLV0` |
| Hoja de confirmación — normal (monto colapsado) | `YpMV7` |
| Hoja de confirmación — monto en edición (keypad) | `irJZw` |
| Hoja de confirmación — ×3 acumuladas | `K5lXU` |
| Hoja de confirmación — ingreso | `EJAvD` |
| Hoja de confirmación — transferencia | `woFWS` |
| Hoja de confirmación — revisión guiada | `rOb6U` |
| Formulario — crear/editar (repetible) | `J0DSIm` |
| Formulario — pago único (`once`) | `jJhpW` |
| Detalle — híbrido (repetible activo) | `OY2Kj` |
| Detalle — `once` histórico | `Eyold` |
| Detalle — transferencia | `XmaSX` |
| Detalle — menú "⋮" (recurrente/transfer) | `yHf9k` |
| Detalle — menú "⋮" (`once`, sin Posponer) | `nLkvf` |
| Sheet — Posponer (nueva fecha) | `dQUMj` |
| Notas de decisiones para `flutter-dev` | `StBxL` (lista) · `XWSrD` (formulario) |

**Tema oscuro:** cada frame de arriba tiene su gemelo oscuro en la banda **"PAGOS PROGRAMADOS — OSCURO"** (etiqueta `j9f1r5`, `y:43420+`), separada debajo del claro. Generados con `theme:{mode:"dark"}` — recoloreo 100% por tokens, cero hex. Paridad y contraste AA en oscuro verificados por `ui-ux-reviewer`.

**Componentes reutilizables:**
- `Scheduled Card/B — Tarjeta` (`tit0W`) — plantilla activa en la lista principal.
- `Scheduled Pending Row/B2 — Compacta` (`QhuIP`) — ocurrencia pendiente. Su `context` lleva la regla de truncado; **léelo antes de tocarla**.

## Navegación

Pantalla **apilada**: `Page Header` (atrás) + **sin `Tab Bar`** (se llega desde Más → Pagos programados). Crear = **FAB**. La subpantalla "Por confirmar" también es apilada, con scroll real (`ListView`); la lista **no** tiene scroll interno anidado.

## Arriba ocurrencias, abajo plantillas (regla crítica)

La sección "Por confirmar" lista **ocurrencias**; la lista principal lista **plantillas activas**. Una plantilla con ocurrencia pendiente **no se repite abajo**: mientras está pendiente, `nextDate` no ha avanzado (solo avanza al confirmar u omitir), así que aparecer en ambos lados sería mostrar la misma fecha dos veces.

El chip **"Activos · N" cuenta todas** las plantillas activas, incluidas las que tienen pendiente arriba. En el mockup: 8 activas = 6 con pendiente arriba + 2 tarjetas abajo. Es coherente, no un bug. **"Activos · N" no es un badge de notificación** — cuenta plantillas, no pendientes.

## Zona de pendientes — regla de tope (solo en la lista)

- Máximo **4 filas** (`QhuIP`), ordenadas por `nextDate` ascendente (la más vencida primero).
- Si N>4: 4 filas + **fila de desbordamiento de 44px al pie, dentro del borde**: iconos de categoría de los que sobran + "Ver los otros N pendientes" (`$primary-on-soft-strong` 13/700) + `chevron-right` → subpantalla "Por confirmar".
- Alto duro **~275px, constante para todo N≥5**. Garantiza **≥2 tarjetas de programados futuros siempre visibles**: la pantalla no puede degradarse a una bandeja de pendientes.
- El contador del header de sección muestra **N total**, no las visibles.

### Cadena de dependencia del alto (no romper)

```
truncado con ellipsis → fila de 52px fijos → tope de ~275px → ≥2 tarjetas visibles
```

- `Sub` y `Name` de la fila: `maxLines: 1` + `TextOverflow.ellipsis` dentro de `Expanded`. **No deben envolver.**
- Verificado en canvas: con nombres de cuenta reales del sistema ("Bancolombia Ahorros · Salario") + monto ancho ("+$3.200.000"), el `Sub` envuelve a 2 líneas y **desborda** los 52px, chocando con el divisor. Pencil no renderiza ellipsis, así que el mockup usa cadenas que caben — **el truncado es lo que sostiene el alto fijo en producción**.
- La **fecha vive en la columna derecha**, bajo el monto, **no** en el `Sub`: así el `Sub` no compite por ancho con el monto, y las fechas alinean en columna (la pantalla está ordenada por `nextDate`).
- **`snapshot_layout` no detecta este desbordamiento** (reporta "No layout problems" con el bug presente). Verificar **siempre** por screenshot de fila con contenido largo real.

## Una sola densidad (decisión, no omisión)

La fila mide **52px en la lista y en la subpantalla**. Se evaluó darle más alto en la subpantalla —donde el tope no rige— y **se descartó**: mismo contenido + misma tarea (triar) = misma densidad; dos alturas del mismo row para el mismo dato es una diferencia perceptible sin pago funcional. El espacio que sobra en la subpantalla con N=5-8 es inherente y aceptable: el CTA se ancló abajo (zona de pulgar) en vez de inflar filas para rellenar.

## Confirmar nunca es a ciegas (HU-03)

- Tap en una fila → **vista de verificación/edición** (`date`/`accountId`/`amountMinor` precargados). **No existe aceptar-tal-cual** de un toque desde la lista.
- **"Revisar todas"** (link del header de sección en la lista + CTA de la subpantalla) **no aplica N de un golpe**: abre **revisión guiada secuencial** — misma hoja, progreso "1 de 6", "Confirmar y siguiente" / "Omitir" / "Salir".
- **Misma acción = misma etiqueta** a propósito en los dos puntos de entrada. La ambigüedad se resolvió por **icono, no por texto**:
  - `chevron-right` = **navegar** (fila de desbordamiento).
  - `list-checks` = **empezar la revisión** ("Revisar todas").
  Antes ambos usaban chevron y el link se leía como navegación.
- **Omitir no existe inline en la lista**: vive en la hoja. Acelerador opcional por swipe, siempre reversible con `Snackbar` "Deshacer" (`zSTlU`).

## Bordes: por qué difieren a propósito

| Zona | Borde | Porqué |
|---|---|---|
| Pendientes en la lista (`eswQN`) | `$primary` / 1.5 | Tiene que distinguirse de las tarjetas `tit0W` que conviven abajo. Hay contraste real que crear. |
| Pendientes en la subpantalla (`iEAww`) | `$border` / 1 | Ahí **toda** la pantalla es pendientes: un borde morado no separaría de nada y degradaría el acento de marca a decoración ambiental (misma lógica que "el rojo es señal con significado" en `presupuestos.md`). |

## Copy y tono

- Caption **"Aún no afectan tu saldo"** bajo el header de sección: es *la* regla de HU-03 que el usuario necesita saber.
- **Se quitó "venció"** de las filas: dentro de una sección "Por confirmar", bajo un caption que ya lo explica, toda fila está vencida por definición. No aportaba, empujaba el wrap, y repetido 6 veces arrastraba el tono hacia bandeja de cobro. La fecha desnuda ("30 jul") es igual de informativa y más neutral.
- **Cero `$expense`.** Violeta de marca para el estado pendiente, nunca alarma. El rojo sigue reservado al sobregasto real de Presupuestos.

## Casos cubiertos en el canvas

- **Ocurrencias acumuladas de la misma plantilla:** chip "×3" en la fila (11px/700 — es la única fuente de ese dato, no es decorativo).
- **Varias plantillas distintas con pendiente:** regla de tope + desbordamiento.
- **0 pendientes:** la zona **no se renderiza** — sin banner, sin sección, sin andamiaje vacío, sin contador en cero (`t6UXUo`).
- **`income`** (+$3.200.000 en `$income-text`) y **`transfer`** ("Bancolombia → Fondo viaje") representados, no solo `expense`.
- El sub de un `transfer` **sí** lleva "origen → destino": es el dato de cuenta que pide HU-04, no redundancia. Parecía duplicado solo porque el mockup llamaba a la plantilla "Ahorro a Fondo de viaje"; se renombró a **"Ahorro mensual"** — el nombre lo escribe el usuario (`note`, opcional) y puede no mencionar el destino.
- **`frequency = once`** ("pago único" + icono `calendar-check`) vs. repetibles ("cada mes" + icono `repeat`).

## Hoja de confirmación (HU-03)

Es un **bottom sheet**, no una pantalla apilada — se eligió a propósito: el caso común (`YpMV7`, ~330px, confirmar tal cual o solo mirar) es genuinamente ligero, y la hoja solo crece cuando de verdad editas (divulgación progresiva). Una confirmación que *parece* un formulario se pospone, y los pendientes se acumulan — el fracaso que esta pantalla existe para evitar.

- **Monto anclado abajo** (`ofg07` colapsada / `Rslzk` expandida): tap en el monto **expande el keypad en sitio**, dentro del mismo sheet — NO abre un sheet sobre el sheet. Vocabulario de icono honesto: `chevron-down` en Monto = expande aquí; `chevron-right` en Fecha/Cuenta = abre selector (`zMqxt`/`fcVZN`). El keypad queda en zona de pulgar (~627px); se descartó un sheet dedicado de teclado (taparía justo lo que confirmas).
- **Head = la plantilla:** icono + nombre + "categoría · frecuencia" + **lápiz** (ir a editar la plantilla, HU-05). **Toda la fila del head es tocable** (44pt), el lápiz es solo afordancia. El lápiz distingue "editar la plantilla" del `chevron-right` de las filas ("editar este campo de la ocurrencia"). **En modo guiado el lápiz NO aparece** (tocarlo abortaría la revisión).
- **Scope Note:** "Lo que edites aplica solo a este pago. La plantilla sigue igual y el próximo mes vuelve a proponer $X." Es lo único que el usuario no puede deducir mirando. **Omitida cuando `frequency = once`** (no hay plantilla futura que aclarar).
- **No hay bloque "de la plantilla"** (Tipo/Categoría/Nota en solo-lectura): se quitó. Tipo es redundante (el monto ya lo dice por signo/color), la categoría subió al head, la nota deja de informar tras leerla una vez.
- **Ocurrencias acumuladas (×2+):** franja de contexto "Tienes N pagos de X sin confirmar / Ahora confirmas el más antiguo, del [fecha]. Las otras N siguen en tu lista." Con **×1 NO se renderiza** (la fila Fecha ya lo dice). Confirmar una ocurrencia **cierra y vuelve a la lista** (que muestra ×N−1), no encadena in-sheet; para vaciar la cola de corrido está "Revisar todas" (revisión guiada secuencial).
- **Tres acciones:** **Confirmar** (primario, full-width, abajo, zona de pulgar) + fila secundaria **[Posponer | Omitir]** (dos `Button/Secondary` outline). Arreglo **local** — no se modificó el `Sheet Buttons Row` (`Ot4yI`) compartido. Guiada: Posponer + "Confirmar y siguiente" + Omitir + Salir (link arriba-derecha, fuera de la zona de acciones).
- **Tipos:** `expense`; `income` (monto en `$income-text` con `+`, head con categoría de ingreso); `transfer` (dos filas Cuenta origen/destino, head sin categoría, "Monto a transferir"; **sin swap** — es conveniencia de creación, no de confirmación).

## Formulario crear/editar (HU-01, HU-05)

Variante ganadora: **V3 adaptada**. El **mismo** formulario para crear (desde el FAB de la lista) y editar (desde el lápiz de la hoja / el "⋮" del detalle). Reusa el formulario de Transacciones.

- **Orden:** Segmented (tipo) → Cuenta(s) → Categoría → **Frecuencia** → **Repetir cada** → **Primer pago** → **Termina** → **Modo de registro** → Nota → **Etiquetas** → (Eliminar, solo modo editar).
- **Disclosure condicional de la frecuencia** (el diferenciador): `once` **oculta** Interval Row y Termina, y "Primer pago" → **"Fecha del pago"**. El formulario se encoge, no muestra campos muertos (`jJhpW`).
- **Frecuencia = chips de unidad** (Único / Día / Semana / Mes / Año), no adjetivos. **Stepper solo-número** ("Repetir cada [− 2 +]") — la unidad la da el chip, no se repite.
- **Modo automático/manual = dos tarjetas radio con explicación** ("Modo Block (radio)", injertado desde la variante V1 al elegir V3), no switch ni segmentado. Muestra las dos consecuencias a la vez (HU-03): "Automático · se registra solo" / "Manual · te avisamos antes de afectar tu saldo". Se descartaron el switch (escondía manual como "apagado") y el segmentado (solo muestra el modo activo).
- **La frase en lenguaje natural NO va aquí** — redundante con los controles (que ya son la fuente de verdad) y cara de mantener (gramática es-CO, riesgo de desincronía). Vive solo en el detalle.
- **Monto anclado abajo**; **Delete Link** (`u0THG`) al fondo del scroll en modo editar.

## Detalle (HU-05)

**Híbrido A+C**: responde dos trabajos que conviven — *cuándo cae el próximo pago y de cuánto* + *verificar la config* antes de editar/eliminar.

- **Hero "Próximo pago"** (`OY2Kj`): "PRÓXIMO PAGO" + pill "en N días" / fecha grande / **monto** / **frase en lenguaje natural** de sub-línea ("Se repite cada mes desde el 13 de julio, para siempre"). Esta es la **única superficie** donde vive la frase (solo-lectura, sin controles que la dupliquen).
- **Ficha** (`Info Row`): **Modo · Cuenta · Estado · Etiquetas**. No repite Monto (en el hero) ni una fila de Frecuencia (la frase ya la da). Categoría en el subtítulo del identity strip.
- **Acciones en el menú "⋮" del header**, no en fila anclada (pedido del usuario, para dar espacio al histórico): **Posponer este pago** (acción de la *ocurrencia*) → **divisor** → **Editar** → **Eliminar** (acciones de la *plantilla*). El divisor separa los dos grupos conceptuales.
- **Histórico:** transacciones generadas (`source = scheduled`), **3 filas + "Ver historial completo (N)"** que **expande la lista in-place** (cargar más), **no navega** — mismo patrón que Presupuestos. Cada fila sí enlaza a su transacción.
- **Etiquetas:** `Tag Chip` (`nM9ea`) con la "x" desactivada (solo-lectura). Label a **`$primary-on-soft-strong`** por override local (AA — ver deuda global abajo).
- **Casos borde (frames propios, no anotaciones):**
  - **`once` histórico** (`Eyold`): hero invertido — "PAGO EJECUTADO" (sin pill, fecha pasada, icono `calendar-check`), frase "Una sola vez el [fecha]", ficha **Estado: Terminada**, histórico de 1 fila, y su menú "⋮" (`nLkvf`) **sin Posponer**.
  - **`transfer`** (`XmaSX`): sin categoría ni bloque Etiquetas, fila de cuenta "origen → destino" con **wrap forzado a 2 líneas** (el `Value` de `Info Row` es `auto` y desbordaría con nombres reales — `snapshot_layout` es ciego a esto).

## Posponer (HU-07)

Snooze de una ocurrencia: moverla a una fecha posterior **sin registrarla ni saltarla**. Tercera vía junto a Confirmar (registra) y Omitir (descarta).

- Vive en **dos puntos**: 3ra acción de la hoja de confirmación (ocurrencia manual vencida) y el "⋮" del detalle (próximo pago auto/manual). **No** en el `once` histórico (no hay futuro).
- Abre el **sheet de nueva fecha** (`dQUMj`): reusa `Month Calendar` (`w4yuu`) + `Bottom Sheet Base`, con contexto ("X · vencía el [fecha] · muévelo hacia adelante") y título "Elige la nueva fecha".
- **Todo el pasado hasta el piso `max(fecha original, hoy)` se atenúa en bloque continuo** (`opacity 0.35`), no solo la fecha original — para una ocurrencia vencida el piso es **hoy**, no la fecha original (posponer al pasado sería incoherente). El bloque continuo se lee como la convención universal de "fechas pasadas deshabilitadas".
- **Reversible:** tras posponer, `Snackbar` "Pago movido al [fecha] · Deshacer" (`zSTlU`).
- La **cadencia de la plantilla no se altera** (solo esa ocurrencia); el modelo de datos (override de fecha por ocurrencia vs. tabla de excepciones) se resuelve en implementación.

## Etiquetas

- N:N vía tabla puente nueva **`ScheduledPaymentTags`** (gemela de `TransactionTags`, reusa la tabla `Tags`). **Requiere cambio de esquema** (`schemaVersion` → 11).
- En el **formulario**: sección tras Nota, `Tag Chip` editable (con "x") + chip **"+ Etiqueta"** (outline). **No aplica a `type = transfer`** (paridad con Transacciones).
- **Heredadas** por la transacción generada (copia en el momento de generar, no vínculo vivo — HU-02): editar las etiquetas de la plantilla no reescribe las de transacciones ya generadas.

## Deuda técnica / notas para `flutter-dev`

- **Deuda AA global de `nM9ea` (Tag Chip):** su label por defecto usa `$primary-on-soft` sobre `$primary-soft` (~4.17:1, **falla AA**). Se corrigió por **override local** a `$primary-on-soft-strong` en las instancias de esta feature (detalle + formulario); el componente global sigue con el token débil porque es compartido con Transacciones (feature cerrada / código implementado, no se quiso crear drift). **Limpieza transversal pendiente** aparte.
- **Tap targets** de "+ Etiqueta" y de la "x" del `Tag Chip` (36px/12px): padear el área tocable a **44pt** en Flutter (mismo fix ya aplicado a `AI Question Chip`).
- **Cambio de esquema `ScheduledPaymentTags`** + herencia de etiquetas al generar (HU-02) — vía `/drift-schema-change`.
- **Enforcement del date picker de Posponer:** deshabilitar dinámicamente todo día ≤ `max(fecha original, hoy)`; abrir el calendario en el mes de la primera fecha seleccionable (no en el de la fecha original) por si el piso cae a fin de mes.

## Trampas de herramienta (aprendidas en este diseño)

- **`snapshot_layout` es ciego** al desbordamiento de texto en filas de alto fijo. Verificar por screenshot con contenido largo real.
- **Mover un nodo dentro de un componente descarta en silencio los overrides de sus instancias.** Tras tocar la estructura de un componente, revisar todas las instancias.
- Probar con **contenido real y largo** ("Bancolombia Ahorros", montos de 7 cifras), no con cadenas convenientes: un mockup que solo cabe con texto corto esconde el bug.

## Pendiente

**De diseño:** nada — la feature está cerrada en ambos temas.

- **Puente desde un gasto con fecha futura** (HU-06): vive en la presentación de **Transacciones** (la app pregunta "¿Es un pago programado?" al guardar con fecha futura), no es una pantalla propia de esta feature — se diseña/implementa desde allá.
- La deuda de **implementación** (`flutter-dev`) está en "Deuda técnica" arriba: esquema `ScheduledPaymentTags`, tap targets del `Tag Chip` a 44pt, AA global de `nM9ea`, y el enforcement del date picker de Posponer.
