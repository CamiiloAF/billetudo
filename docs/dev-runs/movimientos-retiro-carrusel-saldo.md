# Dev-run — Retiro del carrusel de saldo de Movimientos

> **Fecha:** 2026-11-07 · **Estado:** implementado y verificado · **Nada commiteado.**
> Pedido explícito del usuario: «Remove Accounts card in Movements Page».

## Qué se retiró y por qué

La Lista de Movimientos (pestaña **Movimientos**, `/movimientos`) mostraba, entre la fila de chips y la lista, el **carrusel de saldo** de Mejora #2 (2026-07-21): una `Balance Card` por cuenta del filtro, con peek/dots cuando había 2+ cuentas, una manija de colapso y una barra compacta «N cuentas · Saldo total» cuando estaba colapsado.

El usuario pidió eliminar ese bloque. No se reemplaza por nada: la pantalla vuelve a ser **header + buscador + chips de cuenta + Period Stepper + lista** (más los bloques que ya existían: capturas pendientes y total del periodo). El saldo por cuenta ya vive en Cuentas y en la Hoja de cuenta de Inicio, así que Movimientos deja de duplicarlo.

**Decisión de producto:** no hay rediseño ni frame nuevo en Pencil; es un retiro. La documentación de diseño (`design-system/billetudo/pages/transacciones.md`, sección «Retiro 2026-11-07») queda actualizada y los frames del carrusel se marcan obsoletos.

## Alcance técnico

**Eliminado (lib):**
- `lib/features/transactions/presentation/widgets/movements_balance_carousel.dart` (`MovementsBalanceCarousel`, `MovementsBalanceCarouselCollapsed`, `MovementsBalanceCarouselExpanded`).
- `lib/features/transactions/presentation/widgets/movements_balance_card.dart` (`MovementsBalanceCard`, variantes simple/tarjeta, figuras).
- `lib/core/preferences/balance_carousel_cubit.dart`, `balance_carousel_state.dart`, `balance_carousel_preference_datasource.dart` (persistencia per-device del colapso y página activa).
- Keys l10n `transactionsBalanceTotalLabel`, `transactionsBalanceTotalSemantics`, `transactionsBalanceCardBalanceLabel`, `transactionsBalanceCarouselCollapse`, `transactionsBalanceCarouselExpand` (es + en) y su código generado.

**Editado (lib):**
- `transactions_page.dart`: fuera las 3 inserciones del carrusel (estado vacío, lista ordenada por monto, lista agrupada), el flag `showCarousel` y la aritmética de slots; fuera el parámetro `onOpenAccount` de `TransactionsPage`/`TransactionsListView` (su único consumidor era el tap en una card).
- `transactions_list_state.dart`: fuera `displayedBalanceTotalMinor`/`displayedCurrency`; se conserva `displayedAccounts` porque alimenta la preselección del FAB.
- `app_router.dart`: fuera los providers de `BalanceCarouselCubit` (branch de Movimientos y modos de enlace Deudas/Metas) y el `onOpenAccount` de la ruta.
- Preselección del FAB: antes era la cuenta de la card activa del carrusel (página recordada); ahora es **la primera cuenta mostrada por el filtro** (null si no hay cuentas). Se preserva el caso útil: con una cuenta filtrada, el formulario abre en esa cuenta.

**Tests:** se eliminaron los tests/goldens del carrusel, se quitaron los providers `BalanceCarouselCubit` de los harnesses de página y se regeneraron solo los goldens de Movimientos afectados por el cambio de píxeles.

## Verificación

- `flutter analyze` sin issues nuevos (queda 1 warning **preexistente y ajeno** a este cambio: `unused_field '_chipMaxWidth'` en `lib/features/home/presentation/widgets/ai_card_chips.dart`, de trabajo en vuelo anterior a esta corrida).
- `flutter test` verde en `test/features/transactions` y en el golden de `debt_link_mode_page`; goldens afectados regenerados y revisados (la única diferencia esperada es la ausencia del bloque de saldos).
- Sin referencias residuales a las clases eliminadas ni a las keys l10n retiradas.

## Pendientes / próximos pasos

1. **Pencil:** borrar los frames obsoletos `cgasM`/`Y0lWi`, `rGVw1`/`uxIps`, `Ljf8l`/`RdbCG` y los componentes `C2g9cA`/`d2TX3`. No se pudo hacer en esta corrida (MCP de Pencil no disponible); queda para `pencil-designer`.
2. **Fidelidad visual:** los goldens de Movimientos se actualizaron por la ausencia del carrusel; no aplica una nueva corrida de `/design-fidelity-check` más allá de confirmar que el resto del chrome no cambió.
