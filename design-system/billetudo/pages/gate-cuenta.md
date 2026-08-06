# Página: Gate "necesitas una cuenta" (hoja puente)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** tema claro aprobado y auditado por `ui-ux-reviewer` para las 8 superficies de HU-03 (patrón base + transferencia 0/1 cuentas + encadenamiento + pago programado + deuda con caja + meta con movimiento + enlazar movimiento). Pendiente: tema oscuro — no se construye hasta que el claro esté 100% cerrado, y ya lo está. Requisitos en `docs/requirements/15-gate-cuenta.md`.

## Tesis (norte del diseño)

**"Puente, no muro":** la hoja nunca se presenta como error ni advertencia. Explica en una línea qué falta y ofrece resolverlo ahí mismo, sin desviar al usuario de la acción que quería hacer. Es un único componente compartido, parametrizado por copy — nunca una implementación por feature.

De 3 variantes de layout evaluadas (CTA único + link, botones dobles, paso a paso con step-indicator) se eligió **Variante B — Botones dobles**: mismo tratamiento que el resto de hojas de confirmación del sistema (ej. "Confirmar Eliminar"), lo que la hace la más consistente visualmente, cuidando que el copy nunca suene a advertencia para no leerse como una confirmación destructiva.

## Frames

Todos en tema Claro por ahora (oscuro pendiente).

| Pieza | Descripción | nodeId |
|---|---|---|
| Hoja puente — patrón base | Variante B, superficie "registrar movimiento" (FAB), 0 cuentas activas | `Zjsfz` |
| Copy — Transferencia · 0 cuentas | "Necesitas dos cuentas para transferir" — pide la primera, avisa que luego pedirá la segunda | `XYfSq` |
| Copy — Transferencia · 1 cuenta activa | "Necesitas una segunda cuenta" — copy distinto al de 0 cuentas, pide específicamente la segunda | `goGwA` |
| Anotación — Encadenamiento 0→1→2 cuentas | Diagrama de flechas (no una pantalla nueva) que documenta cómo se reabre la hoja | `j0YXVo` |
| Copy — Pago programado · 0 cuentas | "Crea una cuenta para tu pago programado" | `G0mfgY` |
| Copy — Deuda con caja (desembolso/abono que mueve dinero) · 0 cuentas | "Necesitas una cuenta para este movimiento" | `K6bGhq` |
| Copy — Meta con movimiento de dinero · 0 cuentas | "Necesitas una cuenta para este aporte" | `xU4uz` |
| Copy — Enlazar movimiento existente · 0 cuentas | "Aún no hay movimientos para enlazar" | `oHAVJ` |

## Componentes reutilizados (sin componentes nuevos)

Toda la hoja se construyó con componentes `reusable:true` ya existentes — no se creó ningún componente nuevo para esta feature:

- `Bottom Sheet Base` (`PqTUt`)
- `Sheet Icon Header` (`XPjIZ`)
- `Sheet Buttons Row` (`Ot4yI`) — botón secundario "Ahora no" + botón primario "Crear cuenta"
- `Button/Primary` (`j7Zvt`)

## Decisiones cerradas durante el diseño (no repetir la discusión)

- **Variante B (botones dobles) sobre A (CTA único + link) y C (paso a paso con step-indicator).** A y C se descartaron y se borraron del canvas al aprobar B, según higiene estándar de Pencil. B se prefirió por consistencia con el resto del sistema; el riesgo de leerse como confirmación/advertencia se mitiga con el copy, no con el layout.
- **Sin estado de transición "Cuenta creada / Continuando…".** Se diseñó un snackbar de transición (`afc4M`) tras crear la cuenta y se descartó por completo — no está en los criterios de aceptación de HU-01 (que solo exige "continúa automáticamente a la acción original", no un aviso intermedio) y el propio formulario de destino ya comunica el éxito al mostrar la cuenta recién creada seleccionada. Añadir un toast era fricción extra sobre un flujo que el requerimiento pide fluido, no interrumpido.
- **Encadenamiento de la segunda cuenta en transferencia con 0 cuentas activas: reabrir la misma hoja, no un flujo nuevo.** El usuario crea la primera cuenta desde la hoja con copy de `XYfSq`; esa hoja se cierra y automáticamente se reabre la misma hoja puente con el copy de `goGwA` ("segunda cuenta"). Es 2 pasos, no 3 (sin el toast intermedio que se descartó). No es un componente ni un frame nuevo — `j0YXVo` es una anotación que referencia los dos frames reales, no una pantalla adicional que implementar.
- **El icono cambia por superficie:** `landmark` (registrar movimiento), `arrow-left-right` (transferencia), `calendar-clock` (pago programado), `credit-card` (deuda con caja), `piggy-bank` (meta con movimiento), `link` (enlazar movimiento). Ninguna de las 4 superficies nuevas exige "1 cuenta activa" como la transferencia — todas solo requieren que exista *alguna* cuenta, así que no se repitió esa variante de copy para ellas.
- **Cancelar = tap en scrim o botón "Ahora no".** No se diseñó un estado explícito adicional; se asume el comportamiento estándar de `Bottom Sheet Base` (tap fuera de la hoja cierra sin cambios), a confirmar con `ui-ux-reviewer`.

## Auditoría de `ui-ux-reviewer`

Pasó sin hallazgos críticos ni importantes sobre el patrón base y las 3 superficies de referencia iniciales (`Zjsfz`, `XYfSq`, `goGwA`). Confirmó explícitamente que el tratamiento de "botones dobles" no se lee como confirmación destructiva (paleta `$primary` vs. `$expense` de "Confirmar Eliminar"), cero iconografía prohibida, y touch targets ~48px de alto. Único hallazgo menor — la anotación `j0YXVo` no se distinguía como diagrama a simple vista — corregido con el kicker `S03SB` ("⚠ DIAGRAMA — NO IMPLEMENTAR TAL CUAL").

## Pendiente / fuera de alcance de Pencil

- **El formulario de creación de cuenta embebido en la hoja** no se rediseñó — es el mismo de `pages/cuentas.md` (HU-01), solo referenciado, no reconstruido en este documento.
- **Tema oscuro:** no se construye hasta que el claro quede 100% cerrado — ya lo está para las 8 superficies de HU-03; queda pendiente pasar a tema oscuro cuando el flujo de la feature lo indique.
