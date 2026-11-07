# Descartar una captura por confirmar con swipe (Centro de avisos)

**Fecha:** 2026-11-07 · **Tipo:** feature pequeña (diseño + UI, una sola capa) · **Estado:** diseño aprobado en claro y oscuro, implementado, tests y goldens verdes.

## Qué se pidió y qué se corrigió del primer intento

Se pidió "una opción para cancelar/eliminar una captura por confirmar". El flujo de descarte **ya existía** en dominio y presentación (`DiscardPendingCapture` → `status = discarded`, reversible con `RestorePendingCapture`) y solo lo disparaba la tarjeta de posible duplicado ("Es la misma"). Faltaba la acción en la tarjeta normal.

**Primer intento (rechazado por el usuario):** un botón `✕` de 44x44 al final de la tarjeta, reemplazando el chevron. Quedó implementado y commiteado (`a30966c2`) y el usuario lo rechazó por diseño. **Este documento describe el diseño que sí se aprobó**, y el commit citado queda como el punto donde se probó esa versión. Regla del repo aplicada después: **diseño primero en Pencil**, y solo con aprobación explícita se toca `lib/`.

## Diseño aprobado: swipe para descartar (variante C)

**Frames de referencia en `billetudo.pen`:** claro `IMs3M`, oscuro `bkNc1`
("CAPTURAS · Descartar con swipe — C"). Spec escrita en
[`design-system/billetudo/pages/avisos.md`](../../design-system/billetudo/pages/avisos.md).

- **Reposo:** la tarjeta aprobada (`skjlg` simple, `RSizy` agrupada) **no cambia**: chevron, monto y kicker intactos. Cero señales nuevas.
- **Gestos:** solo de derecha a izquierda (`endToStart`). Umbral **35%** del ancho.
- **Acción revelada:** slice de **96x81** en `$expense`, radio 16 por el clip de la tarjeta, basurero lucide 16 + "Descartar" 11/700 `$on-primary`.
- **Al soltar:** descarta (status `discarded`, sin borrado físico) y la página muestra el snackbar existente "Captura descartada · Deshacer" (5 s). Si la escritura falla, la tarjeta vuelve a su lugar.
- **Alcance:** Centro de avisos (`skjlg` + `RSizy`). **No** la tarjeta de duplicado (`EqRlj` ya tiene "Es la misma") ni la fila fantasma de Movimientos (`vRWd5`, fuera de alcance).
- **Accesibilidad:** el gesto es invisible, así que la tarjeta expone una **acción de accesibilidad** "Descartar captura" (`Semantics.customSemanticsActions`). El área revelada es 96x81 (≥44) y blanco sobre `$expense` da **4.83:1** (pasa 4.5 en ambos temas; `$expense` es fijo por MASTER).
- **Temas:** el oscuro es `Copy(IMs3M, {theme:{mode:'dark'}})`, recoloreado 100% por variables, sin overrides.

Variantes descartadas del canvas (A: link "Descartar" bajo el monto; B: menú `⋯`) y el marcador de revisión se borraron al aprobar.

## Implementación

- **`capture_swipe_dismissible.dart`** (nuevo): envuelve la tarjeta en `Dismissible` (`key` por id de captura, `direction: endToStart`, `dismissThresholds: 0.35`), `background` alineado a la derecha y `confirmDismiss` que **espera** `onDiscard` y devuelve `false` — el dueño de sacar la fila de la lista es el cubit/stream, no el widget (evita "dismissed Dismissible still in the tree" y deja el snap-back si la escritura falla). Expone la acción de accesibilidad.
- **`capture_swipe_action.dart`** (nuevo): el panel rojo (nodo `IMs3M`), tokens `$expense`/`$on-primary`, label desde l10n.
- **`captures_section.dart`**: `onDiscard` pasa a `Future<void> Function(CaptureReviewItem)` y envuelve **solo** captura simple y agrupada con `CaptureSwipeDismissible`.
- **`pending_capture_card.dart` / `grouped_capture_card.dart`**: vuelven a su estado aprobado (chevron restaurado); ya no conocen el descarte.
- **`notices_page.dart`**: `onDiscard: (item) => cubit.discard(item.id)`. Cubit, dominio y repositorio **no cambian**.
- **`capture_discard_button.dart`**: eliminado (era el ✕ rechazado), junto con su test.
- **l10n:** `captureDiscardSwipeLabel` ("Descartar"/"Discard") y se conserva `captureDiscardAction` ("Descartar captura") como etiqueta de la acción accesible.

## Tests y goldens

- `capture_swipe_dismissible_test.dart` (nuevo): cruzar el umbral descarta una vez; un arrastre corto no; la dirección contraria no; la acción revelada muestra basurero + "Descartar"; el lector de pantalla ejecuta la misma acción sin gesto.
- `notices_page_discard_test.dart`: el swipe descarta a través del cubit y **no** despacha al formulario; tocar la tarjeta sigue despachando. (El arrastre es de −400px porque el viewport de test es 800 de ancho: 35% ≈ 266px.)
- Tests de tarjetas restaurados a su contrato previo (chevron; sin `onDiscard`).
- **Goldens:** los 10 PNG de las capturas vuelven a la versión previa al ✕ (restaurados de `a30966c2^`) y se agregan 2 nuevos para el estado swipe: `capture_swipe_action_light.png` / `capture_swipe_action_dark.png` (gesto mantenido a mitad de arrastre, sin soltar). Los 3 archivos de golden de capturas pasan en verde.
- Verificación: `flutter analyze` limpio en lo tocado y `flutter test test/features/capture` en verde (497/497).

## Notas de tooling / pendientes

- El guardado del `.pen` **por MCP falló** durante toda la sesión (`failed to save the document`); el usuario guardó manualmente antes del oscuro. Verificar al próximo arranque que `IMs3M` y `bkNc1` están en el archivo y que el marcador de revisión ya no está. Posible causa: dos pestañas del mismo archivo y el `.pen` modificado en disco por otro proceso. La flakiness del MCP se mitigó reintentando y con llamadas chicas, pero es una deuda operativa.
- `EqRlj` y `vRWd5` quedaron fuera a propósito; si se quiere el swipe en Movimientos, el cubit de esa pantalla necesita `discard` + undo.
- La estrategia de commits (amend de `a30966c2` vs. commit nuevo encima) la decide el usuario; acá no se commitea.
