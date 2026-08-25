# Página: Gate "necesitas una cuenta" (hoja puente)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado: diseño cerrado, claro + oscuro, auditado por `ui-ux-reviewer` en ambos temas.** Listo para `flutter-dev`. Requisitos en `docs/requirements/fase-1/15-gate-cuenta.md`.

## Tema oscuro

Copias 1:1 de las 7 superficies (`Zjsfz`, `XYfSq`, `goGwA`, `G0mfgY`, `K6bGhq`, `xU4uz`, `oHAVJ`) generadas con `Copy(...,{theme:{mode:'dark'}})`, sin overrides manuales de color — recoloreo automático por variable. `j0YXVo` (la anotación de encadenamiento) no se copió a oscuro a propósito: es documentación interna de flujo, no una pantalla que el usuario vea. Auditoría sin hallazgos: cero hex hardcodeado, fidelidad estructural exacta contra el claro, sin overflow/clipping nuevo.

| Claro | Oscuro |
|---|---|
| `Zjsfz` | `xQ0Je` |
| `XYfSq` | `rYNtV` |
| `goGwA` | `qG7Xu` |
| `G0mfgY` | `U1jF9l` |
| `K6bGhq` | `NHnn9` |
| `xU4uz` | `Yeiha` |
| `oHAVJ` | `sQfVw` |

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
| Copy — Presupuesto (bloqueante, decisión revertida 2026-08-06) · 0 cuentas | "Crea una cuenta para tu presupuesto" | `flt4U` |
| Copy — Meta, vincular cuenta (informativa, NO bloqueante) · 0 cuentas | "Vincula una cuenta a tu meta" | `kOr4c` |

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

## Superficies agregadas 2026-08-06 (bugs reales encontrados en producción)

- **Presupuestos pasó de "no se bloquea" a bloqueante** — decisión de producto explícita del usuario tras probar la app: toda la creación de presupuestos exige cuenta activa, incluido el alcance "Todo" (que en rigor no referencia ninguna cuenta puntual — se prioriza consistencia de flujo sobre esa posibilidad de dominio). Ver nota en `docs/requirements/fase-1/15-gate-cuenta.md`. Implementado como guarda de router en `/presupuestos/nuevo`.
- **Meta — vincular cuenta:** el campo "Cuenta vinculada (recomendado)" del formulario de Metas era un no-op silencioso al tocarlo sin cuentas activas — bug real, no una decisión de diseño. Se corrigió para mostrar la hoja puente de forma informativa (no bloqueante): crear la meta sin cuenta sigue funcionando igual que siempre.

## Pendiente / fuera de alcance de Pencil

- **El formulario de creación de cuenta embebido en la hoja** no se rediseñó — es el mismo de `pages/cuentas.md` (HU-01), solo referenciado, no reconstruido en este documento.
- **Tema oscuro:** no se construye hasta que el claro quede 100% cerrado. Las 8 superficies originales ya lo tienen; `flt4U` (Presupuesto) y `kOr4c` (Meta) quedan pendientes de su pasada de oscuro.
- **Auditoría de `ui-ux-reviewer`** sobre `flt4U`/`kOr4c`: no corrida todavía, quedó pendiente tras la aprobación directa del usuario.
