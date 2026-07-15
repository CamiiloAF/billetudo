# Pagina: Cuentas

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras varias rondas de auditoria adversarial con `ui-ux-reviewer` y correccion con `pencil-designer`.

## Frames

Todas las piezas existen en tema Claro y en su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido/estructura, solo recolorea).

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Lista de cuentas — con datos | `l055o` | `B0q282` |
| Lista de cuentas — vacio | `nwFMA` | `r0Sia5` |
| Lista de cuentas — carga | `sh7r2` | `P9sa2` |
| Lista de cuentas — error | `L6Za0` | `dN9KS` |
| Detalle de cuenta (normal) | `ZCSCc` | `F7nuYK` |
| Detalle de cuenta (tarjeta de credito) | `G5PvVM` | `LjsJ5` |
| Detalle de cuenta (tarjeta) — Sobrecupo | `qhp7k` | `jblVp` |
| Agregar cuenta (formulario vacio) | `CwiKu` | `m7IVFy` |
| Editar cuenta (formulario prellenado) | `xdLeB` | `y2RuL8` |
| Editar cuenta — Tipo de cuenta expandido (referencia) | `jg9DA` | `WAk61` |
| Confirmar eliminar (bottom sheet) | `oymM5` | `gTqr8` |
| Confirmar archivar (bottom sheet) | `o8dBmH` | `Xeu1E` |
| Confirmar cambio de tipo/moneda — HU-06 (bottom sheet) | `SpjqW` | `mnFUb` |
| Selector de moneda — COP/USD (bottom sheet) | `rCY7Q` | `Nm87F` |
| Selector de dia — corte/pago (bottom sheet) | `tYzxA` | `p6SGT` |
| No se puede eliminar la unica cuenta (bottom sheet) | `Yc1U2` | `ObZA9` |
| Cuentas archivadas | `ft48Z` | `b7pEp` |
| Cuentas archivadas — vacio | `eAwin` | `Ag939` |
| Reordenando (referencia de long-press, HU-09) | `Lv1Mh` | `HF6WG` |
| Balance Card — Sobrecupo (referencia standalone) | `P1Eh9` | `W6FBm` |
| Balance Card — Carrusel Pagina 2, Deuda actual (referencia) | `YXUj5` | `XbyYN` |

**Navegacion:** todas usan `Page Header` (boton atras) SIN `Tab Bar` — Cuentas es una subseccion, se llega desde un acceso **temporal** en el Hero de Inicio (nota `P0eUE`, pendiente de reubicar al diseñar Home/menu "Mas").

**Organizacion del canvas:** componentes reutilizables en `y:140`. Zona CLARA de Cuentas en 3 filas anchas (`y:1632/2782/3932`). Zona OSCURA muy por debajo (`y:8000/9150/10300`), separada de Inicio-oscuro (`y:6320`) por un salto grande. Regla del proyecto: **el oscuro se genera solo cuando el claro esta 100% aprobado** — nunca en paralelo.

## Lista de cuentas (`l055o`)

1. `Page Header`: atras + titulo "Cuentas" + boton `+` (agregar cuenta).
2. **Total Card**: gradiente `$primary-deep`→`$primary`, label "Patrimonio total" + monto grande + sub-linea "Deudas: -$X" (`$on-primary`, 13px/500) — distingue activos de pasivos sin necesitar agrupar la lista por tipo.
3. Lista de cuentas, **orden lineal** (soporta HU-09, reordenar por arrastre, sin ambiguedad de grupos):
   - Cuentas normales: instancia de `Account Card`.
   - Tarjeta de credito: instancia de `Credit Card Account Row` (icono + nombre/tipo + deuda `$expense` + barra de cupo usado + cifras Deuda/Cupo disponible).

**Decision de diseño (variante ganadora):** se exploraron una lista plana y una agrupada por tipo. Se eligio la **plana** porque HU-09 mapea 1:1 a una lista lineal y se rompe conceptualmente al agrupar. La ganancia informativa de la agrupada (separar deuda de activos) se logro sin agrupar, con la sub-linea de deuda en el Total Card. Variantes descartadas eliminadas del `.pen` (regla: al elegir, se borran las demas de inmediato).

### Estados
- **Vacio**: usa el componente `Empty State` (icono `landmark` + mensaje "Aun no has agregado ninguna cuenta" + CTA "Agregar cuenta").
- **Carga**: 4 instancias de `Skeleton Row` con la misma geometria que el estado con datos (evita salto visual).
- **Error**: tarjeta centrada, icono `triangle-alert` en tono NEUTRAL (`$muted`/`$text-secondary`, no `$expense` — no es alerta financiera, es error de carga), mensaje + recordatorio local-first ("Tus datos siguen guardados en tu dispositivo") + boton "Reintentar".

## Detalle de cuenta

### Cuenta normal (`ZCSCc`)
`Page Header` → Balance Card simple ("Saldo actual" + monto) → Info Card con filas `Info Row` (institucion, tipo, tasa de interes) + fila especial de numero de cuenta (HU-03: enmascarado `•••••••4321`, boton ojo + copiar, fuera del componente `Info Row` por sus botones, tipografia alineada a mano) → acciones ancladas hacia el fondo (safe-area 34px): `Button/Secondary` "Archivar" + link discreto "Eliminar cuenta ›" (14px/600, `$expense-text`, con chevron — no `$expense` puro, que falla contraste en texto normal).

### Tarjeta de credito (`G5PvVM`)
- **Balance Card en carrusel** (componente `Balance Card Hero`): cifra protagonista centrada que alterna por swipe entre "Cupo disponible" (`$text-primary`, default) y "Deuda actual" (`$expense`), con 2 dots como unico indicador. **Se probaron flechas/chevrons como affordance extra y se descartaron** — el usuario decidio aceptar el riesgo de descubribilidad senalado por `ui-ux-reviewer`, solo dots. Barra de progreso + caption FIJOS abajo, compartidos entre ambas vistas.
- **Sobrecupo real** (`qhp7k`, pantalla completa — no solo referencia): cuando la deuda supera el cupo, el Hero muestra Cupo disponible en `$0`, badge "Sobrecupo" (icono + texto en `$expense-text`, no `$expense` puro — mismo motivo de contraste), barra al 100% en `$expense`, caption breve "Excedido en $150.000".
- Info Card: institucion, tipo, numero enmascarado (`last4` unicamente — HU-03 prohibe guardar el PAN de tarjetas, sin boton ojo/copiar, diferencia intencional), dia de corte, dia de pago, tasa de interes.

## Agregar / Editar cuenta

Separados en 2 pantallas para evitar ambiguedad (un unico frame con datos prellenados bajo el titulo "Nueva cuenta" confundia el estado):
- **Agregar** (`CwiKu`): sin tipo seleccionado (grid neutral de 6 `Category Chip`), campos vacios con placeholder, sin campos condicionales de tarjeta.
- **Editar** (`xdLeB`): datos reales prellenados. Selector de tipo **colapsado en un pill** (icono + nombre + "Cambiar"). Grupo "Datos de la tarjeta" (Cupo maximo, Dia de corte, Dia de pago) con su propio label, consecutivos.
- **Tipo de cuenta expandido** (`jg9DA`, referencia): "Cambiar" expande el grid **inline** dentro del formulario (decision del usuario, no bottom sheet), empujando los demas campos hacia abajo.

**Sin selector de icono/color:** se exploro y se **descarto** (decision del usuario) — las cuentas usan icono/color ESTANDAR, derivado automaticamente del tipo elegido (el icono ya varia por tipo via `Account Card`/`Credit Card Account Row`; no existe personalizacion adicional). Los 4 tokens de paleta que se agregaron para esa feature descartada (`coral`/`amber`/`teal`/`indigo`) quedaron definidos mds sin uso, disponibles para el futuro.

### Campos y iconos (Form Field)
Nombre → `text-cursor-input`. Institucion → `landmark`. Saldo inicial/Cupo maximo → `banknote`/`circle-dollar-sign`. Moneda → `coins` + chevron-down (indica selector). Dia de corte/pago → `calendar`/`calendar-check`. Tasa de interes → **sin icono** (el valor ya muestra "24.5%", el icono `percent` era redundante, se quito).

## Bottom sheets

Todos instancian el componente **`Bottom Sheet Base`**: scrim + Sheet anclado abajo, radios `[28,28,0,0]`, handle. Ver seccion de componentes en `MASTER.md`.

- **Confirmar eliminar** (HU-08): icono `triangle-alert` en `$expense`/`$expense-soft` (destructivo real).
- **Confirmar archivar** (HU-07): icono `archive` en `$primary`/`$primary-on-soft` (reversible, NO rojo). Mensaje aclara que se puede recuperar desde "Cuentas archivadas".
- **Confirmar cambio de tipo/moneda** (HU-06): icono `info`. Boton "Confirmar" con icono `check` (se corrigio un error donde tenia `trash-2` copiado del flujo de eliminar).
- **Selector de moneda**: reducido a solo **COP y USD** (se quitaron MXN/EUR). Patron tap-para-elegir-y-cerrar, sin boton "Confirmar" explicito. Usa el componente `Currency Row`.
- **Selector de dia**: grid 1-31 con componente `Day Cell`. Titulo dinamico ("Dia de corte" / "Dia de pago" segun el campo que lo invoque — el mockup ilustra "Dia de corte"). Se quito la nota explicativa de "si el mes no tiene el dia..." (decision del usuario: caso borde que el sistema resuelve solo, no hace falta explicarlo).
- **No se puede eliminar la unica cuenta** (HU-08): icono `info` neutral (no `$expense`, es una restriccion del sistema, no destructiva). Dos botones: "Entendido" como **primario** (la accion segura de cerrar) + "Crear cuenta" como secundario (jerarquia invertida tras revision: en un dialogo bloqueante, cerrar debe ser la accion dominante, no navegar 3 niveles de stacking).

## Cuentas archivadas (HU-07)

- **Con datos** (`ft48Z`): lista con componente `Archived Account Row` (Account Card + footer "Desarchivar" integrados en un solo contenedor visual — se corrigio porque el footer suelto se sentia "perdido" sin conexion con la tarjeta). Boton `+` del header reemplazado por un spacer real (`enabled:false`, NO oculto con `fill:$background`, para no dejar una zona de tap fantasma/focuseable vacia para lectores de pantalla).
- **Vacio** (`eAwin`): componente `Empty State` sin CTA (archivar no se inicia desde esta vista).

## Reordenar (HU-09)

Decision: **long-press directo** sobre una fila (no un modo "Editar" separado; Archivar/Eliminar siguen viviendo en el Detalle de cada cuenta). Referencia visual (`Lv1Mh`): fila elevada con sombra simulando el instante de arrastre + "landing slot" con borde punteado indicando donde caeria.

## Componentes reutilizables nuevos de esta feature

Documentados en detalle (estructura + overrides) en `design-system/billetudo/MASTER.md`: `Credit Card Account Row`, `Info Row`, `Bottom Sheet Base`, `Balance Card Hero`, `Empty State`, `Sheet Buttons Row`, `Skeleton Row`, `Archived Account Row`, `Day Cell`, `Currency Row`.

## Tokens de accesibilidad nuevos (documentados en `MASTER.md`)

- **`primary-on-soft`**: reemplaza a `$primary` cuando texto/icono va SOBRE fondo `$primary-soft` (o `$surface` en el caso del footer de Archivadas) — `$primary` puro falla contraste en oscuro (~2.75:1). Se encontro y corrigio reintroducido en 5 componentes (`Account Card`, `Credit Card Account Row`, `Empty State`, `Archived Account Row`) durante la generacion de oscuro — quedo resuelto a nivel de componente.
- **`expense-text`**: reemplaza a `$expense` para texto/icono chico destructivo o de alerta (link "Eliminar cuenta", badge "Sobrecupo") — `$expense` puro no llega a 4.5:1 en ningun tema para contenido de tamaño normal.
- **Page Header centrado real**: boton atras y boton de accion miden AMBOS 44x44 (antes el de atras media 40x40, descentraba el titulo). El `Title` usa `textGrowth:"fixed-width"` + `textAlign:"center"`, nunca `"auto"`.

## Pendientes conocidos (fuera de alcance de diseño, quedan para implementacion)

- **Interaccion real de expandir/colapsar** el pill de "Tipo de cuenta": hoy 2 estados estaticos (`xdLeB` colapsado, `jg9DA` expandido). Falta decidir la animacion (`AnimatedSize` sugerido).
- **Interaccion real del carrusel** del Balance Card de tarjeta: 2 estados estaticos. Falta decidir el mecanismo (`PageView` sugerido) y si los dots son interactivos.
- **Disparadores de los bottom sheets** no conectados al flujo real (que accion exacta abre cada uno) — decision de `flutter-dev`.
- **Acceso definitivo desde Home**: hoy es un link temporal en el Hero de Inicio, pendiente de reubicar cuando se diseñe esa feature.
- **HU-05** (selector multi-cuenta / vista combinada de transacciones): vive en la feature de Transacciones, no en Cuentas — fuera de alcance de este documento.
- Confirmacion visual "Copiado" al copiar numero de cuenta + limpieza de portapapeles a 60s (HU-03): interaccion, no diseño estatico.
