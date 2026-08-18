# Página: Minitutoriales (ayuda contextual por feature)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado: diseño cerrado, claro + oscuro, auditado por `ui-ux-reviewer` en ambos temas.** Listo para `flutter-dev`. Requisitos en `docs/requirements/fase-1/16-minitutoriales.md`.

## Tema oscuro

Copias 1:1 vía `Copy(...,{theme:{mode:'dark'}})`, sin overrides manuales de color, auditadas sin hallazgos (cero hex hardcodeado, fidelidad estructural exacta, ícono `⋮` a 20px consistente, sin overflow/clipping nuevo).

**HU-01:** `H0eSz6`→`swNUR` (Presupuestos), `cn6bt`→`FymG2` (Metas), `v1ol5`→`LTt5a` (Deudas), `fxKYb`→`vaaqR` (Pagos programados).

**HU-02:** `TPEgi`→`s6IFj8`, `d9Urm0`→`ZHzhI`, `pkMHa`→`UiTri`, `v4RWSm`→`VOU3m`, `kNH0I`→`R8SxE`, `xUQIp`→`zQ0rp`, `qObeL`→`nkwUi`. El demo `uTvJ2` no se copió a oscuro (superado por la sincronización real en `cOcbC`, sin valor de producción).

**HU-03 (menús `⋮` completos, oscuro):** `c9tyn1`→`V46Bbp` (Metas), `lTUQr`→`LftRt` (Deudas), `Q2GpD`→`AdVCt` (Pagos programados). Más las ediciones directas dentro de frames de producción oscuros ya aprobados: `cOcbC`/nodo `yW2GM` (fila "Ver ayuda" en Presupuestos), `zQj6Z`/nodo `D75jj` (botón `⋮` en Metas), `fXBWg` (header de Deudas reconstruido con el patrón Left Group + spacer, igual que el claro), `L3GvO`/nodo `O0DU5` (botón `⋮` en Pagos programados).

**HU-04 (Ajustes, oscuro):** `TQHmY`/nodo `JHldK` (con sesión), `j4JYF`/nodo `XQekD` (sin sesión) — misma fila "Mostrar ayuda" insertada en los frames de producción oscuros ya aprobados.

**Deuda técnica preexistente detectada durante la auditoría (no atribuible a este trabajo, no bloqueante):** `fXBWg` y `rPgbX` (Deudas, claro) comparten un clipping de lista ya existente antes de este cambio; `TQHmY`/`j4JYF` y sus gemelos claros comparten un clipping de "SH Link" (elemento `enabled:false`) también preexistente. Queda para quien audite Deudas/Ajustes por separado.

## HU-03 — Reapertura vía menú `⋮` (cerrado, claro + oscuro)

Presupuestos ya tenía `⋮` en su pantalla principal; Metas, Deudas y Pagos programados no — se les agregó, cambio de estructura sobre pantallas de producción ya cerradas de esas 3 features (documentado también en sus respectivos `pages/<feature>.md` si aplica).

| Pantalla | Header | Botón `⋮` | Menú "Ver ayuda" |
|---|---|---|---|
| Presupuestos | `TmOGV` (ya existía) | `HqZOy` | `TmOGV` → fila `wjeGO` |
| Metas | `sNItj` | `kwIRq` (nuevo, orden `⋮ → Archive → +`) | `c9tyn1` → fila `ZncCT` |
| Deudas | `REKRV` (`Page Header`) | `hhqFE` (nuevo) | `lTUQr` → fila `Gu5fX` |
| Pagos programados | `c196T3` | `MANKK` (reemplazó un `Action Spacer` vacío) | `Q2GpD` → fila `xINsA` |

**Componente `Action Ver ayuda`** (`z4xpk`, `reusable:true`): icon-wrap 38px `$muted` + `circle-help` 19px + Label fijo "Ver ayuda" + Sub por instancia. Reemplazó las 4 filas construidas a mano (no se tocó el demo `uTvJ2`, que puede quedar como referencia o actualizarse después sin urgencia).

**Decisión de layout — Deudas necesitó un patrón nuevo:** `Page Header` con 2 acciones a la derecha (`⋮` + `+`) rompe el spacer simple de 44×44 ya documentado para "un lado sin acción" — hace falta espejar el grupo completo. Documentado como precedente reutilizable en `MASTER.md`, sección "Page Header" ("Left Group + spacer invisible").

**Ícono `⋮` unificado a 20px** en los 4 botones (Deudas y Pagos programados heredaban 18px del componente base `Page Header`, corregido por override de instancia sin propagar al componente).

**Pendiente de sincronizar (no bloqueante, fuera de este cierre):** la fila "Ver ayuda" del menú de Presupuestos falta en su gemelo oscuro (`cOcbC`) y en la variante "modo activo" (`tFZyK`) — se agrega en la pasada de tema oscuro.

## Tesis (norte del diseño)

**Hoja explicativa de concepto, no checklist de acciones.** La decisión de forma (bottom sheet reabrible, no coach marks) ya estaba cerrada en el propio requerimiento (16-minitutoriales.md, "Forma", 2026-07-27); lo que se diseñó acá es el layout y — más importante — el tono del copy: cada punto explica **qué es** algo de la app (qué es un presupuesto, qué es el modo sobres), no una instrucción de "hazlo así". La primera redacción probada listaba acciones imperativas ("Elige el periodo", "Prueba el modo sobres") y se descartó por no ser lo que HU-01 pide explicar.

De 3 variantes de layout evaluadas (icono centrado + lista con íconos, header editorial + tarjeta numerada, icono grande + botones asimétricos) se eligió la **de header editorial + tarjeta numerada**: es la única de las tres que no recorta el CTA largo ("Crear mi primer presupuesto") — las otras dos rompían con textos de esa longitud, que varios de los 11 tutoriales del alcance total van a necesitar.

## Frames

Todos en tema Claro por ahora (oscuro pendiente). Ubicados en su propio clúster del canvas, junto al de Gate Cuenta.

| Pieza | Descripción | nodeId |
|---|---|---|
| Tutorial — Presupuestos | Patrón base. "Así funcionan los presupuestos": qué es un presupuesto por período, alcance por cuenta/categoría, modo sobres | `H0eSz6` |
| Punto de inserción de reapertura | Demo del menú `⋮` de Presupuestos con la fila nueva "Ver ayuda" | `uTvJ2` |
| Tutorial — Metas | "Así funcionan las metas": para qué sirve, cómo se arma el avance, tipo de aporte | `cn6bt` |
| Tutorial — Deudas | "Así funcionan las deudas": para qué sirve, quién calcula el saldo, tipo de abono | `v1ol5` |
| Tutorial — Pagos programados | "Así funcionan los pagos programados": para qué sirven, automático vs. manual, bandeja de vencimientos | `fxKYb` |

### Copy final (HU-01)

**Presupuestos** (`H0eSz6`) — título "Así funcionan los presupuestos"
1. Un presupuesto por período — "Defines un monto para gastar en un período (semanal, quincenal, mensual o solo por esta vez) y ves cuánto te queda mientras avanza."
2. Con el alcance que tú eliges — "Puede cubrir todo tu gasto, o enfocarse solo en una cuenta o categoría en particular."
3. El modo sobres, para más control — "Reparte todo tu ingreso entre tus categorías, para que cada peso ya tenga un destino desde el inicio."
CTA: "Crear mi primer presupuesto" / "Entendido"

**Metas** (`cn6bt`) — título "Así funcionan las metas"
1. Para qué sirve una meta — "Úsala para ahorrar para algo puntual, como un viaje, un fondo de emergencia o un regalo, y ver tu avance en cualquier momento."
2. El avance se arma con tus aportes — "Cada vez que registras un aporte, tu progreso sube. No es un número que tú edites: es la suma de lo que has ido aportando."
3. Un aporte puede mover dinero, o no — "Puedes aportar moviendo dinero real de una cuenta, o solo dejarlo anotado sin tocar tu saldo (útil si ya guardaste ese dinero en otro lado)."
CTA: "Crear mi primera meta" / "Entendido"

**Deudas** (`v1ol5`) — título "Así funcionan las deudas"
1. Para qué sirve una deuda — "Lleva el control del dinero que debes (a un banco, una tarjeta o una persona) o que te deben a ti, sin tener que hacer cuentas a mano."
2. Tú registras, la app calcula — "Anotas lo que pediste prestado, lo que has abonado y los intereses que se suman, y la app calcula sola cuánto falta por pagar."
3. Un abono puede mover dinero, o no — "Puedes descontar un abono de una de tus cuentas, o solo anotarlo sin mover dinero (útil si alguien más pagó por ti, o si fue en efectivo)."
CTA: "Registrar mi primera deuda" / "Entendido"

**Pagos programados** (`fxKYb`) — título "Así funcionan los pagos programados"
1. Para qué sirven — "Sirven para no olvidar pagos que se repiten, como el arriendo, una suscripción o una cuota, y dejar que la app los registre por ti si quieres."
2. Automático o manual — "Uno automático se registra solo en su fecha. Uno manual te avisa y tú confirmas antes de que cuente (útil si el monto cambia cada vez)."
3. La bandeja de vencimientos — "Ahí ves todos tus pagos pendientes en un solo lugar y los confirmas cuando te llegan."
CTA: "Programar mi primer pago" / "Entendido"

### Patrón de sub-flujo (HU-02)

Mismo componente base (`Bottom Sheet Base`, misma `Points Card` con viñeta) que HU-01, pero:
- **Nunca lleva CTA de navegación adicional — solo "Entendido".** Regla cerrada tras la auditoría de `ui-ux-reviewer`: como HU-02 no bloquea el formulario y el usuario permanece exactamente donde estaba, no hay un "destino" al que navegar tras cerrar el minitutorial (a diferencia de HU-01, donde el CTA primario sí lleva a la acción real de la feature). Aplica a los 5 sub-flujos restantes — no se evalúa caso por caso.
- **"Entendido" usa `Button/Primary` sin el ícono check, no `Button/Secondary`.** Corrección tras feedback del usuario ("se pierde"): un botón secundario/outline está pensado para competir junto a un primario, no para ser la única salida de la hoja. Al ser la única acción, merece tratamiento de acción principal — mismo criterio que ya usa "No se Puede Eliminar" (`Yc1U2`/`sruRv`) para su botón único de cierre, **incluido desactivar su ícono check** (`ui-ux-reviewer` encontró que el primer intento lo dejó visible, leyéndose como "confirmar/aplicar" en vez de "cerrar" — más delicado en `d9Urm0`, donde podía sugerir que el botón aplicaba la elección Sí/No del toggle en vez de solo cerrar la explicación).
- **1-2 puntos**, no 3 — contenido más corto, consistente con "se muestra en medio de una acción, no bloquea".
- **Regla general del sistema, no solo de esta feature:** "Entendido" tiene dos tratamientos válidos según el contexto — link de texto plano cuando compite con un CTA primario al lado (HU-01), o `Button/Primary` sin ícono cuando es la única acción de la hoja (HU-02, `Yc1U2`). No es inconsistencia, es la misma lógica (de-enfatizar cuando compite, enfatizar cuando es la única salida) aplicada a dos contextos distintos — documentado acá para que no se reinvente ni se rompa por accidente al construir los 5 sub-flujos restantes.

Los 7 sub-flujos de la tabla de HU-02 están completos:

| Sub-flujo | Título | Ícono | nodeId |
|---|---|---|---|
| Enlazar movimiento a deuda | "Enlazar un movimiento existente" | `link` | `TPEgi` |
| Enlazar movimiento a meta | "Enlazar un movimiento existente" | `link` | `pkMHa` |
| Toggle abono de deuda | "¿Agregar el abono a una cuenta?" | `toggle-right` | `d9Urm0` |
| Toggle aporte a meta | "¿Mover dinero de una cuenta?" | `toggle-right` | `v4RWSm` |
| Cuota programada de deuda | "La cuota vive en Pagos programados" | `calendar-clock` | `kNH0I` |
| Transferencia presupuestable | "¿Contar esta transferencia en tu presupuesto?" | `clipboard-list` | `xUQIp` |
| Modo sobres / zero-based | "Así funciona el modo sobres" | `layout-grid` | `qObeL` |

**Copy final:**

**Enlazar un movimiento existente** (`TPEgi` deuda / `pkMHa` meta — mismo copy verbatim en ambos, por diseño: "mismo patrón, misma explicación" del requerimiento)
1. No crea un movimiento nuevo — "Atribuye uno que ya registraste, para no duplicar."
"Entendido"

**¿Agregar el abono a una cuenta?** (`d9Urm0`)
1. Si eliges "Sí" — "El abono también descuenta el monto de la cuenta que elijas, como una transacción real."
2. Si eliges "No" — "La deuda baja igual, pero no se toca ningún saldo (útil si pagaste en efectivo o alguien más pagó por ti)."
"Entendido"

**¿Mover dinero de una cuenta?** (`v4RWSm`)
1. Si eliges "Sí" — "El aporte descuenta el monto real de una cuenta, como una transferencia."
2. Si eliges "No" — "El aporte solo queda anotado en la meta, sin tocar ningún saldo (útil si ya guardaste ese dinero en otro lado)."
"Entendido"

**La cuota vive en Pagos programados** (`kNH0I`)
1. Se configura aquí, se confirma allá — "La configuras desde esta deuda, pero se confirma desde la bandeja de Pagos programados, como cualquier otro pago."
2. Un solo movimiento, dos efectos — "Al confirmarla, un solo movimiento baja el saldo de tu cuenta y abona a la deuda al mismo tiempo."
"Entendido"

**¿Contar esta transferencia en tu presupuesto?** (`xUQIp`)
1. Para qué sirve marcarla — "Algunas transferencias sí son parte de tu plan de gasto, aunque no sean un gasto real (por ejemplo, mover dinero a la cuenta que usas para gastar en el mes)."
2. Qué cambia al marcarla — "Se resta de tu presupuesto igual que un gasto, aunque el dinero siga siendo tuyo, solo que en otra cuenta."
"Entendido"

**Así funciona el modo sobres** (`qObeL`)
1. Para qué sirve — "Reparte todo tu ingreso entre tus categorías, para que cada peso ya tenga un destino desde el inicio."
2. Qué cambia en la pantalla — "En vez de un solo monto libre, ves cuánto le queda a cada categoría por separado."
"Entendido"

**Variantes descartadas** durante la elección del patrón (borradas del canvas): V1 (estructura completa + CTA "Buscar movimiento" + "Entendido" como link) y V3 (compacta, sin tarjeta envolvente, texto directo bajo el header) — se eligió la estructura completa con tarjeta (misma identidad visual que HU-01) sin CTA de acción por defecto.

**Criterio de íconos fijado tras auditoría de `ui-ux-reviewer`:** dos sub-flujos con mismo título/copy comparten ícono (`link` en ambos casos de "enlazar movimiento"); los toggles usan un ícono que representa el **control de UI** (`toggle-right`), no la acción semántica que dispara — se corrigió `v4RWSm` de `arrow-left-right` a `toggle-right` para unificar con `d9Urm0` bajo este criterio; un ícono no debe competir con el de otro tutorial ya usado en la misma feature salvo guiño intencional y defendible (`kNH0I` comparte `calendar-clock` con el tutorial principal de Pagos Programados a propósito, porque la cuota literalmente vive ahí); se evitan íconos que fuera de su contexto puntual se leen como algo distinto (se descartó `mail` para modo sobres por asociarse a correo/notificaciones en cualquier otro uso, aunque dibuje un sobre).

## Componentes reutilizados

Construida sobre `Bottom Sheet Base` (`PqTUt`), `Button/Primary` (`j7Zvt`) y `Button/Secondary` (`pNjOz`). El patrón de tarjeta con viñetas se componentizó como **`Points Card`** (`WuP5d`, envolvente: `$surface`, `cornerRadius:16`, `stroke:$border`, padding 16) + **`Point Row`** (`dP46y`, unidad repetible: badge circular `•` en `$primary-soft`/`$primary-on-soft-strong` + heading 14/700 + body 13/500, con divisor inferior que se desactiva en la última fila de cada tarjeta) — mismo mecanismo de slot reemplazable que ya usa `Bottom Sheet Base` para su `Content Slot`, soporta de 1 a 3 puntos según la tarjeta. Reemplazó las 11 instancias construidas a mano sin cambio visual (verificado por comparación de capturas antes/después).

## Decisiones cerradas durante el diseño (no repetir la discusión)

- **Header editorial + tarjeta con viñetas sobre icono centrado + lista con íconos.** Las otras dos variantes se borraron del canvas al aprobar, según higiene estándar de Pencil. Motivo objetivo, no solo preferencia: con el CTA real más largo del set de contenido, las descartadas truncaban el botón primario.
- **Copy conceptual, no instructivo.** Cambio explícito pedido tras la primera pasada: los puntos explican qué es cada concepto en vez de listar acciones a tomar. El título de cada tutorial pasó de un eslogan a una frase que anuncia que esto es una explicación ("Así funcionan los presupuestos/las metas/las deudas/los pagos programados").
- **Viñetas (`•`) en vez de números (1/2/3).** Hallazgo de `ui-ux-reviewer`: el badge numerado justo encima del CTA primario se leía como "pasos a completar en orden", contradiciendo la tesis del diseño de que los puntos son datos independientes sobre el mismo concepto, no una secuencia. Se corrigió cambiando solo el glifo del badge, sin tocar el resto del layout.
- **Punto 1 = "para qué sirve", siempre.** Segunda vuelta de copy pedida explícitamente por el usuario: el primer punto de cada tutorial debe explicar el beneficio/uso cotidiano concreto antes de explicar el mecanismo interno — el público objetivo nunca ha usado la app y no tiene vocabulario financiero previo. Se descartó jerga técnica del primer intento de Metas/Deudas/Pagos programados (`ledger`, "registro de eventos", "se deriva", "cadencia") por lenguaje simple y cotidiano. Presupuestos (redactado en la primera vuelta) ya cumplía este criterio y no necesitó reescritura.
- **Puntuación de incisos: paréntesis, nunca guiones.** Preferencia explícita del usuario, aplicada de forma consistente en las 4 pantallas — se coló dos veces en rondas de copy nuevas antes de quedar fija; cualquier copy nuevo de esta feature (los 7 tutoriales de sub-flujo) debe seguir el mismo criterio desde el primer intento.
- **Desviación del criterio de aceptación de HU-03 del requerimiento — sin "?" dedicado en el header.** `docs/requirements/fase-1/16-minitutoriales.md` HU-03 pedía un ícono "?" siempre visible en el header de cada pantalla del alcance de HU-01. Se descartó por saturar un header que ya tiene `⋮` y `+`. **Decisión de producto tomada en esta sesión de diseño:** la reapertura vive como una fila más ("Ver ayuda") dentro del menú `⋮` que ya existe en cada pantalla, en vez de un ícono propio. La hoja se sigue abriendo sola en el primer acceso (eso no cambió); solo cambia el mecanismo de reapertura manual. **Pendiente:** esto todavía no se reflejó en los frames de producción de Presupuestos (`TmOGV`/`cOcbC`, ya aprobados/cerrados) — solo existe en el demo `uTvJ2`. Falta decidir si se actualiza el menú real de Presupuestos ahora o cuando se cablee esta feature en Flutter, y aplicar el mismo patrón de fila al `⋮` de Metas, Deudas y Pagos programados cuando se aterricen sus tutoriales.

## Pendiente / fuera de alcance de Pencil

- **Los 7 tutoriales de sub-flujo** (HU-02) — no explorados todavía. El requerimiento pide el mismo componente con contenido más corto (1-2 puntos, quizá sin acción primaria fuerte); falta validar que el layout elegido se vea bien en esa versión reducida antes de darlo por cerrado para todo el alcance. Al redactar su copy, seguir desde el primer intento los criterios ya fijados arriba (punto 1 = para qué sirve, lenguaje sin jerga, paréntesis nunca guiones).
- **Actualizar el menú `⋮` real de Presupuestos** con la fila "Ver ayuda" (hoy solo existe en el demo) y replicar el mismo patrón en el `⋮` de Metas/Deudas/Pagos programados.
- **Ajuste "Mostrar ayuda al entrar a una sección"** de HU-04 (Ajustes) — no tiene pantalla propia diseñada todavía.
- **Tema oscuro:** no se construye hasta que el claro quede 100% cerrado para todo el alcance (los 11 tutoriales + el ajuste de Ajustes).
