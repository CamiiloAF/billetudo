# Página: Inicio

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`, zona `CPHbt` — "Zona — INICIO · Paquete Hero Compacto (Claro+Oscuro)". Requerimientos funcionales en `docs/requirements/fase-1/04-inicio.md` (desactualizado respecto a este `.md` en los nodeId citados — corregir en un pase aparte).

## Estado

**Aprobado** (2026-08-27). Claro y oscuro cerrados — 41 frames en total (16 pares del hero/card de IA/hoja de saldos + 1 par adicional de hero "Presupuestos sin destacar" + 4 frames de la hoja de cuenta con sus pares oscuros), auditados por `ui-ux-reviewer` en varias pasadas, sin ninguna marca de revisión pendiente en el canvas. **Regla dura del proyecto: el tema oscuro nunca se vuelve a tocar hasta que el usuario apruebe el claro explícitamente** — ya cumplida acá; cualquier cambio nuevo de diseño reabre esa secuencia (claro primero, oscuro después).

> **Nota de historia:** este paquete reemplaza dos generaciones de diseño anteriores, ambas borradas del `.pen` el 2026-08-27: la variante "V2" con tira "Mis cuentas" + banner de IA al fondo (`LktTm`/`AVgUv`), y antes de esa, la variante A "actividad primero" (`aOhoY`/`A9v7s`/`DliNF`/`AmifS` + oscuros). El hero compacto de este paquete ya cubre con/sin presupuesto en un solo componente (`xRSdl`), y `s8ZgCk`/`Zq0iW` cubren vacío/carga — no hace falta portar nada de las generaciones viejas.

## Tesis (norte del diseño)

Tres cambios de fondo respecto al Home viejo:

1. **El hero se comprime y se vuelve multi-estado.** En vez de un bloque estático que solo sabe mostrar "gasto vs. presupuesto lineal", `Hero Compact · Presupuesto (D)` (`xRSdl`) resuelve **7 estados de negocio reales** en un solo componente con overrides — sano, cerca del límite, en el límite exacto, riesgo de sobregiro proyectado (pagos programados), sobregasto real, sin presupuesto (nunca creó ninguno), y con presupuestos pero ninguno destacado. Nunca reestructurado: cada estado es un set de overrides de instancia documentado en el `context` del componente.
2. **"Te quedan $X" es el ancla fija.** El kicker + monto grande del hero **nunca cambian de pregunta** entre estados — mientras exista saldo restante, siempre responden "Te quedan $X". Cualquier aviso adicional (riesgo proyectado) se suma como información extra en su propia línea, nunca reemplazando el par kicker+monto. La única excepción es sobregasto real, donde no hay restante que anclar y "Excedido por $X" pasa a ser el dato protagonista. Motivo: antes el estado de riesgo reemplazaba el número protagonista por "Podría exceder por $330.000" y el restante real quedaba oculto — corregido a pedido del usuario.
3. **La card de IA se dimensiona según lo que puede ofrecer.** Regla simplificada el 2026-08-27, tras retirar un cuarto estado que existió brevemente ("fila mínima", `a0bxww`/`fKdmJ`, ya borrado): **cero transacciones** → sin card de IA (estado Vacío); **con transacciones y hay insight** → card grande con el insight; **con transacciones y sin insight** → card grande con chips, **sin importar si el usuario tiene acceso al chat o no** (tocar un chip abre el gate si hace falta). Razón: "sin insight" no es lo mismo que "usuario nuevo" — un usuario con antigüedad también puede no tener insight un mes dado, y esa card con chips es la vitrina que puede llevarlo a Premium. El gate solo aparece **al tocar**, nunca como interrupción del Home — la card en sí (insight/resumen/chips) es Nivel 0 y no se restringe, lo restringido es la conversación.

Composición general (de arriba a abajo, todos los estados con datos): **Status Bar → Header (avatar + saludo + 2 botones) → Hero compacto → Card de IA (condicional, ver arriba) → Acceso rápido (5 chips) → Movimientos recientes (4 filas visibles + spacer de reserva del FAB) → Tab Bar → FAB**.

## Header — `Home Header · Avatar de cuenta` (`v8CGbF`)

Refactor de 3 movimientos (frame de origen `Hv7A1`):

1. **El indicador de sync deja de ser un ícono suelto y permanente.** Su función (avisar que algo falló + puerta de entrada a respaldar) la absorbe el **badge del avatar** (`fPMzQ` → `Status Badge`), que solo se enciende cuando tiene algo que decir. En estado sincronizado el badge está apagado y el header no dibuja nada extra. El acceso *siempre disponible* al `SyncStatusSheet` vive en Más → Estado de sincronización (`pages/sincronizacion.md`) — no desaparece, solo deja de duplicarse en el header.
2. **El saludo se comprime** de dos líneas ("Hola de nuevo," / "Cami") a una sola ("Hola, Cami"), conservando nombre y emoji (HU-07).
3. **El avatar deja de ser decorativo.** Es tocable (44×44, abre "Tu cuenta") y portador del estado de respaldo/sincronización.

Resultado: el lado derecho queda con **dos affordances idénticas en forma y tamaño** (44×44 circulares: Saldos-wallet y Notificaciones-bell) en vez de tres heterogéneas. El botón de saldos (`wallet`) es hoy el único camino a la hoja de saldos, porque la tira "Mis cuentas" del Home viejo se eliminó.

**`Account Avatar` (`fPMzQ`)** — componente propio del avatar:
- Overrides: `Initial` (contenido) y `Status Badge` (enabled/fill/glifo).
- **Regla:** el badge nunca es un punto pelado — siempre lleva un mini-glifo dentro (color-not-only, WCAG 1.4.1; un punto de color sobre un avatar significa "tienes mensajes" en la convención universal de UI, y acá significa otra cosa). Anillo de 2px en `$background` separa el badge del degradado del avatar.
- **Fallback sin sesión:** el avatar tiene dos contenidos excluyentes — `Initial` (inicial del `displayName`) y `Fallback Icon` (glifo `user` 22px, apagado por defecto). Sin sesión no hay `displayName`: la instancia apaga `Initial` y enciende `Fallback Icon`, y el saludo cae al genérico "Hola de nuevo" (sin nombre). Verificado contra `lib/features/home/presentation/widgets/home_header.dart` (`_initial` devuelve `null` sin sesión).
- **El ícono del badge en estado "requiere atención" (`$amber`) es por-tema, no un valor único**: en claro se queda en `$on-primary` (blanco, `$amber` claro es oscuro y el blanco ya pasa 4.21:1); en oscuro se sobreescribe a `#1C1B29` fijo (`$amber` oscuro es amarillo brillante, el blanco cae a 1.36:1 ahí). Fue una corrección en dos pasos: el primer intento fijó `#1C1B29` para los dos temas, pasaba el número en claro (~4.03:1) pero se veía apagado a ojo — el usuario lo detectó mirando el render, no un chequeo automático. **Lección documentada en `MASTER.md` § Paleta**: un fix de contraste medido en un tema no se aplica ciegamente al otro sin volver a medir ahí.

**Overrides por instancia del badge (`Status Badge`), 4 estados** (tira de referencia `uT2fj`/`q16Bo`, documenta el contrato, no es pantalla real del Home):

| Estado | Fill | Glifo |
|---|---|---|
| Sincronizado | apagado | — |
| Sincronizando | `$primary-soft` + `$primary` | `refresh-cw` |
| Sin cuenta | `$surface` + `$primary-on-soft` | `cloud-upload` |
| Requiere atención | `$amber` | `cloud-off` (blanco en claro, `#1C1B29` fijo en oscuro) |

## Hero compacto — `Hero Compact · Presupuesto (D)` (`xRSdl`)

Componente único creado 2026-08-26 absorbiendo copias a mano que vivían duplicadas en los frames de estado — todos los frames de hero son instancias con overrides, y el tema oscuro se genera sobre ESTE componente, no sobre copias divergentes.

**Gradiente:** `$primary-deep@0 → $primary@0.65 → $primary@1` a 145°. El stop se adelantó de 1 a 0.65 para que el rango completo del degradado caiga dentro del área de contenido (con stop en 1 el violeta quedaba confinado a la esquina inferior derecha y se leía plano). El punto más claro sigue siendo `$primary` puro (4.86:1 contra `$on-primary`), así que ningún texto baja de ahí.

**Modelo de color — sobrio, sin semáforo por cercanía:** el progreso sano va SIEMPRE en violeta (`$on-primary`), incluso al 97%. `$amber`/`$on-primary-warn` está reservado exclusivamente a la **proyección** de pagos programados aún no ejecutados; `$expense`/`$on-primary-alert` solo entra con el **sobregasto real** (>100%). Copy prohibido: "Te pasaste". Solo "Te quedan" / "Podría exceder por" / "Excedido por".

**Los 7 estados** (overrides de instancia, nunca reestructurados):

| Estado | Kicker | Monto | Barra / bloque inferior |
|---|---|---|---|
| Sano | "Te quedan" | `$on-primary`, 30px/800 | 1 tramo `$on-primary` |
| Al límite (97%) | "Te quedan" | igual que sano | 1 tramo `$on-primary`, solo cambia el ancho — sin teñir |
| En el límite exacto (100%) | "Te quedan" | `$on-primary` (sin cambio) | Solo la barra pasa a `$on-primary-alert` — "traspaso en dos escalones" hacia el sobregasto: 100% es límite *alcanzado* (hecho consumado), no cercanía, pero tampoco es sobregasto real todavía |
| Riesgo de sobregiro proyectado | "Te quedan" + restante real (nunca el excedente) | igual que sano | 2 tramos contiguos: gasto real (`$on-primary`) + proyección de pagos programados (`$on-primary-warn`) + `Risk Note` con `calendar-clock` y "Podría exceder por $X" |
| Sobregasto real | "Excedido por" | `$on-primary-alert`, **32px/800** (subido de 30 para recuperar peso por tamaño en el estado más grave) + ícono `circle-minus` | 1 tramo `$on-primary-alert`, 314px (lleno) |
| Sin presupuesto (nunca creó uno) | "Gastado" + monto, layout vertical apilado (mismo tratamiento que Vacío) | — | Sin barra/%/días. Chip de mes en vez de stepper de rango. Nota: "Sin presupuesto activo este mes". Card de IA muestra el insight "crea un presupuesto" (ver abajo) |
| Con presupuestos, ninguno destacado | igual que "Sin presupuesto" | — | Nota distinta: "Ningún presupuesto destacado este mes" — el texto viejo sería falso acá, el usuario SÍ tiene presupuesto(s). Card de IA usa su lógica **normal** (chips/insight según corresponda), sin ningún insight forzado — el usuario ya sabe qué son los presupuestos |

**Reglas de tamaño del monto** (Pencil no las evalúa sola, las aplica Flutter): por defecto 30px/800; sobregasto real 32px/800; si el contenido supera ~10 glifos (ej. `$99.999.999`), baja a 26px — medido contra el track útil de 314px, a 32px desborda 10px. En Flutter esto es un `FittedBox`/auto-size, no un breakpoint fijo.

**Barra de progreso:** track `$track-overlay`, tramos contiguos sin gap (misma convención que la barra de 3 tramos de Presupuestos). Con un tramo único, las 4 esquinas van a radio 5; con 2 tramos, izquierdo `[5,0,0,5]` y derecho `[0,5,5,0]`. **Umbral de remanente:** cuando el remanente del track a la derecha del tramo único es menor a 2× el radio (<10px, ej. 97%), ese tramo también va `[5,0,0,5]` — a 9px de remanente el cap redondeado del relleno y el del track se solapan y el hueco se lee como antialiasing, no como "te queda un 3%".

**Tokens de barra sobre gradiente:** `$on-primary-warn` (`#FFD27A`) y `$on-primary-alert` (`#FFCFC4`) existen porque `$amber`/`$expense` son casi invisibles sobre el degradado violeta (1.15:1 / 1.01:1). Pasan 3:1 de objeto gráfico (3.40–4.73:1 según fondo) pero NO sirven para texto pequeño (ningún tinte cálido alcanza 4.5:1 sobre este degradado) — por eso el kicker se queda siempre en `$on-primary` sólido. **Son intencionalmente fijos en ambos temas** (no varían por tema como el resto de la paleta) porque están pensados para caer siempre sobre este mismo gradiente, que no cambia de forma relevante entre temas — documentado en `MASTER.md` § Paleta.

**Gesto del period pill:** el hero completo es tocable y navega al detalle del presupuesto destacado (o al `MonthPickerSheet` en los estados sin presupuesto destacado). La pastilla de período/mes (2 chevrones 44×44 + texto) **absorbe el gesto por completo** y no lo propaga al hero — los píxeles centrales del rango de fechas no son zona muerta, pertenecen a la pastilla. En Flutter: `GestureDetector` del hero por fuera, pastilla envuelta en un `AbsorbPointer`/`behavior: opaque` con sus 2 hit targets internos.

## Card de IA — chrome condicional en el slot 2, debajo del Hero

| Estado | Cuándo aparece | Descripción |
|---|---|---|
| **Sin card** | Cero transacciones (estado Vacío) | No aporta valor sin un solo dato que resumir — hereda la regla del Home viejo. |
| **Con chips** (canónica: `MrROq`/`OcfBN`) | Con transacciones, sin insight nuevo — **con o sin acceso al chat** | Card grande 137px: `Orb` (sparkles, gradiente `$primary`→`$primary-deep`) + texto genérico + chevron + fila de scroll horizontal con 4 `AI Question Chip` (`tMqvn`), el 4° es "Ayúdame a presupuestar" (ver abajo). Es el estado por defecto de todo frame del hero D que no demuestra otro caso puntual. |
| **Con insight único** ("Ahora no") | Con transacciones, hay un insight disponible, sin cola | Reemplaza el botón `x` de descartar por el link "Ahora no": se entiende sin aprendizaje previo, comunica que el insight vuelve (no se destruye). Sin contador — un solo insight no tiene cola que anunciar. |
| **Con insight y cola** ("Ahora no" + contador) | Ídem, con ≥2 insights en cola | Misma estructura, con el contador "1 de N" encendido a la derecha del kicker. El contador aparece SOLO cuando hay cola, nunca siempre. |
| **Insight "crea un presupuesto"** (`GmKkQ`/`plbn5`) | Estado del hero "Sin presupuesto" (nunca creó uno) | Tercera familia de insight, distinta de "comparación contra promedio" y "proyección de presupuesto" — no requiere 3 meses de historia, su única condición es "no hay presupuesto activo". Icono `gauge` (`$teal`/`$teal-soft` — no `piggy-bank`, que lee como ahorro, ni `pie-chart`, que no existe en Pencil y cae al fallback "?"). Kicker "Nuevo en Billetudo", título "Presupuesta y no gastes de más", meta "Verás cuánto te queda del mes" — sin prometer notificaciones (el centro de notificaciones sigue exploratorio, `docs/requirements/fase-3/22-centro-notificaciones.md`). Chip "Ayúdame a presupuestar" → navega directo a crear presupuesto, no abre el chat (ver regla abajo). |
| **Gate de acceso al chat** (`ytvPw`/`VxGME`) | Al tocar la card o un chip de conversación, si la persona no tiene acceso | Bottom sheet ("Conversación en beta") que aparece **al tocar**, nunca antes. La card en el Home se ve igual para cualquier usuario — lo restringido es la conversación, nunca el Home mismo. |

**Regla del chip "Ayúdame a presupuestar"** (vive en `MrROq`/`OcfBN` como 4° chip, y como CTA del insight de `GmKkQ`/`plbn5`): **no abre el chat**, navega directo al formulario de crear presupuesto (`onCreateBudget`, ya cableado en `home_page.dart`). Razón: crear presupuesto es Nivel 0 — nunca puede depender de sesión ni de Premium. Si abriera el chat, la mayoría de usuarios nuevos (sin sesión, o sin acceso a la beta) se toparía con el gate justo en el momento pensado para enseñarles que los presupuestos existen. Se distingue visualmente de los chips que sí abren conversación con `arrow-right` (recto) en vez de `arrow-up-right` (diagonal).

## Acceso rápido (`Quick Access A`, chrome fijo — igual en TODOS los estados y pantallas del paquete)

6 chips en scroll horizontal: **Pagos programados** (con badge de contador, `njGBt` — "Quick Access Chip A · Con badge") → **Cuentas** → **Deudas** → **Gráficas** → **Metas** (todos `ref` a `HAPxy`) → **Ajustes** (`ref` a `u4f7l`, último de la fila).

**`Quick Access Chip A · Con badge`** (`njGBt`): variante de `HAPxy` con contador de pendientes a la derecha del label. Se creó como componente NUEVO (no un slot en `HAPxy`, que ya tiene decenas de instancias con overrides — regla de MASTER contra reestructurar un reusable ya instanciado). **El contador cuenta solo ocurrencias de pagos programados por confirmar** (no cobros próximos ni otro tipo de aviso), corta en "9+" por encima de 9, y sin pendientes se instancia el chip base sin badge (nunca un badge en cero). Mismo chrome/altura 44/padding que `HAPxy`.

**`Quick Access Chip A · Ajustes`** (`u4f7l`, agregado 2026-08-27): 6.º chip al final del scroll, circular 44×44 (`fill:$surface`, `stroke:$border` 1px, `cornerRadius:22`), ícono `settings` (lucide) 18×18 en `$text-secondary`, **sin label visible** — acción secundaria de configuración, no una categoría de navegación como las otras 5, accesible por tooltip/semantics en Flutter. Abre "Ajustes ▸ Orden del acceso rápido" (reordenamiento de los 5 chips de categoría; la interacción del reordenamiento en sí sigue sin diseño propio en Pencil, pendiente abierto no bloqueante). Reemplaza el `QuickAccessSettingsButton` que vivía fijo fuera del scroll en la implementación — esa posición fija fue deriva de `flutter-dev` sin frame en Pencil, corregida a partir de la auditoría de fidelidad del 2026-08-27 (`docs/fidelidad-visual-tracking.md`). Instancia como 6.º hijo de `Scroll Row` en los 9 frames del hero (claro y oscuro): claro `vmbkf`/`cpvgN`/`d5GFi`/`f3o4xX`/`yDNda`/`BCIHv`/`cLNds`/`bhYcD`/`YjKTg`; oscuro `HusZi`/`ToTuH`/`qWYFn`/`yHwUi`/`l9FYV`/`UCOyp`/`O6T8F`/`e7QXE`/`K8gjgY` (mismos 9 frames que Hero + Vacío + Carga, en orden).

## Movimientos recientes

Header de sección ("Movimientos recientes" + link "Ver todos →") + hasta 5 `Transaction Row` (`DKJaf`) — Mercado, Netflix, Salario, Uber, Café. En la mayoría de frames del paquete se muestran **4 filas visibles** (Café deshabilitada) para dejar margen real antes del FAB — ver "Carril del FAB" abajo. Agrega movimientos de todas las cuentas activas.

## Hoja de saldos — `Saldos · Hoja de cuentas` (frame `bEYPr`/`D1L1cE`, botón "wallet" del header)

Bottom sheet ("Tu dinero") sobre el fondo real del Home (`Home BG` con `Status Bar`/`Content`/`Tab Bar`/`FAB` detrás, sheet `ref` a `Bottom Sheet Base` encima):

- **Todas las cuentas con nombre completo sin truncar**, agrupadas SOLO por moneda, con un total por moneda — nunca un total mixto (multi-moneda no normaliza en Fase 0).
- **Contenedor bottom sheet** (decisión del usuario; la variante drawer lateral se evaluó y se descartó — el contenido de la hoja empuja "Cerrar sesión" fuera de la zona alcanzable del pulgar en un drawer, mientras que el sheet nace desde abajo).
- **Cabecera "bloque de dinero":** el total se alinea al eje izquierdo en 3 líneas (etiqueta 12/600 → cifra 24/800 → nota 11/500); la moneda con su conteo pasa a un chip `$muted` a la derecha (es metadato, no dato). Sin conteo total de cuentas activas en el title row (redundante con los conteos por grupo).
- **Etiqueta del total "TU DINERO"**: suma cash + bank + savings + other, excluye card (plata prestada, no propia) e investment (suya pero no líquida). La lista **no se divide por tipo** — todas las cuentas conviven en la misma lista agrupada solo por moneda; la etiqueta es la que aclara qué suma el total, no la agrupación.
- La nota "No incluye tarjetas de crédito ni inversiones" solo se dibuja en el grupo donde el total deja algo afuera — el grupo con una sola cuenta bancaria (sin tarjetas) no la lleva.
- **Filas tocables → Movimientos filtrados por esa cuenta** (no detalle de cuenta), reusando la navegación `onOpenAccountMovements` ya existente en `home_page.dart`/`app_router.dart` — es el mismo atajo que ofrecía la tira "Mis cuentas" que se eliminó del Home. Sin chevron ni otra señal visual adicional (`pages/cuentas.md` ya descartó chevrons en `Account Card`, y ningún otro componente de fila del sistema los usa). Tap target 350×74, muy sobre el mínimo de 44pt.

## Hoja de cuenta (destino del avatar) — 4 pares claro/oscuro

El avatar tocable (`fPMzQ`) abre "Tu cuenta". A diferencia de la hoja de saldos, no tiene doc propia en `pages/` todavía (toda la decisión vive en los `context` del `.pen`) — se documenta acá como parte de Inicio porque el avatar que la abre es parte del header del Home.

| Frame | Claro | Oscuro | Notas |
|---|---|---|---|
| Tira comparativa de 4 estados del badge | `uT2fj` | `q16Bo` | No es una pantalla — 4 instancias de `v8CGbF` lado a lado con caption explicando cada estado. Documenta el contrato, no forma parte del flujo real. |
| Hoja del avatar — con sesión, sin conexión | `sauTn` | `ZjL0H` | Estado "algo merece tu atención" (sin conexión, 3 cambios esperando) — el que justifica el badge ámbar del avatar. |
| Hoja del avatar — con sesión, sincronizado | `b8ffs` | `t9ImpN` | Estado "todo bien" — reusa el copy ya aprobado de la familia de sincronización ("Todo está sincronizado", `cloud-check`, `$mint`). |
| Hoja del avatar — sin cuenta | `HKhFc` | `Noi1D` | Punto de conversión que se perdía al quitar la nube del header. No intrusivo: requiere tocar el avatar (HU-07), nunca un modal al abrir la app. |

**Estructura de la hoja** (los 4 frames con sesión, ambos temas): Title "Tu cuenta" → Identity Row (avatar + nombre + correo/proveedor) → **bloque de sync** → "Ajustes" (`Menu Row`, acceso **duplicado** con Más — el borrado de cuenta es requisito de Apple/Google y no puede colgar solo de un avatar) → separador → "Cerrar sesión" (aire + hairline, `$expense-text`, sin chevron porque no navega). El frame sin cuenta reemplaza Identity Row + bloque de sync por una invitación con CTA primario "Activar respaldo", y no lleva "Cerrar sesión".

### El bloque de sync — parametrización del componente `XxHV3` (Sync Hero), no un componente aparte

Pasó por varias iteraciones el 2026-08-27, documentadas para que quien lo retome entienda el porqué de cada decisión:

1. **Primer intento: componente nuevo** (`Sync Row · Compacta`). El usuario lo rechazó explícitamente — quería el **mismo componente** que ya usa la pantalla real de "Estado de sincronización" (`pages/sincronizacion.md`), solo parametrizado, no uno paralelo.
2. **Se agregó un modo compacto a `XxHV3` vía overrides opcionales** que, ausentes, dejan el componente exactamente como está en sus ~20 usos de `sincronizacion.md` — mismo patrón después reusado para el chevron (ver punto 4). El modo compacto: `cornerRadius`/`padding`/`gap` reducidos, párrafo largo de contención apagado o acortado a una frase, botón "Sincronizar ahora" **mismo componente `Button/Secondary` (`pNjOz`)** que la pantalla completa, no reconstruido con texto+ícono sueltos.
3. **El botón se quitó del todo.** El usuario pidió que el bloque entero fuera tocable y navegara a "Estado de sincronización" en vez de tener un CTA propio — el botón real vive en la pantalla completa. El CTA queda `enabled:false` en el override (no borrado), documentado en el `context`.
4. **Se agregó un chevron**, también como override opcional nuevo del componente (`Q7KLYg`, nace `enabled:false`, verificado que las ~20 instancias de `sincronizacion.md` no lo heredan encendido). Motivo: sin botón ni chevron, el bloque "sincronizado" no tenía ningún límite visual (`fill`/`stroke` transparentes) y se leía como texto suelto, mientras la fila "Ajustes" justo debajo sí mostraba su chevron — inconsistencia real que el usuario notó en el render. **Ambos estados** (sincronizado y sin conexión) llevan el chevron encendido hoy.
5. **La fila `Menu Row` "Estado de sincronización" que vivía debajo se borró** — quedó redundante una vez que el bloque de arriba se volvió tocable hacia el mismo destino.

**Estados del bloque:**
- **Sincronizado** (`e2EBxp`/`t9r4P`): sin fill/stroke — se funde con la lista, mismo trato que una fila más. Ícono `cloud-check` en `$mint`/`$mint-soft`. Chevron encendido.
- **Sin conexión** (`ICqxW`/`PJgY8`): fill `$amber-soft` sin borde (presencia por fondo, no por contorno — mismo criterio que el resto del sistema de sync). Ícono `cloud-off` en `$amber`. Chevron encendido. Nota corta: "Sincronizaremos solos en cuanto haya conexión."

## Componentes reutilizables (tabla resumen)

| Componente | Node ID | Uso |
|---|---|---|
| Hero Compact · Presupuesto (D) | `xRSdl` | Hero de Inicio, 7 estados vía overrides (ver arriba). |
| Home Header · Avatar de cuenta | `v8CGbF` | Header de todas las pantallas del paquete + hoja de saldos + hoja de cuenta. |
| Account Avatar | `fPMzQ` | Avatar tocable + badge de estado, usado dentro de `v8CGbF`. |
| Quick Access Chip A · Con badge | `njGBt` | Chip "Pagos programados" con contador, variante de `HAPxy`. |
| Sync Hero | `XxHV3` | Familia de sincronización (`pages/sincronizacion.md`, ~20 usos) + modo compacto parametrizado para la hoja de cuenta (ver arriba). |

## Estados de pantalla — mapa completo de nodeId

Chrome (Status Bar, Header, Tab Bar, FAB) igual en todos los estados con datos; solo cambia el área de Hero/Card IA/Movimientos.

### Hero (7 estados)

| Estado | Claro | Oscuro |
|---|---|---|
| Sano | `M9Gsd` | `m1xWR` |
| Al límite (97%) | `krz8g` | `YP2Dm` |
| En el límite exacto (100%) | `D2UHyr` | `tbvDA` |
| Riesgo de sobregiro proyectado | `p32Jeg` | `IzvtF` |
| Sobregasto real | `jLiDL` | `CrthW` |
| Sin presupuesto (nunca creó uno) | `GmKkQ` | `plbn5` |
| Con presupuestos, ninguno destacado | `UEUJP` | `X7uQP` |

### Card de IA — variantes standalone

| Estado | Claro | Oscuro |
|---|---|---|
| Con chips (canónica) | `MrROq` | `OcfBN` |
| Insight único ("Ahora no") | `Ih1x4` | `GpFk6` |
| Insight con cola ("Ahora no" + contador) | `lKQ3p` | `lclPR` |
| Gate de acceso al chat | `ytvPw` | `VxGME` |

### Header/Avatar

| Frame | Claro | Oscuro |
|---|---|---|
| Header refactorizado (origen de `v8CGbF`) | `Hv7A1` | `V9nxeJ` |
| Avatar con aviso de respaldo | `F1xcy` | `xEV2N` |

### Hoja de saldos

| Frame | Claro | Oscuro |
|---|---|---|
| Saldos · Hoja de cuentas | `bEYPr` | `D1L1cE` |

### Hoja de cuenta

Ver tabla completa arriba, sección "Hoja de cuenta".

### Pantalla completa (2 estados)

| Estado | Claro | Oscuro | Qué cambia |
|---|---|---|---|
| Vacío (HU-08) | `s8ZgCk` | `OvR4h` | Hero en `$0`; **sin card de IA** (no aporta valor sin un solo dato que resumir); Movimientos reemplazado por `Empty State` (`jmQO5`, ícono `receipt` + "Aún no registras movimientos" + CTA "Agregar movimiento"), centrado en el espacio libre. |
| Carga (HU-09) | `Zq0iW` | `a2oDQ` | Hero en skeleton (misma geometría exacta del hero D para que no salte al hidratar) + 5 `Transaction Skeleton Row` (`gDAqP`). Acceso rápido NO es skeleton (destinos estáticos). **La card de IA no tiene skeleton**: el slot queda vacío y aparece al hidratar. |

**Inicio NO tiene un estado "Error" de pantalla completa por diseño** — no hay frame en Pencil para él y no debería crearse uno: la app es local-first, el Home no se vacía sin conexión, y un fallo de sync se comunica con el indicador discreto del badge del avatar (ver Header arriba), no con una pantalla de error. El golden `home_page_error_{light,dark}.png` que existe en `test/features/home/presentation/golden/` es cobertura defensiva de código (un fallback genérico ante un error catastrófico de lectura local), no un estado de diseño — no es un gap de fidelidad, verificado el 2026-08-27 vía `pencil-fidelity-reviewer`/`/design-fidelity-check`.

## Decisiones específicas de esta página

- **Composición "hero multi-estado + card IA condicional"** reemplaza tanto la variante A ("actividad primero") como la V2 (tira "Mis cuentas"). El desglose por categoría sigue sin vivir en el Home (vive en Gráficas).
- **Modelo de color sobrio, sin semáforo por cercanía** (hereda de `pages/presupuestos.md` § Modelo de color): 97% no se tiñe, 100% se tiñe apenas (traspaso en dos escalones), el ámbar es exclusivo de proyección y el rojo exclusivo de sobregasto real.
- **"Te quedan $X" como ancla fija** del hero, nunca reemplazado por un aviso adicional salvo en sobregasto real.
- **La card de IA con chips es el estado por defecto** cuando hay transacciones sin insight, sin importar el acceso al chat — es la vitrina de la función, no solo un atajo para quien ya puede usarla.
- **Crear presupuesto y elegir cuál destacar nunca pasan por el chat** — son acciones de Nivel 0 con pantalla propia; el chip navega directo.
- **El gate de acceso al chat aparece solo al tocar**, nunca como interrupción.
- **El indicador de sync suelto del header desaparece**, absorbido por el badge del avatar.
- **Hoja de saldos ("Tu dinero") en bottom sheet**, agrupada por moneda sin total mixto, etiqueta definida por el usuario (cash+bank+savings+other, excluye card e investment).
- **El bloque de sync de la hoja de cuenta reusa `XxHV3` parametrizado**, nunca un componente paralelo — regla explícita del usuario tras un primer intento rechazado.

## Hoja "Saldos" — estado vacío

Cuando el usuario no tiene ninguna cuenta activa, la hoja "Saldos" (`Bottom Sheet Base`, nodeId `LxZls` dentro del frame `X7eBX`, "Saldos · Hoja de cuentas — Vacío Variante A (Claro)") muestra el componente reusable `Empty State` (`jmQO5`), con el mismo copy que el estado vacío de Cuentas:

- Icono `landmark` (lucide) sobre círculo `$primary-soft` / `$primary-on-soft`.
- Mensaje: "Aún no has agregado ninguna cuenta" (`$text-primary`, 16/600).
- Subtítulo: deshabilitado (no se usa en este patrón).
- CTA: `Button/Primary` con ícono `plus`, label "Agregar cuenta".

Decisión aprobada por el usuario 2026-09-02, eligiendo la Variante A entre dos exploradas (la Variante B, `DPcW6`, se descartó y se borró del canvas).

**Duda técnica abierta para `flutter-dev`:** esta hoja se abre desde Home (botón "wallet" del header), no desde la pantalla de Cuentas. El CTA "Agregar cuenta" navega al formulario de creación de cuenta — falta decidir si el sheet se cierra antes de navegar (y al volver el usuario queda en Home) o si el formulario se apila por encima del sheet abierto (y al volver el usuario reaparece dentro del sheet, ahora con la cuenta recién creada). Esta interacción no está diseñada en Pencil; queda como decisión de implementación o para una iteración de diseño futura si el comportamiento por defecto de navegación no se siente bien.

## Correcciones de accesibilidad aplicadas (`ui-ux-reviewer`)

- Sobregasto real: monto sube a 32px/800 para compensar que `$on-primary-alert` da 3.46:1 (vs. 4.86:1 de `$on-primary`) — sigue calificando como texto grande (piso 3:1), y el estado no se cifra solo en color (glifo `circle-minus` + copy "Excedido por").
- Barra de progreso: umbral de remanente <10px fuerza esquina recta para que el 97% no se lea como 100% por solapamiento de caps redondeados.
- Badge del avatar en estado "requiere atención": ícono blanco en claro, `#1C1B29` fijo en oscuro (no un valor único para los dos temas — ver Header arriba).
- Badge del avatar nunca es un punto pelado — siempre lleva un mini-glifo.
- **Carril del FAB:** la reserva original (`padding-bottom` sobre un `Content` de alto fijo) no empujaba nada — se recortaba invisible. Corregido con un spacer real (96px) como último hijo del `Content`, y "Movimientos" bajó a 4 filas visibles en la mayoría de frames para que la última fila termine con margen real antes del FAB (33–93px medido según frame).
- **Chevron del bloque de sync compacto**: sin él (y sin el CTA que se quitó), el estado "sincronizado" no tenía ningún límite visual — corregido, ver "Hoja de cuenta" arriba.
- **`AI Question Chip` (`tMqvn`), 2026-08-29 (v2, revierte stroke):** el chip (`fill:$muted`) se fundía con la card que lo contiene (`fill:$surface`) — 1.09:1/1.16:1, muy por debajo del 3:1 de WCAG 1.4.11. Un primer intento agregó `stroke:$primary-on-soft` 1.5px; el usuario lo rechazó al verlo en captura ("no me convence, se ve barato"). Se resolvió con COLOR: nuevo token `$muted-strong` (idéntico a `$muted` en claro, `#6E68AB` en oscuro, ~3.30:1 contra `$surface` oscuro), sin borde. Detalle completo en `MASTER.md` § AI Question Chip.
- **Reversión de color (2026-09-03):** `$muted-strong` se implementó en producción (`ai_question_chip.dart`) el 2026-09-02 junto con el resto del fix de legibilidad de issue #22. El usuario vio el resultado real en tema oscuro y no le gustó ("ese color no me gustó que quedó") — pidió explícitamente revertir SOLO el color, dejando el resto del fix (wrap a 2 líneas, altura compartida por fila, tipografía 14/600) intacto. Se revirtió `fill` a `$muted` tanto en `tMqvn` (componente base en Pencil) como en `ai_question_chip.dart` (código) y su test. El hallazgo de contraste WCAG de 2026-08-29 sigue documentado arriba como referencia histórica, pero **ya no aplica al estado actual** — el token `$muted-strong` sigue existiendo en el sistema (por si se necesita en otro contexto), simplemente este componente ya no lo usa.
- **Regla de altura dinámica por fila (issue #22, 2026-09-02):** el chip prefiere SIEMPRE 1 sola línea de texto (alto natural 44px). Cuando una pregunta real no cabe en 1 línea ni con el ancho generoso, necesita 2 líneas — y en ese caso **todos los chips visibles en esa fila/scroll comparten el mismo alto de 2 líneas**, aunque el texto de algunos quepa en 1 línea (nunca alturas mixtas dentro de la misma fila). Si ningún chip de la fila necesita 2 líneas, todos quedan en 44px. Referencia aprobada: `OshOq` ("Inicio · Chips IA — Variante A"), tarjeta `t1sfJ`, fila `XHTS0` ("Chips Scroll Row"). Ya implementado en producción (`ai_card_chips.dart`, vía `IntrinsicHeight`).
- **Pendiente de propagación:** la tipografía 14px/600 (subida desde 13/500) del label del chip solo está aplicada como override en `OshOq`/`t1sfJ` (frame de referencia del fix). Las tarjetas de producción reales del Home (`MrROq`/`OcfBN`, `Ih1x4`/`GpFk6`, `lKQ3p`/`lclPR`, `ytvPw`/`VxGME`, `GmKkQ`/`plbn5`) todavía usan el default 13/500 del componente — no se tocaron en esta sesión, verificar y propagar antes de dar el fix por completo terminado en producción.

## Pendientes

- **Propagar issue #22 a las tarjetas de producción:** `OshOq` es el frame de referencia aprobado; falta aplicar la tipografía 14/600 (y confirmar la regla de altura de fila) en las instancias reales de la card de IA (`MrROq`/`OcfBN`, `Ih1x4`/`GpFk6`, `lKQ3p`/`lclPR`, `ytvPw`/`VxGME`, `GmKkQ`/`plbn5`).
- **Insight de la card de IA admite hasta 2 líneas por texto** (kicker/título/meta) — documentado en el `.pen` pero visualmente sigue en 1 línea (copy corto). Si crece a 2 líneas, la card sube ~36px y puede volver a invadir el carril del FAB; no se pudo verificar si el scroll real del Home en Flutter lo resuelve solo.
- **`xBv3N`/`oMXhw`** (Hero Period Stepper viejo, zona Presupuestos): ya fueron **borrados** del `.pen` — su función quedó absorbida por el stepper integrado de `xRSdl`. Sin acción pendiente.
- **Implementación en Flutter** (`flutter-dev`): no iniciada. El diseño está aprobado en ambos temas — puede empezar.
- **Auth/Ajustes:** confirmar que "Cerrar sesión" separado en la hoja de cuenta no diverge del patrón ya usado en Más/Ajustes (mismo criterio de aire + hairline).
- **`docs/requirements/fase-1/04-inicio.md`** sigue citando nodeId viejos — corregir en un pase aparte cuando se actualicen los requisitos funcionales.
