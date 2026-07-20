# Design System Master File

> **LOGICA:** Al construir una pantalla especifica, revisa primero `design-system/pages/[page-name].md`.
> Si existe, sus reglas **sobreescriben** este Master file. Si no, sigue las reglas de abajo.

---

**Proyecto:** Finance App (Billetudo)
**Actualizado:** 2026-07-11
**Categoria:** Personal Finance Tracker — Flutter, Android + iOS
**Fuente de verdad real:** `billetudo.pen` (Pencil). Este documento describe lo que hay en ese archivo; si alguna vez difieren, `billetudo.pen` manda y hay que corregir este `.md`, no al reves.

> Historial: la primera version de este documento fue generada por la skill `ui-ux-pro-max` con una paleta azul/verde y tono "Dark Mode OLED" que **nunca se uso**. El diseno real que se construyo y aprobo en Pencil (Propuesta 12, "Monai-style") usa violeta como color de marca, con soporte completo claro/oscuro. Este documento fue reescrito para reflejar eso.

---

## Global Rules

### Paleta de color

34 variables definidas en `billetudo.pen` (`get_variables`), todas con soporte de tema `light`/`dark` salvo donde se indica. **Nunca hardcodear un hex en una pantalla nueva — usar siempre la variable.**

| Token | Claro | Oscuro | Uso |
|-------|-------|--------|-----|
| `primary` | `#6C5CE7` | `#6D4FE0` | Color de marca. CTAs, iconos activos, links, gradiente del Hero. |
| `primary-deep` | `#5648C8` | `#5B4BE0` | Extremo oscuro de degradados con `primary` (nunca usar `primary-light` detras de texto/iconos, ver Accesibilidad). |
| `primary-light` | `#A78BFA` (fijo, sin tema) | — | Solo para detalles decorativos SIN texto/iconos encima (ej. mitad de un degradado decorativo sin contenido). **Extensión de uso (Presupuestos, HU-12):** también válido como fill de un segmento de barra de progreso que codifica un dato real (monto "programado" de pagos programados) — sigue sin llevar texto/icono superpuesto, que es la condición real de la regla, aunque ya no sea decoración pura. Ver `pages/presupuestos.md`. |
| `primary-soft` | `#EEECFB` | `#26243B` | Fondo tenue para iconos/chips relacionados a `primary` (ej. categoria "Vivienda"). |
| `primary-on-soft` | `#6C5CE7` (= `primary` claro) | `#A78BFA` (= `primary-light`) | **Usar SIEMPRE en vez de `primary` cuando el texto/icono va SOBRE un fondo `primary-soft`** (ej. icono de `Category Row`, label de un chip/pill seleccionado, codigo de moneda seleccionado). Motivo: `primary` sobre `primary-soft` en modo oscuro da ~2.75:1, insuficiente incluso para texto grande/iconos (min. 3:1). Con `primary-on-soft` el contraste sube a ~5.5:1 en oscuro sin tocar `primary` ni `primary-soft` (que siguen usandose igual en cualquier otro contexto, ej. CTAs solidos, fondos tenues sin texto encima). En claro este token es identico a `primary` (~4.17:1 sobre `primary-soft`), asi que no cambia nada visualmente ahi — ese 4.17:1 pasa el umbral de 3:1 (icono/texto grande) pero NO el 4.5:1 de texto normal. Por eso, en textos de contenido chicos/normales (no decorativos) sobre `primary-soft`, subir el tamaño a ≥19px/700 (calificar como "texto grande") en vez de asumir que `primary-on-soft` alcanza. Excepcion valida solo cuando el texto es decorativo/redundante (ej. codigo de moneda "COP" dentro de un badge, cuando el nombre completo ya aparece al lado) — ahi el umbral de 3:1 aplica igual que a un icono. No copiar esa excepcion a texto que sea la unica fuente de esa informacion. **Tambien usar en vez de `primary` cuando el texto/icono va sobre `$surface`/`$background` planos** (no solo `primary-soft`) — hallazgo de Transacciones: `primary` crudo como texto sobre `$surface` da ~4.86:1 en claro (pasa raspando) pero cae a ~3.00:1 en oscuro (falla texto normal). Ejemplos: acciones "Todas"/"Ninguna" en headers de sheet, label activo de un `Segmented Control` cuando el color semantico es `primary` (ej. segmento "Transferencia"), montos/valores en `primary` puro. `primary-on-soft` sube esos casos a ~6:1 en oscuro sin cambiar nada en claro. |
| `mint` | `#059669` | `#34D399` | Color de categoria (ej. Comida). Verificado a 3:1+ contra `mint-soft` en ambos temas. |
| `mint-soft` | `#E6F7EF` | `#16321F` | Fondo tenue para `mint`. |
| `sky` | `#2563EB` | `#4C9AFF` | Color de categoria (ej. Transporte). |
| `sky-soft` | `#E6F0FD` | `#1B2A42` | Fondo tenue para `sky`. |
| `peach` | `#C2410C` | `#FB923C` | Color de categoria (ej. Ocio). |
| `peach-soft` | `#FDEEE6` | `#3A2418` | Fondo tenue para `peach`. |
| `coral` | `#E11D48` | `#FB7185` | Color de paleta decorativa (ej. selector de color de cuenta). Verificado ≥3:1 contra `coral-soft` en ambos temas (4.02:1 claro, 5.93:1 oscuro). |
| `coral-soft` | `#FDE8ED` | `#3A1620` | Fondo tenue para `coral`. |
| `amber` | `#9B7608` | `#FBDE24` | Color de paleta decorativa. Ajustado desde un primer intento (`#B45309`/`#FBBF24`) que se confundia demasiado con `peach` (solo 8.5° de diferencia de matiz) — ahora 27.4° de separacion en claro / 24.9° en oscuro. Verificado ≥3:1 contra `amber-soft` en ambos temas (3.82:1 claro, 9.87:1 oscuro). Como texto normal (no grande) no alcanza 4.5:1 AA en claro (~4.2:1) — usar `amber-text` en esos casos. |
| `amber-soft` | `#FDF3E0` | `#3A2E0F` | Fondo tenue para `amber`. |
| `amber-text` | `#8A6906` | `#FBDE24` (= `amber` oscuro, sin cambio) | Variante de `amber` calibrada para texto normal 12px/700 sobre `$surface`: ~5.12:1 en claro (el `amber` base solo da ~4.2:1, falla AA). Mismo patron que `expense-text`/`income-text`. Primer uso real: caption/fila de "riesgo de sobregiro proyectado" en Presupuestos (HU-12), ver `pages/presupuestos.md`. |
| `teal` | `#0F766E` | `#2DD4BF` | Color de paleta decorativa. Verificado ≥3:1 contra `teal-soft` en ambos temas (4.83:1 claro, 7.80:1 oscuro). |
| `teal-soft` | `#E0F5F3` | `#0F2E2B` | Fondo tenue para `teal`. |
| `indigo` | `#3730A3` | `#818CF8` | Color de paleta decorativa. Verificado ≥3:1 contra `indigo-soft` en ambos temas (8.07:1 claro, 5.22:1 oscuro). |
| `indigo-soft` | `#E7E6F7` | `#211F45` | Fondo tenue para `indigo`. |
| `background` | `#F4F3FA` | `#14141F` | Fondo de pantalla. |
| `surface` | `#FFFFFF` | `#1E1E2E` | Tarjetas, barras, superficies elevadas. |
| `muted` | `#EEECFB` | `#26243B` | Fondos sutiles genericos (chips inactivos, AI Assistant card). **`muted` y `primary-soft` son el MISMO hex en ambos temas** — ver la regla de "estado seleccionado sin color de entidad" mas abajo antes de usar uno para distinguir del otro. |
| `border` | `#ECEBF3` | `#2A2A3D` | Bordes/divisores sutiles. |
| `skeleton` | `#ECEBF3` | `#45455F` | **Relleno de bloques placeholder de skeleton (estados de carga).** Claro = idéntico a `border` (el skeleton claro no cambia); oscuro deliberadamente más luminoso que `border` (`#2A2A3D`) para que el skeleton se lea sin gritar (~1.9:1 sobre `background`, ~1.77:1 sobre `surface`) — `border` oscuro daba ~1.25:1, casi invisible. Usar SOLO para rellenos placeholder de skeleton, nunca para bordes/divisores reales (esos siguen en `border`). Disponible para reusar en skeletons de otras features (Cuentas/Categorías/Movimientos). |
| `text-primary` | `#1C1B29` | `#F4F3FA` | Texto principal. |
| `text-secondary` | `#6B6980` | `#9A98B5` | Texto secundario/metadatos. |
| `on-primary` | `#FFFFFF` (fijo) | — | Texto/iconos sobre superficies `primary`. Usar SIEMPRE solido, nunca traslucido (ver Accesibilidad). |
| `income` | `#22C55E` | `#34D399` | Semantica: monto positivo/ingreso. Usado en Cuentas (deuda de tarjeta ya saldada, saldos positivos) ademas de Transacciones. |
| `income-text` | `#166534` | `#34D399` (sin cambio) | **Usar en vez de `income` para texto de tamaño normal/mediano** (ej. `Amount Value` del formulario de Ingreso, 36-40px pero no calificando como "texto grande" por debajo de ~800 weight en algunos casos limite). Motivo: `income` (`#22C55E`) sobre `background` da solo ~2.07:1 en claro, muy por debajo de cualquier umbral WCAG. `income-text` calibrado a ~6.46:1 en claro; en oscuro `income` (`#34D399`) ya pasa por si solo asi que `income-text` reusa el mismo valor sin cambio. Mismo patron que `expense`/`expense-text`. |
| `snackbar-action` | `#A78BFA` | `#5648C8` | **Texto de acción sobre el fondo invertido de `Snackbar`** (ej. "Deshacer"). Motivo: el primer intento uso `primary-light`, un hex fijo sin variante de tema (`#A78BFA` en ambos), que da buen contraste en claro (~6.23:1 sobre `$text-primary` claro) pero se rompe en oscuro (~1.5:1) porque `$text-primary` se invierte por tema y `primary-light` no. `snackbar-action` sí varia por tema: claro reusa el mismo `#A78BFA` (6.23:1), oscuro usa `#5648C8` (= `primary-deep` claro, 6.03:1 sobre `$text-primary` oscuro). Nunca reusar `primary-light` para texto — MASTER ya lo reserva solo para decoracion sin contenido encima. |
| `expense` | `#DC2626` (fijo) | — | Semantica: alertas/montos negativos, deuda real (ej. tarjeta de credito en Cuentas). Deliberadamente NO se usa para "gasto" en tono neutral (ver Tono de marca abajo). |
| `expense-soft` | `#FDE8E8` | `#3A1616` | Fondo tenue para `expense` (ej. badge "Sobrecupo" en Cuentas — verificar contraste caso a caso, en algunos pares no alcanza 4.5:1 con texto normal). |
| `expense-text` | `#B91C1C` | `#F87171` | **Usar en vez de `expense` para texto/links destructivos de tamaño normal** (ej. "Eliminar cuenta" cuando se quiere un tratamiento discreto, no en negrita/tamaño grande). Motivo: `expense` (`#DC2626`, fijo) sobre `background` da ~4.38:1 en claro (falla el 4.5:1 de texto normal, solo pasa como "texto grande") y ~3.78:1 en oscuro (tampoco alcanza 4.5:1). `expense-text` esta calibrado por tema — mas oscuro en claro (~5.87:1), mas claro en oscuro (~6.6:1) — para que un link de eliminar chico/normal cumpla contraste en ambos temas sin depender de agrandar el texto. `expense` sigue siendo el rojo para botones solidos, badges e iconos grandes (ahi sigue pasando 3:1 sin problema); `expense-text` es solo para texto pequeno. |
| `scrim` | `#00000066` (fijo) | — | Overlay semitransparente detras de bottom sheets/modales. |
| `primary-on-soft-strong` | `#5648C8` (= `primary-deep` claro) | `#A78BFA` (= `primary-on-soft` oscuro, sin cambio ahi) | Excepcion de contraste para texto/icono **pequeno** (no texto grande) sobre `primary-soft` cuando `primary-on-soft` no alcanza 4.5:1 a ese tamano. Caso de uso: label del `Category Chip` seleccionado (13px/700 sobre `primary-soft`/`background`, `primary-on-soft` daba ~4.2-4.4:1; con este token sube a 6.04:1 en claro). Usar solo cuando subir el tamano a ≥19px/700 (la solucion general documentada para `primary-on-soft`) no es viable por el tamano del contenedor — no reemplazar `primary-on-soft` por defecto, es una excepcion puntual. |

`mint`/`sky`/`peach` en modo claro fueron oscurecidos a proposito respecto a su primer intento (`#22C55E`/`#4C9AFF`/`#FF8A65`) — esos valores originales fallaban el contraste minimo de icono/grafico (3:1 WCAG) contra su propio `-soft`. Ver seccion Accesibilidad. Los 4 colores agregados en la ampliacion de la paleta decorativa (`coral`, `amber`, `teal`, `indigo`) se calibraron con la misma metodologia, verificando contraste ≥3:1 contra su propio `-soft` en ambos temas antes de fijar el hex final.

**`coral`/`teal`/`indigo` (+ sus `-soft`) estan definidos en el `.pen` pero SIN uso actual** — se agregaron para un selector de color de cuenta que el usuario decidio descartar (las cuentas usan icono/color estandar segun su tipo, sin personalizacion). Quedan disponibles para una futura feature que necesite mas variedad de paleta decorativa (ya calibrados y verificados), no se borraron por no romper nada al dejarlos. **`amber` ya tiene uso real** (Presupuestos, HU-12: "riesgo de sobregiro proyectado" — ver `pages/presupuestos.md`), como excepcion documentada a la regla general de "prohibido semaforo por cercania al limite": ese caso es proximidad de *gasto real* ya materializado; HU-12 es una *proyeccion* de pagos aun no ejecutados, un caso distinto.

**Pendiente para cuando se genere el tema oscuro de un selector de color (ej. Selector de Icono y Color de Cuentas):** el patron de "check blanco (`$on-primary`) superpuesto sobre un swatch solido" (usado para marcar el color seleccionado) pasa contraste ≥3:1 en modo CLARO contra los 8 colores de la paleta decorativa, pero en modo OSCURO solo `primary` (5.46:1) pasa — `mint`/`sky`/`peach`/`coral`/`amber`/`teal`/`indigo` se aclaran en oscuro (pensados para texto/icono sobre fondo `-soft`, no como fondo solido detras de blanco) y el check blanco cae a 1.6-3.0:1 en esos 7. **Antes de generar la copia oscura de cualquier pantalla con este patron**, verificar contraste real por swatch y, para los 7 colores que fallan con blanco, usar un check oscuro (ej. `#1C1B29`, mismo valor que `text-primary` claro) en su lugar — sobreescribir el `fill` del check por instancia segun el swatch, no asumir que `$on-primary` funciona igual en todos.

### Tipografia

- **Fuente unica:** Plus Jakarta Sans (heading y body).
- **Mood:** geometrica, moderna, legible, profesional pero calida.
- **Google Fonts:** [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)
- **Flutter:** la familia se declara en `pubspec.yaml` bajo `flutter: fonts:` con sus cinco pesos (los `.ttf` viven en `assets/fonts/`) y se aplica vía `AppTheme.fontFamily`. **No usar `google_fonts` en `lib/`.**
  - **Por qué (2026-07-19):** `GoogleFonts.plusJakartaSansTextTheme` estampaba `fontFamily: 'PlusJakartaSans_regular'` —una familia de **un solo peso**— en cada estilo del text theme, así que `copyWith(fontWeight:)` era **inerte en toda la app**: pedir 700 u 800 renderizaba 400, y ningún test lo detectaba porque los goldens congelaron el resultado. Afectaba a 233 call sites con peso explícito más 65 que heredaban el 400 de Material — un peso que ni siquiera está en la paleta de abajo.
  - **El peso base del text theme es 500**, no el 400/500 mezclado de Material: todo texto que no pide peso debe caer en el 500 de cuerpo de los frames.
  - **Ojo en tests:** los `.ttf` de `pubspec.yaml` se empaquetan pero `flutter test` **no los registra** — eso lo hacía `google_fonts` como efecto colateral. Lo resuelve `test/flutter_test_config.dart`, que los registra una vez para toda la suite. Sin eso, los widget tests miden con la tipografía placeholder y fallan con overflows falsos.
- **Pesos usados:** 500 (cuerpo/metadatos), 600 (enfasis/links), 700 (titulos), 800 (montos grandes tipo Hero).
- **Escala tipica:** 42px (monto Hero), 24px (titulo de pantalla/label de exploracion), 17px (nombre de usuario), 15-16px (titulos de tarjeta, nombres de fila), 12-14px (metadatos, labels, botones).

### Radios y espaciado

- Radio grande (tarjetas/Hero/tab bar): 24-28px.
- Radio medio (chips, botones, wraps de icono): 14-16px.
- Radio de icon-wrap circular: mitad de su alto (ej. 44px alto -> 22px radio).
- Padding de contenido de pantalla: 20px horizontal.
- Gap entre secciones mayores: 18px. Gap entre items relacionados: 8-16px.
- Los frames de pantalla ("Screen") usan **altura fija de 972px, igual en TODAS las pantallas** (no `fit_content`). Esto se cambio a proposito: con `fit_content` cada pantalla se encogia a su propio contenido y el "dispositivo" quedaba de tamaño distinto entre pantallas (obvio en estados con poco contenido, ej. Error), lo cual confunde al comparar mockups. El wrapper `Content` (el que va DEBAJO del status bar y ENCIMA del tab bar) usa `height:"fill_container"` para ocupar el espacio restante — así el Tab Bar siempre queda anclado al fondo real de los 972px, sin importar cuanto contenido tenga esa pantalla. Para estados con poco contenido (ej. Error), centrar el bloque de contenido dentro de `Content` con `justifyContent:"center"` en vez de dejarlo pegado arriba con espacio muerto abajo.

---

## Modo claro + oscuro

Toda pantalla se construye UNA vez en claro con todos los fills enlazados a variables (nunca hex literal, salvo casos documentados como `on-primary` a traves de opacidad). La version oscura se genera con `Copy()` del frame raiz + `theme: {mode: "dark"}` — no se redibuja a mano. Si una pantalla nueva no se recolorea sola al aplicar el tema oscuro, es señal de que algo quedo hardcodeado en vez de referenciar una variable.

---

## Componentes reutilizables (Pencil)

Viven como frames `reusable:true` en `billetudo.pen`. Instanciar con `ref` + `descendants`, nunca duplicar la estructura a mano.

### Patron de seleccion en grids (icono vs. color)
Cuando un grid permite elegir una opcion (ej. icono de cuenta, color de cuenta), el tratamiento del item seleccionado depende de que se esta mostrando, no es un patron unico:
- **Iconos**: fondo `$primary-soft` + borde `$primary` + icono en `$primary-on-soft` (mismo criterio que `Category Chip`).

**Estado seleccionado cuando la entidad NO tiene color propio (regla critica).** `$muted` y `$primary-soft` son **el mismo hex** en claro (`#EEECFB`) y en oscuro (`#26243B`). Por eso:

- Si la entidad **tiene color** (categorias, cuentas), el seleccionado se dibuja con su par cromatico: `fill $<color>-soft` + `stroke $<color>` (ej. `$sky-soft` + `$sky` en `lAxmS`). Se distingue del reposo porque es **otra familia de color**, no por el tono.
- Si la entidad **no tiene color** (presupuestos: `Budgets` guarda `icon` pero no `color`), su "soft" es `$primary-soft` — hex-identico a `$muted`. Pintar el seleccionado con `$primary-soft` lo deja **visualmente identico al reposo**, y el estado queda cifrado solo en el anillo. En ese caso el seleccionado va **hueco**: `fill $surface` + `stroke $primary` 2. Ejemplo: `XsnnD/x9w2F`.
- La misma trampa aplica a cualquier par seleccionado/inactivo que intente distinguirse con esos dos tokens: ya paso en `Scheduled Filter Chips`, donde el estado se cifraba solo en el color del label (fallo WCAG 1.4.1) y hubo que anadir borde. **Antes de usar `$primary-soft` vs `$muted` como senal de estado, comprueba que no sean el mismo valor** — no lo son en ningun tema.
- **Colores solidos** (swatches): un check superpuesto en `$on-primary`, sin fondo `-soft` extra (el color solido ya comunica suficiente, agregar fondo tenue detras de un color solido es redundante).
- **Filas de texto/lista** (ej. selector de moneda): check a la derecha de la fila, sin cambiar el fondo de toda la fila.
Es intencional que varien segun el tipo de contenido — no "corregir" para forzar un patron unico entre estos tres casos.

### Category Row
Fila de categoria de gasto: icono + nombre + contador de movimientos + monto + porcentaje + barra de progreso.

- **Overrides por instancia:** icono (`icon`, `fill`), fondo del icon-wrap (`fill`), nombre, contador, monto, porcentaje, y **ancho en px del relleno de la barra**.
- **Formula del ancho de barra:** `ancho_px = (monto_categoria / monto_total_del_periodo) * ancho_disponible_del_track`. En el layout actual (Card de 350px, padding 18), el track disponible es ~312-314px. Documentado tambien como `context` en el nodo `Fill` del componente — si cambia el padding del Card, hay que recalcular.
- **Limitacion conocida de la herramienta:** si se sobreescribe el nombre con un texto largo via `descendants` en una instancia, Pencil no recalcula el wrap correctamente en el canvas (se ve superpuesto). Verificado que la MISMA estructura sin instancia (`ref`) sí ajusta bien — es un artefacto del editor, no del componente. En Flutter, implementar como `Text` normal con `maxLines: 2, overflow: TextOverflow.ellipsis` dentro de un `Expanded`; funcionara sin problema.
- **Contraste:** icono siempre debe dar >=3:1 contra su `-soft` de fondo. Por eso `mint`/`sky`/`peach` en claro estan mas oscuros que su primer intento.

### AI Question Chip
Chip de pregunta sugerida para el asistente "Billetudo". Texto + flecha, fondo `surface`.

- Padding `[14,16]` (subido desde `[11,14]`) para cumplir el tap target minimo de 44pt de alto — hallazgo de la revision UX, corregido a nivel de componente (afecta ambas instancias/pantallas automaticamente).

### Tab Bar
Navegacion inferior de 5 destinos (Inicio, Movimientos, Presupuestos, Metas, Mas), estilo flotante tipo "Liquid Glass".

- **Overrides por instancia:** que tab esta activo (`fill` del item a `$muted`, `fill` de icono/label a `$primary`; el resto queda en `$text-secondary`/transparente por defecto).
- **Pendiente/anotado, no bloqueante:** 3 de los 5 items (Inicio, Metas, Mas) tienen un frame de contenido visual bajo 44pt de ANCHO (el alto si cumple, 47px). Al implementar en Flutter, el `InkWell`/`GestureDetector` debe cubrir el slot completo distribuido por `space_around` (~72-76px), no solo el contenido visible del icono+label.

### Page Header
Header de subpantalla (no es un destino de tab): boton "atras" (o "x" para modales/formularios), titulo centrado en el flujo, boton de accion a la derecha (agregar, guardar/check).

- **Overrides tipicos:** icono del boton de atras (`arrow-left` para volver, `x` para cerrar un modal/formulario), titulo, icono del boton de accion (`plus` para agregar, `check` para guardar).
- **Regla de navegacion:** toda pantalla con `Page Header` (boton atras/cerrar) NO lleva `Tab Bar` — son pantallas apiladas (push/modal), no destinos de tab. Solo Inicio, Transacciones/Movimientos, Presupuestos y Metas (los 5 items del Tab Bar) usan su propio header custom + `Tab Bar`.
- **Centrado real del titulo:** boton de atras y boton de accion miden AMBOS 44x44 (antes el de atras media 40x40, descentraba el titulo en pantallas con texto largo — corregido). El `Title` usa `textGrowth:"fixed-width"` + `width:"fill_container"` + `textAlign:"center"`, nunca `textGrowth:"auto"` — asi se centra en el espacio real entre botones en vez de depender solo de que ambos lados midan igual. Si un lado no tiene accion (ej. pantallas sin boton `+`), usar un spacer `enabled:false` de 44x44 en su lugar, nunca quitar el nodo — si se quita, el titulo se descentra.

### Button/Primary y Button/Secondary
CTA principal (fill `$primary`) y secundario (outline, `$surface` + `$border`). Icono opcional a la izquierda (`enabled:false` para ocultarlo, ej. en `Button/Secondary` de "Cancelar").

### Status Bar/Android y Status Bar/iOS
Barra de estado simulada (hora + iconos de senal/wifi/bateria) que corona cada mockup de pantalla. Dos variantes intercambiables, mismo chrome externo (`height:62`, `padding:[16,24,0,24]`, `width` override a `fill_container` por instancia).

- **Status Bar/Android**: hora alineada a la izquierda + iconos lucide `signal`/`wifi`/`battery-full` a la derecha (`$text-primary`, 16x16, gap 6). Variante por defecto en todas las instancias existentes.
- **Status Bar/iOS**: hora centrada (spacer invisible de 60px a la izquierda balanceando el ancho del grupo de iconos de la derecha, texto con `textAlign:center` en un contenedor `fill_container`) + iconos lucide `signal-high` (barras, estilo Apple)/`wifi`/`battery-full`.
- **Overrides tipicos:** ninguno mas alla de `width:"fill_container"` al instanciar dentro de una pantalla — el contenido (hora "9:41", iconos) es fijo por convencion de mockup.
- Convertido a componente reusable (antes duplicado a mano en ~65 frames) — todas las instancias existentes usan `Status Bar/Android`; `Status Bar/iOS` queda disponible sin usar todavia, para cuando se quiera mostrar contexto iOS especificamente.

### Form Field
Campo de formulario: label + caja de input (icono opcional + valor/placeholder) + texto de error opcional (`enabled:false` por defecto, fill `$expense`).

- **Overrides tipicos:** label, icono (`enabled:true/false`), contenido del valor, y activar `Error` con su mensaje cuando la validacion falla — no crear una variante de componente separada para el estado de error, es el mismo Form Field con ese nodo habilitado.

### Bottom Sheet Base
Panel que sube desde abajo — patron obligatorio para confirmaciones/selectores en mobile (nunca modal/dialog centrado, ver regla de patrones mobile mas abajo). Estructura: `Overlay` (`fill:$scrim`, `justifyContent:end`, cubre toda la pantalla) → `Sheet` (`fill:$surface`, `cornerRadius:[28,28,0,0]` — solo esquinas superiores, `padding:[12,20,28,20]`, `gap:16`) → `Handle Wrap` (barra `$border` de agarre, centrada) + **`Content Slot`** (vacio en el componente base; cada instancia reemplaza este slot via `Replace()` con su titulo/icono/mensaje/lista/grid + fila de botones especifica).

- El componente base NO impone un "Title" fijo — algunas instancias usan titulo de texto simple (ej. Selector de Moneda), otras usan icono+mensaje sin titulo (ej. Confirmar Eliminar). Cada instancia decide la forma de su contenido, el slot solo fija el chrome compartido (scrim, radios, handle, padding).
- Instancias existentes: Confirmar Eliminar (`oymM5`), Confirmar Archivar (`o8dBmH`), Confirmar Cambio tipo/moneda (`SpjqW`), Selector de Moneda (`rCY7Q`), Selector de Dia (`tYzxA`), No se Puede Eliminar (`Yc1U2`). (El Selector de Icono y Color se descarto — las cuentas usan icono/color estandar segun tipo, sin personalizacion.)
- Al crear un nuevo bottom sheet, SIEMPRE instanciar este componente (`ref` + `Replace()` del slot) — nunca reconstruir el `Overlay`/`Sheet`/`Handle` a mano de nuevo.

### Balance Card Hero (`o8HEx`)
Bloque protagonista de saldo con soporte de carrusel (usado en Detalle de tarjeta de credito): `Hero Figure` (Label + Value + `Badge Sobrecupo` opcional + 2 Dots) + `Progress` (Track/Fill + Caption).

- **Overrides:** `Label`/`Value` (content), `Value` fill (`$text-primary` para cifras positivas como "Cupo disponible", `$expense` para "Deuda actual" — nunca al reves), `Badge Sobrecupo` (`enabled:true/false`), `Dot 1`/`Dot 2` (fill `$primary` el activo / `$muted` el inactivo — el orden de los dots es fijo, se controla cual esta activo por fill, no por posicion), `Fill` de la barra (`width` en px + fill `$primary` normal / `$expense` si hay sobrecupo), `Caption` (content).
- Instancias: Detalle Tarjeta (`G5PvVM` → `o6LMZ`), referencia de carrusel pagina 2 (`YXUj5` → `jb3yI`), Detalle Tarjeta Sobrecupo (`qhp7k` → `ta3oh`), referencia de sobrecupo standalone (`w17FA9` → `P1Eh9`).

### Empty State (`jmQO5`)
Estado vacio generico: `Icon Circle` (88px, `$primary-soft`) + `Icon` + `Message` + `CTA Button` opcional (ref a `Button/Primary`).

- **Overrides:** `Icon` (icono lucide), `Message` (content), `CTA Button` (`enabled:true/false` + descendants de label/icono — `false` cuando no hay accion posible desde ese estado, ej. Archivadas vacio).
- Instancias: Cuentas vacio (`nwFMA` → `w5Vx99`, con CTA "Agregar cuenta"), Archivadas vacio (`eAwin` → `pBSNN`, sin CTA).
- **NO fusionado con el Error de Cuentas** (`L6Za0`): estructuralmente distinto (card `$surface` envolvente con padding, Titulo + Subtitulo separados, icon-wrap 56px `$muted` en vez de 88px `$primary-soft`) — replica a proposito el patron ya usado sin componentizar en el Error de Inicio. Si se decide unificar a futuro, decidir primero si el Error de Inicio tambien se componentiza.

### Sheet Buttons Row (`Ot4yI`)
Fila de 2 botones para bottom sheets: `Left Button` (ref `Button/Secondary` por defecto) + `Right Button` (ref `Button/Primary` por defecto).

- **Overrides:** label/icono de cada boton via paths anidados (ver regla tecnica de Pencil mas abajo). El fill/tipo de cada slot puede invertirse (ej. en "No se Puede Eliminar" el boton izquierdo es `Button/Primary` "Entendido" y el derecho es `Button/Secondary` "+ Crear cuenta") reemplazando el `type` completo del descendant, no solo sus props.
- Instancias: Confirmar Eliminar (`oymM5` → `bjzFi`), Confirmar Archivar (`o8dBmH` → `rbQSQ`), Confirmar Cambio (`SpjqW` → `tWgZw`), No se Puede Eliminar (`Yc1U2` → `sruRv`).

### Skeleton Row (`CKnQC`)
Fila de carga: Icon Wrap circular + Mid (Skeleton Name + Skeleton Type) + Skeleton Balance, todo en `$border`.

- **Overrides:** `width` de `Skeleton Name`/`Skeleton Type` (variar longitud entre filas para que no se vea repetitivo).
- Instancias: las 4 filas de `Cuentas — Carga` (`sh7r2` → `T6mGl`, `a0PS83`, `OBCP0`, `BpBqq`).
- **Es una tarjeta** (`$surface` + borde + radio) — correcto para skeletons de `Account Card` (que SON tarjetas). Para skeletons de `Transaction Row` (filas planas) usar `Transaction Skeleton Row`, no este.

### Transaction Skeleton Row (`gDAqP`)
Fila de carga PLANA (sin card envolvente) que imita la geometria de `Transaction Row`: circulo de icono 44x44 + Mid (2 lineas) + bloque de monto a la derecha, todo en `$skeleton`.

- **Overrides:** ancho de las 2 lineas (variar entre filas para que no se vea repetitivo).
- Instancias: las 5 filas de `Inicio - Carga` (`AmifS`/`Y5TnWd`).
- **Regla:** el skeleton debe imitar la geometria REAL de lo que carga. `Transaction Row` es una fila plana, asi que su skeleton es plano — no reusar `Skeleton Row` (`CKnQC`, que es tarjeta) aqui.

### Archived Account Row (`VS0d0`)
`Account Card` (ref `Q1ynM`) + `Footer` (icono + label, borde superior) integrados en un solo contenedor visual — evita que la accion del footer se vea "perdida" separada de la tarjeta.

- **Overrides:** todos los de `Account Card` (icono, tipo, monto, nombre) + `Footer Icon`/`Footer Label` (pensado para reusarse con otras acciones de footer a futuro, no solo "Desarchivar").
- Instancias: `Cuentas — Archivadas` (`ft48Z` → `ilgyG`, `cOP8K`).

### Day Cell (`gVeaW`)
Celda de dia del selector de calendario: circulo 44x44 + numero.

- **Overrides:** `Num` (content + fill), fill del contenedor (`$primary` si seleccionado / transparente si no), `fontWeight` del numero (700 seleccionado / 500 normal).
- Instancias: las 31 celdas de `Cuentas — Selector de Dia` (`tYzxA`).

### Currency Row (`Q6KVp`)
Fila de selector de moneda: Icon Wrap (codigo de 3 letras) + Label + Check (visible solo si seleccionada). Sigue el patron ya documentado arriba ("Filas de texto/lista: check a la derecha").

- **Overrides:** `Icon Wrap` fill (`$primary-soft`/`$muted`), `Code` (content + fill), `Label` (content), icono `check` (`enabled:true/false` + fill).
- Instancias: `Cuentas — Selector de Moneda` (`rCY7Q` → `k30ZI` COP seleccionada, `P2e7A6` USD sin seleccionar).

### Regla tecnica de Pencil: overrides anidados en instancias
Al hacer `descendants` sobre una instancia que a su vez contiene otra instancia anidada (ej. `Sheet Buttons Row` conteniendo un `Button/Primary`), un `descendants` anidado dos niveles (`descendants:{"hijoId":{descendants:{...}}}`) NO se aplica sobre nodos ya existentes. Usar en su lugar `Update("instancia/hijoId/nietoId", {...})` con el path explicito completo. Los overrides anidados en un solo nivel SOLO funcionan cuando van dentro de un reemplazo completo de `type` (ej. cambiar que componente referencia un slot), no para modificar props de un descendant ya instanciado.

### Segmented Control (`hFu41`)
Selector de 3 opciones tipo iOS (usado para Gasto/Ingreso/Transferencia en el formulario de transaccion). El segmento activo tiene fondo `$surface` y texto en su color semantico (`$text-primary` gasto neutral / `$income` ingreso / `$primary` transferencia — nunca `$expense` rojo, mismo criterio que `Transaction Row`); los inactivos son transparentes con texto `$text-secondary`.

- Al reusar para otro contexto de 3 opciones, mantener el patron fondo-solido-en-activo — no introducir un cuarto tratamiento visual.
- **Tap target:** el padding vertical interno de cada segmento se ajusto a `[14,8]` para que el area tocable real sea 44px de alto (antes el contenedor medía 44px pero el padding dejaba solo 36px tocables — hallazgo de `ui-ux-reviewer` en el formulario de Transacciones, corregido a nivel de componente).

### Account Card
Fila de cuenta: icono + nombre + tipo de cuenta + saldo (rojo/`$expense` si es negativo, ej. deuda de tarjeta de credito; `$text-primary` si es positivo).

### Transaction Row
Fila de transaccion individual: icono de categoria + descripcion + "cuenta . fecha" + monto (verde/`$income` si es ingreso, `$text-primary` si es gasto — deliberadamente NO se usa `$expense` rojo para gastos normales, ver Tono de marca).

- Distinto de `Category Row`: no tiene barra de progreso ni porcentaje, es una transaccion puntual no un agregado por categoria.

### Category Chip (`mK8oI`)
Chip pequeño reusado en dos contextos: selector de tipo de cuenta (Agregar Cuenta) y selector/gestion de categoria (Nueva Transaccion, Categorias). Icono en circulo + label debajo, estado seleccionado = fondo `-soft` + borde solido del color de la categoria; no seleccionado = fondo `$muted`, sin borde.

- **Label:** 13px/700 (subido desde 11px/600 — es contenido primario, el nombre de la categoria, no metadata; MASTER reserva 11-12px solo para metadata).
- **Contraste en seleccionado:** usar `$primary-on-soft-strong` en vez de `$primary-on-soft` para el label (a 13px, `primary-on-soft` sobre `primary-soft`/`background` no alcanza 4.5:1 — ver fila de la tabla de paleta arriba).

---

## Estados de pantalla (Inicio)

Toda pantalla que carga datos de forma async debe considerar sus estados (con datos / vacio / carga; error solo si de verdad puede quedarse sin datos). **Inicio** se rediseño (composicion "actividad primero", ver `pages/inicio.md`) y es la referencia de este patron — 8 frames en `billetudo.pen` (4 estados x 2 temas):

| Estado | Frame claro | Frame oscuro | Que cambia |
|--------|-------------|---------------|------------|
| Con datos (con presupuesto) | `aOhoY` | `ls7Ed` | Hero con gasto real + barra de presupuesto, movimientos recientes, banner IA. |
| Con datos (sin presupuesto) | `A9v7s` | `hceQ1` | Igual, pero el hero muestra invitacion a crear presupuesto en vez de barra. |
| Vacio | `DliNF` | `dJDHi` | Hero en `$0` + mensaje neutral (no punitivo); bloque de movimientos reemplazado por `Empty State` (icono + mensaje + CTA "Agregar movimiento"). |
| Carga | `AmifS` | `Y5TnWd` | Skeleton: hero y 5 `Transaction Skeleton Row` planas (bloques `$skeleton`), misma geometria que el estado con datos. |

**Inicio NO tiene estado de Error de pantalla completa** (el diseño viejo si; se descarto): es local-first, el Home no se vacia sin conexion, y un fallo de sync se comunica con un **indicador discreto** (HU-10 en `docs/requirements/04-inicio.md`). Otras features pueden tener su propio estado de error solo si de verdad pueden quedarse sin datos.

Status bar, header (saludo + avatar + campana), Tab Bar y FAB se mantienen IGUALES en todos los estados — solo cambia el area de contenido (Hero + movimientos + banner). Replicar este patron para Movimientos/Presupuestos/Metas: la unica parte de la pantalla que entra en estado vacio/carga es el area de datos, nunca el chrome de navegacion.

---

## Accesibilidad — reglas aprendidas (no repetir estos errores)

Una revision UX adversarial (agente `ui-ux-reviewer`) encontro y se corrigieron estos problemas reales; quedan como reglas para toda pantalla nueva:

1. **Nunca poner texto/iconos sobre el extremo `primary-light` de un degradado.** Un blanco 100% opaco sobre `primary-light` (`#A78BFA`) da ~2.7:1, insuficiente incluso para texto grande (necesita 3:1) y muy por debajo de 4.5:1 para texto normal. Todo degradado que lleve texto/iconos encima debe ir entre `primary-deep` y `primary` unicamente (nunca `primary-light`). `primary-light` solo para decoracion sin contenido encima.
2. **No usar opacidad variable como sustituto de contraste real.** Se encontraron 3 valores distintos (`#FFFFFFCC/DD/E0`) para el "mismo" texto secundario sobre el Hero — corregir una instancia no corregia las demas. Usar `$on-primary` solido y diferenciar jerarquia con tamano/peso de fuente, no con opacidad.
3. **Los colores de categoria deben cumplir 3:1 contra su propio fondo `-soft`, no solo verse bien sobre blanco/superficie.** Revisar cada par color/tinte en AMBOS temas — un color puede pasar en oscuro y fallar en claro con el mismo par de tokens (paso con `mint`/`sky`/`peach`).
4. **Tap targets minimos 44x44pt** — verificar alto Y ancho del area interactiva real (no solo del contenido visual centrado dentro de ella).
5. **Cuidado con las dos formas de romper el alto de pantalla, son opuestas:** (a) un alto fijo demasiado chico para el contenido real causa **clipping silencioso** que `snapshot_layout` no siempre detecta si `problemsOnly` corre a poca profundidad; (b) dejar que el frame de pantalla use `fit_content` sin mas hace que **cada pantalla/estado tenga un "dispositivo" de tamaño distinto** (un estado con poco contenido, ej. Error, se ve mas corto que el resto), lo cual confunde al comparar mockups. La solucion que se uso: altura fija de 972px en el frame de pantalla (igual en TODAS), con el wrapper `Content` en `height:"fill_container"` para que el Tab Bar siempre quede anclado al fondo real sin importar cuanto contenido tenga esa pantalla especifica. Ver seccion "Radios y espaciado".
6. **No asumir que un "no layout problems" de una sola pasada es suficiente** — probar con contenido largo/real (nombres largos, montos grandes) antes de dar un componente por terminado.
7. **`Page Header` (boton atras/cerrar) y `Tab Bar` son mutuamente excluyentes en una misma pantalla.** Mezclarlos confunde el modelo mental de navegacion (¿esto es un destino de tab o una pantalla apilada?). Decidir esto ANTES de construir la pantalla, no despues.

### Delete Opt-in Row (`S533j9`)

Fila de opt-in para una accion destructiva **opcional** dentro de una hoja cuya accion base NO es destructiva. Hoy la usa Cerrar sesion (HU-06, ver `pages/auth.md`): "Borrar tambien los datos de este telefono".

- **Reposo:** `fill $surface` + `stroke $border` 1px, checkbox vacio con borde `$text-secondary`.
- **Activado (4 overrides, todos de color/visibilidad, ninguno estructural):** root `$expense-soft` + `stroke $expense` 2px; checkbox `fill`/`stroke` `$expense`; glifo `check` visible; titulo `$expense-text`.
- **El area tocable es la fila completa, no el checkbox.** Un checkbox de 24x24 no llega al minimo de 44; el alto de ~112px solo lo cumple si el gesto cubre todo el contenedor.
- **El estado se comunica por tres senales redundantes** — relleno, glifo `check` y borde de 2px — nunca solo por color (WCAG 1.4.1). No simplificar a color.
- **Marcarlo tiene efectos fuera del componente:** muta el CTA de la hoja a `$expense` y recorta el mensaje del header para no prometer algo que la accion ya no cumple. Eso es parte del contrato del opt-in, no del frame que lo contiene.

**No confundir con las filas de opcion de `K8SAG`** (paso 2 de borrar cuenta). Son affordances distintas, no variantes de estilo: alli son **radios** de una eleccion excluyente y deliberadamente **sin default** (regla de no-dark-pattern de HU-07); aca es un **checkbox** de opt-in independiente con default apagado. Se evaluo unificarlos y se descarto: obligaria a reconstruir el subarbol del indicador en cada instancia, y un componente compartido invitaria a copiar el default al lado donde esta prohibido.

---

## Tono de marca

- Nunca colores/iconografia punitiva para gastos (sin rojos de alarma en montos de categoria — se usa `$text-primary`, no `$expense`, para montos normales).
- Estado vacio y error redactados en tono neutral/tranquilizador, nunca culpando al usuario ("Aun no registras gastos", no "No tienes actividad").
- Estado de error recuerda explicitamente que los datos siguen a salvo localmente (coherente con la arquitectura local-first del proyecto).

---

## Inventario de pantallas — Fase 1

Fase 1 (`docs/Plan_Monetizacion_y_Tecnico.md`, seccion Roadmap): registro manual, cuentas, transferencias, categorias con onboarding, presupuestos, metas, deudas, graficas/informes esenciales, import/export, busqueda/filtros, pagos programados, multi-moneda, login social + borrado de cuenta. Se disena por lotes priorizados, empezando por el nucleo de uso diario.

### Lote 1 — Cuentas, Transacciones y Categorias (completo)

Detalle completo en `design-system/billetudo/pages/`. Resumen:

| Area | Pantallas | Estados | Doc |
|------|-----------|---------|-----|
| Cuentas | Lista de cuentas | con datos, vacio, carga | `pages/cuentas.md` |
| Cuentas | Agregar/editar cuenta | formulario (1 estado representativo + patron de error inline) | `pages/cuentas.md` |
| Transacciones | Lista (tab "Movimientos") | con datos, vacio, carga | `pages/transacciones.md` |
| Transacciones | Nueva/editar transaccion | formulario con Segmented Control Gasto/Ingreso/Transferencia | `pages/transacciones.md` |
| Categorias | Gestion de categorias (semillas de onboarding) | con datos (las semillas siempre existen) | `pages/categorias.md` |

Todas construidas en claro + copia con `theme:{mode:"dark"}`, altura de dispositivo fija en 972px, y usando los componentes reutilizables listados arriba (ademas de los 3 de Inicio: `Category Row`, `AI Question Chip`, `Tab Bar`).

### Pendiente (proximos lotes)

Presupuestos, Metas, Deudas, Graficas/Informes, Import/Export, Busqueda/Filtros avanzada, Pagos programados, Multi-moneda (settings), Login social + borrado de cuenta, Onboarding general.

---

## Checklist antes de dar una pantalla por terminada

- [ ] Todos los fills usan variables `$token`, cero hex literal salvo casos documentados (opacidades sobre `on-primary`, decoracion).
- [ ] Copia con `theme:{mode:"dark"}` se ve correcta sin ajustes manuales de color.
- [ ] `snapshot_layout({problemsOnly:true})` sin hallazgos, en profundidad suficiente para llegar a tarjetas anidadas.
- [ ] Contraste de texto/iconos verificado contra el fondo real donde caen (no solo contra la superficie base) en AMBOS temas.
- [ ] Estados vacio/error/carga considerados (aunque sea reutilizando el patron de Inicio).
- [ ] Probado con contenido largo (nombres, montos) antes de instanciar el componente en mas pantallas.
- [ ] Componentes repetidos (>=2 instancias) convertidos a `reusable:true`, no copiados a mano.
