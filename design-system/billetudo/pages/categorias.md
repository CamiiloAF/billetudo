# Pagina: Categorias

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras varias rondas de auditoria adversarial con `ui-ux-reviewer` y correccion con `pencil-designer`.

## Frames

Todas las piezas existen en tema Claro y en su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido/estructura, solo recolorea).

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Listado principal — con datos | `bA51N` | `WIUxb` |
| Listado — vacio | `vH7RI` | `nXifR` |
| Listado — carga | `QZAKU` | `grOKj` |
| Listado — error | `oaBzm` | `FqSWP` |
| Editar subcategoria | `CuTjr` | `UG6js` |
| Editar categoria raiz | `iUmrh` | `sKSQn` |
| Crear categoria (raiz) | `PZvWF` | `GE2wv` |
| Crear subcategoria | `STIfS` | `EEFu8` |
| Confirmar eliminar sin dependientes | `jngMo` | `v1tXr` |
| Confirmar eliminar con transacciones | `snXFk` | `pnE0W` |
| Confirmar eliminar raiz con subcategorias | `w9ixr` | `kYA4E` |
| Selector de categoria padre | `Q55fEz` | `A7pbY3` |
| Selector de icono y color | `lAxmS` | `PtZ2o` |

**Navegacion:** todas usan `Page Header` (boton atras) SIN `Tab Bar` — Categorias es una subseccion, se llega desde el listado o desde el menu "Mas" (mismo criterio que Cuentas). El listado principal (`bA51N`) es la unica excepcion parcial: no lleva `Page Header` clasico, su encabezado es el titulo "Categorias" + boton `+` directo (igual patron que Presupuestos/Metas).

**Organizacion del canvas:** componentes reutilizables en `y:140`. Zona CLARA de Categorias en fila unica (`y:5704`, 13 pantallas, pitch 450px). Zona OSCURA muy por debajo (`y:18386/18456/18576`), justo despues de Cuentas-Oscuro. Regla del proyecto: **el oscuro se genera solo cuando el claro esta 100% aprobado** — nunca en paralelo.

## Listado principal (`bA51N`)

**Decision de diseño (variante ganadora):** se exploraron 3 variantes — tabs subrayado + acordeon, toggle + tarjetas con chips, y lista agrupada sin selector. Se eligio **Toggle (Segmented Control) + Acordeon** (variante 1, con el toggle reemplazando las tabs originales por pedido del usuario). Razon de peso: escalabilidad — con las ~17 categorias raiz de gasto del set semilla, el acordeon colapsado ocupa ~1200px de scroll total vs ~2700px de la variante de tarjetas siempre expandidas; ademas los chips de subcategoria truncaban nombres largos reales del apendice ("Impuestos y matricula (SOAT, revision, etc.)"), cosa que el acordeon con `fill_container`+wrap real no sufre. Variantes descartadas eliminadas del `.pen` (regla: al elegir, se borran las demas de inmediato).

1. Titulo "Categorias" + boton `+` (crear categoria raiz).
2. **Toggle** (`Segmented Control`, componente `hFu41`) Gasto/Ingreso — el 3er segmento "Transferencia" queda oculto (`enabled:false`, `width:0`), ya que las categorias nunca aplican a transferencias.
3. Lista de categorias raiz en **acordeon**: fila con icono+color, nombre, contador de subcategorias, chevron (expandir/colapsar). Una categoria expandida muestra sus subcategorias indentadas + link "Agregar subcategoria". El resto queda colapsado mostrando solo el conteo.
4. **Reordenar (HU-05):** long-press directo sobre una fila raiz, mismo criterio que Cuentas (`Lv1Mh`) — sin icono de grip dedicado (se probo con grip visible y se descarto para mantener consistencia con el patron ya aprobado).

### Estados
- **Vacio** (`vH7RI`): componente `Empty State` (icono `folder-plus`, mensaje "Aun no tienes categorias de gasto/ingreso" segun el tab activo, CTA "Crear categoria"). Solo se disena para el caso borde donde el usuario elimino todas sus categorias de un `kind` — el set semilla (HU-06) asegura que esto no ocurre para un usuario nuevo.
- **Carga** (`QZAKU`): 6 instancias de `Skeleton Row` con anchos variados, misma geometria que las filas reales.
- **Error** (`oaBzm`): tarjeta centrada, icono `triangle-alert` en tono NEUTRAL (`$muted`/`$text-secondary`, no `$expense`), mensaje + recordatorio local-first + boton "Reintentar" — mismo patron que Cuentas.

## Editar / Crear categoria

4 variantes de un mismo formulario base, todas construidas sobre la misma estructura (Apariencia → Nombre → Tipo → [Categoria padre] → Guardar/Eliminar), diferenciadas solo donde el requisito lo exige:

- **Editar subcategoria** (`CuTjr`): tiene campo "Categoria padre" (picker) y el Toggle de Tipo queda **bloqueado** (candado + `opacity:0.55` + caption "Hereda el tipo de la categoria padre — no se puede cambiar en subcategorias"), porque el `kind` de una subcategoria siempre coincide con el de su raiz (regla de negocio HU-02/HU-03).
- **Editar categoria raiz** (`iUmrh`): sin campo de padre. El Toggle de Tipo se bloquea **condicionalmente**: si la raiz tiene subcategorias activas (ej. "Transporte"), queda con el mismo tratamiento de candado que las subcategorias pero con copy propio ("No se puede cambiar el tipo porque tiene subcategorias de gasto. Elimina o reasigna las subcategorias primero.") — evita romper la coherencia de `kind` entre padre e hijas.
- **Crear categoria** (`PZvWF`): variante raiz del estado "vacio" — placeholder en Nombre, Apariencia sin elegir ("Elegir icono y color", icono `sparkles` neutral), Tipo editable (default Gasto), sin link de eliminar.
- **Crear subcategoria** (`STIfS`, cubre HU-02): mismo estado "vacio" que crear raiz, pero con el campo "Categoria padre" **prellenado y no editable** (fondo `$muted`, sin chevron) con la raiz desde la que se creo.

**Toggle "Gasto" ya no es rojo:** el componente base `Segmented Control` (`hFu41`) tenia el label "Gasto" en `$expense` por defecto — se corrigio a `$text-primary` (neutro) directamente en el componente, para que se propague a TODAS sus instancias (Categorias y Transacciones) sin necesitar overrides manuales. Razon: mostrar "Gasto" en rojo en cada pantalla de categorizacion se sentia punitivo, contra el tono de marca de `CLAUDE.md` ("nunca avergonzar al usuario por sus gastos").

### Componente nuevo: `Appearance Field`
Fila reusable (icon-wrap 44x44 + label "Icono y color"/sublabel + chevron) que reemplaza 4 copias manuales casi identicas en los 4 formularios de arriba. Overrides: fill del icon-wrap, icono + su color, label, sublabel (para diferenciar "Toca para cambiar" de datos reales vs "Toca para elegir (opcional)" en el estado vacio).

## Confirmar eliminar (HU-04)

3 bottom sheets, uno por caso del requisito — tono deliberadamente calmado, nunca alarmista, siguiendo `CLAUDE.md`:

- **Sin dependientes** (`jngMo`): icono `trash-2` en `$primary`/`$primary-soft` (no rojo — es reversible via papelera). Mensaje aclara que se puede recuperar despues. Botones Cancelar/Eliminar.
- **Con transacciones asociadas** (`snXFk`): mismo icono neutral + conteo de movimientos. Debajo, 2 opciones tipo radio: "Reasignar a otra categoria" (abre selector, **pendiente de diseñar el picker especifico**) o "Dejar sin categoria" (resuelve directo, `categoryId = null`).
- **Raiz con subcategorias activas** (`w9ixr`): icono `info` (es una restriccion del sistema, no un destructivo directo). Dos acciones navegacionales con peso visual diferenciado: "Reasignar subcategorias" (neutro, `$primary-soft`) y "Eliminar todo en cascada" (fondo `$expense-soft` para diferenciarlo claramente de la opcion segura — ambas se veian con el mismo peso visual en una ronda anterior y se corrigio). Un solo boton "Cancelar" a ancho completo (las 2 acciones reales ya viven arriba).

## Selector de categoria padre (`Q55fEz`)

Bottom sheet, patron tap-para-elegir-y-cerrar (sin boton "Confirmar" explicito, mismo criterio que el Selector de moneda de Cuentas). Solo muestra categorias **raiz** del mismo `kind` que la subcategoria editada (cumple la regla de negocio de coherencia de `kind` y el limite de 2 niveles de jerarquia — HU-02/HU-03). Usa el componente nuevo `Parent Category Row` (icon-wrap + nombre + check a la derecha en la seleccionada).

**Scroll acotado:** el set semilla real tiene ~17 categorias raiz de gasto — el sheet muestra ~6 filas visibles dentro de un viewport con `clip:true` + mascara + icono `chevron-down` como indicador de que hay mas contenido abajo. En Flutter esto es un `ListView`/`Expanded` con altura acotada real, no un recorte fijo.

## Selector de icono y color (`lAxmS`)

Se exploraron y descartaron 2 variantes con catalogo ampliado (grilla+scroll sin buscador vs grilla+scroll+buscador) — se eligio la **sin buscador**. Razon: los 32 iconos ya estan agrupados por afinidad visual (comida/transporte/vehiculo/vivienda, salud/seguros/suscripciones/compras, etc.), un solo swipe cubre el catalogo completo; el buscador no reducia esa carga y ademas no tenia forma de funcionar de verdad (ningun icono tiene un nombre/caption visible que el usuario pudiera escribir).

- **Grilla de iconos:** 32 iconos lucide (componente reusable `Icon Tile`, 60x60), viewport de 320px con scroll acotado (mismo patron del selector de padre). Solo el icono **seleccionado** toma color (fill `$<color>-soft` + stroke `$<color>` + icono `$<color>`) — el resto queda neutro (`$muted`/`$text-secondary`). Antes el seleccionado usaba un acento fijo en `$primary` desconectado del color realmente elegido en la seccion de abajo; se corrigio para que ambos coincidan.
- **Grilla de color:** 7 swatches decorativos (`mint`/`sky`/`peach`/`coral`/`amber`/`teal`/`indigo` — nunca `$primary`, reservado para marca/CTAs). Tratamiento pastel: fondo `$<color>-soft` + punto centrado en `$<color>` (no circulos solidos a color pleno, que generaban ruido visual al estar los 7 uno junto al otro). El seleccionado ademas lleva un anillo `stroke:$<color>` + check en `$<color>` (no `$on-primary`, que no tendria contraste suficiente sobre un fondo pastel claro). Ambas filas usan el mismo `gap:58` fijo y alineacion a la izquierda (antes la fila de 3 colores se estiraba con `space_between` y se veia desordenada frente a la fila de 4).
- **Sin preview separado:** se elimino la fila de preview grande (76px, icono+color combinados) al tope de la pantalla — quedo redundante una vez que el tile seleccionado en la grilla ya refleja el color elegido en tiempo real.

## Componentes reutilizables nuevos de esta feature

Documentados en detalle (estructura + overrides) deben agregarse a `design-system/billetudo/MASTER.md`: `Delete Link` (reemplaza copias sueltas del link "Eliminar X" en Cuentas y Categorias, icono `trash-2`, height:44), `Icon Tile` (grilla de iconos del selector), `Appearance Field` (fila "Icono y color" de los formularios), `Parent Category Row` (fila del selector de categoria padre).

## Tokens de accesibilidad — hallazgo nuevo de esta feature

- **`primary-deep` sobre `$background` falla en oscuro:** el link "Agregar subcategoria" (texto+icono en `$primary-deep`) da ~6.05:1 en claro pero solo ~3.07:1 en oscuro contra `$background` (por debajo del 4.5:1 requerido para texto normal). Corregido en la copia oscura a `$primary-on-soft` (~6.71:1). El claro se queda en `$primary-deep`, que ahi funciona bien. A diferencia de las reglas ya documentadas en MASTER (`primary` sobre `primary-soft`, `expense` puro en texto), este caso es un color de marca puro sobre fondo PLANO (no sobre un `-soft`) — vale la pena que `ui-ux-reviewer` confirme si aplica como regla general a otros links de acento en toda la app.

## Pendientes conocidos (fuera de alcance de diseño, quedan para implementacion)

- **HU-02 — picker de "Reasignar a otra categoria"** desde las pantallas de eliminar (`snXFk`, `w9ixr`): no tiene su propio bottom sheet diseñado; probablemente reusa `Parent Category Row` pero sin filtrar solo por raiz.
- **Interaccion real del acordeon** (expandir/colapsar): hoy 2 estados estaticos ilustrativos (Vehiculo expandido, Comida colapsada). Falta decidir la animacion (`AnimatedSize` sugerido, igual que el pill de tipo de cuenta).
- **Interaccion real del selector de icono/color:** scroll con momentum, tap-to-select en vivo antes de "Guardar" — hoy es un mockup estatico.
- **Disparadores de los bottom sheets** no conectados al flujo real (que condicion exacta muestra cada caso de "Confirmar eliminar") — decision de `flutter-dev`.
- **Confirmacion explicita adicional para "Eliminar en cascada"** (`w9ixr`): el requisito pide friccion extra para esta accion amplia; hoy es un solo tap en la fila — evaluar si necesita un segundo sheet de confirmacion antes de ejecutar.
- **Destino del boton `+`** del header del listado (¿abre directo el formulario de crear raiz, o un selector previo Gasto/Ingreso?) — no definido.
