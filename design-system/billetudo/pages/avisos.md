# Página: Centro de avisos

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Requisitos:
`docs/requirements/fase-2/19-notificaciones-bancarias.md` (HU-04, HU-05, HU-07, HU-10).
Pantalla: **Centro de avisos** (`/avisos`), frame `Bk8zW` (claro) y su gemela oscura.

**Estado (2026-11-07):** pantalla y tarjetas ya construidas y aprobadas (2026-09-09). Esta
spec se crea al cerrar una acción nueva: **descartar una captura con swipe**, aprobada por el
usuario en claro y oscuro. Todo el resto del documento es el estado vigente del canvas, no una
propuesta.

## Estructura de la pantalla

Pantalla completa apilada (ruta propia, no bottom sheet), `Page Header` (`Dtm0X`) con back y
sin Tab Bar. Dos secciones: "Avisos" (fase 3, cobros/metas — todavía sin contenido en app) y
"Capturas por confirmar" (HU-04/HU-05). Ver el `context` de `Bk8zW` para las reglas de
jerarquía, topes por sección y presupuesto medido; siguen vigentes.

## Familia de tarjetas de captura

| Nodo | Pieza | Notas |
|---|---|---|
| `skjlg` | `Pending Capture Card` (Centro de avisos) | `$surface` + `$border` 1px + radio 16, carril 4px `$primary-on-soft`, sin tinte, sin botón; la tarjeta entera navega al formulario pre-llenado. |
| `RSizy` | `Grouped Capture Card` (billetera + banco) | Misma familia, tira de procedencia; también tocable entera. |
| `EqRlj` | Posible duplicado | Ámbar + dos acciones excluyentes ("Es la misma" / "Es otra compra"). |
| `vRWd5` | `MovementPendingCaptureCard` (Movimientos) | Fuera de alcance de esta acción. |

## Acción nueva: descartar con swipe (aprobada 2026-11-07)

**Estado de los frames:** a la fecha de este cambio, la sección de referencia
("CAPTURAS · Descartar con swipe — C", claro y oscuro) fue dibujada y aprobada en Pencil, pero
**no quedó persistida en `billetudo.pen`**: la app tenía dos pestañas del mismo archivo y la que
se guardó era una versión desincronizada (los frames que la otra sesión había commiteado no
estaban en ese documento). Restaurar/crear la sección es un pendiente de tooling, no de diseño;
los ids citados en este documento son provisionales. Los **goldens** del estado swipe
(`capture_swipe_action_{light,dark}.png`) son la referencia determinista que ya vive en el repo.
Los componentes `skjlg` y `RSizy` **no cambian**: su estado en reposo es el aprobado y sigue
siendo el único que existe en la tarjeta.

**Por qué swipe.** La tarjeta ya lleva cinco señales de "esto no es dinero" y un chevron que
declara "toca para abrir el formulario". Una ✕ permanente (probada en la app y **rechazada
por el usuario**) competía con el monto y el chevron, y tres glifos al final rompen la
jerarquía. El gesto no agrega nada visible en reposo y usa el idioma móvil estándar para
"quitar de una lista".

### Geometría y tokens

- **Panel de acción:** 96 x 81 (alto real de la tarjeta), a la derecha, `$expense` fijo. El
  borde derecho lo aporta el `clip` del contenedor con radio 16 (mismo radio que la tarjeta).
- Contenido del panel, centrado: icono `trash-2` (lucide) 16px `$on-primary` + texto
  "Descartar" 11/700 `$on-primary`, gap 3.
- En reposo: exactamente la tarjeta aprobada (chevron 16 `$text-secondary` intacto). No se
  pinta ningún indicio del gesto.

### Comportamiento

- Dirección **solo** `endToStart` (derecha → izquierda). La dirección contraria no hace nada:
  no hay dos acciones compitiendo sobre la misma tarjeta.
- Umbral de descarte: **35% del ancho** (`Dismissible.dismissThresholds`).
- Al soltar por encima del umbral: descarta —`status = discarded`, **sin borrado físico**— y
  el Centro de avisos muestra el snackbar que ya existe: "Captura descartada" con acción
  **Deshacer** (5 s). Deshacer vuelve a `pending` (`RestorePendingCapture`).
- Si `discard` falla, la tarjeta vuelve a su lugar (no se saca de la lista localmente).
- Convención de escritura: el cubit/repositorio existentes no cambian; la tarjeta no escribe
  nada por su cuenta.

### Alcance

- **Sí:** captura simple (`skjlg`) y agrupada (`RSizy`), en el Centro de avisos.
- **No:** tarjeta de posible duplicado (`EqRlj`), que ya descarta con "Es la misma" y además
  registra contra qué movimiento se comparó.
- **No (por ahora):** fila fantasma de Movimientos (`vRWd5`). Si se agrega, requiere `discard`
  + undo en `PendingCapturesCubit`.

### Accesibilidad

- El gesto es invisible: en Flutter la tarjeta expone una **acción de accesibilidad**
  "Descartar captura" (`Semantics.customSemanticsActions`), para que un lector de pantalla
  pueda ejecutarla sin arrastrar.
- El panel rojo es el área tocable y mide 96x81 (≥44 en ambos ejes).
- Contraste texto/icono blanco (`$on-primary`) sobre `$expense` (#DC2626): **4.83:1**, pasa
  4.5:1 para texto normal en ambos temas (`$expense` es fijo por decisión de MASTER).
- El snackbar de Deshacer es el mecanismo de recuperación; no hay confirmación previa porque la
  acción es reversible.

### Temas

- Claro y oscuro comparten estructura y **recolorean 100% por variables** (el oscuro `bkNc1`
  es `Copy(IMs3M, {theme:{mode:'dark'}})`, sin overrides). `$expense` y `$on-primary` no
  cambian entre temas.

## Pendientes / notas de tooling

- El guardado del `.pen` por MCP falló durante esta sesión (`failed to save the document`);
  el usuario guardó manualmente al menos una vez. Verificar en el próximo arranque que
  `IMs3M` y `bkNc1` estén persistidos en el archivo.
- Si se retoma la idea de descartar también en Movimientos, la spec vive acá y se replica en
  `pages/transacciones.md` (la fila fantasma pertenece a esa pantalla).
