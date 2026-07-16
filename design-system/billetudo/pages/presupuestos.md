# Página: Presupuestos

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** en progreso. La **lista de presupuestos (tema claro, con datos)** está aprobada como base tras auditoría con `ui-ux-reviewer` y varias rondas de refinamiento. Faltan: formulario crear/editar, detalle (+ stepper de periodos), estados vacío/carga, histórico, modo base-cero, y **tema oscuro** (se genera solo al final, cuando el claro esté 100% aprobado). Requisitos de la feature: `docs/requirements/06-presupuestos.md`.

## Frames

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Lista de presupuestos — con datos | `s833Gk` | *pendiente* |
| Componente `Budget Line` (reusable) | `FSL69` | — |

**Navegación:** Presupuestos es **destino de `Tab Bar`** (uno de los 5 ítems). La lista lleva **header custom** ("Presupuestos" + botón `+`) **+ `Tab Bar`**, SIN `Page Header`. El detalle y el formulario (subsecciones) sí usarán `Page Header` con botón atrás, sin `Tab Bar` (mismo patrón que Cuentas).

## Lenguaje visual (aplica a TODAS las pantallas de la feature)

Estas decisiones se tomaron contra el norte de limpieza de **Inicio** (`aOhoY`) — casi todo blanco, un solo acento, mucho aire. Son de obligado cumplimiento en las pantallas que faltan.

### Modelo de color — SOBRIO (no semáforo)
- **Un solo acento de marca:** el progreso "sano" siempre en **violeta `$primary`**. Prohibido verde/ámbar/semáforo por cercanía al límite (se probó y se descartó por ensuciar).
- **Rojo solo en sobregasto (>100%)**, y con la familia **semántica `expense`** (nunca `$coral` decorativo): barra `$expense`, icon-wrap `$expense-soft`, monto y `%` en `$expense-text`. Solo la tarjeta excedida se vuelve roja → el rojo es **señal con significado**, no color ambiental. Nunca pintar el fondo de la tarjeta de rojo.
- **Nunca un badge/pill de color** para el `%` ni chips de color para el alcance (ambos se probaron y ensuciaron). El color vive en la barra/indicador y, en sobregasto, en el texto.

### Copy y tono (positivo, nunca punitivo — CLAUDE.md)
- Dato primario del restante: **"Te quedan $X"** (sano) / **"Excedido por $X"** (sobregasto). **Prohibido "Te pasaste"** (en es-CO se lee como reproche).
- **Ancla temporal del periodo** (en la línea meta), depende de la recurrencia:
  - **Recurrente:** "se reinicia el [fecha]" (ej. "se reinicia el 21") — el borrón y cuenta nueva.
  - **Una única vez (no recurrente):** "termina el [fecha]" — no se reinicia, se acaba en `endDate`.

### Densidad (componente `Budget Line`, `FSL69`)
Cada presupuesto en la lista muestra **3 datos + barra**, no más:
- **Línea 1:** icono + **nombre** (izq) + stack **"Te quedan / $X"** o **"Excedido por / $X"** (der).
- **Línea 2 (meta, 12px `$text-secondary`):** **alcance corto · ancla temporal · %** en una sola línea. El `%` va gris (`$text-secondary`) en sano y rojo (`$expense-text`) en sobregasto.
- **Barra** de progreso delgada.
- **Al detalle, NO a la lista:** gastado, total, periodicidad, umbral de alerta, desglose. La lista es para decidir "¿puedo seguir gastando?", no para el desglose.
- **Icon-wrap neutro `$muted`** idéntico en todas las tarjetas (sin arcoíris de categorías); única excepción: `$expense-soft` en sobregasto.
- Aire: padding de card ~18, gap entre tarjetas ~18, borde `$border` 1px sutil, radio 20, fondo blanco dominante.

### Punto de entrada a crear
Fila-CTA **"+ Nuevo presupuesto"** al final de la lista (círculo `$surface` + `plus`, fondo `$primary-soft`, borde `$primary-light`, label `$primary-on-soft-strong` para pasar contraste). Reemplaza al FAB en esta pantalla.

## Reglas que aplican a las pantallas pendientes (de la auditoría)

- **No hay resumen agregado permanente** ("$X presupuestado este mes" sumando todos los presupuestos): es semánticamente engañoso porque los presupuestos tienen **periodos distintos**, pueden **solaparse** (doble conteo) y ser **multi-moneda**. Un agregado así **solo** es válido en el **modo base-cero** (HU-06), con su framing propio ("ingreso − asignado = sin asignar"). No usarlo como hero de la lista.
- **El stepper de periodo (‹ / ›) es por-presupuesto**, no global: cada presupuesto ancla su propio ciclo (tarjeta 21-20, quincenal, custom), así que un "Julio" global sobre la lista es incorrecto. La navegación entre periodos (HU-05) vive en el **detalle** de cada presupuesto.

## Estados (pendientes de diseñar, tema claro primero)
- **Vacío** (sin presupuestos): componente `Empty State` + CTA "Crear presupuesto".
- **Carga:** skeleton (patrón `Skeleton Row`).
- **Texto largo:** nombre/alcance a una línea con ellipsis (regla de contenido largo de MASTER).

## Pantallas pendientes (roadmap de diseño)
1. **Formulario crear/editar** (HU-01/02/03/09): nombre, monto, alcance (cuentas + categorías, o global), periodicidad, fecha de anclaje, recurrencia (única vez → inicio+fin / recurrente → inicio+periodicidad, "Para Siempre" o fecha fin), umbral de alerta.
2. **Detalle de presupuesto** (HU-04/05/10/11): progreso del periodo vigente, **stepper de periodos** (pasado/futuro), desglose (aquí sí caben gastado/total/periodicidad), acciones editar/**cerrar**/eliminar.
3. **Histórico** de presupuestos cerrados (HU-11), separado de la papelera.
4. **Modo base-cero** (HU-06): "ingreso − asignado = sin asignar".
5. **Tema oscuro** de todo lo anterior (al final, componentizando lo repetido).
