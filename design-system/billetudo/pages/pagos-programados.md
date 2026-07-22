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
| Sheet — confirmar eliminar | `tED4D` |
| Lista — vacía (0 plantillas) | `YI1wY` |
| Lista — vacía (0 activas, con terminadas) | `U9jUDR` |
| Lista — carga (skeletons) | `QE1Wq` |
| Lista — error | `KeKke` |
| Lista — filtro Terminados (con datos) | `LmrIV` |
| Lista — filtro Terminados, carga | `gD9g7` |
| Lista — filtro Terminados, error | `w3MUo` |
| Notas de decisiones para `flutter-dev` | `StBxL` (lista) · `XWSrD` (formulario) |

**Sin frame (estados de runtime, no requieren diseño):** carga/vacío/error de la subpantalla "Por confirmar", carga/fallo del detalle, y los estados "guardando" de la hoja de confirmación y del sheet de Posponer.

**Sin frame y pendiente de diseñar:** el detalle de una plantilla con lápida (`inactive`), hoy tratado como estado de runtime; y "Volver a programar" desde una plantilla terminada (nota `qPQAD` en el canvas, mejora futura no dibujada).

## Terminados: filtro en sitio, no pantalla aparte

Los chips **"Activos · N" / "Terminados · N"** son un par de pills que **filtran la misma lista**; no navegan. Se diseñó así tras una auditoría: el vocabulario de pill con estado seleccionado ya promete filtro, y la implementación original empujaba una pantalla apilada con back y **sin** la fila de chips — el usuario no podía predecir el toque y, una vez dentro, no tenía forma de volver a "Activos" salvo el back. `LmrIV` es por eso hermano de `o0twiq`/`t6UXUo`: mismo chrome, misma `Tab Bar`, mismo FAB, solo cambia el área de contenido.

- **El chip "Terminados · N" se oculta con N = 0** (no deshabilitado). Por eso **no existe un frame de "filtro Terminados vacío"**: no hay chip que tocar. El caso borde —quedarse sin terminadas estando dentro del filtro— se resuelve con el fallback de estado descrito más abajo.
- **El FAB se queda en el filtro:** crear un pago programado es acción de la pantalla, no del filtro; ocultarlo haría saltar el chrome al alternar chips.
- **La tarjeta terminada es la misma `tit0W`, con la misma geometría que la activa** (monto arriba, en el `Top`). Solo cambia el eje inferior: donde la activa lleva el chip de cadencia va un chip **"Terminada" + `check-circle`** en `$muted`/`$text-secondary`, y la meta dice **"Último pago · 15 mar 2026"**. Dos reglas detrás de eso: (a) **no atenuar la tarjeta** — son históricos navegables, no elementos deshabilitados, y el gris leería como castigo; (b) la meta va **etiquetada** porque ocupa el mismo slot donde la activa dice "en 3 días" (próximo pago), y para una repetible que alcanzó su `endDate` el último pago y la fecha de fin **no son la misma fecha**. Se soltó el contador relativo ("hace 48 días"), que crece para siempre y a 400+ días no informa.
- **Tap en tarjeta terminada → detalle** (`Eyold`). El `InkWell` cubre la tarjeta completa.
- **Selección del chip: fondo `-soft` + borde `$primary-on-soft-strong` 1.5 `inner`.** El borde **no es decorativo, es el único diferenciador real**: `$primary-soft` y `$muted` tienen el mismo valor en cada tema (`#EEECFB` claro, `#26243B` oscuro), así que sin él las dos cajas son idénticas y el estado se cifra solo en el color del label — WCAG 1.4.1. Y el borde **no puede ser `$primary` crudo**: sobre `$muted` en oscuro da 2.75:1, por debajo del 3:1 de WCAG 1.4.11. `$primary-on-soft-strong` da 6.04:1 claro / 5.52:1 oscuro. `strokeAlignment: inner` para no inflar el tap target de 44px.
- **La fila de chips se renderiza cuando los contadores ya son conocidos.** Por eso `gD9g7`/`w3MUo` (carga/error *del filtro*) sí la llevan —llegaste tocando el chip, quitarla te dejaría sin salida— y `QE1Wq`/`KeKke` (carga/error *inicial*) no. Es divergencia deliberada. **Pero la carga inicial sí reserva el alto de la fila** con un placeholder de dos pills en `$skeleton` sin labels (`QE1Wq`→`c2RuB`, `VcbSV`→`XHnuP`): sin eso, la fila de 44px + gap 16 aparece de golpe al resolver y empuja el contenido ~60px, lo que se lee como glitch. `KeKke` no lo lleva — es estado terminal, no hay resolución que empuje nada.
- **Carga: `min(N, 5)` skeletons**, no 5 fijos. Si el contador del chip ya es conocido (que es la razón por la que la fila se muestra), pintar 5 cuando el chip dice 3 hace que la pantalla encoja al resolver.
- **Dos vacíos distintos, y su copy debe diferir.** `YI1wY` es el vacío total (0 plantillas): no lleva chips —con 0 plantillas no hay nada que filtrar— y dice "Aún no tienes pagos programados". `U9jUDR` es "0 activas + N terminadas": **sí** lleva chips (son el único camino al histórico) y dice **"Por ahora no tienes pagos programados activos"** + subtítulo *"Tus N pagos terminados siguen disponibles en «Terminados»"*. Reusar el "Aún no" de `YI1wY` sería copy de primer uso para alguien que **sí tuvo** pagos programados: le borra el historial, en contra del tono de progreso.
- **El fallback a "Activos" es una condición de estado, no de navegación.** Cuando N llega a 0 —sea cual sea la causa— el filtro cae a Activos. Con PowerSync la lista es un stream: N puede llegar a 0 por sync de otro dispositivo sin que haya ningún evento de retorno, así que el fallback cuelga de la emisión del stream, no de un callback de pop.
- La fila de chips es el componente reutilizable **`Scheduled Filter Chips` (`qPSvV`)**; en código va como widget propio, no inline en cada estado.

**Tema oscuro:** cada frame de arriba tiene su gemelo oscuro en la banda **"PAGOS PROGRAMADOS — OSCURO"** (etiqueta `j9f1r5`, `y:43420+`), separada debajo del claro. Generados con `theme:{mode:"dark"}` — recoloreo 100% por tokens, cero hex. Paridad y contraste AA en oscuro verificados por `ui-ux-reviewer`.

**Componentes reutilizables:**
- `Scheduled Card/B — Tarjeta` (`tit0W`) — plantilla en la lista principal, **activa o terminada** (ver "Terminados: filtro en sitio" más abajo: misma geometría, solo cambia el eje inferior).
  - **Se removió el chip de recordatorio "Te avisamos"** (ícono de campana) del componente: el feature todavía no permite configurar cuándo recordar ni tiene notificaciones push, así que el chip prometía algo no cumplible. Se reintroducirá con **HU-08 (Fase 2)** de `docs/requirements/09-pagos-programados.md` (config de timing del recordatorio: día del pago / 1 día antes / 3 días antes / una semana antes). **No confundir** con el copy del modo manual "te avisamos antes de afectar tu saldo" (ver "Formulario crear/editar"), que describe un comportamiento in-app real y NO se tocó.
- `Scheduled Filter Chips` (`qPSvV`) — la fila "Activos · N / Terminados · N". Filtra en sitio; **no navega**.
- `Scheduled Pending Row/B2 — Compacta` (`QhuIP`) — ocurrencia pendiente. Su `context` lleva la regla de truncado; **léelo antes de tocarla**.

## Geometría del `Content` (valores del `.pen`, no deducibles del texto)

| Estado | `Content.padding` | `Content.gap` | `Lista.gap` |
|---|---|---|---|
| Lista con datos (`o0twiq`, `t6UXUo`, filtro `LmrIV`) | `[6, 20, 92, 20]` | 16 | 10 |
| Lista en carga (`QE1Wq`) y carga del filtro (`gD9g7`) | `[6, 20, 92, 20]` | 16 | 10 |
| Error del filtro (`w3MUo`) y vacío "0 activas" (`U9jUDR`) | `[6, 20, 92, 20]` | 16 | — |
| Error inicial (`KeKke`) y vacío total (`YI1wY`) | `[6, 20, 20, 20]` | — | — |

**El `92` de abajo no es espaciado: es el colchón del FAB**, que va en `layoutPosition: absolute` en `x:306 y:888` sobre un frame de 972. Es una **dependencia entre dos nodos** — con menos, la última tarjeta de una lista larga queda tapada por el FAB. Es un bug funcional, no cosmético, y no se detecta leyendo el `.md`: hay un test de regresión que verifica que el borde inferior de la última tarjeta no cruce el borde superior del FAB.

**Los dos estados terminales (`KeKke`, `YI1wY`) llevan `20` en vez de `92` a propósito**: no tienen chips ni contenido vivo debajo, así que no hay nada que el FAB pueda tapar. No los uniformes con los demás — la divergencia es deliberada.

Todos los estados comparten estos valores **para que ninguno mueva el contenido al transicionar a otro**: si el skeleton y la lista cargada difieren, la pantalla salta al resolver y el placeholder de chips pierde su razón de ser.

## Navegación

Pantalla **apilada**: `Page Header` (atrás) + **sin `Tab Bar`** (se llega desde Más → Pagos programados). Crear = **FAB**. La subpantalla "Por confirmar" también es apilada, con scroll real (`ListView`); la lista **no** tiene scroll interno anidado.

**Los chips Activos/Terminados NO navegan** — filtran en sitio (ver "Terminados: filtro en sitio" arriba). La única navegación desde la lista es: fila de desbordamiento → "Por confirmar", tarjeta → detalle, FAB → formulario.

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

- **Monto anclado abajo** (`ofg07` colapsada / `Rslzk` expandida): tap en el monto **expande el keypad en sitio**, dentro del mismo sheet — NO abre un sheet sobre el sheet. Vocabulario de icono honesto: el Monto usa **`chevron-up` colapsado** (afordancia de "se abre hacia arriba", verificado en `ofg07`/`YpMV7`) y `chevron-down` expandido (colapsar) = expande aquí; `chevron-right` en Fecha/Cuenta = abre selector (`zMqxt`/`fcVZN`). El keypad queda en zona de pulgar (~627px); se descartó un sheet dedicado de teclado (taparía justo lo que confirmas).
- **Head = la plantilla:** icono + nombre + "categoría · frecuencia" + **lápiz** (ir a editar la plantilla, HU-05). **Toda la fila del head es tocable** (44pt), el lápiz es solo afordancia. El lápiz distingue "editar la plantilla" del `chevron-right` de las filas ("editar este campo de la ocurrencia"). **En modo guiado el lápiz NO aparece** (tocarlo abortaría la revisión).
- **Scope Note — ELIMINADA (decisión del usuario).** La franja "Lo que edites aplica solo a este pago…" ya no existe en el diseño: generaba ruido visual y el alcance "solo este pago" se entiende por el contexto del propio sheet de confirmación. No reintroducirla.
- **No hay bloque "de la plantilla"** (Tipo/Categoría/Nota en solo-lectura): se quitó. Tipo es redundante (el monto ya lo dice por signo/color), la categoría subió al head, la nota deja de informar tras leerla una vez.
- **Ocurrencias acumuladas (×2+):** franja de contexto "Tienes N pagos de X sin confirmar / Ahora confirmas el más antiguo, del [fecha]. Las otras N siguen en tu lista." Con **×1 NO se renderiza** (la fila Fecha ya lo dice). Confirmar una ocurrencia **cierra y vuelve a la lista** (que muestra ×N−1), no encadena in-sheet; para vaciar la cola de corrido está "Revisar todas" (revisión guiada secuencial).
- **Tres acciones:** **Confirmar** (primario, full-width, abajo, zona de pulgar) + fila secundaria **[Posponer | Omitir]** (dos `Button/Secondary` outline). Arreglo **local** — no se modificó el `Sheet Buttons Row` (`Ot4yI`) compartido. Guiada: Posponer + "Confirmar y siguiente" + Omitir + Salir (link arriba-derecha, fuera de la zona de acciones).
- **Tipos:** `expense`; `income` (monto en `$income-text` con `+`, head con categoría de ingreso); `transfer` (dos filas Cuenta origen/destino, head sin categoría, "Monto a transferir"; **sin swap** — es conveniencia de creación, no de confirmación).
- **Token del ingreso:** el icon tile del head de `EJAvD` usa **`$mint-soft`**. No existe `$income-soft` en el `.pen` — el par suave del verde es `mint-soft`. No lo inventes en `AppColors`.

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
- **CTA "Confirmar ahora"** (`Ht24a` dentro del hero real `Tk3V8`/`OY2Kj` — nodos `Rl1Ws` ícono, `nqSdQ` label; decidido sobre la copia de mockup `gnC6J`/`T6Wn7k`, que queda solo como referencia histórica de la elección): resuelve el punto 1 de `docs/bugfixes.md` — hasta ahora solo se podía confirmar/registrar un pago automático cuando ya estaba vencido (`dateIsDueOn`, ver "Deuda técnica" abajo); este botón permite hacerlo **antes** de `nextDate`, adelantándose. Franja de ancho completo pegada al fondo del hero, debajo de la frase de sub-línea, `fill:$primary-soft`, `cornerRadius:14`, ícono `zap` + label "Confirmar ahora" en `$primary-on-soft-strong` (`Qws7K`/`KwYrT`). Se descartaron `check-circle`/`circle-check-big` (ya significan "Terminada"/pago ejecutado en esta misma feature) y `calendar-check` (ya significa "pago único", `once`) — `zap` no colisiona con ningún ícono existente en el `.pen` y comunica "ahora, sin esperar" en vez de "completado". Solo visible cuando el pago es automático y aún no está vencido (si ya está vencido, el hero completo ya es tappable por el mecanismo existente — el CTA no debe duplicarse con eso). Al tocarlo, abre el mismo `ConfirmationSheet` (`YpMV7`) que el resto de los flujos de confirmación — reusa el caso de uso existente, no un flujo nuevo.
  - **Tema oscuro (producción):** el CTA vive en el frame real `tlGsU` ("PP Detalle — Híbrido (Oscuro)", par de `OY2Kj`/`Ssl97`), no solo en la variante de mockup `gnC6J`. Insertado como último hijo del hero real `i5VmS`, pegado al fondo igual que en claro. Nodos: contenedor `rdGS5` (`fill:$primary-soft`, `cornerRadius:14`, `padding:[13,16]`), ícono `zap` `SdWEi` (`fill:$primary-on-soft-strong`, 18×18), label "Confirmar ahora" `X34Uj8` (`fill:$primary-on-soft-strong`, 14/700). Mismos tokens que en claro — recoloreo automático, contraste ya verificado (5.52:1 en oscuro, documentado más abajo para este par de tokens).
- **Ficha** (`Info Row`): **Modo · Cuenta · Estado · Etiquetas**. No repite Monto (en el hero) ni una fila de Frecuencia (la frase ya la da). Categoría en el subtítulo del identity strip.
- **Acciones en el menú "⋮" del header**, no en fila anclada (pedido del usuario, para dar espacio al histórico): **Posponer este pago** (acción de la *ocurrencia*) → **divisor** → **Editar** → **Eliminar** (acciones de la *plantilla*). El divisor separa los dos grupos conceptuales.
- **Histórico → "Historial" con omitidos** (variante A aprobada; claro `PatSn`/`QbY9P`, oscuro `mar1S`): ya no es solo "generados". Es un **historial de eventos** de la plantilla, **intercalado cronológicamente** (más reciente arriba): pagos **confirmados** (transacción `source = scheduled`, fila `Transaction Row` `DKJaf`, enlaza a su transacción) y pagos **omitidos** (ocurrencia `skipped`, que **no** genera transacción). **3 filas + "Ver historial completo (N)"** in-place, mismo patrón/densidad que Presupuestos.
  - **Fila de omitido — componente reutilizable `Skipped Entry Row` (`GPlOy`)**, geometría propia (no duplica `DKJaf`): icon-wrap `$muted` 44×44 con **`calendar-x`** `$text-secondary`; nombre `$text-primary` 15/600; sub = **badge neutral "Omitido"** (`$muted` + label `$text-primary` 11/700) + fecha `$text-secondary`; a la derecha **monto tachado** (`$text-secondary` 15/700 con `TextDecoration.lineThrough`) + link **"Recuperar"** (`$primary-on-soft-strong` 12/700). Señal de "omitido" **redundante** (icono + badge + tachado), **nunca `$expense`/rojo** — no punitivo (regla de tono de marca). Contraste AA verificado en claro y oscuro.
    - **Tachado:** el nodo `m8O6Ha` lleva `strikethrough:true`, pero **Pencil no lo serializa ni lo dibuja** (limitación conocida, igual que `ellipsis`) — se ve plano en el `.pen`/goldens de Pencil; en Flutter va `TextDecoration.lineThrough` y sí se renderiza. No declararlo faltante.
  - **Recuperar (Fase 2):** tocar "Recuperar" es una **acción directa reversible** (no abre sheet de confirmación) que devuelve el pago a **pendiente por confirmar** (`undoSkipOccurrence`, ya existe) + **Snackbar "Pago recuperado"** con acción **"Deshacer"** (re-omite) — mismo patrón que Posponer/Omitir. Diseñado: estado "al recuperar" (claro `V0j9k`, oscuro `j6KXP`; la fila recuperada desaparece del Historial) + snackbar (instancia de `zSTlU`, `ztokz`).
  - **Nota para `flutter-dev`:** el tap target de "Recuperar" (12/700, ~15×61px) **no llega a 44pt** — padear el área tocable a 44pt (mismo criterio que `Tag Chip`/`AI Question Chip`). Datos: el historial combina transacciones confirmadas + ocurrencias `skipped` ordenadas por fecha desc (paginación sobre ambas fuentes).
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
- ~~**Enforcement del date picker de Posponer**~~ — **resuelto** (2026-07-19): el piso `max(fecha original, hoy) + 1 día` se aplica en `SnoozeSheetCubit`, el pasado queda atenuado en bloque continuo y el calendario abre en el mes de la primera fecha seleccionable. Verificado contra `dQUMj` por `pencil-fidelity-reviewer`.
- ~~**CTA "Posponer" al pie del sheet `dQUMj`**~~ — **resuelto** (2026-07-19): **se queda** y ya está dibujado en ambos temas (`WBbrs` claro / `M9QWa` oscuro), `Button/Primary` full-width con `alarm-clock`. Razón: en el resto de la app el `Date Picker Sheet` llena un campo y la escritura la confirma el "Guardar" de la pantalla; aquí no hay nada después, así que sin el botón un solo tap en el calendario ejecuta una escritura real. Sin "Cancelar" al lado: el scrim y el handle ya son escotillas, y posponer es reversible por Snackbar.
- ~~**Signo de los gastos**~~ — **resuelto** (2026-07-19), **revertido** (2026-07-20): la resolución del 19 (gasto sin signo, solo el ingreso con `+`) duró un día — el usuario pidió explícitamente volver a mostrar el `-` en el gasto en **todos** los listados (Movimientos, Inicio), no solo en Cuentas. El código quedó con signo en gasto e ingreso (`transactionAmountLabel`, `lib/features/transactions/presentation/utils/transaction_amount_presentation.dart`, compartido entre `TransactionRow` y `RecentActivityRow`). Esto **diverge del `.pen`** (que sigue mostrando el gasto sin signo) — pendiente que `pencil-designer` actualice el `.pen` para que vuelva a coincidir, o que se documente ahí la excepción si se decide mantenerla solo en código.
- **Signo del monto en pagos programados:** `-` gasto / `+` ingreso / neutral transferencia **solo en las filas de lista** (tarjeta de "Activos", fila de "Por confirmar"). En los **displays prominentes** —hero del detalle y hoja de confirmación ("Amount to record")— el gasto va **sin signo** (el ingreso mantiene `+`), por decisión del usuario: ahí el tipo ya está etiquetado y el `-` sería peso redundante. No unificar sin pedirlo.
- **Feedback silencioso al Recuperar/Deshacer un omitido (pendiente):** si `recoverSkipped` (`undoSkipOccurrence`) o el "Deshacer" (`skipOccurrence`) fallan, hoy **no** se muestra aviso al usuario — el error sí se reporta al `CrashReporter` (dev: consola; prod: Sentry) desde el data layer, pero el cubit del detalle **no emite `failure`** a propósito: reusaría el copy de "Confirmar ahora" (engañoso) y no se creó una clave l10n propia. Si se quiere feedback visible ante fallo, hace falta un **string nuevo** (es/en) y emitir el `failure` en `ScheduledPaymentDetailCubit.recoverSkipped`/`undoRecover`. Decisión de producto pendiente.

## Limitaciones conocidas de los datos de mockup

Los frames son maquetas, no una base de datos: sus datos son coherentes **dentro de cada pantalla** y entre las pantallas de una misma plantilla, pero no forman un dataset global consistente. Al leerlos como especificación, ten esto presente:

- **El "hoy" implícito varía entre plantillas.** Está unificado por plantilla (todas las pantallas de "Ahorro mensual" asumen hoy = 9 ago 2026, forzado por las tarjetas hermanas de su misma lista), pero no en todo el canvas. Perseguir un "hoy" global es trabajo sin retorno y se rompe con cualquier edición futura.
- **La ocurrencia pendiente de "Ahorro mensual" cae el 1 ago, pero su serie está anclada al día 13** (13 may / 13 jun / 13 jul generados). Es una ocurrencia vencida coherente con la zona "Por confirmar", pero no pertenece a la serie mensual. Alinearla exigiría reordenar filas en la zona de pendientes y chocaría con el 13 jul ya listado como generado — se dejó a propósito.
- Los nombres de cuenta se acortan en filas compactas ("Fondo viaje") frente al detalle ("Fondo de viaje familiar"). Es **intencional**: el mockup usa cadenas cortas donde en producción hay ellipsis. No son dos cuentas distintas.

Regla general: si un dato del mockup contradice una regla de `docs/requirements/09-pagos-programados.md`, **manda el requisito**. Los datos de maqueta existen para mostrar la forma, no para definir el comportamiento.

## Trampas de herramienta (aprendidas en este diseño)

- **`snapshot_layout` es ciego** al desbordamiento de texto en filas de alto fijo. Verificar por screenshot con contenido largo real.
- **Mover un nodo dentro de un componente descarta en silencio los overrides de sus instancias.** Tras tocar la estructura de un componente, revisar todas las instancias.
- Probar con **contenido real y largo** ("Bancolombia Ahorros", montos de 7 cifras), no con cadenas convenientes: un mockup que solo cabe con texto corto esconde el bug.

## Pendiente

**De diseño:** nada — la feature está cerrada en ambos temas.

- **Puente desde un gasto con fecha futura** (HU-06): vive en la presentación de **Transacciones** (la app pregunta "¿Es un pago programado?" al guardar con fecha futura), no es una pantalla propia de esta feature — se diseña/implementa desde allá.
- La deuda de **implementación** (`flutter-dev`) está en "Deuda técnica" arriba: esquema `ScheduledPaymentTags`, tap targets del `Tag Chip` a 44pt, AA global de `nM9ea`, y el enforcement del date picker de Posponer.
