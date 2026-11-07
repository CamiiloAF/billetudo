# Descartar una captura por confirmar desde el Centro de avisos

**Fecha:** 2026-11-07 · **Tipo:** feature pequeña (UI + cableado, una sola capa) · **Estado:** implementada, tests y goldens verdes; frame de Pencil pendiente.

## Qué se pidió

"Agregar una opción para cancelar/eliminar una captura por confirmar."

El flujo de descarte **ya existía completo** en dominio y presentación: `DiscardPendingCapture` (mueve la fila a `status = discarded`, nunca borra físicamente) y `NoticesCubit.discard` con su snackbar "Captura descartada · Deshacer" y su undo (`RestorePendingCapture`). La única superficie que lo disparaba era la tarjeta de posible duplicado ("Es la misma"). Una captura normal no tenía cómo descartarse sin abrir el formulario, y el usuario no podía "cancelar" una captura que no iba a registrar.

Decisiones de producto tomadas con el usuario antes de implementar:

- **Interacción:** botón `✕` visible en la tarjeta (no swipe, no long-press).
- **Alcance:** solo el Centro de avisos (`/avisos`). El bloque "Pendientes de confirmar" de Movimientos queda fuera (requeriría extender `PendingCapturesCubit` con `discard` y su propio snackbar de undo; anotado como follow-up).
- **Sin hoja de confirmación:** el descarte es reversible con el snackbar de deshacer, así que un modal solo agregaría un toque a una acción que el usuario ya decidió. El patrón `Confirmar Eliminar` del sistema queda reservado para borrados irreversibles.

## Implementación

- **`lib/features/capture/presentation/widgets/capture_discard_button.dart`** (nuevo, público en su propio archivo): `IconButton` de **44x44** (mínimo del sistema, `tapTargetSize: shrinkWrap` para que Material no lo infle a 48), glifo `LucideIcons.x` de 18px, color `$text-secondary` — nunca `$expense`, porque es una acción reversible y secundaria. Tooltip/etiqueta de accesibilidad desde l10n.
- **`pending_capture_card.dart` / `grouped_capture_card.dart`**: nuevo `onDiscard` requerido. El botón **ocupa el slot del `chevron-right`**, que se retira: dos glifos al final competirían como un solo grupo y achicarían aún más la columna del comercio. La tarjeta sigue siendo tappable de punta a punta para despachar al formulario.
- **`captures_section.dart`**: `onDiscard` se propaga solo a las dos tarjetas de captura simple/agrupada. La tarjeta de duplicado conserva sus dos acciones propias ("Es la misma" ya descarta y además registra contra qué movimiento se comparó).
- **`notices_page.dart`**: `onDiscard: (item) => cubit.discard(item.id)` — el mismo flujo del duplicado, sin `duplicateOfTransactionId`.
- **l10n**: `captureDiscardAction` en `app_es.arb` ("Descartar captura") y `app_en.arb` ("Discard capture") + `flutter gen-l10n`.

Sin cambios de dominio, esquema, DI ni rutas. Nada de `Confirmar`/`Eliminar` irreversible: el descarte escribe `discarded` y queda en la ventana de undo.

## Tests y goldens

- `capture_discard_button_test.dart` (nuevo): 44x44, tooltip localizado, glifo correcto, color `$text-secondary` (nunca `$expense`), callback una sola vez.
- `notices_page_discard_test.dart` (nuevo): tocar `✕` llama `cubit.discard('capture-1')` y **no** despacha al formulario; tocar el cuerpo de la tarjeta sigue despachando y no descarta.
- `pending_capture_card_test.dart` / `grouped_capture_card_test.dart`: actualizados al nuevo contrato; el chevron ya no está, el affordance de descarte sí, y la tarjeta entera sigue despachando.
- `capture_cards_golden_test.dart` / `notices_page_golden_test.dart`: regenerados. **10 PNG afectados**: `pending_capture_card_with_issuer_{light,dark}`, `pending_capture_card_no_account_{light,dark}`, `grouped_capture_card_{light,dark}`, `notices_page_mixed_under_cap_{light,dark}`, `notices_page_over_cap_{light,dark}`. Los estados vacíos no cambian.
- Verificación: `flutter analyze` limpio sobre lo tocado (queda 1 warning preexistente en `ai_card_chips.dart`, de trabajo en vuelo ajeno) y `flutter test test/features/capture` **487/487 en verde**.

Efecto visual aceptado: el botón mide 44px donde el chevron medía 16, así que la columna de texto pierde ~28px y el subtítulo ("Cuenta Nu · 1 de septiembre, …") trunca un poco antes. Ya truncaba antes; el nombre del comercio sigue intacto en una línea.

## Pendiente / follow-up

1. **Frame en Pencil (gate de fidelidad).** No existe `design-system/billetudo/pages/avisos.md` ni frame documentado del Centro de avisos; esta corrida implementó la interacción acordada sin acceso al MCP de Pencil en la sesión. Falta que `pencil-designer` dibuje el estado de la tarjeta con el `✕` (claro y oscuro) y que se registre en el `.md` de la pantalla para que la fidelidad visual quede verificable. El cambio no altera tokens ni componentes: reusa el chasis existente y el patrón de tap target/tooltip de `NoticeBellButton`.
2. **Movimientos (fuera de alcance):** si se quiere el mismo descarte en el bloque "Pendientes de confirmar", hay que agregar `discard` + undo a `PendingCapturesCubit` y su snackbar en la página de Movimientos.
3. **Patrol e2e:** no se agregó escenario; el flujo feliz (descartar + deshacer) ya está cubierto a nivel widget/cubit. Un caso e2e encajaría en `integration_test/capture_inbox_patrol_test.dart` cuando se retome esa suite.
