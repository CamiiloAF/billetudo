# Página: Asistente con IA

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`, zona `JLbGS` — "Zona — ASISTENTE IA (Claro+Oscuro)".

**Estado:** cerrado y aprobado en claro y oscuro para el chat/historial base (2026-08-26). **Reportar un mensaje** (menú + hoja de motivo): claro aprobado (2026-09-02), oscuro construido y pendiente de aprobación explícita del usuario — ver sección "Reportar un mensaje". Claro (chat/historial base): exploración (3 variantes), tres rondas de auditoría de `ui-ux-reviewer` (base: 2 hallazgos IMPORTANTE corregidos; estados nuevos del chat: 2 hallazgos IMPORTANTE corregidos, incluido un bug real de Pencil sin máscara de recorte). Oscuro (chat/historial base): generado por `Copy()`+`theme:{mode:"dark"}` sobre las 16 piezas del claro, auditado con contraste re-medido de forma independiente (no solo confiado al informe del diseñador) — aprobado sin hallazgos. Requisitos en `docs/requirements/fase-4/21-asistente-ia.md`.

Entra desde el `AI Banner` de Inicio (`h5dN1`, existente, solo cambia su copy) y desde un tile nuevo en "Más". El bloque `AI Assistant` (`cwxZI`, orbe+chips) que hoy vive en la hoja de "próximamente" queda pendiente de decisión — ver "Pendientes" abajo.

## Tesis (norte del diseño)

El asistente **propone, nunca ejecuta**. Cada acción con dinero real (crear presupuesto, meta, categoría, registrar movimiento) pasa por una tarjeta que el usuario confirma con un toque explícito — nada se escribe en la cuenta sin eso. La identidad visual es un orbe (`sparkles` sobre gradiente `$primary`→`$primary-deep`) que se repite junto a cada respuesta del asistente: es un chat con presencia de marca, no una interfaz genérica de texto plano.

El tono es el de todo billetudo: positivo, nunca punitivo. El asistente no regaña un gasto ni trata un descarte del usuario como un error — por eso el estado "Descartada" de la tarjeta de propuesta es visualmente discreto a propósito (ver "AI Proposal Card" abajo), no una alarma.

El aviso legal ("Beta" + "No es asesoría financiera") es un **requisito legal, no decorativo**: vive fuera del área scrolleable, fijo, visible en todo momento de la conversación.

## Frames

Claro y oscuro construidos, cada pieza oscura es `Copy()`+`theme:{mode:"dark"}` de su contraparte clara (mismo contenido/estructura, solo recolorea). Todas las piezas viven en `JLbGS`.

### Pantallas
| Pantalla | nodeId (Claro) | nodeId (Oscuro) | Notas |
|---|---|---|
| Chat — base (input vacío) | `ueaIi` | `Gk56I` | Header con 2 acciones (`Right Group`): historial (`history`) + nueva conversación (`plus`). Beta+disclaimer en barra fija bajo el header. Composer con ícono Send (ajustado por el usuario tras la primera pasada), `opacity:0.4` mientras el input está vacío. |
| Chat — vacío (primera conversación, sin mensajes) | `p3tJFm` | `hx3IY` | Composición: `Orb` 48×48 protagonista (gradiente `$primary`→`$primary-deep`, `sparkles`) + Title + Subtitle centrados + 4 instancias de `AI Question Chip` (`tMqvn`) en grid. Título "¿Por dónde empezamos?", subtítulo "Elige una pregunta o escríbeme lo que necesites." Beta+disclaimer y Composer se mantienen fijos igual que en el resto del chat (no son parte de este estado, son chrome compartido). Aprobado (2026-08-26) por el usuario y por `ui-ux-reviewer`; único hallazgo (Title/Subtitle con `fontFamily:"Inter"` hardcodeado en vez de `$font-body`) corregido. |
| Chat — pensando | `M2oLsq` | `PinsS` | Burbuja de respuesta con 3 puntos neutros (`$text-secondary`, 7px) en vez de texto, mismo Orb. Sin precedente de "escribiendo…" en el sistema — patrón nuevo, aprobado. Send Button en `opacity:0.4` (input vuelve a estar vacío tras enviar). Contraste `$text-secondary`/`$surface` oscuro: 5.88:1. |
| Chat — error de red | `V7gvu` | `NyU3T` | Burbuja con `triangle-alert` + "No pude responder" en `$expense-text`, cuerpo "Inténtalo de nuevo. Tus datos siguen a salvo en tu dispositivo.", link "Reintentar" en `$primary` (44px de alto, no destructivo). Send Button en `opacity:0.4`. Contraste `$expense-text`/`$surface` oscuro: 5.93:1. |
| Chat — composer con texto (teclado abierto) | `hAZza` | `T8Khkw` | Input con texto real, Send Button en `opacity:1` (habilitado). Placeholder de teclado del sistema comprime la conversación; solo se muestra la última respuesta (con la tarjeta de propuesta) — Pencil no tiene máscara de recorte, así que los mensajes que no caben se **omiten del mockup** en vez de quedar pintados por debajo de Composer/Teclado sin recortar (bug real detectado y corregido, no el "scroll intencional" que se reportó en una pasada anterior). En Flutter esto es simplemente una lista scrolleable con clip real. |
| Historial de conversaciones — lista | `EGwSs` | `Y2XcWc` | Header simple: back + "Borrar todo" (`trash-2`, `$expense-text`). |
| Historial — estado vacío | `Si9o8` | `RVEIW` | Reusa `jmQO5` (Empty State), CTA "Nueva conversación". |
| Historial — estado cargando | `bDdyA` | `YENqW` | Skeletons `rVldq` (Conversation Skeleton Row), 5 instancias. |
| Historial — estado de error | `JZVFV` | `aKzNa` | Reusa `ECG7D` (Error State) tal cual. |
| Sheet — confirmar eliminar una conversación | `uPidu` | `BvBE8` | `Bottom Sheet Base` (`PqTUt`) + `Sheet Icon Header` (`XPjIZ`) + `Sheet Buttons Row` (`Ot4yI`). Mismo patrón que `oymM5` (Cuentas — Confirmar Eliminar). |
| Sheet — confirmar eliminar todo el historial | `fvmUI` | `i2Qz3G` | Mismo patrón que arriba, copy ajustado a "todas tus conversaciones". |

### Componentes reutilizables nuevos
| Componente | nodeId (Claro) | nodeId (Oscuro) | Notas |
|---|---|---|---|
| AI Proposal Card | `TmIac` | `mkIux` | Chrome fijo (Kicker + Title + **Body Slot** reemplazable por instancia + Footnote + Actions Row). El Body Slot se sustituye entero vía `Replace()`, mismo patrón que el "CTA Slot" de `Sync Hero` (`XxHV3`) — así una sola estructura sirve para presupuesto/meta/categoría/transacción sin duplicar el componente. La versión oscura es un `ref` con `theme:dark`, no una copia estructural — un cambio futuro a la base se propaga solo. |
| Conversation Row | `cBizM` | `ADS8m` | Fila de historial: título (derivado del primer mensaje del usuario, truncado) + fecha relativa + footer borrable (mismo patrón que `Archived Goal Row`/`Archived Budget Row`, pero en `$expense-text` porque acá la acción es destructiva real, no restaurativa). |
| Conversation Skeleton Row | `rVldq` | `qCxdk` | Imita la silueta real de `cBizM` (Body 2 líneas + Footer con divisor). |

### Estados de `AI Proposal Card` (mismo componente, `Body Slot` + overrides — nunca reestructurado)
| Estado | nodeId (Claro) | nodeId (Oscuro) | Tratamiento |
|---|---|---|---|
| Pendiente (base) | `TmIac` / instancia `QbxtJ` en el chat | `mkIux` | Kicker "Propuesta" en `$primary-on-soft`. Fila **Monto** en **22px/800** `$text-primary` (jerarquía elevada tras auditoría — mismo peso que usan `Detail Amount Hero`/`Balance Card Hero` para cifras protagonistas). Actions Row: Descartar (`Button/Secondary`, neutro — declinar no es destructivo) + Confirmar (`Button/Primary`). Contraste del monto en oscuro (`$text-primary`/`$surface`): 14.88:1. |
| Confirmada | `NKaY4` | `n5WJ2j` | Kicker `check` + "Confirmado" en `$income-text`. Actions Row reemplazada por fila de solo lectura ("Ya está en tus movimientos" + `check-circle-2`). Footnote con fecha/hora de aplicación. Contraste `$income-text`/`$surface` oscuro: 8.54:1. |
| Descartada | `Xc64n` | `T7OfZm` | Kicker `x` + "Descartada" en `$text-secondary`. `fill:$surface` + `strokeWidth:1` (igual que los otros 3 estados — **no** un contenedor sin card). Contenido interno (kicker, título, body, footnote) a **opacidad 94%** — es el piso real medido por contraste WCAG en claro: `$text-secondary` sobre `$surface` cae bajo 4.5:1 por debajo de ~93%. En oscuro el mismo 94% da 5.38:1, con margen — no hizo falta subirlo. Actions Row deshabilitada (`enabled:false`). La diferenciación real de este estado no depende solo de la opacidad: el cambio de color del kicker (violeta→gris) y la desaparición completa de los botones son las señales fuertes; el dimming sutil es deliberado y coherente con el tono no-punitivo (declinar una propuesta no es un error que haya que resaltar). |
| Fallida | `D6HYxR` | `E8kU6` | Kicker `triangle-alert` + "No se pudo guardar" en `$expense-text`. Mensaje corto de error + "Tus datos siguen a salvo en tu dispositivo" (regla de tono de `MASTER.md`). Botón "Descartar" oculto; "Confirmar" reemplazado por "Reintentar" (`refresh-cw`) a ancho completo. |

### Reportar un mensaje del asistente

Menú contextual sobre un mensaje del asistente (long-press) → hoja de motivo con chips de selección única.

| Pieza | nodeId (Claro) | nodeId (Oscuro) | Notas |
|---|---|---|---|
| Menú de acciones (Copiar / Reportar) | `PpcIh` (mockup completo) / `Cbssw` (componente) | `flRpc` | `Cbssw` (`reusable:true`): fila "Copiar" (`copy`) + divisor + fila "Reportar" (`flag`), ambas 44px de alto tocable, fondo `$surface` + borde `$border`. En el mockup se representa insertado en el flujo de la conversación bajo el mensaje objetivo (`MjhiN`), resto de la pantalla atenuado a `opacity:0.35` para comunicar foco — en Flutter es un overlay real anclado al punto de long-press (`CompositedTransformFollower`/`showMenu`), NO un elemento en el flujo del scroll. |
| Hoja de motivo — chip seleccionado | `zV9g3` | `BQ79s` | Instancia `Bottom Sheet Base` (`PqTUt`). Ilustra el tratamiento del chip **seleccionado**: `Reason Chip` (`Afl5e`) con `fill:$surface` + `stroke:$primary` + ícono/label en `$primary-on-soft`/`$primary-on-soft-strong` (patrón "entidad sin color", igual que el selector de ícono de Presupuestos). |
| Hoja de motivo — sin selección (estado real por defecto) | `G6uAwV` | `W0k8Z2` | Mismo sheet, ningún chip seleccionado (todos `fill:$surface`+`stroke:$border`, ícono/label `$text-secondary`) y botón "Enviar" (`Ot4yI` → `qfTBg`) en `opacity:0.4` — deshabilitado hasta elegir un motivo. Este es el estado con el que abre la hoja en producción; `zV9g3` es solo la referencia visual del estado seleccionado. |

**Estructura de la hoja (`zV9g3`/`G6uAwV`):** `Content Slot` partido en **zona scrolleable** (`Sheet Icon Header` con ícono `flag` + "Reportar mensaje" + `Reason Grid` de 5 `Reason Chip` en 3 filas + `Comment Field` opcional, ref `wOlOA`) y **zona fija** (`Privacy Note Strip`, ref `YAUFx`, + `Sheet Buttons Row`, ref `Ot4yI`) — así el aviso de envío al servidor es imposible de pasar por alto sin verlo antes de poder tocar "Enviar". Mismo patrón de partición ya usado en Gráficas · Resumen (ver MASTER).

**Copy de la Privacy Note** (única excepción a "nada de la conversación sale del dispositivo", ver política de privacidad §17.5): "Le enviaremos este mensaje a nuestro equipo para revisarlo. El resto de tu conversación se queda solo en tu dispositivo."

**Reason Chip (`Afl5e`, `reusable:true`):** ícono + label, `width:167` (grid 2×2) o `fill_container` (fila final de 1). Tap target: padding `[13,10]` → 44px de alto tocable (verificado). Reason Chip NO introduce colores propios de familia (no tiene par cromático como categorías/cuentas) — sigue el patrón "entidad sin color" documentado en MASTER: seleccionado = hueco (`$surface` + `stroke:$primary`), no relleno `-soft` (que sería idéntico a `$muted` en reposo). Chips inactivos: `fill:$surface` + `stroke:$border` (nunca sin borde).

**Motivos del grid:** Ofensivo (`frown`), Incorrecto (`x-circle`), Dañino (`shield-alert`), Privacidad (`lock`), Otro (`more-horizontal`).

**Tema oscuro (2026-09-02):** generado por `Copy()`+`theme:{mode:"dark"}` sobre los 3 frames, sin cambios estructurales — `Cbssw`, `Afl5e`, `YAUFx`, `PqTUt` ya resuelven oscuro vía sus propios tokens. Contraste verificado a mano (sin `get_screenshot` disponible en esa sesión):
- Chip seleccionado, `stroke:$primary` sobre `$surface` oscuro: **exactamente 3.00:1** — mismo límite ya documentado en MASTER para `primary` oscuro/`surface` (caso sistémico pendiente de migración a `primary-data`, no exclusivo de esta pantalla). Consistente con el patrón ya aceptado en Presupuestos (`XsnnD/x9w2F`).
- Chip inactivo, `stroke:$border` sobre `$surface` oscuro: **~1.17:1** (peor que claro ~1.02:1, mismo orden). Igual que `Button/Secondary`, el chip se identifica por su **label/ícono** (`$text-secondary` ~6:1 inactivo, `$primary-on-soft-strong` ~6.03:1 seleccionado), no por el borde — trade-off ya aceptado en el sistema, no una regresión nueva de esta pantalla.
- `Privacy Note Strip`: `fill:$muted` + texto/ícono `$text-primary` sobre `$muted` oscuro (`#26243B`/`#F4F3FA`) — contraste >12:1, mantiene su prominencia sin cambios.

Pendiente de aprobación explícita del usuario (marcado con badge de revisión en el canvas): `flRpc`, `BQ79s`, `W0k8Z2`.

## Interacción del header del chat (`ueaIi`)

`Dtm0X` (Page Header) en su forma base solo tiene un `Action Button`. Acá se compuso un override **puntual de esta instancia** (`fKVDX`) con dos grupos, siguiendo el patrón ya usado en Deudas (`REKRV`) y en `Home Header` (`Nk9rB`, `Sync Indicator` + `Bell`):
- `Left Group`: Back Button + spacer invisible 44×44 (necesario para mantener el título centrado con la derecha más pesada).
- `Right Group` (gap 8): ícono `history` (abre Historial) + ícono `plus` (nueva conversación).

No se tocó la definición base de `Dtm0X` — evita repetir el incidente de purga de overrides ya documentado en `MASTER.md` (142 instancias afectadas la vez anterior que se editó la base).

## Pendientes (de interacción/producto, no de diseño visual — para `flutter-dev`)

- **Interacción de apertura de los 2 sheets** (`uPidu`, `fvmUI`): qué gesto exacto del footer de `Conversation Row` y qué botón del header de Historial los disparan no está declarado en Pencil.
- **Área tocable del footer de `Conversation Row`**: mide 44px de alto pero el contenido está pegado a la derecha (`justifyContent:"end"`). El área tocable en Flutter debe ser la fila completa, no solo el bounding box visual de ícono+label — mismo criterio que `Delete Opt-in Row`.
- **Resuelto (2026-08-26):** el estado vacío del chat (`p3tJFm`/`hx3IY`, ver tabla de Pantallas arriba) no reutiliza `cwxZI` tal cual — es una composición nueva inspirada en él (orbe 48px en vez de 42px, título/subtítulo propios, mismas 4 chips vía `tMqvn`). `cwxZI` sigue viviendo sin cambios en la hoja de "próximamente" de Inicio, ajeno a esta feature.
- **Trigger real de "pensando"/error**: websocket, timeout, reintentos — decisión de implementación, no de diseño.
- **Sugerencia no bloqueante de la auditoría**: si en uso real "Descartada" pasa desapercibida al scrollear, considerar un badge/chip adicional junto al kicker — no implementado, no era necesario para aprobar.

## Tema oscuro

**Construido y aprobado.** Generado por `Copy()`+`theme:{mode:"dark"}` sobre las 10 pantallas; los 6 componentes/estados de `AI Proposal Card`/`Conversation Row`/`Conversation Skeleton Row` se resolvieron como `ref` con `theme:dark` sobre el mismo componente base (no copia estructural), así que cualquier cambio futuro a la base se propaga solo a ambos temas.

Auditado por `ui-ux-reviewer` con contraste **re-medido de forma independiente** (no solo confiado al informe de quien lo construyó) en los 7 pares críticos — todos superan 4.5:1 con margen, ninguno necesitó ajuste respecto al valor calibrado en claro (incluida la opacidad 94% de "Descartada", que en oscuro da 5.38:1). Cero hex hardcodeado, mismos patrones de superficie/borde que el resto de la app en oscuro (sin sombras — el sistema no las usa).

La zona `JLbGS` se renombró a "Zona — ASISTENTE IA (Claro+Oscuro)" y el bloque oscuro se ubicó a la derecha del claro, siguiendo la convención de "oscuras separadas de las claras" del resto del canvas.

**Bug real encontrado y corregido tras la aprobación (2026-08-26):** las 16 piezas del tema oscuro habían quedado anidadas como hijos estructurales de `JLbGS` en vez de hermanos a nivel raíz — mismo incidente ya ocurrido dos veces antes en esta feature (una zona decorativa con `width`/`height` fijos recorta cualquier hijo real que anide, en vez de ser solo un rectángulo de fondo). Corregido con `Move(id, 'root')` sobre las 16; verificado con cero problemas en las 20 pantallas (10 claras + 10 oscuras) tras el fix. Si se vuelve a tocar esta zona, **nunca insertar contenido nuevo como hijo de una `Zona —` decorativa** — siempre a nivel raíz, usando la zona solo como referencia visual de coordenadas.
