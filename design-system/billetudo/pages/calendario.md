# Componente transversal: Selector de fecha (Month Calendar)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** documentación retroactiva. La vista de año y la estabilización de altura ya están
**implementadas y aprobadas en Flutter** (`lib/core/widgets/month_calendar.dart`) — el usuario
aprobó ambos temas a partir de un screenshot de los golden tests, no de un frame Pencil previo al
build. Es el caso inverso al flujo normal "Pencil primero, código después" (ver CLAUDE.md, sección
Diseño/UI): aquí el `.pen` se puso al día con lo que ya se construyó y se validó en código, el
mismo tipo de secuencia que ya se documentó para otras derivas del proyecto (ver "Gate de acceso a
Pencil" en CLAUDE.md). No es una variante a elegir; es la constancia en el sistema de diseño de una
decisión ya cerrada.

Componente compartido, usado por Deudas, Metas, Presupuestos, Transacciones y Pagos Programados
(cualquier feature con selector de fecha vía `MonthCalendar`).

## Piezas en `billetudo.pen`

| Pieza | Node ID | Tipo |
|---|---|---|
| Date Picker Sheet (base, vista de mes) | `zMqxt` | reusable |
| Month Calendar (vista de mes) | `w4yuu` | reusable |
| Day Cell | `gVeaW` | reusable |
| **Year Cell** (nuevo) | `fGtqp` | reusable |
| **Year Calendar** (nuevo) | `pLyUt` | reusable |
| **Date Picker Sheet · Vista de año (Claro)** (nuevo) | `KBoJZ` | instancia de `zMqxt` |
| **Date Picker Sheet · Vista de año (Oscuro)** (nuevo) | `lmsrC` | instancia de `zMqxt` |

## Patrón: vista de año

Al tocar el label "mes año" del header de `Month Calendar` (antes texto plano, ahora tappable),
el sheet cambia de la grilla de días a una **grilla de años**:

- **Grid 3 columnas × 4 filas** (12 celdas = 1 "bloque" de 12 años), cada celda es una instancia de
  `Year Cell` (`fGtqp`): rectángulo redondeado `height:56` + `cornerRadius:16` (NO píldora — corregido
  tras hallazgo de `ui-ux-reviewer`, el original usaba 48/24 que dibujaba un stadium), texto 15/600
  `$text-primary` en reposo.
- **Navegación por bloque**: `Year Nav` (dentro de `Year Calendar`/`pLyUt`) replica el
  chrome exacto de `Month Nav` — `$surface` + `$border` 1px, radio 16, padding 6, chevrons
  `chevron-left`/`chevron-right` en botones de 44×44 — con un label central (`Block Label`) tipo
  "2020 – 2031" que salta de bloque en bloque (12 años a la vez) al tocar las flechas.
- **Año seleccionado**: celda rellena `$primary`, texto `$on-primary` en 700 — mismo criterio de
  contraste ya usado en `Day Cell` (`$primary` sólido + `$on-primary` sobre él, nunca sobre
  `primary-light`).
- **Año actual, no seleccionado** (tercer estado, instanciado en 2025): fondo transparente + anillo
  `stroke:$primary`/`strokeWidth:1` + texto 600 — mismo lenguaje que el anillo de "Hoy" en `Day Cell`
  (`QQvU5` dentro de `w4yuu`).
- **Al elegir un año**, el sheet vuelve a la vista de mes ya posicionada en enero (o el mes que
  estaba activo) de ese año — no hay paso de confirmación intermedio en la vista de año.

En el `.pen`, `KBoJZ`/`lmsrC` son instancias del mismo `Date Picker Sheet` base (`zMqxt`) con un
solo override real: el slot que en la vista de mes aloja `Month Calendar` aloja aquí `Year Calendar`.
El título del header se mantiene "Elegir fecha" en ambas vistas (corregido tras hallazgo de
`ui-ux-reviewer`: en el código real, `date_picker_sheet.dart` usa siempre `l10n.datePickerTitle` sin
importar la vista — "Elegir año" es el tooltip del label mes/año tappable, `datePickerSelectYear`,
no el título del sheet). El resto del chrome (Overlay/Sheet/Handle de `Bottom Sheet Base`, `Hoy Chip`,
`Sheet Buttons Row` con Cancelar/Confirmar) es idéntico al de la vista de mes — verificado contra
`date_picker_sheet.dart`: Cancelar/Confirmar viven fuera de `MonthCalendar` y no cambian entre vista
de mes/año.

## Estabilización de altura del sheet

La vista de mes **siempre reserva 6 filas de semana**, sin importar cuántas semanas tenga el mes
visible (meses de 4 o 5 semanas ya no encogen/expanden el sheet). Esto evita que el bottom sheet
"salte" de alto al navegar entre meses. **No se rehizo el mockup existente (`w4yuu`) para reflejar
esto visualmente** — julio 2026 en el `.pen` sigue mostrando 5 filas, que es lo que ese mes
concreto necesita; la regla de 6 filas fijas es un comportamiento de layout en código
(`month_calendar.dart`), documentado aquí como referencia para quien lo implemente en otra
pantalla, no como algo que cada mockup estático deba mostrar literalmente.

## Pantallas que heredan este patrón

Cualquier feature con selector de fecha vía el widget compartido `MonthCalendar`:
Deudas, Metas, Presupuestos, Transacciones, Pagos Programados.

## Pendiente / decisiones abiertas

- No se añadió affordance visual (ej. `chevron-down`) al label "mes año" de `Month Calendar` para
  indicar que es tappable — cambiarlo tocaría un componente muy instanciado (`w4yuu`) con overrides
  reales en 5 features; ver la regla técnica de "NUNCA reestructurar un componente con overrides"
  en MASTER.md. Si se quiere el afordance en Pencil, se decide y ejecuta aparte.
- No existe ninguna instancia real de `zMqxt`/`w4yuu` en pantallas de features (Deudas/Metas/
  Presupuestos/Transacciones/Pagos Programados) dentro del `.pen` — viven solo como componentes de
  biblioteca sin `ref` en pantallas concretas. Preexistente al presente cambio, no introducido por
  esta ronda de documentación.
