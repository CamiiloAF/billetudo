# Sesión de diseño — Transacciones (2026-07-13)

Cierre de sesión: qué se hizo, decisiones tomadas, y qué falta para continuar. Fuente real del diseño sigue siendo `billetudo.pen`; este documento es un mapa de la sesión, no reemplaza `design-system/billetudo/pages/transacciones.md` (spec vigente) ni `docs/requirements/03-transacciones.md` (HUs).

## 1. Requisitos refinados (`docs/requirements/03-transacciones.md`)

- **HU-06a (nueva)** — filtro rápido de cuentas: bottom sheet multi-selección, chip compacto según cantidad seleccionada (nombre / "N cuentas" / sin badge si todas), transferencias visibles si la cuenta filtrada es origen o destino, sin total sumado cuando hay monedas distintas seleccionadas.
- **HU-06b (nueva, reescrita 2 veces hoy)** — filtro rápido de fecha: selector de granularidad Semana/Mes/Año + stepper de un toque, "Todo" para quitar el filtro, "Rango personalizado" con confirmación aparte. **Decisión final del día:** el estado por defecto es **"Este mes"**, no "Todo" — evita sobrecargar la lista con todo el histórico de entrada.

## 2. Lista de transacciones (tab Movimientos) — **APROBADA, tema claro**

- Se exploraron 4 variantes (V1 chips-scroll+agrupado, V2 filtro-único+lista-continua, V3 chip-cuenta-protagonista+airy, V4 mezcla V1+V3).
- **Ganadora: V4**, nodo `B3GGa`, renombrado a **"Movimientos - Final (Claro)"**. Variantes descartadas ya borradas del canvas.
- Auditada por `ui-ux-reviewer` y corregida: contraste del Account Chip (label subido a 19px/700), chip de filtro por Etiqueta agregado (faltaba, lo exige HU-06).
- Documentada en `design-system/billetudo/pages/transacciones.md`.
- **Pendiente:** estados vacío/carga/error (solo existe "con datos"); tema oscuro (se hace al final, cuando toda la feature esté aprobada en claro, no solo esta pantalla).

## 3. Formulario Nueva/Editar transacción — **EN EXPLORACIÓN, sin aprobación final**

- 3 frames, uno por tipo del Segmented Control: `OUUdV` (Gasto), `EPZQj` (Ingreso), `VG9V2` (Transferencia).
- Patrón unificado a pedido del usuario: monto con calculadora protagonista + teclado con operadores básicos (`÷ × − +` `=`, nuevo componente reusable `Keypad` / `gHDTi`), categoría en grid de `Category Chip` (Transferencia no lleva categoría, correcto por HU-03).
- Auditados y corregidos 6 hallazgos de `ui-ux-reviewer`: gap/spacer roto de `EPZQj` (causa raíz: Buttons Row duplicada + check de header deshabilitado), tap target del Segmented Control (36px→44px, fix a nivel de componente `hFu41`), tipografía/contraste del Category Chip (11px→13px, nuevo token `primary-on-soft-strong`), Swap Button de Transferencia (36x36→44x44), inconsistencia de color del monto (Ingreso ahora usa `$income`, coherente con Gasto=`$text-primary` neutral y Transferencia=`$primary`).
- Verificado por una segunda pasada del reviewer: los 6 fixes están confirmados contra los nodos reales, no solo reportados.
- **Falta:** el usuario todavía no dio la aprobación explícita de una decisión final (el paso equivalente a lo que se hizo con la Lista) — mientras eso no pase, no se documenta como definitivo en `pages/transacciones.md` ni se considera cerrado.

## 4. Bottom sheet — Selector de fecha (HU-06b) — **CERRADO en tema claro**

- Se construyeron 4 candidatos: original `uUUdF` + 3 variantes (V-A lista vertical `SkoCg`, V-B stepper `P5fSkK`, V-C carrusel+años `AWzRJ`).
- Usuario eligió **V-B**, con mejoras ya aplicadas y confirmadas:
  1. La fila "Todo" (check de lista que competía con el stepper) fue reemplazada por un toggle "Ver todo" integrado al `Stepper Group`, que atenúa visualmente el stepper cuando se activa (mutuamente excluyentes, nunca ambos "activos" a la vez).
  2. Estado por defecto ajustado a **"Este mes"** (Julio 2026, granularidad Mes) — "Ver todo" queda inactivo por defecto.
  3. Divisores resueltos: ninguna sección lleva borde, solo `gap:16` consistente.
  4. Tap-area de "Rango personalizado" resuelta de raíz (se quitó `space_between`, se usa spacer explícito) — nota técnica conservada para `flutter-dev`.
  5. Candidatos descartados (`uUUdF`, `SkoCg`, `AWzRJ`) eliminados del canvas; `P5fSkK` renombrado a **"Sheet - Selector de Fecha - Final (Claro)"**.
- `snapshot_layout` sin hallazgos, verificado con screenshot. Documentado en `pages/transacciones.md`.
- **Pendiente:** interacción real de navegación del stepper (wrap de años, feedback de transición) sin definir, solo estado estático; contraste de "Ver todo" en tema oscuro sin verificar (se hace cuando se genere esa copia).

## Qué falta para continuar mañana (en orden sugerido)

1. **Ajustar el chip "Fecha" de la Lista (`B3GGa`)** para reflejar el nuevo default "Este mes" en su label de ejemplo (quedó pendiente de la última ronda, anotado en `pages/transacciones.md`).
2. **Decidir el Formulario Nueva/Editar transacción como definitivo** (aprobación explícita del usuario sobre `OUUdV`/`EPZQj`/`VG9V2`, ya con los 6 fixes aplicados) — mismo paso que ya se hizo con la Lista.
3. **Diseñar los bottom sheets que faltan:**
   - Filtro de cuentas (HU-06a) — el chip existe en la Lista pero no abre nada construido.
   - Filtro de categoría y filtro de tipo — mismo caso, chips sin sheet detrás.
   - "Rango personalizado" — solo existe el punto de entrada (fila con chevron), falta el selector de rango con confirmación.
4. **Diseñar los estados faltantes del Account Chip** en la Lista: "N cuentas" (2+ seleccionadas) y "todas" (sin badge) — solo se diseñó el caso de 1 cuenta.
5. **Construir estados vacío/carga/error** de la Lista de Movimientos (patrón ya documentado, siguiendo el de Inicio, pero sin frames construidos aún).
6. **Tema oscuro de toda la feature** — solo cuando el claro esté 100% aprobado en todas las pantallas de arriba (regla del proyecto: oscuro al final, después de componentizar lo repetido).
7. Una vez cerrado todo lo anterior, pasar a `flutter-dev` para implementación (Clean Architecture, según el flujo de `CLAUDE.md`).

## Nodos clave en `billetudo.pen` (fila TRANSACCIONES, y≈7196)

| Pieza | Node ID | Estado |
|---|---|---|
| Lista de Movimientos | `B3GGa` | Aprobada, renombrada a Final |
| Formulario — Gasto | `OUUdV` | Exploración, fixes aplicados |
| Formulario — Ingreso | `EPZQj` | Exploración, fixes aplicados |
| Formulario — Transferencia | `VG9V2` | Exploración, fixes aplicados |
| Selector de fecha — Final | `P5fSkK` | Cerrado en tema claro |
| Componente `Keypad` | `gHDTi` | Nuevo, reusable |
| Componente `Segmented Control` | `hFu41` | Tap target corregido |
| Componente `Category Chip` | `mK8oI` | Tipografía/contraste corregidos |
| Variable nueva | `primary-on-soft-strong` | Documentada en `MASTER.md` |
