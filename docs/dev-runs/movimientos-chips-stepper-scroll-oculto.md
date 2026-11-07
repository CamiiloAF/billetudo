# Dev-run — Chips de cuenta y Period Stepper ocultos al scrollear (Movimientos)

> **Fecha:** 2026-11-07 · **Estado:** implementado y verificado · **Nada commiteado.**
> Pedido explícito del usuario: «Qué tal si hacemos que los chips de cuentas y el card del mes se oculten igual que el fab?»

## Qué cambió y por qué

En Movimientos, el buscador, la fila de `Account Chip` y el `Period Stepper` («card del mes») estaban **fijos**: solo la lista scrolleaba, y el FAB ya era scroll-aware (se ocultaba al bajar y volvía al subir). El usuario pidió que los chips y el stepper se comporten igual que el FAB.

Resultado: al scrollear hacia abajo, chips + stepper se pliegan juntos (alto → 0 + fade, 200 ms) y la lista gana ese espacio; al scrollear hacia arriba reaparecen. El **buscador sigue siempre visible** (no se pidió ocultarlo) y el banner de modo enlace (Deudas/Metas) tampoco se pliega.

No hay frame nuevo en Pencil: Pencil no modela interacciones y la animación reutiliza el movimiento ya usado por el FAB (200 ms). En reposo (scroll 0) la pantalla es pixel-idéntica al diseño aprobado.

## Alcance técnico

- **Nuevo** `lib/core/widgets/scroll_aware_collapsible.dart`: `ScrollAwareCollapsible(visible, child)` — `StatefulWidget` con `AnimationController` de 200 ms (`Curves.easeInOut`) que anima `heightFactor` + opacidad, mantiene el hijo montado y lo saca de hit-testing/semantics mientras está oculto. **Detalle de implementación (regresión detectada por QA y corregida):** el `ClipRect` solo recorta **mientras está oculto o animando**; en reposo (visible e idle) usa `Clip.none` para no cortar decoraciones que desbordan su caja — el `Period Stepper` pinta un `BoxShadow` (blur 10, offset 0/3) que quedaba hard-clipped y desviaba **todos** los goldens de Movimientos (~964 px por golden). Además el `Align` usa `topLeft` (no `topCenter`): una fila de un solo chip quedaba centrada y movía los goldens del estado "barra sin renderizar". Acompaña a `ScrollAwareFab`/`ScrollAwareFabVisibility`.
- `lib/core/widgets/scroll_aware_fab_visibility.dart`: alias de lectura `scrollAwareVisible` = `_fabVisible`, para que otro chrome scroll-driven use la misma señal sin acoplarse al nombre "FAB".
- `lib/features/transactions/presentation/pages/transactions_page.dart`: chips + stepper envueltos en un único `ScrollAwareCollapsible(visible: scrollAwareVisible)`, preservando el espaciado exacto en reposo (el `SizedBox(8)` antes del banner/lista queda fuera del bloque plegable). Comentarios actualizados (antes decían "search and filters stay pinned").
- **Tests:** `transactions_page_scroll_chrome_test.dart` — cubre reposo, ocultado al bajar (opacity/heightFactor + FAB también oculto), reaparición al subir, buscador siempre visible y que el chrome oculto no recibe taps. Los goldens **no** se regeneran: en reposo no cambia un píxel.

## Verificación

- `flutter test test/features/transactions` → **608/608 verde** (incluye los 40 goldens de Movimientos pasando **sin regenerar** y los 6 tests nuevos de `transactions_page_scroll_chrome_test.dart`); el golden de `debt_link_mode_page` (otra pantalla que renderiza `TransactionsPage`) también verde.
- `flutter analyze` sin issues nuevos (persiste 1 warning preexistente y ajeno en `ai_card_chips.dart`, de trabajo en vuelo anterior).
- `dart format` limpio sobre los archivos tocados.
- QA detectó y se corrigió una regresión real durante la verificación: el `ClipRect` incondicional recortaba la sombra del `Period Stepper` en reposo y desviaba los 40 goldens (~964 px cada uno). El fix (clip solo al ocultar/animar + alineación `topLeft`) está cubierto ahora también por un test explícito del estado en reposo.

## Pendientes / próximos pasos

- Ninguno funcional. Si producto quisiera ocultar también el buscador, sería cambiar qué queda dentro del `ScrollAwareCollapsible` (el widget ya es reutilizable); hoy el pedido explícito fue solo chips + card del mes, y mantener el buscador fijo conserva "buscar siempre disponible".
- **Edge conocido (preexistente, no introducido acá):** el `CustomScrollView` de la rama "vacío" no está cableado al `fabScrollController`, así que en ese estado ni el FAB ni este bloque reaccionan al scroll (solo se cubre su estado expandido en reposo). Mientras el estado vacío no scrollee de verdad es inalcanzable; si en el futuro se vuelve scrolleable (p. ej. con muchas capturas pendientes), hay que cablear el controller para ambos.
- El `.pen` no requiere cambios: son estados de interacción, no de diseño estático; la referencia visual en reposo sigue siendo `B3GGa`/`xAk6Y`.
